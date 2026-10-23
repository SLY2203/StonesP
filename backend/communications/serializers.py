from rest_framework import serializers
from .models import (
    Communication,
    RSVP,
    DepartmentFeedback,
    SystemFeedbackSurvey,
    InAppNotification,
    CommunicationReadReceipt,
)

class RSVPSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_reg = serializers.CharField(source='alumnus.registration_number', read_only=True)
    alumnus_email = serializers.EmailField(source='alumnus.user.email', read_only=True)
    alumnus_programme = serializers.CharField(source='alumnus.programme', read_only=True)
    alumnus_grad_year = serializers.IntegerField(source='alumnus.graduation_year', read_only=True)
    communication_title = serializers.CharField(source='communication.title', read_only=True)
    communication_category = serializers.CharField(source='communication.category', read_only=True)
    communication_category_display = serializers.CharField(source='communication.get_category_display', read_only=True)

    class Meta:
        model = RSVP
        fields = [
            'id', 'communication', 'alumnus', 'alumnus_name', 'alumnus_reg',
            'alumnus_email', 'alumnus_programme', 'alumnus_grad_year',
            'communication_title', 'communication_category', 'communication_category_display',
            'response_type', 'notes', 'created_at'
        ]
        read_only_fields = [
            'id', 'alumnus', 'alumnus_name', 'alumnus_reg',
            'alumnus_email', 'alumnus_programme', 'alumnus_grad_year',
            'communication_title', 'communication_category', 'communication_category_display',
            'created_at'
        ]

class CommunicationSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    author_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    counts = serializers.SerializerMethodField()
    my_rsvp = serializers.SerializerMethodField()
    is_read = serializers.SerializerMethodField()

    class Meta:
        model = Communication
        fields = [
            'id', 'title', 'content', 'category', 'category_display',
            'target_graduation_year', 'target_programme', 'target_skills',
            'event_date', 'location', 'application_deadline', 'external_link',
            'created_by', 'author_name', 'counts', 'my_rsvp', 'is_read',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'author_name', 'counts', 'my_rsvp', 'is_read', 'created_at', 'updated_at']

    def get_counts(self, obj):
        return {
            'total_responses': obj.rsvps.count(),
            'attending': obj.rsvps.filter(response_type=RSVP.ResponseType.ATTENDING).count(),
            'interested': obj.rsvps.filter(response_type=RSVP.ResponseType.INTERESTED).count(),
            'applied': obj.rsvps.filter(response_type=RSVP.ResponseType.APPLIED).count(),
            'reads': obj.read_receipts.count(),
        }

    def get_my_rsvp(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated and hasattr(request.user, 'alumni_profile'):
            user_rsvp = obj.rsvps.filter(alumnus=request.user.alumni_profile).first()
            if user_rsvp:
                return {
                    'response_type': user_rsvp.response_type,
                    'created_at': user_rsvp.created_at
                }
        return None

    def get_is_read(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.read_receipts.filter(user=request.user).exists()
        return False

class DepartmentFeedbackSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_reg = serializers.CharField(source='alumnus.registration_number', read_only=True)
    alumnus_email = serializers.EmailField(source='alumnus.user.email', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = DepartmentFeedback
        fields = [
            'id', 'alumnus', 'alumnus_name', 'alumnus_reg', 'alumnus_email',
            'subject', 'category', 'category_display', 'message',
            'is_reviewed', 'created_at'
        ]
        read_only_fields = ['id', 'alumnus', 'alumnus_name', 'alumnus_reg', 'alumnus_email', 'category_display', 'created_at']

class SystemFeedbackSurveySerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_role = serializers.CharField(source='user.role', read_only=True)
    aspect_display = serializers.CharField(source='get_system_aspect_display', read_only=True)

    class Meta:
        model = SystemFeedbackSurvey
        fields = [
            'id', 'user', 'user_name', 'user_email', 'user_role',
            'overall_rating', 'ease_of_use_rating', 'features_rating', 'performance_rating',
            'system_aspect', 'aspect_display',
            'what_works_well', 'improvements_needed', 'would_recommend',
            'created_at'
        ]
        read_only_fields = ['id', 'user', 'user_name', 'user_email', 'user_role', 'aspect_display', 'created_at']


class InAppNotificationSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = InAppNotification
        fields = [
            'id', 'user', 'title', 'message', 'category', 'category_display',
            'reference_id', 'action_url', 'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'category_display', 'created_at']


class CommunicationReadReceiptSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = CommunicationReadReceipt
        fields = ['id', 'communication', 'user', 'user_name', 'user_email', 'read_at']
        read_only_fields = ['id', 'user', 'read_at']
