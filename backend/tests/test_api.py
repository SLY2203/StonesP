import json
from datetime import date
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from accounts.models import User
from alumni.models import AlumniProfile
from careers.models import CareerRecord
from communications.models import Communication, RSVP

class MSUDCSAlumniAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Admin user
        self.admin_user = User.objects.create_user(
            username='dcs_admin',
            email='admin@dcs.msu.ac.zw',
            password='Password123!',
            first_name='Admin',
            last_name='Staff',
            role=User.UserRole.ADMIN,
            is_verified=True,
            is_staff=True
        )

        # Verified Alumni user
        self.alumni_user = User.objects.create_user(
            username='tinashe',
            email='tinashe@alumni.msu.ac.zw',
            password='Password123!',
            first_name='Tinashe',
            last_name='Moyo',
            role=User.UserRole.ALUMNI,
            is_verified=True
        )
        self.alumni_profile = AlumniProfile.objects.create(
            user=self.alumni_user,
            registration_number='R175420X',
            graduation_year=2021,
            programme='BSc Hons Computer Science'
        )

        # Unverified Alumni user
        self.unverified_user = User.objects.create_user(
            username='blessing',
            email='blessing@alumni.msu.ac.zw',
            password='Password123!',
            first_name='Blessing',
            last_name='Munemo',
            role=User.UserRole.ALUMNI,
            is_verified=False
        )
        self.unverified_profile = AlumniProfile.objects.create(
            user=self.unverified_user,
            registration_number='R208899B',
            graduation_year=2024,
            programme='BSc Hons Computer Science'
        )

        # Communication
        self.communication = Communication.objects.create(
            title='MSU Tech Expo 2026',
            content='Annual innovation expo and showcase.',
            category=Communication.Category.EVENT,
            created_by=self.admin_user
        )

    def test_alumni_registration(self):
        """Test that an alumnus can register and starts as unverified."""
        payload = {
            'email': 'new.alumnus@alumni.msu.ac.zw',
            'password': 'StrongPassword123',
            'first_name': 'Kuda',
            'last_name': 'Nhema',
            'registration_number': 'R219900K',
            'graduation_year': 2023,
            'programme': 'BSc Hons Information Technology',
            'phone_number': '+263771112222'
        }
        url = reverse('auth_register')
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertFalse(response.data['user']['is_verified'])

        # Verify profile created in database
        profile = AlumniProfile.objects.filter(registration_number='R219900K').first()
        self.assertIsNotNone(profile)
        self.assertEqual(profile.user.email, 'new.alumnus@alumni.msu.ac.zw')

    def test_jwt_login(self):
        """Test login returns access and refresh JWT tokens and user metadata."""
        url = reverse('auth_login')
        payload = {
            'email': 'tinashe@alumni.msu.ac.zw',
            'password': 'Password123!'
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['email'], 'tinashe@alumni.msu.ac.zw')
        self.assertEqual(response.data['user']['role'], 'ALUMNI')

    def test_rbac_alumni_cannot_access_admin_directory(self):
        """Alumni should receive 403 Forbidden when trying to access admin directory."""
        self.client.force_authenticate(user=self.alumni_user)
        url = reverse('alumni_directory')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_verify_alumnus(self):
        """Admin can toggle verification for pending alumni."""
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('verify_alumni', kwargs={'user_id': self.unverified_user.id})
        response = self.client.post(url, {'is_verified': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.unverified_user.refresh_from_db()
        self.assertTrue(self.unverified_user.is_verified)

    def test_career_timeline_crud(self):
        """Alumni can add, list, and update career timeline milestones."""
        self.client.force_authenticate(user=self.alumni_user)
        url = reverse('my_career_records')

        # Add milestone
        payload = {
            'job_title': 'Software Engineer',
            'employer': 'EcoCash',
            'employment_status': CareerRecord.EmploymentStatus.EMPLOYED,
            'industry_sector': 'FinTech & Banking',
            'start_date': '2023-01-01',
            'is_current': True,
            'description': 'Core backend developer'
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        record_id = response.data['id']

        # List records
        list_response = self.client.get(url)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        records = list_response.data.get('results', list_response.data)
        self.assertEqual(len(records), 1)

        # Update record
        detail_url = reverse('my_career_record_detail', kwargs={'pk': record_id})
        update_response = self.client.patch(detail_url, {'job_title': 'Senior Software Engineer'}, format='json')
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(update_response.data['job_title'], 'Senior Software Engineer')

    def test_communication_feed_and_rsvp(self):
        """Verified alumni can read communications and submit an RSVP."""
        self.client.force_authenticate(user=self.alumni_user)
        url = reverse('communication_list_create')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        feed = response.data.get('results', response.data)
        self.assertGreaterEqual(len(feed), 1)

        # Submit RSVP
        rsvp_url = reverse('communication_rsvp', kwargs={'communication_id': self.communication.id})
        rsvp_res = self.client.post(rsvp_url, {
            'response_type': RSVP.ResponseType.ATTENDING,
            'notes': 'Looking forward to attending.'
        }, format='json')
        self.assertEqual(rsvp_res.status_code, status.HTTP_200_OK)

        # Check in database
        rsvp = RSVP.objects.filter(communication=self.communication, alumnus=self.alumni_profile).first()
        self.assertIsNotNone(rsvp)
        self.assertEqual(rsvp.response_type, RSVP.ResponseType.ATTENDING)

    def test_admin_reports_and_exports(self):
        """Admin can access summary statistics, CSV export, and PDF export."""
        self.client.force_authenticate(user=self.admin_user)

        # 1. Summary stats
        summary_res = self.client.get(reverse('report_summary'))
        self.assertEqual(summary_res.status_code, status.HTTP_200_OK)
        self.assertIn('metrics', summary_res.data)
        self.assertIn('overall_employment_rate', summary_res.data['metrics'])

        # 2. CSV export
        csv_res = self.client.get(reverse('report_export_csv'))
        self.assertEqual(csv_res.status_code, status.HTTP_200_OK)
        self.assertEqual(csv_res['Content-Type'], 'text/csv')
        self.assertIn('Registration No,Full Name', csv_res.content.decode('utf-8'))

        # 3. PDF export
        pdf_res = self.client.get(reverse('report_export_pdf'))
        self.assertEqual(pdf_res.status_code, status.HTTP_200_OK)
        self.assertEqual(pdf_res['Content-Type'], 'application/pdf')
        self.assertTrue(pdf_res.content.startswith(b'%PDF'))
