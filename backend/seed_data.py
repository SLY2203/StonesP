"""
Seed data script for MSU DCS Alumni Tracking System.
Populates:
  - 1 Department Staff Administrator
  - 10 Realistic Alumni profiles with career histories and verification states
  - 5 Engaging department communications (events, job vacancies, announcements, mentorship)
  - Pre-seeded RSVP responses for engagement tracking
"""
import os
import sys
import django
from datetime import date, datetime, timedelta

# Setup django environment
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dcs_alumni_project.settings')
django.setup()

from django.utils import timezone
from accounts.models import User
from alumni.models import AlumniProfile, GraduationRoster, MentorshipRequest
from careers.models import CareerRecord
from communications.models import Communication, RSVP

def run_seed():
    print("Seeding MSU DCS Alumni Tracking System Database...")

    # 1. Create Department Admin User
    admin_email = "admin@dcs.msu.ac.zw"
    admin_user, created = User.objects.get_or_create(
        email=admin_email,
        defaults={
            'username': 'dcs_admin',
            'first_name': 'Prof. Tendai',
            'last_name': 'Marufu',
            'role': User.UserRole.ADMIN,
            'is_staff': True,
            'is_superuser': True,
            'is_verified': True,
        }
    )
    admin_user.set_password("stones123")
    admin_user.save()
    print(f" [OK] Admin user created: {admin_user.email} (Password: stones123)")

    # 2. Define Sample Alumni Data
    alumni_data = [
        {
            'email': 'tinashe.moyo@alumni.msu.ac.zw',
            'first_name': 'Tinashe',
            'last_name': 'Moyo',
            'reg_number': 'R175420X',
            'grad_year': 2021,
            'programme': 'BSc Hons Computer Science',
            'phone': '+263 77 123 4567',
            'bio': 'Passionate software architect focused on distributed mobile financial solutions in Southern Africa.',
            'linkedin': 'https://linkedin.com/in/tinashe-moyo-dcs',
            'is_verified': True,
            'skills': 'Python, Django, Flutter, PostgreSQL, Microservices, Docker, Redis',
            'is_available_for_mentorship': True,
            'mentorship_areas': 'FinTech Architecture, Backend APIs, Career Transition',
            'careers': [
                {
                    'job_title': 'Senior Software Engineer',
                    'employer': 'EcoCash Holdings Zimbabwe',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2023, 1, 15),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Leading payment rails integration and microservices development.'
                },
                {
                    'job_title': 'Junior Software Developer',
                    'employer': 'Cassava Smartech',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2021, 3, 1),
                    'end_date': date(2022, 12, 31),
                    'is_current': False,
                    'description': 'Backend API developer building merchant integrations.'
                }
            ]
        },
        {
            'email': 'nyasha.chidambazina@alumni.msu.ac.zw',
            'first_name': 'Nyasha',
            'last_name': 'Chidambazina',
            'reg_number': 'R184321A',
            'grad_year': 2022,
            'programme': 'BSc Hons Information Technology',
            'phone': '+263 71 987 6543',
            'bio': 'Cloud solutions engineer specializing in AWS and multi-tenant enterprise infrastructure.',
            'linkedin': 'https://linkedin.com/in/nyasha-chidambazina',
            'is_verified': True,
            'skills': 'AWS, Terraform, Kubernetes, Linux, Python, CI/CD, Cloud Architecture',
            'is_available_for_mentorship': True,
            'mentorship_areas': 'Cloud Certifications, DevOps & SRE, Infrastructure',
            'careers': [
                {
                    'job_title': 'Cloud Solutions Architect',
                    'employer': 'Liquid Intelligent Technologies',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'Telecommunications',
                    'start_date': date(2022, 7, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Designing hybrid cloud deployments and disaster recovery architectures.'
                }
            ]
        },
        {
            'email': 'tafadzwa.ndlovu@alumni.msu.ac.zw',
            'first_name': 'Tafadzwa',
            'last_name': 'Ndlovu',
            'reg_number': 'R162981M',
            'grad_year': 2020,
            'programme': 'BSc Hons Software Engineering',
            'phone': '+263 78 555 1212',
            'bio': 'Tech founder building software solutions for African SMEs and AgriTech.',
            'linkedin': 'https://linkedin.com/in/tafadzwa-ndlovu-codelab',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Founder & Chief Technology Officer',
                    'employer': 'Harare CodeLab Solutions',
                    'status': CareerRecord.EmploymentStatus.SELF_EMPLOYED,
                    'industry': 'Software & IT Services',
                    'start_date': date(2021, 6, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Managing tech strategy and custom enterprise software delivery for clients.'
                }
            ]
        },
        {
            'email': 'rutendo.sithole@alumni.msu.ac.zw',
            'first_name': 'Rutendo',
            'last_name': 'Sithole',
            'reg_number': 'R196112P',
            'grad_year': 2023,
            'programme': 'BSc Hons Computer Science',
            'phone': '+263 77 444 8899',
            'bio': 'Backend developer with deep interest in data pipelines and high-throughput systems.',
            'linkedin': 'https://linkedin.com/in/rutendo-sithole-dev',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Associate Software Engineer',
                    'employer': 'Cassava Technologies',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2023, 10, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Developing event-driven data streaming services using Kafka and Go.'
                }
            ]
        },
        {
            'email': 'farai.mutasa@alumni.msu.ac.zw',
            'first_name': 'Farai',
            'last_name': 'Mutasa',
            'reg_number': 'R152341K',
            'grad_year': 2019,
            'programme': 'BSc Hons Information Systems',
            'phone': '+263 73 222 3344',
            'bio': 'Enterprise IT Specialist ensuring system uptime and ITIL governance.',
            'linkedin': 'https://linkedin.com/in/farai-mutasa-systems',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Senior Systems Analyst',
                    'employer': 'Old Mutual Zimbabwe',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2020, 2, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Overseeing core financial system audits and automated test suites.'
                }
            ]
        },
        {
            'email': 'chipo.mashumba@alumni.msu.ac.zw',
            'first_name': 'Chipo',
            'last_name': 'Mashumba',
            'reg_number': 'R187765C',
            'grad_year': 2022,
            'programme': 'BSc Hons Cybersecurity & Digital Forensics',
            'phone': '+263 77 999 1122',
            'bio': 'SOC analyst and vulnerability assessment specialist in banking security.',
            'linkedin': 'https://linkedin.com/in/chipo-mashumba-sec',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Cybersecurity Analyst',
                    'employer': 'CBZ Bank Limited',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2022, 11, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Threat intelligence, penetration testing, and incident response.'
                }
            ]
        },
        {
            'email': 'simbarashe.dube@alumni.msu.ac.zw',
            'first_name': 'Simbarashe',
            'last_name': 'Dube',
            'reg_number': 'R203344D',
            'grad_year': 2024,
            'programme': 'BSc Hons Computer Science',
            'phone': '+263 71 333 4455',
            'bio': 'Pursuing post-graduate machine learning research on low-resource African language NLP.',
            'linkedin': 'https://linkedin.com/in/simba-dube-nlp',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Graduate Research Assistant',
                    'employer': 'Midlands State University',
                    'status': CareerRecord.EmploymentStatus.FURTHER_STUDIES,
                    'industry': 'Education & Research',
                    'start_date': date(2024, 8, 1),
                    'end_date': None,
                    'is_current': True,
                    'further_institution': 'Midlands State University',
                    'further_programme': 'MSc in Artificial Intelligence & Data Science',
                    'description': 'Assisting undergraduate labs while researching speech models for Shona & Ndebele.'
                }
            ]
        },
        {
            'email': 'memory.gumbo@alumni.msu.ac.zw',
            'first_name': 'Memory',
            'last_name': 'Gumbo',
            'reg_number': 'R198822G',
            'grad_year': 2023,
            'programme': 'BSc Hons Software Engineering',
            'phone': '+263 77 666 5544',
            'bio': 'Full-stack software developer proficient in Flutter, React, and Python.',
            'linkedin': 'https://linkedin.com/in/memory-gumbo-dev',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Full-Stack Developer',
                    'employer': 'ZimSwitch Technologies',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'FinTech & Banking',
                    'start_date': date(2023, 9, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Building real-time payment monitoring dashboards.'
                }
            ]
        },
        {
            'email': 'kudakwashe.sibanda@alumni.msu.ac.zw',
            'first_name': 'Kudakwashe',
            'last_name': 'Sibanda',
            'reg_number': 'R205566S',
            'grad_year': 2024,
            'programme': 'BSc Hons Information Technology',
            'phone': '+263 78 111 2233',
            'bio': 'Eager junior technician looking for software testing, DevOps, or system administration opportunities.',
            'linkedin': 'https://linkedin.com/in/kudakwashe-sibanda-it',
            'is_verified': True,
            'careers': [
                {
                    'job_title': 'Graduate IT Intern (Recent Graduate)',
                    'employer': 'Freelance / Seeking Full-Time Role',
                    'status': CareerRecord.EmploymentStatus.UNEMPLOYED,
                    'industry': 'Software & IT Services',
                    'start_date': date(2024, 7, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Open for junior software engineer and network admin roles.'
                }
            ]
        },
        {
            'email': 'blessing.munemo@alumni.msu.ac.zw',
            'first_name': 'Blessing',
            'last_name': 'Munemo',
            'reg_number': 'R208899B',
            'grad_year': 2024,
            'programme': 'BSc Hons Computer Science',
            'phone': '+263 77 777 8899',
            'bio': 'Recent graduate eager to connect with industry mentors. Account newly submitted.',
            'linkedin': 'https://linkedin.com/in/blessing-munemo',
            'is_verified': False,  # Unverified for testing Admin verification workflow!
            'careers': [
                {
                    'job_title': 'Junior Web Developer',
                    'employer': 'Mutare Web Studios',
                    'status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry': 'E-Commerce & Retail',
                    'start_date': date(2024, 8, 1),
                    'end_date': None,
                    'is_current': True,
                    'description': 'Front-end development with Tailwind and Next.js.'
                }
            ]
        },
    ]

    alumni_profiles = []
    for item in alumni_data:
        email = item['email']
        username = email.split('@')[0]
        user, u_created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': username,
                'first_name': item['first_name'],
                'last_name': item['last_name'],
                'role': User.UserRole.ALUMNI,
                'is_verified': item['is_verified'],
            }
        )
        user.set_password("stones123")
        user.is_verified = item['is_verified']
        user.save()

        profile, p_created = AlumniProfile.objects.get_or_create(
            user=user,
            defaults={
                'registration_number': item['reg_number'],
                'graduation_year': item['grad_year'],
                'programme': item['programme'],
                'phone_number': item['phone'],
                'bio': item['bio'],
                'linkedin_url': item['linkedin'],
                'skills': item.get('skills', 'Python, SQL, Git'),
                'is_available_for_mentorship': item.get('is_available_for_mentorship', False),
                'mentorship_areas': item.get('mentorship_areas', ''),
            }
        )
        if not profile.skills and item.get('skills'):
            profile.skills = item['skills']
        if item.get('is_available_for_mentorship'):
            profile.is_available_for_mentorship = item['is_available_for_mentorship']
            profile.mentorship_areas = item.get('mentorship_areas', '')
        profile.save()
        alumni_profiles.append(profile)

        # Seed Career records
        for c in item['careers']:
            rec, _ = CareerRecord.objects.get_or_create(
                alumnus=profile,
                job_title=c['job_title'],
                employer=c['employer'],
                defaults={
                    'employment_status': c['status'],
                    'industry_sector': c['industry'],
                    'start_date': c['start_date'],
                    'end_date': c.get('end_date'),
                    'is_current': c['is_current'],
                    'further_education_institution': c.get('further_institution'),
                    'further_education_programme': c.get('further_programme'),
                    'description': c['description'],
                    'skills_used': c.get('skills_used', profile.skills),
                }
            )

    print(f" [OK] Seeded {len(alumni_profiles)} realistic Alumni accounts & profiles.")

    # 3. Create 5 Engaging Communications
    now = timezone.now()
    communications_data = [
        {
            'title': 'Welcome to the MSU DCS Alumni Network & 2026 Innovation Hackathon',
            'category': Communication.Category.ANNOUNCEMENT,
            'content': (
                "The Department of Computer Science is proud to launch our unified Alumni Tracking and Engagement Portal! "
                "We invite all graduates to keep their employment records up to date, mentor current finalists, and register for "
                "the upcoming National Innovation Hackathon held in collaboration with the MSU Innovation Hub."
            ),
            'target_graduation_year': None,
            'event_date': None,
            'location': 'MSU Gweru Main Campus & Online',
            'deadline': None,
            'link': 'https://dcs.msu.ac.zw/hackathon-2026',
        },
        {
            'title': 'MSU Faculty of Science & Tech Annual Alumni Reunion Dinner & Awards Gala',
            'category': Communication.Category.EVENT,
            'content': (
                "Join your fellow DCS classmates, faculty deans, and keynote speakers from Zimbabwe's leading tech industry "
                "for an evening of networking, dinner, and celebration of distinguished alumni achievements. "
                "Early bird RSVP is now open for all alumni."
            ),
            'target_graduation_year': None,
            'event_date': now + timedelta(days=28),
            'location': 'Great Hall, Midlands State University, Gweru',
            'deadline': now + timedelta(days=21),
            'link': 'https://dcs.msu.ac.zw/gala-rsvp',
        },
        {
            'title': 'Career Opportunity: Graduate Cloud Engineers & DevOps Associates (Liquid Telecom)',
            'category': Communication.Category.JOB_VACANCY,
            'content': (
                "Liquid Intelligent Technologies Zimbabwe is hiring recent DCS graduates (2022-2024 cohorts) "
                "for full-time roles in Cloud Infrastructure, Linux Systems Administration, and DevOps pipelines. "
                "Fast-track interviews available for verified MSU DCS alumni."
            ),
            'target_graduation_year': 2024,
            'event_date': None,
            'location': 'Harare & Remote Hybrid',
            'deadline': now + timedelta(days=14),
            'link': 'https://liquidtelecom.com/careers/msu-graduates',
        },
        {
            'title': 'Call for Alumni Mentors: DCS Final Year Capstone Mentorship Cohort 2026',
            'category': Communication.Category.MENTORSHIP,
            'content': (
                "Give back to your alma mater! We are pairing 4th-year Computer Science and Software Engineering undergraduates "
                "with seasoned alumni working in the industry. Commitment is 2 hours per month via video call to review capstone projects "
                "and share career advice."
            ),
            'target_graduation_year': None,
            'event_date': now + timedelta(days=10),
            'location': 'Virtual / Google Meet',
            'deadline': now + timedelta(days=7),
            'link': 'https://dcs.msu.ac.zw/mentorship-apply',
        },
        {
            'title': 'Guest Tech Talk: Scaling High-Availability Microservices in Africa',
            'category': Communication.Category.EVENT,
            'content': (
                "Featuring DCS Alumnus Tinashe Moyo (Senior Software Engineer, EcoCash). "
                "Topic: Lessons learned processing millions of daily transactions, fault tolerance, and zero-downtime database migrations."
            ),
            'target_graduation_year': None,
            'event_date': now + timedelta(days=7),
            'location': 'DCS Lecture Theatre 3 & Zoom Webinar',
            'deadline': None,
            'link': 'https://zoom.us/j/msu-dcs-techtalk',
        },
    ]

    comms = []
    for c in communications_data:
        comm, _ = Communication.objects.get_or_create(
            title=c['title'],
            defaults={
                'category': c['category'],
                'content': c['content'],
                'target_graduation_year': c['target_graduation_year'],
                'event_date': c['event_date'],
                'location': c['location'],
                'application_deadline': c['deadline'],
                'external_link': c['link'],
                'created_by': admin_user,
            }
        )
        comms.append(comm)

    print(f" [OK] Seeded {len(comms)} Communications & Announcements.")

    # 4. Create Sample RSVPs
    sample_rsvps = [
        (comms[1], alumni_profiles[0], RSVP.ResponseType.ATTENDING, "Looking forward to seeing my 2021 classmates!"),
        (comms[1], alumni_profiles[1], RSVP.ResponseType.ATTENDING, "Attending from Harare."),
        (comms[1], alumni_profiles[4], RSVP.ResponseType.INTERESTED, "Tentative depending on travel."),
        (comms[2], alumni_profiles[8], RSVP.ResponseType.APPLIED, "Submitted my CV for the Cloud Engineer role."),
        (comms[2], alumni_profiles[3], RSVP.ResponseType.INTERESTED, "Sharing with junior colleagues."),
        (comms[3], alumni_profiles[0], RSVP.ResponseType.ATTENDING, "Happy to mentor 2 students in FinTech!"),
        (comms[3], alumni_profiles[2], RSVP.ResponseType.ATTENDING, "Count me in for software architecture capstones."),
        (comms[4], alumni_profiles[1], RSVP.ResponseType.ATTENDING, "Excited for Tinashe's presentation!"),
        (comms[4], alumni_profiles[5], RSVP.ResponseType.INTERESTED, "Will join via Zoom."),
    ]

    for comm, profile, resp_type, note in sample_rsvps:
        RSVP.objects.get_or_create(
            communication=comm,
            alumnus=profile,
            defaults={
                'response_type': resp_type,
                'notes': note
            }
        )

    print(f" [OK] Seeded {len(sample_rsvps)} Engagement RSVPs.")

    # 5. Seed Graduation Roster (Official MSU DCS records for automated verification)
    roster_samples = [
        ('R208899B', 'Blessing Munemo', 2024, 'BSc Hons Computer Science', 'Upper Second (2.1)'),
        ('R210045K', 'Anesu Mavhunga', 2024, 'BSc Hons Software Engineering', 'First Class (1)'),
        ('R215589T', 'Kudzanai Zhou', 2024, 'BSc Hons Cybersecurity & Digital Forensics', 'Upper Second (2.1)'),
        ('R220011C', 'Kudakwashe Chirwa', 2023, 'BSc Hons Software Engineering', 'Upper Second (2.1)'),
        ('R175420X', 'Tinashe Moyo', 2021, 'BSc Hons Computer Science', 'First Class (1)'),
        ('R184321A', 'Nyasha Chidambazina', 2022, 'BSc Hons Information Technology', 'First Class (1)'),
        ('R162981M', 'Tafadzwa Ndlovu', 2020, 'BSc Hons Software Engineering', 'First Class (1)'),
    ]
    for reg, name, yr, prog, deg in roster_samples:
        GraduationRoster.objects.update_or_create(
            registration_number=reg,
            defaults={'full_name': name, 'graduation_year': yr, 'programme': prog, 'degree_class': deg}
        )
    print(f" [OK] Seeded {len(roster_samples)} official Graduation Roster records.")

    # 6. Seed Sample Mentorship Request
    if len(alumni_profiles) >= 2:
        MentorshipRequest.objects.get_or_create(
            mentor=alumni_profiles[0],  # Tinashe Moyo
            mentee=alumni_profiles[1],  # Nyasha Chidambazina
            defaults={
                'topic': 'FinTech Microservices & Distributed Architecture',
                'message': 'Hi Tinashe, looking for architectural guidance on handling high-throughput mobile money transactions.',
                'status': MentorshipRequest.Status.ACCEPTED,
                'response_message': 'Hey Nyasha, glad to help! Let us jump on a call next Tuesday at 5 PM.'
            }
        )
        print(" [OK] Seeded sample Mentorship request & connection.")
    print("\n--- SEED COMPLETE ---")
    print("Default Admin Credentials:")
    print("  Email:    admin@dcs.msu.ac.zw")
    print("  Password: stones123")
    print("Default Alumni Credentials (Verified):")
    print("  Email:    tinashe.moyo@alumni.msu.ac.zw")
    print("  Password: stones123")
    print("Unverified Sample Alumnus (for admin verification test):")
    print("  Email:    blessing.munemo@alumni.msu.ac.zw")
    print("  Password: stones123")

if __name__ == '__main__':
    run_seed()
