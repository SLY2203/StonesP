from django.contrib import admin
from .models import CareerRecord

@admin.register(CareerRecord)
class CareerRecordAdmin(admin.ModelAdmin):
    list_display = ('job_title', 'employer', 'alumnus_name', 'employment_status', 'industry_sector', 'is_current', 'start_date')
    list_filter = ('employment_status', 'industry_sector', 'is_current')
    search_fields = ('job_title', 'employer', 'alumnus__user__first_name', 'alumnus__user__last_name')

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'
