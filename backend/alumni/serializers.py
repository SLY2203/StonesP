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

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user', 'full_name', 'email', 'is_verified',
            'registration_number', 'graduation_year', 'programme',
            'phone_number', 'address', 'bio',
            'linkedin_url', 'github_url', 'profile_photo',
            'skills', 'skills_list',
            'is_available_for_mentorship', 'mentorship_areas',
            'current_job', 'career_records', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'registration_number', 'created_at', 'updated_at']

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

