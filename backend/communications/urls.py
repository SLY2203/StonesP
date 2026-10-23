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
    CommunicationReadView,
    InAppNotificationListView,
    MarkNotificationReadView,
    MarkAllNotificationsReadView,
)

urlpatterns = [
    path('', CommunicationListCreateView.as_view(), name='communication_list_create'),
    path('notifications/', InAppNotificationListView.as_view(), name='in_app_notifications'),
    path('notifications/<int:pk>/read/', MarkNotificationReadView.as_view(), name='notification_read'),
    path('notifications/read-all/', MarkAllNotificationsReadView.as_view(), name='notifications_read_all'),
    path('feedbacks/', AllFeedbacksListView.as_view(), name='all_feedbacks_list'),
    path('surveys/', SystemFeedbackSurveyListCreateView.as_view(), name='system_surveys_list_create'),
    path('surveys/analytics/', SystemFeedbackSurveyAnalyticsView.as_view(), name='system_surveys_analytics'),
    path('department-feedback/', DepartmentFeedbackListCreateView.as_view(), name='department_feedback_list_create'),
    path('department-feedback/<int:pk>/review/', DepartmentFeedbackReviewView.as_view(), name='department_feedback_review'),
    path('<int:pk>/', CommunicationDetailView.as_view(), name='communication_detail'),
    path('<int:pk>/read/', CommunicationReadView.as_view(), name='communication_mark_read'),
    path('<int:communication_id>/rsvp/', RSVPActionView.as_view(), name='communication_rsvp'),
    path('<int:communication_id>/rsvps/', CommunicationRSVPListView.as_view(), name='communication_rsvps_list'),
]
