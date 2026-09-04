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
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = user.role
        token['is_verified'] = user.is_verified
        token['full_name'] = user.get_full_name()
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
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
        if AlumniProfile.objects.filter(registration_number__iexact=reg).exists():
            raise serializers.ValidationError("An alumnus with this registration number is already registered.")
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

        user = User.objects.create_user(
            username=username,
            email=email,
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=User.UserRole.ALUMNI,
            is_verified=False  # Must be approved by department admin
        )

        AlumniProfile.objects.create(
            user=user,
            registration_number=reg_num,
            graduation_year=grad_year,
            programme=programme,
            phone_number=phone
        )

        return user

class VerifyAlumnusSerializer(serializers.Serializer):
    is_verified = serializers.BooleanField()
    notes = serializers.CharField(required=False, allow_blank=True)
