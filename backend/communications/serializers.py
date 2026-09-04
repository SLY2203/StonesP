from rest_framework import serializers
from .models import Communication, RSVP

class RSVPSerializer(serializers.ModelSerializer):
    alumnus_name = serializers.CharField(source='alumnus.user.get_full_name', read_only=True)
    alumnus_reg = serializers.CharField(source='alumnus.registration_number', read_only=True)

    class Meta:
        model = RSVP
        fields = ['id', 'communication', 'alumnus', 'alumnus_name', 'alumnus_reg', 'response_type', 'notes', 'created_at']
        read_only_fields = ['id', 'alumnus', 'alumnus_name', 'alumnus_reg', 'created_at']

class CommunicationSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    author_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    counts = serializers.SerializerMethodField()
    my_rsvp = serializers.SerializerMethodField()

    class Meta:
        model = Communication
        fields = [
            'id', 'title', 'content', 'category', 'category_display',
            'target_graduation_year', 'target_programme',
            'event_date', 'location', 'application_deadline', 'external_link',
            'created_by', 'author_name', 'counts', 'my_rsvp',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'author_name', 'counts', 'my_rsvp', 'created_at', 'updated_at']

    def get_counts(self, obj):
        return {
            'total_responses': obj.rsvps.count(),
            'attending': obj.rsvps.filter(response_type=RSVP.ResponseType.ATTENDING).count(),
            'interested': obj.rsvps.filter(response_type=RSVP.ResponseType.INTERESTED).count(),
            'applied': obj.rsvps.filter(response_type=RSVP.ResponseType.APPLIED).count(),
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
