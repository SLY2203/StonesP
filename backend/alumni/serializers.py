from rest_framework import serializers
from .models import AlumniProfile
from accounts.serializers import UserSerializer

class AlumniProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    is_verified = serializers.BooleanField(source='user.is_verified', read_only=True)
    current_job = serializers.SerializerMethodField()

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user', 'full_name', 'email', 'is_verified',
            'registration_number', 'graduation_year', 'programme',
            'phone_number', 'address', 'bio',
            'linkedin_url', 'github_url', 'profile_photo',
            'current_job', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'registration_number', 'created_at', 'updated_at']

    def get_current_job(self, obj):
        current_career = obj.career_records.filter(is_current=True).first()
        if current_career:
            return {
                'job_title': current_career.job_title,
                'employer': current_career.employer,
                'employment_status': current_career.employment_status,
                'industry_sector': current_career.industry_sector,
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

    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user_id', 'full_name', 'email', 'is_verified',
            'registration_number', 'graduation_year', 'programme',
            'phone_number', 'current_job_title', 'current_employer', 'current_status',
            'created_at'
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
