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

    def test_skills_tagging_and_filtering(self):
        """Alumni profile can save skills, and admin directory can filter by skill."""
        self.client.force_authenticate(user=self.alumni_user)
        # Update profile with skills
        res = self.client.patch(reverse('my_profile'), {
            'skills': 'Python, Flutter, Django, PostgreSQL'
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['skills'], 'Python, Flutter, Django, PostgreSQL')
        self.assertIn('Python', res.data['skills_list'])

        # Admin filter by skill
        self.client.force_authenticate(user=self.admin_user)
        dir_res = self.client.get(reverse('alumni_directory') + '?skill=Flutter')
        self.assertEqual(dir_res.status_code, status.HTTP_200_OK)
        results = dir_res.data.get('results', dir_res.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['registration_number'], 'R175420X')

    def test_auto_verification_with_graduation_roster(self):
        """Registering with a registration number present in GraduationRoster auto-verifies user."""
        from alumni.models import GraduationRoster
        # Pre-seed graduation roster entry
        GraduationRoster.objects.create(
            registration_number='R220011C',
            full_name='Kudakwashe Chirwa',
            graduation_year=2023,
            programme='BSc Hons Software Engineering'
        )

        # Register new alumnus with matching registration number
        reg_payload = {
            'email': 'kuda.chirwa@alumni.msu.ac.zw',
            'password': 'Password123!',
            'first_name': 'Kudakwashe',
            'last_name': 'Chirwa',
            'registration_number': 'R220011C',
            'graduation_year': 2023,
            'programme': 'BSc Hons Software Engineering'
        }
        res = self.client.post(reverse('auth_register'), reg_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data['user']['is_verified'])

    def test_mentorship_directory_request_and_response(self):
        """Alumni can enable mentorship, appear in mentors directory, receive and respond to requests."""
        # Setup alumnus as mentor
        self.alumni_profile.is_available_for_mentorship = True
        self.alumni_profile.mentorship_areas = 'Career Guidance, Software Architecture'
        self.alumni_profile.skills = 'Python, Cloud Architecture'
        self.alumni_profile.save()

        # Another verified alumnus browsing mentors
        mentee_user = User.objects.create_user(
            username='chipo',
            email='chipo@alumni.msu.ac.zw',
            password='Password123!',
            first_name='Chipo',
            last_name='Ndebele',
            role=User.UserRole.ALUMNI,
            is_verified=True
        )
        mentee_profile = AlumniProfile.objects.create(
            user=mentee_user,
            registration_number='R219900M',
            graduation_year=2023,
            programme='BSc Hons Information Systems'
        )

        self.client.force_authenticate(user=mentee_user)
        # Browse mentors
        mentors_res = self.client.get(reverse('mentor_directory'))
        self.assertEqual(mentors_res.status_code, status.HTTP_200_OK)
        mentors = mentors_res.data.get('results', mentors_res.data)
        self.assertEqual(len(mentors), 1)
        self.assertEqual(mentors[0]['full_name'], 'Tinashe Moyo')

        # Send mentorship request
        req_res = self.client.post(reverse('mentorship_requests'), {
            'mentor_id': self.alumni_profile.id,
            'topic': 'CV Review & Mock Interview',
            'message': 'Hi Tinashe, I would love some feedback on transitioning into software architecture.'
        }, format='json')
        self.assertEqual(req_res.status_code, status.HTTP_201_CREATED)
        req_id = req_res.data['id']
        self.assertEqual(req_res.data['status'], 'PENDING')

        # Mentor accepts request
        self.client.force_authenticate(user=self.alumni_user)
        respond_res = self.client.patch(
            reverse('mentorship_respond', kwargs={'id': req_id}),
            {'status': 'ACCEPTED', 'response_message': 'Happy to connect! Let us set up a Google Meet on Friday.'},
            format='json'
        )
        self.assertEqual(respond_res.status_code, status.HTTP_200_OK)
        self.assertEqual(respond_res.data['status'], 'ACCEPTED')

    def test_tracer_survey_submission_and_analytics(self):
        """Test Objective 2: Tracer survey submission and department analytics."""
        self.client.force_authenticate(user=self.alumni_user)

        # Submit tracer survey
        survey_payload = {
            'had_job_before_graduation': False,
            'months_to_first_job': 4,
            'first_job_title': 'Junior Software Developer',
            'first_employer': 'Econet Wireless',
            'first_job_sector': 'Software & IT Services',
            'current_salary_band': '1000_2000',
            'degree_relevance': 'HIGHLY_RELEVANT',
            'career_satisfaction': 5,
            'curriculum_satisfaction': 4,
            'job_search_method': 'ONLINE_PORTAL',
            'skills_gap': 'Cloud infrastructure, Docker, Flutter',
            'is_complete': True,
        }
        res = self.client.post('/api/careers/tracer-survey/me/', survey_payload, format='json')
        self.assertIn(res.status_code, [status.HTTP_200_OK, status.HTTP_201_CREATED])
        self.assertEqual(res.data['months_to_first_job'], 4)
        self.assertEqual(res.data['degree_relevance'], 'HIGHLY_RELEVANT')

        # Retrieve own survey
        get_res = self.client.get('/api/careers/tracer-survey/me/')
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        self.assertEqual(get_res.data['first_employer'], 'Econet Wireless')

        # Admin analytics
        self.client.force_authenticate(user=self.admin_user)
        analytics_res = self.client.get('/api/careers/tracer-survey/analytics/')
        self.assertEqual(analytics_res.status_code, status.HTTP_200_OK)
        self.assertEqual(analytics_res.data['total_completed'], 1)
        self.assertEqual(analytics_res.data['avg_months_to_first_job'], 4.0)

    def test_ai_job_extraction_and_matching(self):
        """Test Objective 3: AI vacancy extraction, publishing, and candidate matching."""
        # Update alumni profile skills
        self.alumni_profile.skills = 'Python, Django, Flutter, PostgreSQL'
        self.alumni_profile.save()

        # Admin extracts job from advert text
        self.client.force_authenticate(user=self.admin_user)
        raw_ad = (
            "Cassava Smartech is hiring a Mid-level Python and Flutter Developer in Harare. "
            "Must have experience with Django REST framework and PostgreSQL database. "
            "Salary: $1,500 - $2,200. Apply at https://cassava.jobs"
        )
        extract_res = self.client.post('/api/jobs/admin/vacancies/ai-extract/', {
            'raw_advert_text': raw_ad,
        }, format='json')
        self.assertEqual(extract_res.status_code, status.HTTP_201_CREATED)
        job_id = extract_res.data['job']['id']

        # Admin publishes job and triggers matching
        publish_res = self.client.post(f'/api/jobs/admin/vacancies/{job_id}/publish-and-match/')
        self.assertEqual(publish_res.status_code, status.HTTP_200_OK)
        self.assertGreater(publish_res.data['total_matches'], 0)

        # Alumni views matched jobs
        self.client.force_authenticate(user=self.alumni_user)
        matched_res = self.client.get('/api/jobs/alumni/matched/')
        self.assertEqual(matched_res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(matched_res.data), 1)
        self.assertIn('flutter', matched_res.data[0]['skills_overlap'].lower())

        # Alumni applies to job
        apply_res = self.client.post(f'/api/jobs/alumni/apply/{job_id}/', {
            'cover_note': 'I have built multiple production Flutter + Django systems at MSU DCS.'
        }, format='json')
        self.assertEqual(apply_res.status_code, status.HTTP_200_OK)
        self.assertEqual(apply_res.data['application']['status'], 'APPLIED')

    def test_in_app_notifications_and_read_receipts(self):
        """Test Objective 4: Targeted broadcast creates notification and read receipt."""
        self.client.force_authenticate(user=self.admin_user)

        # Post targeted broadcast
        broadcast_res = self.client.post('/api/communications/', {
            'title': 'MSU Tech Career Fair 2026',
            'content': 'Leading tech companies visiting Gweru Campus for direct recruitment.',
            'category': 'EVENT',
            'target_graduation_year': 2021,
            'target_programme': 'Computer Science',
        }, format='json')
        self.assertEqual(broadcast_res.status_code, status.HTTP_201_CREATED)
        comm_id = broadcast_res.data['id']

        # Alumni checks in-app notifications
        self.client.force_authenticate(user=self.alumni_user)
        notif_res = self.client.get('/api/communications/notifications/')
        self.assertEqual(notif_res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(notif_res.data['unread_count'], 1)

        # Mark communication as read
        read_res = self.client.post(f'/api/communications/{comm_id}/read/')
        self.assertEqual(read_res.status_code, status.HTTP_200_OK)
        self.assertEqual(read_res.data['status'], 'marked_as_read')

    def test_advanced_reports_analytics(self):
        """Test Objective 5: Report summary includes advanced analytics."""
        self.client.force_authenticate(user=self.admin_user)

        summary_res = self.client.get('/api/reports/summary/')
        self.assertEqual(summary_res.status_code, status.HTTP_200_OK)
        self.assertIn('time_to_first_job', summary_res.data)
        self.assertIn('sector_distribution', summary_res.data)
        self.assertIn('career_progression', summary_res.data)
        self.assertIn('cohort_trends', summary_res.data)
        self.assertIn('tracer_survey_summary', summary_res.data)

