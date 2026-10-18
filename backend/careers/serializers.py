from rest_framework import serializers
from .models import CareerRecord

class CareerRecordSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    status_display = serializers.CharField(source='get_employment_status_display', read_only=True)

    class Meta:
        model = CareerRecord
        fields = [
            'id', 'alumnus', 'alumnus_name', 'job_title', 'employer',
            'employment_status', 'status_display', 'industry_sector',
            'start_date', 'end_date', 'is_current',
            'further_education_institution', 'further_education_programme',
            'description', 'skills_used', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'alumnus', 'alumnus_name', 'status_display', 'created_at', 'updated_at']

    def validate(self, attrs):
        start = attrs.get('start_date')
        end = attrs.get('end_date')
        is_current = attrs.get('is_current', False)

        if end and start and end < start:
            raise serializers.ValidationError({"end_date": "End date cannot be earlier than start date."})

        if is_current and end is not None:
            attrs['end_date'] = None

        return attrs
