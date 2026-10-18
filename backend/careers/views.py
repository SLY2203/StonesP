from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count
from django.shortcuts import get_object_or_404
from .models import CareerRecord
from .serializers import CareerRecordSerializer
from alumni.models import AlumniProfile

class MyCareerRecordListCreateView(generics.ListCreateAPIView):
    """
    Alumni endpoint to view their career progression timeline and record new positions.
    """
    serializer_class = CareerRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        profile = get_object_or_404(AlumniProfile, user=self.request.user)
        return CareerRecord.objects.filter(alumnus=profile).order_by('-is_current', '-start_date')

    def perform_create(self, serializer):
        profile = get_object_or_404(AlumniProfile, user=self.request.user)
        serializer.save(alumnus=profile)

class MyCareerRecordDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Alumni endpoint to update or remove a specific career position.
    """
    serializer_class = CareerRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        profile = get_object_or_404(AlumniProfile, user=self.request.user)
        return CareerRecord.objects.filter(alumnus=profile)

class CareerStatsView(APIView):
    """
    Summary view of aggregate employment stats for department staff and alumni insights.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        total_profiles = AlumniProfile.objects.count()
        current_records = CareerRecord.objects.filter(is_current=True)
        tracked_count = current_records.count()

        status_counts = current_records.values('employment_status').annotate(total=Count('id'))
        status_map = {item['employment_status']: item['total'] for item in status_counts}

        employed = status_map.get(CareerRecord.EmploymentStatus.EMPLOYED, 0)
        self_employed = status_map.get(CareerRecord.EmploymentStatus.SELF_EMPLOYED, 0)
        further_studies = status_map.get(CareerRecord.EmploymentStatus.FURTHER_STUDIES, 0)
        unemployed = status_map.get(CareerRecord.EmploymentStatus.UNEMPLOYED, 0)

        # Percentages based on tracked records
        denom = tracked_count if tracked_count > 0 else 1
        employed_pct = round((employed / denom) * 100, 1)
        self_employed_pct = round((self_employed / denom) * 100, 1)
        further_studies_pct = round((further_studies / denom) * 100, 1)
        unemployed_pct = round((unemployed / denom) * 100, 1)

        # Top 5 Industries
        top_industries = current_records.values('industry_sector').annotate(
            count=Count('id')
        ).order_by('-count')[:5]

        # Top 5 Employers
        top_employers = current_records.exclude(employer='').values('employer').annotate(
            count=Count('id')
        ).order_by('-count')[:5]

        # Top 10 Technical Skills across profiles and career milestones
        skills_counter = {}
        for p in AlumniProfile.objects.exclude(skills=''):
            for sk in p.skills_list:
                s_clean = sk.title()
                skills_counter[s_clean] = skills_counter.get(s_clean, 0) + 1

        for c in CareerRecord.objects.exclude(skills_used=''):
            if c.skills_used:
                for sk in [s.strip() for s in c.skills_used.split(',') if s.strip()]:
                    s_clean = sk.title()
                    skills_counter[s_clean] = skills_counter.get(s_clean, 0) + 1

        top_skills = sorted(
            [{'skill': k, 'count': v} for k, v in skills_counter.items()],
            key=lambda x: x['count'],
            reverse=True
        )[:10]

        return Response({
            'total_alumni': total_profiles,
            'tracked_alumni': tracked_count,
            'employment_distribution': {
                'employed': {'count': employed, 'percentage': employed_pct},
                'self_employed': {'count': self_employed, 'percentage': self_employed_pct},
                'further_studies': {'count': further_studies, 'percentage': further_studies_pct},
                'unemployed': {'count': unemployed, 'percentage': unemployed_pct},
            },
            'overall_employed_rate': round(((employed + self_employed) / denom) * 100, 1),
            'top_industries': list(top_industries),
            'top_employers': list(top_employers),
            'top_skills': top_skills,
        }, status=status.HTTP_200_OK)
