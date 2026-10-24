from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count
from .models import JobVacancy, JobMatch, JobApplication
from .serializers import (
    JobVacancySerializer,
    JobVacancyCreateFromAdvertSerializer,
    JobMatchSerializer,
    JobApplicationSerializer,
)
from .ai_service import extract_job_details_with_gemini, match_alumni_to_job
from alumni.models import AlumniProfile
from accounts.permissions import IsAdminUserRole, IsVerifiedAlumnus


# ==============================================================================
# Admin: Job Vacancy Management
# ==============================================================================

class JobVacancyListCreateView(generics.ListCreateAPIView):
    """
    Admin endpoint to list all job vacancies and create new ones.
    """
    serializer_class = JobVacancySerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = JobVacancy.objects.all()
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(title__icontains=q) | Q(company__icontains=q) |
                Q(required_skills__icontains=q) | Q(industry_sector__icontains=q)
            )
        return qs

    def perform_create(self, serializer):
        serializer.save(posted_by=self.request.user)


class JobVacancyDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Admin endpoint to view, update, or delete a specific job vacancy.
    """
    queryset = JobVacancy.objects.all()
    serializer_class = JobVacancySerializer
    permission_classes = [IsAdminUserRole]


class AIExtractJobView(APIView):
    """
    Admin endpoint to submit raw job advert text and receive AI-extracted structured fields.
    Step 1: AI extracts → returns preview
    Step 2: Admin reviews, edits, and publishes (uses JobVacancyListCreateView)
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request):
        serializer = JobVacancyCreateFromAdvertSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        raw_text = serializer.validated_data['raw_advert_text']

        # Call Gemini AI extraction
        extracted = extract_job_details_with_gemini(raw_text)

        # Apply any admin overrides
        for field in ['title', 'company', 'location', 'salary_range', 'required_skills',
                       'experience_level', 'job_type', 'industry_sector',
                       'application_url', 'application_deadline']:
            override = serializer.validated_data.get(field)
            if override:
                extracted[field] = override

        # Create the job vacancy in DRAFT status
        job = JobVacancy.objects.create(
            title=extracted.get('title', 'Untitled Position'),
            company=extracted.get('company', ''),
            description=raw_text,
            location=extracted.get('location', ''),
            salary_range=extracted.get('salary_range', ''),
            required_skills=extracted.get('required_skills', ''),
            experience_level=extracted.get('experience_level', 'ANY'),
            job_type=extracted.get('job_type', 'FULL_TIME'),
            industry_sector=extracted.get('industry_sector', 'Software & IT Services'),
            qualifications=extracted.get('qualifications', ''),
            responsibilities=extracted.get('responsibilities', ''),
            raw_advert_text=raw_text,
            application_url=extracted.get('application_url') or None,
            application_deadline=extracted.get('application_deadline') or None,
            status='DRAFT',
            posted_by=request.user,
        )

        return Response({
            'message': 'Job advert processed by AI. Review the extracted details and publish when ready.',
            'job': JobVacancySerializer(job).data,
            'ai_extracted_fields': extracted,
        }, status=status.HTTP_201_CREATED)


class PublishJobAndMatchView(APIView):
    """
    Admin endpoint to publish a draft job vacancy and run the matching engine.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request, pk):
        job = get_object_or_404(JobVacancy, pk=pk)
        job.status = 'PUBLISHED'
        job.save()

        # Run matching engine
        matches = match_alumni_to_job(job)

        # Save match records & proactively notify each matched alumnus
        from communications.models import InAppNotification
        created_count = 0
        notifications = []
        for match_data in matches:
            _, created = JobMatch.objects.update_or_create(
                job=job,
                alumnus=match_data['alumnus'],
                defaults={
                    'match_score': match_data['score'],
                    'skills_overlap': match_data['skills_overlap'],
                    'match_reasons': match_data['reasons'],
                }
            )
            if created:
                created_count += 1

            notif_title = f"🎯 New Job Match: {job.title}"
            if len(notif_title) > 220:
                notif_title = notif_title[:217] + "..."

            # Create in-app notification for the matched alumnus
            notifications.append(InAppNotification(
                user=match_data['alumnus'].user,
                title=notif_title,
                message=(
                    f"You have a {match_data['score']:.0f}% match for a "
                    f"{job.get_experience_level_display()} role at {job.company or 'a hiring company'}. "
                    f"Skills overlap: {match_data['skills_overlap'] or 'see details'}."
                ),
                category='JOB_MATCH',
                reference_id=str(job.id),
                action_url=f'/jobs/matched/{job.id}/',
            ))

        if notifications:
            InAppNotification.objects.bulk_create(notifications, ignore_conflicts=True)

        return Response({
            'message': f"Job published, {created_count} alumni matched and notified.",
            'job_id': job.id,
            'total_matches': len(matches),
            'top_matches': [
                {
                    'alumnus_name': m['alumnus'].user.get_full_name(),
                    'score': m['score'],
                    'skills_overlap': m['skills_overlap'],
                }
                for m in matches[:10]
            ],
        }, status=status.HTTP_200_OK)



class JobMatchListView(generics.ListAPIView):
    """
    Admin endpoint to view all matches for a specific job vacancy.
    """
    serializer_class = JobMatchSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        job_id = self.kwargs.get('job_id')
        return JobMatch.objects.filter(job_id=job_id).select_related(
            'alumnus__user', 'job'
        )


class JobApplicationAdminListView(generics.ListAPIView):
    """
    Admin endpoint to view all applications for a specific job vacancy.
    """
    serializer_class = JobApplicationSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        job_id = self.kwargs.get('job_id')
        return JobApplication.objects.filter(job_id=job_id).select_related(
            'alumnus__user', 'job'
        )


# ==============================================================================
# Alumni: Job Feeds & Applications
# ==============================================================================

class AlumniMatchedJobsView(APIView):
    """
    Alumni endpoint to view their personalized job matches.
    """
    permission_classes = [IsVerifiedAlumnus]

    def get(self, request):
        profile = get_object_or_404(AlumniProfile, user=request.user)

        matches = JobMatch.objects.filter(
            alumnus=profile,
            job__status='PUBLISHED'
        ).select_related('job').order_by('-match_score')

        results = []
        for match in matches:
            job = match.job
            # Check if user already applied
            application = JobApplication.objects.filter(job=job, alumnus=profile).first()

            results.append({
                'match_id': match.id,
                'match_score': match.match_score,
                'skills_overlap': match.skills_overlap,
                'match_reasons': match.match_reasons,
                'job': {
                    'id': job.id,
                    'title': job.title,
                    'company': job.company,
                    'location': job.location,
                    'salary_range': job.salary_range,
                    'experience_level': job.experience_level,
                    'experience_display': job.get_experience_level_display(),
                    'job_type': job.job_type,
                    'type_display': job.get_job_type_display(),
                    'industry_sector': job.industry_sector,
                    'required_skills': job.required_skills,
                    'application_deadline': job.application_deadline,
                    'application_url': job.application_url,
                    'created_at': job.created_at,
                },
                'my_application': {
                    'status': application.status,
                    'cover_note': application.cover_note,
                    'created_at': application.created_at,
                } if application else None,
            })

        return Response(results)


class AlumniPublishedJobsView(generics.ListAPIView):
    """
    Alumni endpoint to browse all published job vacancies.
    """
    serializer_class = JobVacancySerializer
    permission_classes = [IsVerifiedAlumnus]

    def get_queryset(self):
        qs = JobVacancy.objects.filter(status='PUBLISHED')
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(title__icontains=q) | Q(company__icontains=q) |
                Q(required_skills__icontains=q)
            )
        return qs


class AlumniApplyToJobView(APIView):
    """
    Alumni endpoint to express interest or apply to a job vacancy.
    """
    permission_classes = [IsVerifiedAlumnus]

    def post(self, request, job_id):
        profile = get_object_or_404(AlumniProfile, user=request.user)
        job = get_object_or_404(JobVacancy, id=job_id, status='PUBLISHED')

        cover_note = request.data.get('cover_note', '')

        application, created = JobApplication.objects.update_or_create(
            job=job,
            alumnus=profile,
            defaults={
                'status': 'APPLIED',
                'cover_note': cover_note,
            }
        )

        action = 'submitted' if created else 'updated'
        return Response({
            'message': f"Your application has been {action}.",
            'application': JobApplicationSerializer(application).data,
        }, status=status.HTTP_200_OK)


class JobMatchingAnalyticsView(APIView):
    """
    Admin analytics for the AI job matching module.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        total_jobs = JobVacancy.objects.count()
        published_jobs = JobVacancy.objects.filter(status='PUBLISHED').count()
        total_matches = JobMatch.objects.count()
        total_applications = JobApplication.objects.count()

        # Average match score
        from django.db.models import Avg
        avg_score = JobMatch.objects.aggregate(avg=Avg('match_score'))['avg']

        # Top matched alumni (most matches)
        top_matched = list(
            JobMatch.objects.values('alumnus__user__first_name', 'alumnus__user__last_name')
            .annotate(match_count=Count('id'))
            .order_by('-match_count')[:5]
        )

        # Application conversion rate
        conversion_rate = 0
        if total_matches > 0:
            conversion_rate = round((total_applications / total_matches) * 100, 1)

        return Response({
            'total_jobs': total_jobs,
            'published_jobs': published_jobs,
            'total_matches': total_matches,
            'total_applications': total_applications,
            'avg_match_score': round(avg_score or 0, 1),
            'application_conversion_rate': conversion_rate,
            'top_matched_alumni': top_matched,
        })
