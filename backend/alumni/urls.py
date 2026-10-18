from django.urls import path
from .views import (
    MyProfileView,
    AlumniDirectoryView,
    AlumniDetailAdminView,
    MentorDirectoryView,
    MentorshipRequestListCreateView,
    MentorshipRequestRespondView,
    GraduationRosterListView,
    GraduationRosterBatchUploadView,
    AutoVerifyPendingAlumniView,
)

urlpatterns = [
    # Profile & Directory
    path('profile/me/', MyProfileView.as_view(), name='my_profile'),
    path('directory/', AlumniDirectoryView.as_view(), name='alumni_directory'),
    path('directory/<int:id>/', AlumniDetailAdminView.as_view(), name='alumni_detail'),

    # Suggestion 3: Mentorship & Peer Networking
    path('mentors/', MentorDirectoryView.as_view(), name='mentor_directory'),
    path('mentorship/requests/', MentorshipRequestListCreateView.as_view(), name='mentorship_requests'),
    path('mentorship/requests/<int:id>/respond/', MentorshipRequestRespondView.as_view(), name='mentorship_respond'),

    # Suggestion 2: Graduation Roster & Auto-Verification
    path('roster/', GraduationRosterListView.as_view(), name='graduation_roster'),
    path('roster/batch/', GraduationRosterBatchUploadView.as_view(), name='graduation_roster_batch'),
    path('roster/auto-verify-pending/', AutoVerifyPendingAlumniView.as_view(), name='auto_verify_pending'),
]

