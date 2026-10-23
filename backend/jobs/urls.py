from django.urls import path
from .views import (
    JobVacancyListCreateView,
    JobVacancyDetailView,
    AIExtractJobView,
    PublishJobAndMatchView,
    JobMatchListView,
    JobApplicationAdminListView,
    JobMatchingAnalyticsView,
    AlumniMatchedJobsView,
    AlumniPublishedJobsView,
    AlumniApplyToJobView,
)

urlpatterns = [
    # Admin endpoints
    path('admin/vacancies/', JobVacancyListCreateView.as_view(), name='admin-job-list-create'),
    path('admin/vacancies/<int:pk>/', JobVacancyDetailView.as_view(), name='admin-job-detail'),
    path('admin/vacancies/ai-extract/', AIExtractJobView.as_view(), name='admin-job-ai-extract'),
    path('admin/vacancies/<int:pk>/publish-and-match/', PublishJobAndMatchView.as_view(), name='admin-job-publish-match'),
    path('admin/vacancies/<int:job_id>/matches/', JobMatchListView.as_view(), name='admin-job-matches'),
    path('admin/vacancies/<int:job_id>/applications/', JobApplicationAdminListView.as_view(), name='admin-job-applications'),
    path('admin/analytics/', JobMatchingAnalyticsView.as_view(), name='admin-job-analytics'),

    # Alumni endpoints
    path('alumni/matched/', AlumniMatchedJobsView.as_view(), name='alumni-matched-jobs'),
    path('alumni/browse/', AlumniPublishedJobsView.as_view(), name='alumni-browse-jobs'),
    path('alumni/apply/<int:job_id>/', AlumniApplyToJobView.as_view(), name='alumni-apply-job'),
]
