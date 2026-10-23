from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Avg, Count, Q
from django.shortcuts import get_object_or_404
from .tracer_models import TracerSurvey
from .tracer_serializers import TracerSurveySerializer
from alumni.models import AlumniProfile
from accounts.permissions import IsAdminUserRole


class MyTracerSurveyView(APIView):
    """
    Alumni endpoint to view, create, or update their own tracer survey.
    GET: Returns the alumnus' tracer survey (or 404 if not yet started).
    POST: Creates or updates the tracer survey.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile = get_object_or_404(AlumniProfile, user=request.user)
        try:
            survey = profile.tracer_survey
        except TracerSurvey.DoesNotExist:
            return Response({'detail': 'You have not started the tracer survey yet.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = TracerSurveySerializer(survey)
        return Response(serializer.data)

    def post(self, request):
        profile = get_object_or_404(AlumniProfile, user=request.user)
        survey, created = TracerSurvey.objects.get_or_create(alumnus=profile)

        serializer = TracerSurveySerializer(survey, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )


class TracerSurveyListView(generics.ListAPIView):
    """
    Admin endpoint to view all tracer survey responses with optional filters.
    """
    serializer_class = TracerSurveySerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = TracerSurvey.objects.select_related('alumnus__user').all()

        is_complete = self.request.query_params.get('is_complete')
        if is_complete is not None:
            qs = qs.filter(is_complete=is_complete.lower() in ('true', '1'))

        relevance = self.request.query_params.get('degree_relevance')
        if relevance:
            qs = qs.filter(degree_relevance=relevance)

        salary = self.request.query_params.get('salary_band')
        if salary:
            qs = qs.filter(current_salary_band=salary)

        grad_year = self.request.query_params.get('graduation_year')
        if grad_year and grad_year.isdigit():
            qs = qs.filter(alumnus__graduation_year=int(grad_year))

        return qs


class TracerSurveyAnalyticsView(APIView):
    """
    Admin analytics endpoint for tracer survey data.
    Returns aggregate metrics: avg time-to-first-job, salary distribution,
    degree relevance breakdown, satisfaction averages, job search methods.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        surveys = TracerSurvey.objects.filter(is_complete=True).select_related('alumnus')
        total = surveys.count()

        if total == 0:
            return Response({
                'total_completed': 0,
                'message': 'No completed tracer surveys yet.',
            })

        # Average time to first job (exclude nulls and those who had jobs before graduation)
        ttfj_surveys = surveys.filter(
            months_to_first_job__isnull=False,
            had_job_before_graduation=False
        )
        avg_time_to_first_job = ttfj_surveys.aggregate(avg=Avg('months_to_first_job'))['avg']
        had_job_before_count = surveys.filter(had_job_before_graduation=True).count()

        # Salary distribution
        salary_dist = list(
            surveys.values('current_salary_band')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Degree relevance breakdown
        relevance_dist = list(
            surveys.values('degree_relevance')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Satisfaction averages
        satisfaction = surveys.aggregate(
            avg_career=Avg('career_satisfaction'),
            avg_curriculum=Avg('curriculum_satisfaction'),
        )

        # Job search method breakdown
        search_methods = list(
            surveys.values('job_search_method')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # First job sectors
        first_job_sectors = list(
            surveys.exclude(first_job_sector='')
            .values('first_job_sector')
            .annotate(count=Count('id'))
            .order_by('-count')[:8]
        )

        # Top skills gaps mentioned (aggregate free-text, simple word frequency)
        skills_gap_entries = surveys.exclude(skills_gap='').values_list('skills_gap', flat=True)
        skills_gap_list = list(skills_gap_entries[:20])  # Return raw for frontend display

        return Response({
            'total_completed': total,
            'total_pending': TracerSurvey.objects.filter(is_complete=False).count(),
            'total_not_started': AlumniProfile.objects.filter(
                user__is_verified=True
            ).exclude(
                id__in=TracerSurvey.objects.values_list('alumnus_id', flat=True)
            ).count(),
            'avg_months_to_first_job': round(avg_time_to_first_job, 1) if avg_time_to_first_job else None,
            'had_job_before_graduation_count': had_job_before_count,
            'salary_distribution': salary_dist,
            'degree_relevance_breakdown': relevance_dist,
            'avg_career_satisfaction': round(satisfaction['avg_career'] or 0, 1),
            'avg_curriculum_satisfaction': round(satisfaction['avg_curriculum'] or 0, 1),
            'job_search_methods': search_methods,
            'first_job_sectors': first_job_sectors,
            'sample_skills_gaps': skills_gap_list,
        })
