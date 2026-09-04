from django.contrib import admin
from .models import Communication, RSVP

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
