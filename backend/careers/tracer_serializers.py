from rest_framework import serializers
from .tracer_models import TracerSurvey


class TracerSurveySerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_reg = serializers.CharField(source='alumnus.registration_number', read_only=True)
    alumnus_programme = serializers.CharField(source='alumnus.programme', read_only=True)
    alumnus_grad_year = serializers.IntegerField(source='alumnus.graduation_year', read_only=True)
    relevance_display = serializers.CharField(source='get_degree_relevance_display', read_only=True)
    salary_display = serializers.CharField(source='get_current_salary_band_display', read_only=True)
    search_method_display = serializers.CharField(source='get_job_search_method_display', read_only=True)

    class Meta:
        model = TracerSurvey
        fields = [
            'id', 'alumnus', 'alumnus_name', 'alumnus_reg', 'alumnus_programme', 'alumnus_grad_year',
            'months_to_first_job', 'had_job_before_graduation',
            'first_job_title', 'first_employer', 'first_job_sector',
            'current_salary_band', 'salary_display',
            'degree_relevance', 'relevance_display',
            'career_satisfaction', 'curriculum_satisfaction',
            'job_search_method', 'search_method_display',
            'skills_gap', 'additional_comments',
            'is_complete', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'alumnus', 'alumnus_name', 'alumnus_reg',
            'alumnus_programme', 'alumnus_grad_year',
            'relevance_display', 'salary_display', 'search_method_display',
            'created_at', 'updated_at',
        ]
