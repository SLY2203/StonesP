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


class AllFeedbacksListView(generics.ListAPIView):
    """
    Admin endpoint to view all alumni feedbacks, applications, and RSVPs across communications and jobs.
    """
    serializer_class = RSVPSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = RSVP.objects.select_related('alumnus__user', 'communication').all()
        cat = self.request.query_params.get('category')
        if cat:
            qs = qs.filter(communication__category=cat.upper())
        resp_type = self.request.query_params.get('response_type')
        if resp_type:
            qs = qs.filter(response_type=resp_type.upper())
        only_with_notes = self.request.query_params.get('with_notes')
        if only_with_notes in ['true', '1']:
            qs = qs.exclude(notes='')
        return qs.order_by('-created_at')


class DepartmentFeedbackListCreateView(generics.ListCreateAPIView):
    """
    List department feedbacks (Admin) or submit new feedback (Verified Alumni).
    """
    from .models import DepartmentFeedback
    from .serializers import DepartmentFeedbackSerializer
    serializer_class = DepartmentFeedbackSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [IsAdminUserRole()]
        return [IsVerifiedAlumnus()]

    def get_queryset(self):
        from .models import DepartmentFeedback
        return DepartmentFeedback.objects.select_related('alumnus__user').all().order_by('-created_at')

    def perform_create(self, serializer):
        alumnus = get_object_or_404(AlumniProfile, user=self.request.user)
        serializer.save(alumnus=alumnus)


class DepartmentFeedbackReviewView(APIView):
    """
    Admin endpoint to mark a department feedback as reviewed.
    """
    permission_classes = [IsAdminUserRole]

    def patch(self, request, pk):
        from .models import DepartmentFeedback
        fb = get_object_or_404(DepartmentFeedback, pk=pk)
        is_reviewed = request.data.get('is_reviewed', True)
        fb.is_reviewed = bool(is_reviewed)
        fb.save()
        from .serializers import DepartmentFeedbackSerializer
        return Response(DepartmentFeedbackSerializer(fb).data)


class SystemFeedbackSurveyListCreateView(generics.ListCreateAPIView):
    """
    List surveys (Admin or User's own) or submit a new survey.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        from .serializers import SystemFeedbackSurveySerializer
        return SystemFeedbackSurveySerializer

    def get_queryset(self):
        from .models import SystemFeedbackSurvey
        user = self.request.user
        if getattr(user, 'role', None) == 'ADMIN' or user.is_staff or user.is_superuser:
            return SystemFeedbackSurvey.objects.select_related('user').all().order_by('-created_at')
        return SystemFeedbackSurvey.objects.filter(user=user).select_related('user').order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SystemFeedbackSurveyAnalyticsView(APIView):
    """
    Returns analytics and average scores of the system feedback surveys.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from .models import SystemFeedbackSurvey
        from django.db.models import Avg, Count
        surveys = SystemFeedbackSurvey.objects.all()
        total_count = surveys.count()
        if total_count == 0:
            return Response({
                'total_surveys': 0,
                'average_overall_rating': 5.0,
                'average_ease_of_use': 5.0,
                'average_features': 5.0,
                'average_performance': 5.0,
                'recommend_rate': 100.0,
                'rating_breakdown': {},
            })

        averages = surveys.aggregate(
            avg_overall=Avg('overall_rating'),
            avg_ease=Avg('ease_of_use_rating'),
            avg_features=Avg('features_rating'),
            avg_perf=Avg('performance_rating'),
        )
        recommend_count = surveys.filter(would_recommend=True).count()
        recommend_rate = round((recommend_count / total_count) * 100, 1)

        breakdown = dict(surveys.values_list('overall_rating').annotate(c=Count('id')).order_by('-overall_rating'))

        return Response({
            'total_surveys': total_count,
            'average_overall_rating': round(averages['avg_overall'] or 5.0, 1),
            'average_ease_of_use': round(averages['avg_ease'] or 5.0, 1),
            'average_features': round(averages['avg_features'] or 5.0, 1),
            'average_performance': round(averages['avg_perf'] or 5.0, 1),
            'recommend_rate': recommend_rate,
            'rating_breakdown': breakdown,
        })
