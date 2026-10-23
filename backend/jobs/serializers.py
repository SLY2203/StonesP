from rest_framework import serializers
from .models import JobVacancy, JobMatch, JobApplication


class JobVacancySerializer(serializers.ModelSerializer):
    experience_display = serializers.CharField(source='get_experience_level_display', read_only=True)
    type_display = serializers.CharField(source='get_job_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    posted_by_name = serializers.CharField(source='posted_by.get_full_name', read_only=True)
    required_skills_list = serializers.ListField(child=serializers.CharField(), read_only=True)
    total_matches = serializers.SerializerMethodField()
    total_applications = serializers.SerializerMethodField()

    class Meta:
        model = JobVacancy
        fields = [
            'id', 'title', 'company', 'description', 'location', 'salary_range',
            'required_skills', 'required_skills_list', 'experience_level', 'experience_display',
            'job_type', 'type_display', 'industry_sector', 'qualifications', 'responsibilities',
            'raw_advert_text', 'status', 'status_display',
            'application_url', 'application_deadline',
            'posted_by', 'posted_by_name', 'total_matches', 'total_applications',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'posted_by', 'posted_by_name',
            'experience_display', 'type_display', 'status_display',
            'required_skills_list', 'total_matches', 'total_applications',
            'created_at', 'updated_at',
        ]

    def get_total_matches(self, obj):
        return obj.matches.count()

    def get_total_applications(self, obj):
        return obj.applications.count()


class JobVacancyCreateFromAdvertSerializer(serializers.Serializer):
    """
    Accepts raw job advert text. The AI service extracts structured fields.
    Admin can optionally override any extracted field.
    """
    raw_advert_text = serializers.CharField(required=True, help_text="Paste the raw job advert text here")
    # Optional overrides (admin can correct AI-extracted values)
    title = serializers.CharField(required=False, allow_blank=True)
    company = serializers.CharField(required=False, allow_blank=True)
    location = serializers.CharField(required=False, allow_blank=True)
    salary_range = serializers.CharField(required=False, allow_blank=True)
    required_skills = serializers.CharField(required=False, allow_blank=True)
    experience_level = serializers.ChoiceField(choices=JobVacancy.EXPERIENCE_LEVEL_CHOICES, required=False)
    job_type = serializers.ChoiceField(choices=JobVacancy.JOB_TYPE_CHOICES, required=False)
    industry_sector = serializers.CharField(required=False, allow_blank=True)
    application_url = serializers.URLField(required=False, allow_blank=True)
    application_deadline = serializers.DateTimeField(required=False, allow_null=True)


class JobMatchSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_email = serializers.EmailField(source='alumnus.user.email', read_only=True)
    alumnus_reg = serializers.CharField(source='alumnus.registration_number', read_only=True)
    alumnus_programme = serializers.CharField(source='alumnus.programme', read_only=True)
    alumnus_grad_year = serializers.IntegerField(source='alumnus.graduation_year', read_only=True)
    alumnus_skills = serializers.CharField(source='alumnus.skills', read_only=True)
    job_title = serializers.CharField(source='job.title', read_only=True)
    job_company = serializers.CharField(source='job.company', read_only=True)

    class Meta:
        model = JobMatch
        fields = [
            'id', 'job', 'job_title', 'job_company',
            'alumnus', 'alumnus_name', 'alumnus_email', 'alumnus_reg',
            'alumnus_programme', 'alumnus_grad_year', 'alumnus_skills',
            'match_score', 'skills_overlap', 'match_reasons',
            'is_notified', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class JobApplicationSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_email = serializers.EmailField(source='alumnus.user.email', read_only=True)
    job_title = serializers.CharField(source='job.title', read_only=True)
    job_company = serializers.CharField(source='job.company', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = JobApplication
        fields = [
            'id', 'job', 'job_title', 'job_company',
            'alumnus', 'alumnus_name', 'alumnus_email',
            'status', 'status_display', 'cover_note',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'alumnus', 'alumnus_name', 'alumnus_email',
            'job_title', 'job_company', 'status_display',
            'created_at', 'updated_at',
        ]
