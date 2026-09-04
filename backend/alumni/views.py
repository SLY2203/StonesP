from rest_framework import generics, permissions, filters
from django.db.models import Q
from django.shortcuts import get_object_or_404
from .models import AlumniProfile
from .serializers import AlumniProfileSerializer, AlumniDirectoryItemSerializer
from accounts.permissions import IsAdminUserRole

class MyProfileView(generics.RetrieveUpdateAPIView):
    """
    Alumni endpoint to view and update their own personal and contact profile.
    """
    serializer_class = AlumniProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _ = AlumniProfile.objects.get_or_create(
            user=self.request.user,
            defaults={
                'registration_number': f"TEMP-{self.request.user.id}",
                'graduation_year': 2024,
                'programme': 'BSc Hons Computer Science'
            }
        )
        return profile

class AlumniDirectoryView(generics.ListAPIView):
    """
    Admin endpoint to list, search, and filter alumni across the department.
    Filters:
      - q: text search across name, email, reg number, employer
      - graduation_year: integer
      - programme: exact or partial programme name
      - is_verified: true/false
    """
    serializer_class = AlumniDirectoryItemSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = AlumniProfile.objects.select_related('user').prefetch_related('career_records').all()

        q = self.request.query_params.get('q', '').strip()
        if q:
            qs = qs.filter(
                Q(user__first_name__icontains=q) |
                Q(user__last_name__icontains=q) |
                Q(user__email__icontains=q) |
                Q(registration_number__icontains=q) |
                Q(career_records__employer__icontains=q) |
                Q(career_records__job_title__icontains=q)
            ).distinct()

        grad_year = self.request.query_params.get('graduation_year')
        if grad_year and grad_year.isdigit():
            qs = qs.filter(graduation_year=int(grad_year))

        programme = self.request.query_params.get('programme')
        if programme:
            qs = qs.filter(programme__icontains=programme)

        is_verified = self.request.query_params.get('is_verified')
        if is_verified is not None:
            if is_verified.lower() in ('true', '1'):
                qs = qs.filter(user__is_verified=True)
            elif is_verified.lower() in ('false', '0'):
                qs = qs.filter(user__is_verified=False)

        return qs

class AlumniDetailAdminView(generics.RetrieveAPIView):
    """
    Admin view to inspect the complete details of any specific alumnus profile.
    """
    queryset = AlumniProfile.objects.select_related('user').prefetch_related('career_records').all()
    serializer_class = AlumniProfileSerializer
    permission_classes = [IsAdminUserRole]
    lookup_field = 'id'
