from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime

from accounts.permissions import IsAdminUserRole
from .services import AlumniReportService

class ReportSummaryView(APIView):
    """
    Returns structured analytical data for the department staff reporting dashboard.
    Supports optional query params: 'graduation_year' (int) and 'programme' (str).
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        year = request.query_params.get('graduation_year')
        programme = request.query_params.get('programme')

        grad_year = int(year) if (year and year.isdigit()) else None
        data = AlumniReportService.get_summary_data(year=grad_year, programme=programme)
        return Response(data, status=status.HTTP_200_OK)

class ReportExportCSVView(APIView):
    """
    Downloads alumni cohort data as a formatted CSV file.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        year = request.query_params.get('graduation_year')
        programme = request.query_params.get('programme')
        grad_year = int(year) if (year and year.isdigit()) else None

        csv_content = AlumniReportService.generate_csv(year=grad_year, programme=programme)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"msu_dcs_alumni_report_{timestamp}.csv"

        response = HttpResponse(csv_content, content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response

class ReportExportPDFView(APIView):
    """
    Generates and downloads a formatted PDF departmental report.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        year = request.query_params.get('graduation_year')
        programme = request.query_params.get('programme')
        grad_year = int(year) if (year and year.isdigit()) else None

        pdf_bytes = AlumniReportService.generate_pdf(year=grad_year, programme=programme)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"msu_dcs_alumni_report_{timestamp}.pdf"

        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response
