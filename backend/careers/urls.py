from django.urls import path
from .views import (
    MyCareerRecordListCreateView,
    MyCareerRecordDetailView,
    CareerStatsView,
)

urlpatterns = [
    path('me/', MyCareerRecordListCreateView.as_view(), name='my_career_records'),
    path('me/<int:pk>/', MyCareerRecordDetailView.as_view(), name='my_career_record_detail'),
    path('stats/', CareerStatsView.as_view(), name='career_stats'),
]
