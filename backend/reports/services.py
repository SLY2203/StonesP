import csv
import io
from datetime import datetime
from django.db.models import Count, Q
from alumni.models import AlumniProfile
from careers.models import CareerRecord
from communications.models import Communication, RSVP
from accounts.models import User

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

class AlumniReportService:
    @staticmethod
    def get_summary_data(year=None, programme=None):
        profiles_qs = AlumniProfile.objects.select_related('user').all()
        if year:
            profiles_qs = profiles_qs.filter(graduation_year=year)
        if programme:
            profiles_qs = profiles_qs.filter(programme__icontains=programme)

        total_alumni = profiles_qs.count()
        verified_count = profiles_qs.filter(user__is_verified=True).count()
        pending_verification = total_alumni - verified_count

        # Career status aggregation
        current_careers = CareerRecord.objects.filter(alumnus__in=profiles_qs, is_current=True)
        tracked_count = current_careers.count()

        status_counts = current_careers.values('employment_status').annotate(total=Count('id'))
        status_dict = {item['employment_status']: item['total'] for item in status_counts}

        employed = status_dict.get(CareerRecord.EmploymentStatus.EMPLOYED, 0)
        self_employed = status_dict.get(CareerRecord.EmploymentStatus.SELF_EMPLOYED, 0)
        further_studies = status_dict.get(CareerRecord.EmploymentStatus.FURTHER_STUDIES, 0)
        unemployed = status_dict.get(CareerRecord.EmploymentStatus.UNEMPLOYED, 0)

        denom = tracked_count if tracked_count > 0 else 1
        employed_rate = round(((employed + self_employed) / denom) * 100, 1)

        # Programme distribution
        programme_counts = list(
            profiles_qs.values('programme').annotate(count=Count('id')).order_by('-count')
        )

        # Graduation year distribution
        year_counts = list(
            profiles_qs.values('graduation_year').annotate(count=Count('id')).order_by('-graduation_year')
        )

        # Top Industries
        top_industries = list(
            current_careers.values('industry_sector').annotate(count=Count('id')).order_by('-count')[:6]
        )

        # Top Employers
        top_employers = list(
            current_careers.exclude(employer='').values('employer').annotate(count=Count('id')).order_by('-count')[:6]
        )

        # Engagement metrics
        total_broadcasts = Communication.objects.count()
        total_rsvps = RSVP.objects.count()

        return {
            'filters': {'graduation_year': year, 'programme': programme},
            'generated_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'metrics': {
                'total_alumni': total_alumni,
                'verified_alumni': verified_count,
                'pending_verification': pending_verification,
                'tracked_employment_count': tracked_count,
                'employed_count': employed,
                'self_employed_count': self_employed,
                'further_studies_count': further_studies,
                'unemployed_count': unemployed,
                'overall_employment_rate': employed_rate,
                'total_broadcasts': total_broadcasts,
                'total_rsvps': total_rsvps,
            },
            'programmes': programme_counts,
            'graduation_years': year_counts,
            'top_industries': top_industries,
            'top_employers': top_employers,
        }

    @staticmethod
    def generate_csv(year=None, programme=None):
        """
        Generates CSV format export of alumni profiles with career statuses.
        """
        profiles_qs = AlumniProfile.objects.select_related('user').prefetch_related('career_records').all()
        if year:
            profiles_qs = profiles_qs.filter(graduation_year=year)
        if programme:
            profiles_qs = profiles_qs.filter(programme__icontains=programme)

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow([
            'Registration No', 'Full Name', 'Email', 'Graduation Year', 'Programme',
            'Phone', 'Account Verified', 'Employment Status', 'Current Employer',
            'Job Title', 'Industry Sector', 'Further Studies Institute'
        ])

        for profile in profiles_qs:
            cur = profile.career_records.filter(is_current=True).first()
            writer.writerow([
                profile.registration_number,
                profile.user.get_full_name(),
                profile.user.email,
                profile.graduation_year,
                profile.programme,
                profile.phone_number or 'N/A',
                'Yes' if profile.user.is_verified else 'No',
                cur.get_employment_status_display() if cur else 'Not Specified',
                cur.employer if cur else 'N/A',
                cur.job_title if cur else 'N/A',
                cur.industry_sector if cur else 'N/A',
                cur.further_education_institution if cur else 'N/A'
            ])

        return output.getvalue()

    @staticmethod
    def generate_pdf(year=None, programme=None):
        """
        Generates a professional PDF report with ReportLab.
        """
        data = AlumniReportService.get_summary_data(year=year, programme=programme)
        metrics = data['metrics']

        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'ReportTitle',
            parent=styles['Heading1'],
            fontName='Helvetica-Bold',
            fontSize=16,
            leading=20,
            textColor=colors.HexColor('#002D62'),
            alignment=1
        )
        subtitle_style = ParagraphStyle(
            'ReportSubtitle',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=10,
            leading=14,
            textColor=colors.HexColor('#4A5568'),
            alignment=1
        )
        section_style = ParagraphStyle(
            'SectionHeading',
            parent=styles['Heading2'],
            fontName='Helvetica-Bold',
            fontSize=12,
            leading=16,
            textColor=colors.HexColor('#002D62'),
            spaceBefore=10,
            spaceAfter=6
        )
        body_style = styles['Normal']

        elements = []

        # Header
        elements.append(Paragraph("MIDLANDS STATE UNIVERSITY", title_style))
        elements.append(Paragraph("FACULTY OF SCIENCE & TECHNOLOGY - DEPARTMENT OF COMPUTER SCIENCE", subtitle_style))
        elements.append(Paragraph("Alumni Career Progression & Graduate Tracking Report", subtitle_style))
        elements.append(Spacer(1, 8))

        gen_info = f"Generated on: {data['generated_at']} | Filter: Year: {year or 'All'}, Programme: {programme or 'All'}"
        elements.append(Paragraph(gen_info, ParagraphStyle('Meta', parent=body_style, fontSize=8, alignment=1, textColor=colors.gray)))
        elements.append(Spacer(1, 14))

        # KPI Summary Table
        kpi_data = [
            ['Metric', 'Value', 'Metric', 'Value'],
            ['Total Registered Alumni', str(metrics['total_alumni']), 'Overall Employment Rate', f"{metrics['overall_employment_rate']}%"],
            ['Verified Accounts', str(metrics['verified_alumni']), 'Employed (Full/Part)', str(metrics['employed_count'])],
            ['Pending Verification', str(metrics['pending_verification']), 'Self-Employed / Founders', str(metrics['self_employed_count'])],
            ['Tracked Employment Profiles', str(metrics['tracked_employment_count']), 'Pursuing Further Studies', str(metrics['further_studies_count'])],
            ['Total Communications', str(metrics['total_broadcasts']), 'Seeking Opportunities', str(metrics['unemployed_count'])],
        ]

        t_kpi = Table(kpi_data, colWidths=[150, 110, 160, 110])
        t_kpi.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#002D62')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E0')),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.HexColor('#F7FAFC'), colors.white]),
            ('ALIGN', (1, 1), (1, -1), 'CENTER'),
            ('ALIGN', (3, 1), (3, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(t_kpi)
        elements.append(Spacer(1, 14))

        # Top Industries Table
        elements.append(Paragraph("Top Industries Employing MSU DCS Graduates", section_style))
        ind_data = [['Industry Sector', 'Alumni Count']]
        if data['top_industries']:
            for ind in data['top_industries']:
                ind_data.append([ind['industry_sector'], str(ind['count'])])
        else:
            ind_data.append(['No industry data tracked yet', '0'])

        t_ind = Table(ind_data, colWidths=[380, 150])
        t_ind.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E0A800')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#002D62')),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E0')),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F7FAFC')]),
            ('ALIGN', (1, 0), (1, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(t_ind)
        elements.append(Spacer(1, 14))

        # Top Employers Table
        elements.append(Paragraph("Leading Employers of DCS Alumni", section_style))
        emp_data = [['Employer Organization', 'Alumni Count']]
        if data['top_employers']:
            for emp in data['top_employers']:
                emp_data.append([emp['employer'], str(emp['count'])])
        else:
            emp_data.append(['No employer data recorded yet', '0'])

        t_emp = Table(emp_data, colWidths=[380, 150])
        t_emp.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#002D62')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E0')),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F7FAFC')]),
            ('ALIGN', (1, 0), (1, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(t_emp)
        elements.append(Spacer(1, 14))

        # Footer sign-off
        signoff_text = "Official Departmental Report - Generated by Midlands State University DCS Alumni Tracking System"
        elements.append(Paragraph(signoff_text, ParagraphStyle('Footer', parent=body_style, fontSize=8, textColor=colors.gray, alignment=1)))

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()
