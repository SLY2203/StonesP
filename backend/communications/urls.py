from django.urls import path
from .views import (
    CommunicationListCreateView,
    CommunicationDetailView,
    RSVPActionView,
    CommunicationRSVPListView,
)

urlpatterns = [
    path('', CommunicationListCreateView.as_view(), name='communication_list_create'),
    path('<int:pk>/', CommunicationDetailView.as_view(), name='communication_detail'),
    path('<int:communication_id>/rsvp/', RSVPActionView.as_view(), name='communication_rsvp'),
    path('<int:communication_id>/rsvps/', CommunicationRSVPListView.as_view(), name='communication_rsvps_list'),
]
