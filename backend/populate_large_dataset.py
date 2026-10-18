"""
High-volume realistic dataset generator for MSU DCS Alumni Tracking System.
Populates:
  - 50+ diverse Alumni profiles with full career records, skills, and bios
  - 35+ Official Graduation Roster records
  - 12+ Communications (Events, Job Vacancies, Announcements, Mentorship)
  - 40+ Event RSVPs and Job Applications
  - 10+ Mentorship Requests across different statuses
"""
import os
import sys
import random
from datetime import date, datetime, timedelta

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dcs_alumni_project.settings')
import django
django.setup()

from django.utils import timezone
from accounts.models import User
from alumni.models import AlumniProfile, GraduationRoster, MentorshipRequest
from careers.models import CareerRecord
from communications.models import Communication, RSVP

# Dataset definitions
FIRST_NAMES_MALE = [
    "Tinashe", "Farai", "Simbarashe", "Tawanda", "Kudakwashe", "Blessing",
    "Tatenda", "Takudzwa", "Tapiwa", "Munyaradzi", "Taurai", "Tendai",
    "Munashe", "Panashe", "Prosper", "Trust", "Pride", "Tadiwa", "Innocent",
    "Lovemore", "Ngonidzashe", "Tariro", "Anesu", "Mthokozisi", "Sipho"
]

FIRST_NAMES_FEMALE = [
    "Nyasha", "Chipo", "Memory", "Ruvimbo", "Tariro", "Gamuchirai",
    "Rutendo", "Tsitsi", "Vimbai", "Kudzai", "Shamiso", "Danai",
    "Fungai", "Rumbidzai", "Nomatter", "Paidamoyo", "Natsai", "Tariroyashe",
    "Nokuthula", "Buhle", "Gugulethu", "Siphiwe", "Tendekai", "Sekai"
]

LAST_NAMES = [
    "Moyo", "Chidambazina", "Mutasa", "Mashumba", "Dube", "Gumbo",
    "Ndlovu", "Sibanda", "Mpofu", "Chikwanha", "Munemo", "Musarurwa",
    "Mavhunga", "Chirwa", "Muzenda", "Ncube", "Shumba", "Matarise",
    "Maphosa", "Zhou", "Katsande", "Chigumba", "Makore", "Hove",
    "Machingambi", "Chiweshe", "Mhlanga", "Banda", "Nyathi", "Marufu"
]

PROGRAMMES = [
    ('BSc Hons Computer Science', 0.35),
    ('BSc Hons Software Engineering', 0.25),
    ('BSc Hons Information Technology', 0.18),
    ('BSc Hons Cybersecurity & Digital Forensics', 0.12),
    ('BSc Hons Information Systems', 0.06),
    ('MSc Information Technology', 0.04),
]

INDUSTRIES = [
    'Software & IT Services',
    'FinTech & Banking',
    'Telecommunications',
    'E-Commerce & Retail',
    'Education & Research',
    'Mining & Energy',
    'Public Sector & Gov',
    'HealthTech & Medical',
]

COMPANIES = [
    ('EcoCash Holdings Zimbabwe', 'FinTech & Banking'),
    ('Liquid Intelligent Technologies', 'Telecommunications'),
    ('Cassava Smartech', 'FinTech & Banking'),
    ('CBZ Bank Limited', 'FinTech & Banking'),
    ('Stanbic Bank Zimbabwe', 'FinTech & Banking'),
    ('CABS Zimbabwe', 'FinTech & Banking'),
    ('Old Mutual Zimbabwe', 'FinTech & Banking'),
    ('Econet Wireless Zimbabwe', 'Telecommunications'),
    ('NetOne Cellular', 'Telecommunications'),
    ('ZimSwitch Technologies', 'FinTech & Banking'),
    ('Mukuru Financial Services', 'FinTech & Banking'),
    ('AfroCode Labs', 'Software & IT Services'),
    ('Midlands State University', 'Education & Research'),
    ('Mimosa Mining Company', 'Mining & Energy'),
    ('Delta Corporation', 'E-Commerce & Retail'),
    ('Amazon Web Services (Remote)', 'Software & IT Services'),
    ('Canonical / Ubuntu (Remote)', 'Software & IT Services'),
    ('DevZim Solutions', 'Software & IT Services'),
    ('Vimbiso FinTech Hub', 'FinTech & Banking'),
    ('HealthTech Africa', 'HealthTech & Medical'),
]

JOB_TITLES = {
    'Software & IT Services': [
        'Junior Software Engineer', 'Software Engineer', 'Senior Software Engineer',
        'Lead Full-Stack Developer', 'Frontend Developer (Flutter/React)',
        'Backend Engineer (Python/Django)', 'DevOps Engineer', 'Solutions Architect'
    ],
    'FinTech & Banking': [
        'Payment Rails Engineer', 'FinTech Systems Analyst', 'Core Banking Developer',
        'Security Operations Analyst', 'Database Administrator', 'API Integration Specialist'
    ],
    'Telecommunications': [
        'Network Systems Engineer', 'Cloud Infrastructure Engineer',
        'Telecom Billing Systems Analyst', 'VoIP & Unified Comms Engineer'
    ],
    'Education & Research': [
        'Graduate Teaching Assistant', 'Lecturer / Research Fellow',
        'AI & NLP Researcher', 'Educational Systems Administrator'
    ],
    'Mining & Energy': [
        'SCADA & Automation Systems Engineer', 'Enterprise IT Support Lead',
        'ERP Systems Specialist'
    ],
    'HealthTech & Medical': [
        'Health Information Systems Analyst', 'Bioinformatics Software Developer'
    ],
}

SKILLS_POOL = [
    'Python', 'Django', 'Django REST Framework', 'Flutter', 'Dart', 'PostgreSQL',
    'MySQL', 'Docker', 'Kubernetes', 'AWS', 'Azure', 'Linux', 'Git', 'CI/CD',
    'Kafka', 'Redis', 'React', 'TypeScript', 'Node.js', 'Go', 'GraphQL',
    'Cybersecurity', 'Penetration Testing', 'Machine Learning', 'TensorFlow',
    'Data Analytics', 'Pandas', 'SQL', 'FastAPI', 'Microservices Architecture'
]

MENTORSHIP_TOPICS = [
    'FinTech Architecture & Distributed Payments',
    'Transitioning from Junior to Senior Software Engineer',
    'Building Production Cross-Platform Mobile Apps with Flutter',
    'Securing Banking APIs & SOC Operations',
    'Navigating Cloud Certifications (AWS & Azure)',
    'Postgraduate Research & Overseas Scholarship Guidance',
    'CV Review, GitHub Portfolio Optimization & Technical Mock Interviews',
    'Starting a Tech Consultancy in Zimbabwe',
]

def choose_programme():
    r = random.random()
    cumulative = 0.0
    for prog, weight in PROGRAMMES:
        cumulative += weight
        if r <= cumulative:
            return prog
    return PROGRAMMES[0][0]

def generate_skills():
    count = random.randint(4, 8)
    return ", ".join(random.sample(SKILLS_POOL, count))

def run_large_seed():
    print("=" * 60)
    print("Starting Comprehensive Database Seeding for Stones Database...")
    print("=" * 60)

    # 1. Ensure Admin Account exists
    admin, _ = User.objects.get_or_create(
        email='admin@dcs.msu.ac.zw',
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
    admin.set_password('stones123')
    admin.is_verified = True
    admin.save()
    print("[OK] Department Admin verified: admin@dcs.msu.ac.zw")

    # Keep track of existing profiles
    existing_reg_numbers = set(AlumniProfile.objects.values_list('registration_number', flat=True))
    existing_emails = set(User.objects.values_list('email', flat=True))

    new_users_to_create = 45
    print(f"Generating {new_users_to_create} additional diverse Alumni profiles...")

    created_alumni = []
    
    for i in range(1, new_users_to_create + 1):
        is_female = random.choice([True, False])
        first_name = random.choice(FIRST_NAMES_FEMALE if is_female else FIRST_NAMES_MALE)
        last_name = random.choice(LAST_NAMES)
        
        # Unique registration number
        grad_year = random.choice([2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025])
        cohort_year_prefix = str(grad_year - 4)[2:]
        random_num = random.randint(1000, 9999)
        suffix = random.choice(['A', 'B', 'C', 'X', 'Y', 'Z', 'K', 'M'])
        reg_number = f"R{cohort_year_prefix}{random_num}{suffix}"
        while reg_number in existing_reg_numbers:
            random_num = random.randint(1000, 9999)
            reg_number = f"R{cohort_year_prefix}{random_num}{suffix}"
        existing_reg_numbers.add(reg_number)

        # Unique email
        clean_first = first_name.lower().replace("'", "").replace(" ", "")
        clean_last = last_name.lower().replace("'", "").replace(" ", "")
        email = f"{clean_first}.{clean_last}{random.randint(1, 99) if f'{clean_first}.{clean_last}@alumni.msu.ac.zw' in existing_emails else ''}@alumni.msu.ac.zw"
        existing_emails.add(email)

        # 85% verified, 15% pending
        is_verified = random.random() < 0.85
        programme = choose_programme()

        user, u_created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': f"{clean_first}_{clean_last}_{random_num}",
                'first_name': first_name,
                'last_name': last_name,
                'role': User.UserRole.ALUMNI,
                'is_verified': is_verified,
            }
        )
        user.set_password('stones123')
        user.is_verified = is_verified
        user.save()

        is_mentor = is_verified and (grad_year <= 2023) and (random.random() < 0.45)
        mentorship_areas = ", ".join(random.sample(MENTORSHIP_TOPICS, random.randint(1, 3))) if is_mentor else ""

        skills = generate_skills()
        bio = f"{programme} graduate (Class of {grad_year}). Passionate about modern computing technologies, problem-solving, and African tech ecosystem development."

        profile, p_created = AlumniProfile.objects.get_or_create(
            user=user,
            defaults={
                'registration_number': reg_number,
                'graduation_year': grad_year,
                'programme': programme,
                'phone_number': f"+263 7{random.choice(['7', '1', '3'])} {random.randint(100, 999)} {random.randint(1000, 9999)}",
                'bio': bio,
                'linkedin_url': f"https://linkedin.com/in/{clean_first}-{clean_last}-{reg_number.lower()}",
                'github_url': f"https://github.com/{clean_first}{clean_last}" if random.random() < 0.7 else None,
                'skills': skills,
                'is_available_for_mentorship': is_mentor,
                'mentorship_areas': mentorship_areas,
            }
        )
        created_alumni.append(profile)

        # Populate Official Graduation Roster for verified graduates
        if is_verified or random.random() < 0.5:
            deg_class = random.choices(
                ['First Class (1.0)', 'Upper Second Class (2.1)', 'Lower Second Class (2.2)', 'Pass'],
                weights=[0.18, 0.48, 0.28, 0.06]
            )[0]
            GraduationRoster.objects.update_or_create(
                registration_number=reg_number,
                defaults={
                    'full_name': f"{first_name} {last_name}",
                    'graduation_year': grad_year,
                    'programme': programme,
                    'degree_class': deg_class,
                }
            )

        # Career history generation
        # Determine current employment status
        status_roll = random.random()
        if grad_year >= 2025 and status_roll < 0.25:
            current_status = CareerRecord.EmploymentStatus.UNEMPLOYED
        elif status_roll < 0.72:
            current_status = CareerRecord.EmploymentStatus.EMPLOYED
        elif status_roll < 0.85:
            current_status = CareerRecord.EmploymentStatus.SELF_EMPLOYED
        elif status_roll < 0.94:
            current_status = CareerRecord.EmploymentStatus.FURTHER_STUDIES
        else:
            current_status = CareerRecord.EmploymentStatus.UNEMPLOYED

        # If unemployed, optionally add an internship or nothing current
        if current_status == CareerRecord.EmploymentStatus.UNEMPLOYED:
            CareerRecord.objects.get_or_create(
                alumnus=profile,
                job_title='Graduate Seeking Opportunities',
                employer='Actively Interviewing',
                defaults={
                    'employment_status': CareerRecord.EmploymentStatus.UNEMPLOYED,
                    'industry_sector': 'Software & IT Services',
                    'start_date': date(grad_year, 11, 1),
                    'is_current': True,
                    'description': 'Actively seeking junior developer or systems administration roles.',
                    'skills_used': skills,
                }
            )
        elif current_status == CareerRecord.EmploymentStatus.FURTHER_STUDIES:
            institution = random.choice(['Midlands State University', 'University of Cape Town', 'University of Zimbabwe', 'Edinburgh University'])
            further_prog = random.choice([
                'MSc in Computer Science & Artificial Intelligence',
                'MSc in Cybersecurity & Data Governance',
                'MPhil in Information Systems',
                'MSc in Big Data Analytics'
            ])
            CareerRecord.objects.get_or_create(
                alumnus=profile,
                job_title='Postgraduate Researcher / Student',
                employer=institution,
                defaults={
                    'employment_status': CareerRecord.EmploymentStatus.FURTHER_STUDIES,
                    'industry_sector': 'Education & Research',
                    'start_date': date(grad_year, 9, 1),
                    'is_current': True,
                    'further_education_institution': institution,
                    'further_education_programme': further_prog,
                    'description': f'Full-time graduate researcher pursuing {further_prog}.',
                    'skills_used': skills,
                }
            )
        elif current_status == CareerRecord.EmploymentStatus.SELF_EMPLOYED:
            venture = random.choice([
                f"{last_name} Tech Innovations", "AfroCloud Digital", "Apex Solutions Zimbabwe",
                "KombiPay Tech", "Harare Code Foundry", "ZimAgriTech Systems"
            ])
            CareerRecord.objects.get_or_create(
                alumnus=profile,
                job_title='Founder & Technical Lead',
                employer=venture,
                defaults={
                    'employment_status': CareerRecord.EmploymentStatus.SELF_EMPLOYED,
                    'industry_sector': 'Software & IT Services',
                    'start_date': date(grad_year + 1, 1, 15),
                    'is_current': True,
                    'description': f'Founded {venture} providing bespoke software, mobile applications, and cloud migration services to SME clients.',
                    'skills_used': skills,
                }
            )
        else:
            # Employed
            company, industry = random.choice(COMPANIES)
            available_titles = JOB_TITLES.get(industry, JOB_TITLES['Software & IT Services'])
            title = random.choice(available_titles)
            
            # Start date
            start_yr = min(grad_year, 2025)
            CareerRecord.objects.get_or_create(
                alumnus=profile,
                job_title=title,
                employer=company,
                defaults={
                    'employment_status': CareerRecord.EmploymentStatus.EMPLOYED,
                    'industry_sector': industry,
                    'start_date': date(start_yr, random.randint(1, 11), 1),
                    'is_current': True,
                    'description': f'Working at {company} specializing in {industry.lower()} software development, system architecture, and maintenance.',
                    'skills_used': skills,
                }
            )

            # If graduated earlier than 2022, add a previous junior job
            if grad_year <= 2021:
                prev_comp, prev_ind = random.choice(COMPANIES)
                CareerRecord.objects.get_or_create(
                    alumnus=profile,
                    job_title='Junior Software Engineer / Intern',
                    employer=prev_comp,
                    defaults={
                        'employment_status': CareerRecord.EmploymentStatus.EMPLOYED,
                        'industry_sector': prev_ind,
                        'start_date': date(grad_year - 1, 3, 1),
                        'end_date': date(grad_year + 1, 12, 31),
                        'is_current': False,
                        'description': 'Student industrial attachment and initial post-graduate developer role.',
                        'skills_used': 'Python, SQL, HTML/CSS, Git',
                    }
                )

    print(f"[OK] Total alumni profiles now available: {AlumniProfile.objects.count()}")

    # 2. Rich Communications (Announcements, Events, Job Vacancies, Mentorship)
    print("Generating comprehensive Communications & Broadcasts...")
    all_admin = User.objects.filter(role=User.UserRole.ADMIN).first()

    now = timezone.now()
    extra_communications = [
        {
            'title': 'Econet Wireless Graduate Trainee Program 2027 (Software Engineering & Cloud)',
            'category': Communication.Category.JOB_VACANCY,
            'content': (
                "Econet Wireless Zimbabwe is recruiting ambitious DCS graduates for the 2027 Graduate Trainee Program. "
                "Rotations will include Core Network Software, Cloud Platforms (AWS & OpenStack), and FinTech Integrations. "
                "Applicants must hold an upper second class (2.1) degree or better."
            ),
            'location': 'Econet Park, Msasa, Harare',
            'application_deadline': now + timedelta(days=25),
            'external_link': 'https://econet.co.zw/careers/graduates-2027',
        },
        {
            'title': 'Liquid Intelligent Technologies: Junior Cloud Security Analyst Opening',
            'category': Communication.Category.JOB_VACANCY,
            'content': (
                "Liquid Intelligent Technologies is looking for a Junior Cloud Security Analyst to join our Regional SOC team. "
                "Requirements: Understanding of ISO 27001, SIEM monitoring, Linux system auditing, and Python scripting."
            ),
            'location': 'Liquid Telecom HQ, Newlands, Harare (Hybrid)',
            'application_deadline': now + timedelta(days=18),
            'external_link': 'https://liquidtelecom.com/careers/sec-analyst',
        },
        {
            'title': 'MSU DCS Annual Alumni Gala Dinner & Tech Exhibition 2026',
            'category': Communication.Category.EVENT,
            'content': (
                "Join faculty members, industry leaders, and fellow MSU DCS alumni for an evening of networking, dinner, "
                "and recognition of remarkable alumni achievements. Special keynotes on 'Artificial Intelligence and FinTech in SADC'."
            ),
            'event_date': now + timedelta(days=40),
            'location': 'Gweru Main Campus Great Hall & Virtual Livestream',
            'external_link': 'https://dcs.msu.ac.zw/events/gala-2026',
        },
        {
            'title': 'Workshop: High-Performance Distributed Systems with Go & Apache Kafka',
            'category': Communication.Category.EVENT,
            'content': (
                "A practical hands-on workshop led by senior alumni working at international payment gateways. "
                "Learn how to design event-driven architectures, handle transactional idempotency, and deploy microservices with Docker."
            ),
            'event_date': now + timedelta(days=14),
            'location': 'MSU Innovation Hub, Gweru & Microsoft Teams',
            'external_link': 'https://dcs.msu.ac.zw/events/distributed-systems-workshop',
        },
        {
            'title': 'DCS Department Mentorship Cohort 2026: Call for Alumni Mentors',
            'category': Communication.Category.MENTORSHIP,
            'content': (
                "The Department of Computer Science is inviting experienced alumni in industry to mentor final-year students "
                "and fresh graduates. Time commitment is approximately 2 hours per month for 4 months."
            ),
            'application_deadline': now + timedelta(days=12),
            'location': 'Virtual Platform (MSU Alumni Portal)',
            'external_link': 'https://dcs.msu.ac.zw/mentorship/cohort-2026',
        },
        {
            'title': 'Call for Curriculum Review Inputs: Industry Relevance for 2027-2031',
            'category': Communication.Category.ANNOUNCEMENT,
            'content': (
                "The DCS Department Advisory Board is conducting our decennial curriculum review. "
                "We invite alumni feedback on trending competencies (e.g., Rust, Large Language Models, Cloud Native DevOps) "
                "to ensure current undergraduates meet real-world industry demands."
            ),
            'external_link': 'https://dcs.msu.ac.zw/feedback/curriculum-review',
        },
        {
            'title': 'CBZ Bank FinTech Hackathon: USD $15,000 Prize Pool',
            'category': Communication.Category.EVENT,
            'content': (
                "CBZ Bank is partnering with MSU DCS to host a 48-hour digital banking hackathon. "
                "Build innovative lending, remittances, or SME financial management apps using open banking APIs. "
                "Alumni teams are warmly welcomed to participate."
            ),
            'event_date': now + timedelta(days=30),
            'location': 'Harare Rainbow Towers & Hybrid',
            'external_link': 'https://cbz.co.zw/hackathon-2026',
        },
    ]

    created_comms = []
    for item in extra_communications:
        comm, _ = Communication.objects.get_or_create(
            title=item['title'],
            defaults={
                'content': item['content'],
                'category': item['category'],
                'event_date': item.get('event_date'),
                'location': item.get('location'),
                'application_deadline': item.get('application_deadline'),
                'external_link': item.get('external_link'),
                'created_by': all_admin,
            }
        )
        created_comms.append(comm)

    all_communications = list(Communication.objects.all())
    all_alumni = list(AlumniProfile.objects.filter(user__is_verified=True))

    print(f"[OK] Total communications available: {len(all_communications)}")

    # 3. Generate RSVPs for communications
    print("Generating active Alumni RSVPs & job applications...")
    rsvp_count = 0
    for comm in all_communications:
        # Sample 5 to 15 alumni to RSVP or apply
        selected_alumni = random.sample(all_alumni, min(random.randint(5, 14), len(all_alumni)))
        for al in selected_alumni:
            if comm.category in (Communication.Category.EVENT, Communication.Category.MENTORSHIP):
                resp = random.choice([RSVP.ResponseType.ATTENDING, RSVP.ResponseType.INTERESTED])
            else:
                resp = random.choice([RSVP.ResponseType.APPLIED, RSVP.ResponseType.INTERESTED])
            
            _, created = RSVP.objects.get_or_create(
                communication=comm,
                alumnus=al,
                defaults={'response_type': resp, 'notes': 'Excited to participate!'}
            )
            if created:
                rsvp_count += 1

    print(f"[OK] Created {rsvp_count} new engagement RSVPs & Applications. Total: {RSVP.objects.count()}")

    # 4. Generate Mentorship Connections
    print("Generating realistic Mentorship Requests...")
    mentors = list(AlumniProfile.objects.filter(is_available_for_mentorship=True))
    mentees = list(AlumniProfile.objects.filter(graduation_year__gte=2023))

    mentorship_sample_topics = [
        ("FinTech Backend Transition", "Hi! I am currently working as a junior developer and would love guidance on transitioning into high-scale FinTech systems."),
        ("Cloud Architecture & AWS Prep", "Hello, I am preparing for the AWS Solutions Architect Associate exam and would appreciate advice on hands-on project portfolio building."),
        ("Cybersecurity SOC Roadmap", "Greetings, I recently completed my degree and am seeking practical tips on getting into enterprise penetration testing and banking security."),
        ("Starting Tech Startup in Zimbabwe", "Good day, looking for insights on common regulatory hurdles and customer acquisition when launching a local SaaS platform."),
        ("Postgraduate Application Review", "Hi mentor, could you review my statement of purpose for MSc Data Science applications?"),
    ]

    mentorship_count = 0
    if mentors and mentees:
        for _ in range(12):
            mentor = random.choice(mentors)
            mentee = random.choice(mentees)
            if mentor == mentee:
                continue

            topic, msg = random.choice(mentorship_sample_topics)
            status = random.choice([
                MentorshipRequest.Status.ACCEPTED,
                MentorshipRequest.Status.ACCEPTED,
                MentorshipRequest.Status.PENDING,
                MentorshipRequest.Status.COMPLETED
            ])
            resp = "Glad to connect! Let us arrange a 30-minute Google Meet call." if status != MentorshipRequest.Status.PENDING else None

            _, created = MentorshipRequest.objects.get_or_create(
                mentor=mentor,
                mentee=mentee,
                topic=topic,
                defaults={
                    'message': msg,
                    'status': status,
                    'response_message': resp,
                }
            )
            if created:
                mentorship_count += 1

    print(f"[OK] Created {mentorship_count} new Mentorship connections. Total: {MentorshipRequest.objects.count()}")

    # 5. Print Summary
    print("\n" + "=" * 60)
    print("DATABASE EXPANSION COMPLETE")
    print("=" * 60)
    print(f"  - Total Users:                {User.objects.count()}")
    print(f"  - Total Alumni Profiles:      {AlumniProfile.objects.count()}")
    print(f"  - Verified Alumni:            {AlumniProfile.objects.filter(user__is_verified=True).count()}")
    print(f"  - Pending Verifications:      {AlumniProfile.objects.filter(user__is_verified=False).count()}")
    print(f"  - Career Records:             {CareerRecord.objects.count()}")
    print(f"  - Active Mentors:             {AlumniProfile.objects.filter(is_available_for_mentorship=True).count()}")
    print(f"  - Mentorship Requests:        {MentorshipRequest.objects.count()}")
    print(f"  - Official Graduation Roster: {GraduationRoster.objects.count()}")
    print(f"  - Broadcast Communications:   {Communication.objects.count()}")
    print(f"  - RSVPs & Applications:       {RSVP.objects.count()}")
    print("=" * 60)

if __name__ == '__main__':
    run_large_seed()

