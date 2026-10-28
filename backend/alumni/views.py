import csv
import io
from rest_framework import generics, permissions, status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from .models import AlumniProfile, GraduationRoster, MentorshipRequest, VerificationRequest
from .serializers import (
    AlumniProfileSerializer,
    AlumniDirectoryItemSerializer,
    GraduationRosterSerializer,
    GraduationRosterBatchUploadSerializer,
    MentorDirectorySerializer,
    MentorshipRequestSerializer,
    MentorshipResponseSerializer,
    AdminCreateAlumnusSerializer,
    VerificationRequestSerializer,
)
from accounts.models import User
from accounts.permissions import IsAdminUserRole

class MyProfileView(generics.RetrieveUpdateAPIView):
    """
    Alumni endpoint to view and update their own personal, skills, and mentorship profile.
    Supports JSON and multipart form data (profile photo upload).
    """
    serializer_class = AlumniProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

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
      - q: text search across name, email, reg number, employer, skills
      - skill: specific technical skill (e.g. Flutter, Python)
      - graduation_year: integer
      - programme: exact or partial programme name
      - is_verified: true/false
    """
    serializer_class = AlumniDirectoryItemSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = AlumniProfile.objects.select_related('user').prefetch_related('career_records').all()

        q = (self.request.query_params.get('q') or self.request.query_params.get('search') or '').strip()
        if q:
            qs = qs.filter(
                Q(user__first_name__icontains=q) |
                Q(user__last_name__icontains=q) |
                Q(user__email__icontains=q) |
                Q(registration_number__icontains=q) |
                Q(career_records__employer__icontains=q) |
                Q(career_records__job_title__icontains=q) |
                Q(skills__icontains=q) |
                Q(career_records__skills_used__icontains=q)
            ).distinct()

        # Suggestion 1: Skill-based search & filter
        skill = (self.request.query_params.get('skill') or '').strip()
        if skill:
            qs = qs.filter(
                Q(skills__icontains=skill) |
                Q(career_records__skills_used__icontains=skill)
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


class AdminCreateAlumnusView(APIView):
    """
    Admin endpoint to directly add an alumnus profile, user account,
    and optional career records into the database.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request):
        serializer = AdminCreateAlumnusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = serializer.save()
        return Response(AlumniDirectoryItemSerializer(profile).data, status=status.HTTP_201_CREATED)



# ==============================================================================
# Suggestion 3: Mentorship & Peer Networking Views
# ==============================================================================

class MentorDirectoryView(generics.ListAPIView):
    """
    Alumni & Student endpoint to discover verified alumni willing to mentor.
    """
    serializer_class = MentorDirectorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = AlumniProfile.objects.filter(
            is_available_for_mentorship=True,
            user__is_verified=True
        ).select_related('user').prefetch_related('career_records')

        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(user__first_name__icontains=q) |
                Q(user__last_name__icontains=q) |
                Q(skills__icontains=q) |
                Q(mentorship_areas__icontains=q) |
                Q(career_records__job_title__icontains=q) |
                Q(career_records__employer__icontains=q)
            ).distinct()

        skill = (self.request.query_params.get('skill') or '').strip()
        if skill:
            qs = qs.filter(skills__icontains=skill)

        topic = (self.request.query_params.get('topic') or '').strip()
        if topic:
            qs = qs.filter(mentorship_areas__icontains=topic)

        return qs


class MentorshipRequestListCreateView(APIView):
    """
    View to list user's mentorship requests (sent or received) and send a new request.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user_profile = getattr(request.user, 'alumni_profile', None)
        if not user_profile:
            return Response({'detail': 'Alumni profile not found.'}, status=status.HTTP_404_NOT_FOUND)

        requests = MentorshipRequest.objects.filter(
            Q(mentor=user_profile) | Q(mentee=user_profile)
        ).select_related('mentor__user', 'mentee__user')

        serializer = MentorshipRequestSerializer(requests, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        user_profile = getattr(request.user, 'alumni_profile', None)
        if not user_profile:
            return Response({'detail': 'You need an alumni profile to request mentorship.'}, status=status.HTTP_400_BAD_REQUEST)

        mentor_id = request.data.get('mentor_id') or request.data.get('mentor')
        if not mentor_id:
            return Response({'mentor_id': 'This field is required.'}, status=status.HTTP_400_BAD_REQUEST)

        mentor_profile = get_object_or_404(AlumniProfile, id=mentor_id)

        if mentor_profile.id == user_profile.id:
            return Response({'detail': 'You cannot request mentorship from yourself.'}, status=status.HTTP_400_BAD_REQUEST)

        if not mentor_profile.is_available_for_mentorship:
            return Response({'detail': 'This alumnus is currently not accepting mentorship requests.'}, status=status.HTTP_400_BAD_REQUEST)

        topic = request.data.get('topic', 'General Career Advice')
        message = request.data.get('message', '')

        mentorship_req = MentorshipRequest.objects.create(
            mentor=mentor_profile,
            mentee=user_profile,
            topic=topic,
            message=message,
            status=MentorshipRequest.Status.PENDING
        )

        return Response(MentorshipRequestSerializer(mentorship_req).data, status=status.HTTP_201_CREATED)


class MentorshipRequestRespondView(APIView):
    """
    Mentor accepts, declines, or marks a mentorship session completed.
    """
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, id):
        user_profile = getattr(request.user, 'alumni_profile', None)
        mentorship_req = get_object_or_404(MentorshipRequest, id=id)

        if mentorship_req.mentor != user_profile and request.user.role != User.UserRole.ADMIN:
            return Response({'detail': 'Only the designated mentor or staff administrator can respond to this request.'},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = MentorshipResponseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']
        resp_msg = serializer.validated_data.get('response_message', '')

        mentorship_req.status = new_status
        if resp_msg:
            mentorship_req.response_message = resp_msg
        mentorship_req.save()

        return Response(MentorshipRequestSerializer(mentorship_req).data, status=status.HTTP_200_OK)


# ==============================================================================
# Suggestion 2: Graduation Roster & Auto-Verification Views
# ==============================================================================

class GraduationRosterListView(generics.ListCreateAPIView):
    """
    Admin endpoint to view and add official graduation roster records.
    """
    serializer_class = GraduationRosterSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = GraduationRoster.objects.all()
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(registration_number__icontains=q) |
                Q(full_name__icontains=q) |
                Q(programme__icontains=q)
            )
        year = self.request.query_params.get('graduation_year')
        if year and year.isdigit():
            qs = qs.filter(graduation_year=int(year))
        return qs


class GraduationRosterBatchUploadView(APIView):
    """
    Admin endpoint to bulk-upload official graduation rosters via CSV text or JSON list.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request):
        serializer = GraduationRosterBatchUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        created_count = 0
        updated_count = 0

        # Handle CSV text format: reg_number,full_name,graduation_year,programme,degree_class
        csv_text = serializer.validated_data.get('roster_csv')
        if csv_text:
            reader = csv.reader(io.StringIO(csv_text.strip()))
            for row in reader:
                if not row or len(row) < 3:
                    continue
                reg_num = row[0].strip().upper()
                name = row[1].strip()
                try:
                    year = int(row[2].strip())
                except ValueError:
                    continue
                programme = row[3].strip() if len(row) > 3 else 'BSc Hons Computer Science'
                degree_class = row[4].strip() if len(row) > 4 else 'Pass'

                _, created = GraduationRoster.objects.update_or_create(
                    registration_number=reg_num,
                    defaults={
                        'full_name': name,
                        'graduation_year': year,
                        'programme': programme,
                        'degree_class': degree_class
                    }
                )
                if created:
                    created_count += 1
                else:
                    updated_count += 1

        # Handle structured JSON list format
        records = serializer.validated_data.get('records', [])
        for rec in records:
            reg_num = rec.get('registration_number', '').strip().upper()
            if not reg_num:
                continue
            _, created = GraduationRoster.objects.update_or_create(
                registration_number=reg_num,
                defaults={
                    'full_name': rec.get('full_name', ''),
                    'graduation_year': int(rec.get('graduation_year', 2024)),
                    'programme': rec.get('programme', 'BSc Hons Computer Science'),
                    'degree_class': rec.get('degree_class', 'Pass')
                }
            )
            if created:
                created_count += 1
            else:
                updated_count += 1

        return Response({
            'message': f"Graduation Roster updated. {created_count} created, {updated_count} updated.",
            'created_count': created_count,
            'updated_count': updated_count,
            'total_roster_count': GraduationRoster.objects.count()
        }, status=status.HTTP_200_OK)


class AutoVerifyPendingAlumniView(APIView):
    """
    1-Tap Admin Action: Auto-verifies all currently unverified alumni
    whose student registration numbers match the official Graduation Roster.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request):
        pending_alumni = AlumniProfile.objects.filter(
            user__is_verified=False
        ).select_related('user')

        verified_names = []
        for profile in pending_alumni:
            reg = profile.registration_number.strip().upper()
            if GraduationRoster.objects.filter(registration_number__iexact=reg).exists():
                profile.user.is_verified = True
                profile.user.save()
                verified_names.append(f"{profile.user.get_full_name()} ({reg})")

        return Response({
            'message': f"Auto-verification complete. {len(verified_names)} alumni verified.",
            'verified_count': len(verified_names),
            'verified_alumni': verified_names,
            'remaining_pending': AlumniProfile.objects.filter(user__is_verified=False).count()
        }, status=status.HTTP_200_OK)


class VerificationRequestCreateView(APIView):
    """
    Endpoint for alumni (either authenticated pending user or registering graduate)
    to notify the Department Administrator to verify their account and graduate status.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from communications.models import InAppNotification

        user = request.user if request.user.is_authenticated else None
        data = request.data

        reg = (data.get('registration_number') or '').strip().upper()
        if user and not reg and hasattr(user, 'alumni_profile'):
            reg = user.alumni_profile.registration_number.upper()

        if not reg:
            return Response({'registration_number': 'Registration number is required.'}, status=status.HTTP_400_BAD_REQUEST)

        full_name = data.get('full_name') or (user.get_full_name() if user else '') or reg
        email = data.get('email') or (user.email if user else '')
        notes = data.get('notes') or data.get('message') or ''
        grad_year = data.get('graduation_year')
        programme = data.get('programme') or 'BSc Hons Computer Science'
        phone = data.get('phone_number') or ''

        # Create or update VerificationRequest
        v_req, created = VerificationRequest.objects.get_or_create(
            registration_number=reg,
            status=VerificationRequest.Status.PENDING,
            defaults={
                'user': user,
                'full_name': full_name,
                'email': email,
                'graduation_year': int(grad_year) if grad_year else None,
                'programme': programme,
                'phone_number': phone,
                'notes': notes,
            }
        )
        if not created:
            v_req.notes = notes or v_req.notes
            v_req.phone_number = phone or v_req.phone_number
            if user:
                v_req.user = user
            v_req.save()

        # Send in-app notification to all administrators
        from django.db.models import Q
        admin_users = User.objects.filter(Q(role=User.UserRole.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct()
        for admin in admin_users:
            InAppNotification.objects.create(
                user=admin,
                title=f"Verification Request: {full_name} ({reg})",
                message=f"Alumnus {full_name} ({reg}) has requested account verification. Note: {notes or 'Please review and verify my record.'}",
                category='SYSTEM',
                reference_id=str(v_req.id),
                action_url='/admin/alumni/verificationrequest/'
            )

        return Response({
            'message': 'Verification request sent to Department Administrators. Staff have been alerted to review your record.',
            'status': 'PENDING',
            'registration_number': reg,
            'request_id': v_req.id
        }, status=status.HTTP_201_CREATED)


class VerificationRequestListView(generics.ListAPIView):
    """
    Admin endpoint to view all pending / reviewed verification requests from alumni.
    """
    serializer_class = VerificationRequestSerializer
    permission_classes = [IsAdminUserRole]

    def get_queryset(self):
        qs = VerificationRequest.objects.all()
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        return qs


class VerificationRequestApproveView(APIView):
    """
    Admin endpoint to approve and verify an alumnus request with 1 tap.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request, id):
        from communications.models import InAppNotification
        from django.utils import timezone

        v_req = get_object_or_404(VerificationRequest, id=id)
        v_req.status = VerificationRequest.Status.APPROVED
        v_req.reviewed_at = timezone.now()
        v_req.admin_notes = request.data.get('admin_notes', 'Approved by administrator.')
        v_req.save()

        # Ensure graduation roster entry
        GraduationRoster.objects.update_or_create(
            registration_number=v_req.registration_number.upper(),
            defaults={
                'full_name': v_req.full_name,
                'graduation_year': v_req.graduation_year or 2024,
                'programme': v_req.programme or 'BSc Hons Computer Science',
                'degree_class': 'Pass',
            }
        )

        # If user exists, mark verified
        if v_req.user:
            v_req.user.is_verified = True
            v_req.user.save()

            InAppNotification.objects.create(
                user=v_req.user,
                title="Account Verified!",
                message="Your alumni account has been verified by the Department of Computer Science. You now have full access.",
                category='SYSTEM',
                action_url='/home'
            )

        return Response({
            'message': f"Verification request for {v_req.full_name} ({v_req.registration_number}) approved.",
            'status': 'APPROVED'
        }, status=status.HTTP_200_OK)


