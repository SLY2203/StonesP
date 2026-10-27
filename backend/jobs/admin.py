from django.contrib import admin
from .models import JobVacancy, JobMatch, JobApplication

@admin.register(JobVacancy)
class JobVacancyAdmin(admin.ModelAdmin):
    list_display = ('title', 'company', 'experience_level', 'job_type', 'status', 'created_at')
    list_filter = ('status', 'experience_level', 'job_type', 'industry_sector')
    search_fields = ('title', 'company', 'description', 'required_skills')
    ordering = ('-created_at',)

@admin.register(JobMatch)
class JobMatchAdmin(admin.ModelAdmin):
    list_display = ('job_title', 'alumnus_name', 'match_score', 'is_notified', 'created_at')
    list_filter = ('is_notified',)
    search_fields = ('job__title', 'alumnus__user__first_name', 'alumnus__user__last_name')
    ordering = ('-match_score',)

    def job_title(self, obj):
        return obj.job.title
    job_title.short_description = 'Job Vacancy'

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'

@admin.register(JobApplication)
class JobApplicationAdmin(admin.ModelAdmin):
    list_display = ('job_title', 'alumnus_name', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('job__title', 'alumnus__user__first_name', 'alumnus__user__last_name')

    def job_title(self, obj):
        return obj.job.title
    job_title.short_description = 'Job Vacancy'

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'
