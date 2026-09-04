from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Communication, RSVP
from .serializers import CommunicationSerializer, RSVPSerializer
from accounts.permissions import IsAdminUserRole, IsVerifiedAlumnus
from alumni.models import AlumniProfile
from .fcm_service import FCMNotificationService

class CommunicationListCreateView(generics.ListCreateAPIView):
    """
    List communications feed (verified alumni and admins)
    Create new communication broadcast (department admins only)
    """
    serializer_class = CommunicationSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAdminUserRole()]
        return [IsVerifiedAlumnus()]

    def get_queryset(self):
        qs = Communication.objects.select_related('created_by').prefetch_related('rsvps').all()

        category = self.request.query_params.get('category')
        if category:
            qs = qs.filter(category=category.upper())

        year = self.request.query_params.get('target_year')
        if year and year.isdigit():
            qs = qs.filter(target_graduation_year=int(year))

        return qs

    def perform_create(self, serializer):
        comm = serializer.save(created_by=self.request.user)
        # Trigger push notification dispatch
        FCMNotificationService.send_broadcast_notification(comm)

class CommunicationDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve communication details or edit/delete (Admin only).
    """
    queryset = Communication.objects.all()
    serializer_class = CommunicationSerializer

    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [IsAdminUserRole()]
        return [IsVerifiedAlumnus()]

class RSVPActionView(APIView):
    """
    Alumni endpoint to RSVP, express interest, or apply to an opportunity/event.
    """
    permission_classes = [IsVerifiedAlumnus]

    def post(self, request, communication_id):
        communication = get_object_or_404(Communication, id=communication_id)
        alumnus = get_object_or_404(AlumniProfile, user=request.user)

        response_type = request.data.get('response_type', RSVP.ResponseType.INTERESTED)
        notes = request.data.get('notes', '')

        valid_types = [choice[0] for choice in RSVP.ResponseType.choices]
        if response_type not in valid_types:
            return Response(
                {'error': f"Invalid response_type. Valid options: {valid_types}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        rsvp, created = RSVP.objects.update_or_create(
            communication=communication,
            alumnus=alumnus,
            defaults={
                'response_type': response_type,
                'notes': notes
            }
        )

        action = "recorded" if created else "updated"
        return Response({
            'message': f"Your response ({response_type}) has been {action}.",
            'rsvp': RSVPSerializer(rsvp).data
        }, status=status.HTTP_200_OK)

    def delete(self, request, communication_id):
        communication = get_object_or_404(Communication, id=communication_id)
        alumnus = get_object_or_404(AlumniProfile, user=request.user)
        deleted_count, _ = RSVP.objects.filter(communication=communication, alumnus=alumnus).delete()

        if deleted_count > 0:
            return Response({'message': 'RSVP removed successfully.'}, status=status.HTTP_200_OK)
        return Response({'message': 'No RSVP was found to remove.'}, status=status.HTTP_404_NOT_FOUND)

class CommunicationRSVPListView(generics.ListAPIView):
    """
    Admin endpoint to view all alumni who responded to an announcement or event.
    """
    serializer_class = RSVPSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        comm_id = self.kwargs.get('communication_id')
        return RSVP.objects.filter(communication_id=comm_id).select_related('alumnus__user')
