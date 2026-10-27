from django.contrib import admin
from .models import CareerRecord
from .tracer_models import TracerSurvey

@admin.register(CareerRecord)
class CareerRecordAdmin(admin.ModelAdmin):
    list_display = ('job_title', 'employer', 'alumnus_name', 'employment_status', 'industry_sector', 'is_current', 'start_date')
    list_filter = ('employment_status', 'industry_sector', 'is_current')
    search_fields = ('job_title', 'employer', 'alumnus__user__first_name', 'alumnus__user__last_name', 'alumnus__registration_number')

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'

@admin.register(TracerSurvey)
class TracerSurveyAdmin(admin.ModelAdmin):
    list_display = ('alumnus_name', 'months_to_first_job', 'current_salary_band', 'degree_relevance', 'is_complete', 'created_at')
    list_filter = ('current_salary_band', 'degree_relevance', 'is_complete')
    search_fields = ('alumnus__user__first_name', 'alumnus__user__last_name', 'alumnus__registration_number')

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'
