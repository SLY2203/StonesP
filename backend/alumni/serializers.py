from rest_framework import serializers
from .models import AlumniProfile, GraduationRoster, MentorshipRequest
from accounts.serializers import UserSerializer
from careers.serializers import CareerRecordSerializer

class AlumniProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    is_verified = serializers.BooleanField(source='user.is_verified', read_only=True)
    current_job = serializers.SerializerMethodField()
    career_records = CareerRecordSerializer(many=True, read_only=True)
    skills_list = serializers.ListField(child=serializers.CharField(), read_only=True)
    profile_completeness_percent = serializers.IntegerField(read_only=True)

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user', 'full_name', 'email', 'is_verified',
            'registration_number', 'graduation_year', 'programme',
            'phone_number', 'address', 'bio',
            'linkedin_url', 'github_url', 'profile_photo',
            'skills', 'skills_list',
            'is_available_for_mentorship', 'mentorship_areas',
            'is_open_to_opportunities',
            'profile_completeness_percent',
            'current_job', 'career_records', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'registration_number', 'profile_completeness_percent', 'created_at', 'updated_at']

    def get_current_job(self, obj):
        current_career = obj.career_records.filter(is_current=True).first()
        if current_career:
            return {
                'id': current_career.id,
                'job_title': current_career.job_title,
                'employer': current_career.employer,
                'employment_status': current_career.employment_status,
                'industry_sector': current_career.industry_sector,
                'start_date': current_career.start_date.isoformat() if current_career.start_date else None,
                'end_date': current_career.end_date.isoformat() if current_career.end_date else None,
                'is_current': current_career.is_current,
                'description': current_career.description,
                'skills_used': current_career.skills_used,
                'created_at': current_career.created_at.strftime('%Y-%m-%d %H:%M:%S') if current_career.created_at else None,
                'updated_at': current_career.updated_at.strftime('%Y-%m-%d %H:%M:%S') if current_career.updated_at else None,
            }
        return None

class AlumniDirectoryItemSerializer(serializers.ModelSerializer):
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    is_verified = serializers.BooleanField(source='user.is_verified', read_only=True)
    current_job_title = serializers.SerializerMethodField()
    current_employer = serializers.SerializerMethodField()
    current_status = serializers.SerializerMethodField()
    current_job_start_date = serializers.SerializerMethodField()
    skills_list = serializers.ListField(child=serializers.CharField(), read_only=True)

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user_id', 'full_name', 'email', 'is_verified',
            'registration_number', 'graduation_year', 'programme',
            'phone_number', 'address', 'bio',
            'current_job_title', 'current_employer', 'current_status', 'current_job_start_date',
            'skills', 'skills_list', 'is_available_for_mentorship',
            'created_at', 'updated_at'
        ]

    def get_current_job_title(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.job_title if cur else None

    def get_current_employer(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.employer if cur else None

    def get_current_status(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.employment_status if cur else 'NOT_SPECIFIED'

    def get_current_job_start_date(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.start_date.isoformat() if (cur and cur.start_date) else None


class GraduationRosterSerializer(serializers.ModelSerializer):
    class Meta:
        model = GraduationRoster
        fields = ['id', 'registration_number', 'full_name', 'graduation_year', 'programme', 'degree_class', 'created_at']
        read_only_fields = ['id', 'created_at']


class GraduationRosterBatchUploadSerializer(serializers.Serializer):
    """
    Accepts raw CSV text or structured JSON list of roster records for bulk import.
    """
    roster_csv = serializers.CharField(required=False, allow_blank=True)
    records = serializers.ListField(child=serializers.DictField(), required=False)


class MentorDirectorySerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    current_job_title = serializers.SerializerMethodField()
    current_employer = serializers.SerializerMethodField()
    skills_list = serializers.ListField(child=serializers.CharField(), read_only=True)

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'full_name', 'email', 'programme', 'graduation_year',
            'current_job_title', 'current_employer',
            'skills', 'skills_list', 'mentorship_areas',
            'linkedin_url', 'bio'
        ]

    def get_current_job_title(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.job_title if cur else None

    def get_current_employer(self, obj):
        cur = obj.career_records.filter(is_current=True).first()
        return cur.employer if cur else None


class MentorshipRequestSerializer(serializers.ModelSerializer):
    mentor_name = serializers.CharField(source='mentor.user.get_full_name', read_only=True)
    mentor_email = serializers.EmailField(source='mentor.user.email', read_only=True)
    mentor_job = serializers.SerializerMethodField()
    mentee_name = serializers.CharField(source='mentee.user.get_full_name', read_only=True)
    mentee_email = serializers.EmailField(source='mentee.user.email', read_only=True)
    mentee_programme = serializers.CharField(source='mentee.programme', read_only=True)
    mentee_grad_year = serializers.IntegerField(source='mentee.graduation_year', read_only=True)

    class Meta:
        model = MentorshipRequest
        fields = [
            'id', 'mentor', 'mentor_name', 'mentor_email', 'mentor_job',
            'mentee', 'mentee_name', 'mentee_email', 'mentee_programme', 'mentee_grad_year',
            'topic', 'message', 'status', 'response_message',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'mentee', 'mentor_name', 'mentor_email', 'mentor_job',
            'mentee_name', 'mentee_email', 'mentee_programme', 'mentee_grad_year',
            'status', 'response_message', 'created_at', 'updated_at'
        ]

    def get_mentor_job(self, obj):
        cur = obj.mentor.career_records.filter(is_current=True).first()
        if cur:
            return f"{cur.job_title} at {cur.employer}"
        return "Alumnus"


class MentorshipResponseSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=['ACCEPTED', 'DECLINED', 'COMPLETED'])
    response_message = serializers.CharField(required=False, allow_blank=True)


class AdminCreateAlumnusSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(required=False, default='MsuAlumni@2025', allow_blank=True)
    registration_number = serializers.CharField(max_length=30)
    graduation_year = serializers.IntegerField(min_value=1990, max_value=2050)
    programme = serializers.ChoiceField(choices=AlumniProfile.PROGRAMME_CHOICES, default='BSc Hons Computer Science')
    phone_number = serializers.CharField(max_length=25, required=False, allow_blank=True)
    skills = serializers.CharField(max_length=500, required=False, allow_blank=True)
    bio = serializers.CharField(required=False, allow_blank=True)
    is_verified = serializers.BooleanField(default=True)

    # Optional initial career info
    current_job_title = serializers.CharField(max_length=150, required=False, allow_blank=True)
    current_employer = serializers.CharField(max_length=150, required=False, allow_blank=True)
    employment_status = serializers.CharField(max_length=30, required=False, default='EMPLOYED', allow_blank=True)
    industry_sector = serializers.CharField(max_length=100, required=False, default='Software & IT Services', allow_blank=True)

    def validate_email(self, value):
        from accounts.models import User
        if User.objects.filter(email__iexact=value.strip()).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.strip().lower()

    def validate_registration_number(self, value):
        reg = value.strip().upper()
        if AlumniProfile.objects.filter(registration_number__iexact=reg).exists():
            raise serializers.ValidationError(f"An alumnus with registration number '{reg}' is already registered.")
        return reg

    def create(self, validated_data):
        import datetime
        from django.db import transaction
        from accounts.models import User
        from careers.models import CareerRecord

        with transaction.atomic():
            reg_num = validated_data['registration_number'].strip().upper()
            first_name = validated_data['first_name'].strip()
            last_name = validated_data['last_name'].strip()
            full_name = f"{first_name} {last_name}".strip()
            grad_year = validated_data['graduation_year']
            programme = validated_data.get('programme', 'BSc Hons Computer Science')
            is_verified = validated_data.get('is_verified', True)

            # Ensure consistent entry in official GraduationRoster
            GraduationRoster.objects.update_or_create(
                registration_number=reg_num,
                defaults={
                    'full_name': full_name,
                    'graduation_year': grad_year,
                    'programme': programme,
                    'degree_class': 'Pass'
                }
            )

            # Create User account
            pwd = (validated_data.get('password') or '').strip()
            if not pwd:
                pwd = 'MsuAlumni@2025'
            user = User(
                email=validated_data['email'],
                username=reg_num,
                first_name=first_name,
                last_name=last_name,
                role=User.UserRole.ALUMNI,
                is_verified=is_verified
            )
            user.set_password(pwd)
            user.save()

            # Create AlumniProfile
            profile = AlumniProfile.objects.create(
                user=user,
                registration_number=reg_num,
                graduation_year=grad_year,
                programme=programme,
                phone_number=validated_data.get('phone_number', ''),
                skills=validated_data.get('skills', ''),
                bio=validated_data.get('bio', ''),
                is_available_for_mentorship=False
            )

            # Optional Career Record
            job_title = (validated_data.get('current_job_title') or '').strip()
            employer = (validated_data.get('current_employer') or '').strip()
            if job_title or employer:
                CareerRecord.objects.create(
                    alumnus=profile,
                    job_title=job_title or 'Graduate Trainee / Professional',
                    employer=employer or 'Self-Employed / Independent',
                    employment_status=validated_data.get('employment_status') or 'EMPLOYED',
                    industry_sector=validated_data.get('industry_sector') or 'Software & IT Services',
                    start_date=datetime.date(grad_year, 1, 1),
                    is_current=True
                )

            return profile


