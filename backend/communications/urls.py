from django.urls import path
from .views import (
    CommunicationListCreateView,
    CommunicationDetailView,
    RSVPActionView,
    CommunicationRSVPListView,
    AllFeedbacksListView,
    DepartmentFeedbackListCreateView,
    DepartmentFeedbackReviewView,
    SystemFeedbackSurveyListCreateView,
    SystemFeedbackSurveyAnalyticsView,
)

urlpatterns = [
    path('', CommunicationListCreateView.as_view(), name='communication_list_create'),
    path('feedbacks/', AllFeedbacksListView.as_view(), name='all_feedbacks_list'),
    path('surveys/', SystemFeedbackSurveyListCreateView.as_view(), name='system_surveys_list_create'),
    path('surveys/analytics/', SystemFeedbackSurveyAnalyticsView.as_view(), name='system_surveys_analytics'),
    path('department-feedback/', DepartmentFeedbackListCreateView.as_view(), name='department_feedback_list_create'),
    path('department-feedback/<int:pk>/review/', DepartmentFeedbackReviewView.as_view(), name='department_feedback_review'),
    path('<int:pk>/', CommunicationDetailView.as_view(), name='communication_detail'),
    path('<int:communication_id>/rsvp/', RSVPActionView.as_view(), name='communication_rsvp'),
    path('<int:communication_id>/rsvps/', CommunicationRSVPListView.as_view(), name='communication_rsvps_list'),
]
