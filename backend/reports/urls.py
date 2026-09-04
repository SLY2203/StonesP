from django.urls import path
from .views import ReportSummaryView, ReportExportCSVView, ReportExportPDFView

urlpatterns = [
    path('summary/', ReportSummaryView.as_view(), name='report_summary'),
    path('export/csv/', ReportExportCSVView.as_view(), name='report_export_csv'),
    path('export/pdf/', ReportExportPDFView.as_view(), name='report_export_pdf'),
]
