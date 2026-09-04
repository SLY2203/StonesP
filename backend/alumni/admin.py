from django.contrib import admin
from .models import AlumniProfile

@admin.register(AlumniProfile)
class AlumniProfileAdmin(admin.ModelAdmin):
    list_display = ('registration_number', 'get_full_name', 'get_email', 'graduation_year', 'programme', 'get_verified')
    list_filter = ('graduation_year', 'programme', 'user__is_verified')
    search_fields = ('registration_number', 'user__first_name', 'user__last_name', 'user__email')

    def get_full_name(self, obj):
        return obj.user.get_full_name()
    get_full_name.short_description = 'Full Name'

    def get_email(self, obj):
        return obj.user.email
    get_email.short_description = 'Email'

    def get_verified(self, obj):
        return obj.user.is_verified
    get_verified.boolean = True
    get_verified.short_description = 'Verified'
