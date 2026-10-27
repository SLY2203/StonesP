from django.contrib import admin
from .models import AlumniProfile, GraduationRoster, MentorshipRequest, VerificationRequest
from careers.models import CareerRecord

class CareerRecordInline(admin.TabularInline):
    model = CareerRecord
    extra = 0
    fields = ('job_title', 'employer', 'employment_status', 'industry_sector', 'is_current', 'start_date', 'end_date')

@admin.register(AlumniProfile)
class AlumniProfileAdmin(admin.ModelAdmin):
    list_display = ('registration_number', 'get_full_name', 'get_email', 'graduation_year', 'programme', 'get_verified', 'is_available_for_mentorship', 'created_at')
    list_filter = ('graduation_year', 'programme', 'user__is_verified', 'is_available_for_mentorship', 'is_open_to_opportunities')
    search_fields = ('registration_number', 'user__first_name', 'user__last_name', 'user__email', 'skills')
    inlines = [CareerRecordInline]
    ordering = ('-graduation_year', 'user__last_name')

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

@admin.register(GraduationRoster)
class GraduationRosterAdmin(admin.ModelAdmin):
    list_display = ('registration_number', 'full_name', 'graduation_year', 'programme', 'degree_class', 'created_at')
    list_filter = ('graduation_year', 'programme', 'degree_class')
    search_fields = ('registration_number', 'full_name')
    ordering = ('-graduation_year', 'registration_number')

@admin.register(MentorshipRequest)
class MentorshipRequestAdmin(admin.ModelAdmin):
    list_display = ('mentee_name', 'mentor_name', 'topic', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('mentor__user__first_name', 'mentor__user__last_name', 'mentee__user__first_name', 'mentee__user__last_name', 'topic')

    def mentor_name(self, obj):
        return obj.mentor.user.get_full_name()
    mentor_name.short_description = 'Mentor'

    def mentee_name(self, obj):
        return obj.mentee.user.get_full_name()
    mentee_name.short_description = 'Mentee'

@admin.register(VerificationRequest)
class VerificationRequestAdmin(admin.ModelAdmin):
    list_display = ('registration_number', 'full_name', 'email', 'graduation_year', 'programme', 'status', 'created_at')
    list_filter = ('status', 'graduation_year', 'programme', 'created_at')
    search_fields = ('registration_number', 'full_name', 'email', 'notes')
    actions = ['approve_verification_requests']

    def approve_verification_requests(self, request, queryset):
        from django.utils import timezone
        count = 0
        for req in queryset:
            req.status = VerificationRequest.Status.APPROVED
            req.reviewed_at = timezone.now()
            req.save()

            # Ensure graduation roster entry exists
            GraduationRoster.objects.update_or_create(
                registration_number=req.registration_number.upper(),
                defaults={
                    'full_name': req.full_name,
                    'graduation_year': req.graduation_year or 2024,
                    'programme': req.programme or 'BSc Hons Computer Science',
                    'degree_class': 'Pass',
                }
            )

            # If user exists, mark verified
            if req.user:
                req.user.is_verified = True
                req.user.save()
            count += 1
        self.message_user(request, f"{count} verification request(s) approved and verified.")
    approve_verification_requests.short_description = 'Approve & Verify Selected Requests'

