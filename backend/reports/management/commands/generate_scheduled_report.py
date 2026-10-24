import os
import datetime
from django.core.management.base import BaseCommand
from django.conf import settings
from django.core.mail import EmailMessage
from reports.services import AlumniReportService

class Command(BaseCommand):
    help = "Generates a monthly/scheduled department alumni analytics PDF report and optionally emails it to department staff."

    def add_arguments(self, parser):
        parser.add_argument(
            '--output-dir',
            type=str,
            default='generated_reports',
            help='Directory path where generated PDF reports will be saved.'
        )
        parser.add_argument(
            '--year',
            type=int,
            default=None,
            help='Filter report by graduation year.'
        )
        parser.add_argument(
            '--programme',
            type=str,
            default=None,
            help='Filter report by programme.'
        )
        parser.add_argument(
            '--email',
            type=str,
            default=None,
            help='Recipient email address to send the generated PDF to.'
        )

    def handle(self, *args, **options):
        output_dir = options['output_dir']
        year = options['year']
        programme = options['programme']
        recipient_email = options['email']

        os.makedirs(output_dir, exist_ok=True)
        now_str = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"MSU_DCS_Alumni_Report_{now_str}.pdf"
        file_path = os.path.join(output_dir, filename)

        pdf_data = AlumniReportService.generate_pdf(year=year, programme=programme)
        pdf_bytes = pdf_data.getvalue() if hasattr(pdf_data, 'getvalue') else pdf_data

        with open(file_path, 'wb') as f:
            f.write(pdf_bytes)

        self.stdout.write(self.style.SUCCESS(f"Generated PDF report saved to: {file_path} ({len(pdf_bytes)} bytes)"))

        if recipient_email:
            subject = f"MSU DCS Alumni Analytics Report - {datetime.datetime.now().strftime('%B %Y')}"
            body = (
                "Dear DCS Department Staff,\n\n"
                "Please find attached the latest auto-generated MSU DCS Alumni Analytics Report.\n\n"
                "Kind regards,\nMSU DCS Alumni System"
            )
            email = EmailMessage(
                subject=subject,
                body=body,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'alumni-system@msu.ac.zw'),
                to=[recipient_email],
            )
            email.attach(filename, pdf_bytes, 'application/pdf')
            try:
                email.send(fail_silently=False)
                self.stdout.write(self.style.SUCCESS(f"Email successfully dispatched to {recipient_email}"))
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"Could not send email: {e}"))
