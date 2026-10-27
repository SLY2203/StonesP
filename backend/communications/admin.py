from django.contrib import admin
from .models import (
    Communication,
    RSVP,
    DepartmentFeedback,
    SystemFeedbackSurvey,
    InAppNotification,
    CommunicationReadReceipt,
)

@admin.register(Communication)
class CommunicationAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'target_graduation_year', 'created_by', 'event_date', 'created_at')
    list_filter = ('category', 'target_graduation_year', 'created_at')
    search_fields = ('title', 'content', 'location')

@admin.register(RSVP)
class RSVPAdmin(admin.ModelAdmin):
    list_display = ('communication', 'alumnus', 'response_type', 'created_at')
    list_filter = ('response_type', 'created_at')
    search_fields = ('communication__title', 'alumnus__user__first_name', 'alumnus__user__last_name')

@admin.register(DepartmentFeedback)
class DepartmentFeedbackAdmin(admin.ModelAdmin):
    list_display = ('subject', 'alumnus_name', 'category', 'is_reviewed', 'created_at')
    list_filter = ('category', 'is_reviewed', 'created_at')
    search_fields = ('subject', 'message', 'alumnus__user__first_name', 'alumnus__user__last_name')

    def alumnus_name(self, obj):
        return obj.alumnus.user.get_full_name()
    alumnus_name.short_description = 'Alumnus'

@admin.register(SystemFeedbackSurvey)
class SystemFeedbackSurveyAdmin(admin.ModelAdmin):
    list_display = ('user_name', 'overall_rating', 'ease_of_use_rating', 'features_rating', 'performance_rating', 'system_aspect', 'would_recommend', 'created_at')
    list_filter = ('overall_rating', 'system_aspect', 'would_recommend', 'created_at')
    search_fields = ('user__first_name', 'user__last_name', 'user__email', 'what_works_well', 'improvements_needed')

    def user_name(self, obj):
        return obj.user.get_full_name()
    user_name.short_description = 'User'

@admin.register(InAppNotification)
class InAppNotificationAdmin(admin.ModelAdmin):
    list_display = ('user_email', 'title', 'category', 'is_read', 'created_at')
    list_filter = ('category', 'is_read', 'created_at')
    search_fields = ('user__email', 'title', 'message')

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'User Email'

@admin.register(CommunicationReadReceipt)
class CommunicationReadReceiptAdmin(admin.ModelAdmin):
    list_display = ('communication_title', 'user_email', 'read_at')
    search_fields = ('communication__title', 'user__email')

    def communication_title(self, obj):
        return obj.communication.title
    communication_title.short_description = 'Broadcast'

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'User Email'
