from django.urls import path
from .views import (
    MyCareerRecordListCreateView,
    MyCareerRecordDetailView,
    CareerStatsView,
)
from .tracer_views import (
    MyTracerSurveyView,
    TracerSurveyListView,
    TracerSurveyAnalyticsView,
)

urlpatterns = [
    path('me/', MyCareerRecordListCreateView.as_view(), name='my_career_records'),
    path('me/<int:pk>/', MyCareerRecordDetailView.as_view(), name='my_career_record_detail'),
    path('stats/', CareerStatsView.as_view(), name='career_stats'),

    # Objective 2: Tracer Survey
    path('tracer-survey/me/', MyTracerSurveyView.as_view(), name='my_tracer_survey'),
    path('tracer-survey/', TracerSurveyListView.as_view(), name='tracer_survey_list'),
    path('tracer-survey/analytics/', TracerSurveyAnalyticsView.as_view(), name='tracer_survey_analytics'),
]
