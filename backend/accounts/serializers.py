import re
from rest_framework import serializers
from django.db import transaction
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User
from alumni.models import AlumniProfile

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Custom JWT serializer returning role, verification status, and profile info
    directly in the login response to simplify frontend route guards.
    """
    role = serializers.CharField(required=False, write_only=True)

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = user.role
        token['is_verified'] = user.is_verified
        token['full_name'] = user.get_full_name()
        return token

    def validate(self, attrs):
        expected_role = attrs.get('role')
        data = super().validate(attrs)
        user = self.user

        if expected_role and user.role != expected_role:
            role_label = "Administrator" if user.role == User.UserRole.ADMIN else "Alumnus"
            expected_label = "Administrator" if expected_role == User.UserRole.ADMIN else "Alumnus"
            raise serializers.ValidationError({
                'detail': f"Access Denied: This account is registered as an {role_label}, but you selected the {expected_label} portal. Please select the correct role."
            })

        data['user'] = {
            'id': user.id,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role,
            'is_verified': user.is_verified,
        }
        if hasattr(user, 'alumni_profile'):
            profile = user.alumni_profile
            data['user']['profile'] = {
                'id': profile.id,
                'registration_number': profile.registration_number,
                'graduation_year': profile.graduation_year,
                'programme': profile.programme,
            }
        return data

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'role', 'is_verified', 'date_joined']
        read_only_fields = ['id', 'role', 'is_verified', 'date_joined']

class RegisterAlumniSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    registration_number = serializers.CharField(write_only=True)
    graduation_year = serializers.IntegerField(write_only=True)
    programme = serializers.CharField(write_only=True, default='BSc Hons Computer Science')
    phone_number = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'email', 'password', 'first_name', 'last_name',
            'registration_number', 'graduation_year', 'programme', 'phone_number'
        ]

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()

    def validate_registration_number(self, value):
        reg = value.strip().upper()
        # Enforce MSU registration number format: R followed by 4-6 digits and a letter
        if not re.match(r'^R\d{4,6}[A-Z]$', reg):
            raise serializers.ValidationError(
                "Invalid MSU registration number format. Expected pattern: R followed by 4-6 digits and a letter (e.g. R201456B)."
            )
        if AlumniProfile.objects.filter(registration_number__iexact=reg).exists():
            raise serializers.ValidationError("An alumnus with this registration number is already registered.")

        from alumni.models import GraduationRoster
        if not GraduationRoster.objects.filter(registration_number__iexact=reg).exists():
            raise serializers.ValidationError(
                f"Registration number '{reg}' is not found in the official MSU DCS Graduation Database. Only verified graduates can register. Please wait for the administrator to verify your record."
            )

        return reg

    @transaction.atomic
    def create(self, validated_data):
        reg_num = validated_data.pop('registration_number')
        grad_year = validated_data.pop('graduation_year')
        programme = validated_data.pop('programme')
        phone = validated_data.pop('phone_number', '')

        # Generate unique username from email
        email = validated_data['email']
        username = email.split('@')[0]
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        from alumni.models import GraduationRoster, VerificationRequest
        from communications.models import InAppNotification

        # Auto-verify if the registration number exists in the official Graduation Roster
        roster_entry = GraduationRoster.objects.filter(registration_number__iexact=reg_num).first()
        is_auto_verified = bool(roster_entry)

        # Cross-validate graduation year and name against roster if entry found
        roster_year_mismatch = False
        roster_name_mismatch = False
        NAME_SIMILARITY_THRESHOLD = 80  # % fuzzy similarity required to auto-verify

        if roster_entry:
            if roster_entry.graduation_year != grad_year:
                roster_year_mismatch = True

            # Fuzzy name matching using rapidfuzz token_sort_ratio
            submitted_name = f"{validated_data.get('first_name', '')} {validated_data.get('last_name', '')}".strip()
            roster_name = roster_entry.full_name.strip()
            if submitted_name and roster_name:
                try:
                    from rapidfuzz import fuzz
                    similarity = max(
                        fuzz.token_sort_ratio(submitted_name.lower(), roster_name.lower()),
                        fuzz.token_set_ratio(submitted_name.lower(), roster_name.lower())
                    )
                    if similarity < NAME_SIMILARITY_THRESHOLD:
                        roster_name_mismatch = True
                        is_auto_verified = False
                except ImportError:
                    submitted_parts = set(submitted_name.lower().split())
                    roster_parts = set(roster_name.lower().split())
                    if not submitted_parts.intersection(roster_parts):
                        roster_name_mismatch = True
                        is_auto_verified = False

        user = User.objects.create_user(
            username=username,
            email=email,
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=User.UserRole.ALUMNI,
            is_verified=is_auto_verified
        )

        AlumniProfile.objects.create(
            user=user,
            registration_number=reg_num,
            graduation_year=grad_year,
            programme=programme,
            phone_number=phone
        )

        # Notify administrator if user is not auto-verified (or not in roster)
        if not is_auto_verified:
            full_name = user.get_full_name()
            VerificationRequest.objects.update_or_create(
                registration_number=reg_num,
                defaults={
                    'user': user,
                    'full_name': full_name,
                    'email': user.email,
                    'graduation_year': grad_year,
                    'programme': programme,
                    'phone_number': phone,
                    'status': VerificationRequest.Status.PENDING,
                    'notes': 'Account registered by graduate; awaiting administrator verification approval.'
                }
            )

            admin_users = User.objects.filter(role=User.UserRole.ADMIN)
            for admin in admin_users:
                InAppNotification.objects.create(
                    user=admin,
                    title=f"New Pending Account: {full_name} ({reg_num})",
                    message=f"Alumnus {full_name} ({reg_num}, {email}) created an account and is awaiting verification approval.",
                    category='SYSTEM',
                    reference_id=str(user.id),
                    action_url='/admin/alumni/verificationrequest/'
                )

        user.is_auto_verified = is_auto_verified
        user.roster_year_mismatch = roster_year_mismatch
        user.roster_name_mismatch = roster_name_mismatch
        return user


class VerifyAlumnusSerializer(serializers.Serializer):
    is_verified = serializers.BooleanField()
    notes = serializers.CharField(required=False, allow_blank=True)
