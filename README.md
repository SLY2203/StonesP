# MSU DCS Alumni Tracking & Career Progression System

A full-stack mobile and API platform built for the **Department of Computer Science (DCS)** at **Midlands State University (MSU)**. The system centralizes alumni records, tracks graduate career progression, facilitates engagement (events, jobs, mentorship, announcements), enforces role-based verification, and generates statistical analytics and PDF/CSV reports.

---

## 🚀 Technology Stack

- **Mobile Frontend:** Flutter (Dart 3)
- **State Management:** Provider
- **Backend:** Django 5 & Django REST Framework (DRF)
- **Authentication:** SimpleJWT (JSON Web Tokens) with Role-Based Access Control (RBAC)
- **Database:** MySQL (`PyMySQL` connector) with automatic fallback to SQLite for zero-setup local development
- **Document & Report Generation:** ReportLab (for PDF exports) and standard CSV streaming
- **Push Notifications:** Firebase Cloud Messaging (FCM) broadcast handler
- **Supported IDEs:** Android Studio (Flutter) & VS Code (Django)

---

## 🏛️ System User Roles

1. **Administrator (Department Staff)**
   - View high-level KPI dashboard (% employed, total registered, active posts).
   - Search and filter the entire alumni directory.
   - Review pending alumni self-registrations and 1-tap **Verify & Activate** or **Revoke** accounts.
   - Compose and dispatch targeted broadcasts (announcements, reunions, job vacancies, mentorship).
   - Filter and export official departmental reports as **PDF** and **CSV**.
2. **Alumni (DCS Graduates)**
   - Self-registration with MSU student registration number, graduation year, and degree qualification.
   - View personalized feed of department communications, filterable by category.
   - RSVP and express interest in events, mentorship calls, and job vacancies.
   - Manage career milestones and historical timeline (current role, past positions, further education).
   - Manage personal, contact, and social profile links (LinkedIn, GitHub, phone, bio).

---

## 📁 Repository Structure

```
StonesP/
├── backend/                        # Django REST Framework API
│   ├── manage.py                   # Django CLI
│   ├── requirements.txt            # Python dependencies
│   ├── seed_data.py                # Database population script
│   ├── .env.example                # Environment template
│   ├── .env                        # Active local configuration
│   ├── dcs_alumni_project/         # Settings, JWT, CORS, URLs
│   │   ├── settings.py
│   │   └── urls.py
│   ├── accounts/                   # Module 1 & 4: RBAC, Custom User, JWT Auth
│   ├── alumni/                     # Module 1: AlumniProfile & Directory
│   ├── careers/                    # Module 2: CareerRecord & Progression Timeline
│   ├── communications/             # Module 3: Broadcasts, Events, Jobs & RSVPs
│   ├── reports/                    # Module 5: Analytics & PDF/CSV Export Services
│   └── tests/                      # Automated API test suite
│
└── frontend/                       # Flutter Mobile Application
    ├── pubspec.yaml                # Flutter dependencies
    ├── analysis_options.yaml       # Dart analyzer rules
    ├── lib/
    │   ├── main.dart               # Entrypoint & MultiProvider setup
    │   ├── constants/              # AppColors (MSU Navy/Gold), AppTheme, AppConstants
    │   ├── models/                 # User, Profile, Career, Communication, Report models
    │   ├── services/               # ApiClient, AuthService, AlumniService, etc.
    │   ├── providers/              # State management providers
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── auth/               # Login, Register, Pending Approval
    │   │   ├── alumni/             # Feed, Profile View/Edit, Career Timeline & Forms
    │   │   └── admin/              # Dashboard, Directory, Broadcast Composer, Reports
    │   └── widgets/                # StatCard, CommunicationCard, TimelineTile, Buttons
    └── test/
        └── widget_test.dart
```

---

## 🔑 Demo Credentials (Pre-Seeded)

The system comes pre-populated with realistic department data:

| Role | Email | Password | Status | Details |
|---|---|---|---|---|
| **Department Admin** | `admin@dcs.msu.ac.zw` | `Admin@MSU2026` | Verified | Full Staff Privileges & Reporting |
| **Verified Alumnus** | `tinashe.moyo@alumni.msu.ac.zw` | `Alumni@MSU2026` | Verified | Senior SWE at EcoCash, 2021 Grad |
| **Verified Alumnus** | `nyasha.chidambazina@alumni.msu.ac.zw` | `Alumni@MSU2026` | Verified | Cloud Architect at Liquid Telecom |
| **Verified Alumnus** | `simbarashe.dube@alumni.msu.ac.zw` | `Alumni@MSU2026` | Verified | Postgrad AI Researcher at MSU |
| **Pending Alumnus** | `blessing.munemo@alumni.msu.ac.zw` | `Alumni@MSU2026` | **Pending** | *Use to test Admin Verification flow* |

---

## ⚙️ Quick Start: Backend Setup (Django)

### 1. Prerequisites
- Python 3.10+ (Python 3.14 supported)
- MySQL Server (optional; defaults to SQLite if MySQL is not running)

### 2. Run Database Migrations & Seed Data
```bash
# Navigate to workspace
cd backend

# Activate virtual environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# (Optional) To connect to MySQL:
# Edit backend/.env and set:
# DB_ENGINE=mysql
# DB_NAME=msu_dcs_alumni_db
# DB_USER=root
# DB_PASSWORD=your_mysql_password

# Apply database migrations
python manage.py migrate

# Seed database with sample alumni, careers, and communications
python seed_data.py

# Run API test suite
python manage.py test tests
```

### 3. Start the Backend Server
```bash
python manage.py runserver 0.0.0.0:8000
```
- API Base URL: `http://127.0.0.1:8000/api/`
- Django Admin Panel: `http://127.0.0.1:8000/admin/`

---

## 📱 Quick Start: Mobile Setup (Flutter)

### 1. Open in IDE
- **Android Studio**: Open `StonesP/frontend` folder as a Flutter project.
- **VS Code**: Open `StonesP/frontend` folder.

### 2. Install Dependencies & Run
```bash
cd frontend
flutter pub get
flutter run
```

### 3. Backend Host Configuration
- **Android Emulator**: Uses `http://10.0.2.2:8000/api` (default).
- **Physical Device**: Connect phone to the same Wi-Fi network and set base URL to your computer's local IP (e.g. `http://192.168.1.50:8000/api`).
- **Windows / Web**: Tap the **Settings icon (⚙️)** on the Login screen to switch to `http://127.0.0.1:8000/api` with 1 tap.

---

## 📡 REST API Reference

### 1. Authentication & Accounts (`/api/auth/`)
- `POST /api/auth/login/` – Authenticate with email/password; returns JWT access + refresh tokens and user role.
- `POST /api/auth/register/` – Alumni self-registration; creates unverified account.
- `POST /api/auth/token/refresh/` – Refresh expired JWT access token.
- `GET /api/auth/me/` – Retrieve current authenticated user details.
- `POST /api/auth/alumni/<user_id>/verify/` – **[Admin Only]** Verify/approve or revoke an alumnus account.

### 2. Alumni Profile & Directory (`/api/alumni/`)
- `GET /api/alumni/profile/me/` – Retrieve current alumnus profile.
- `PATCH /api/alumni/profile/me/` – Update personal, contact, and social information.
- `GET /api/alumni/directory/` – **[Admin Only]** Search and filter all registered alumni (`?q=`, `?graduation_year=`, `?programme=`, `?is_verified=`).
- `GET /api/alumni/directory/<id>/` – **[Admin Only]** Full details of a specific alumnus.

### 3. Career Milestones & Tracking (`/api/careers/`)
- `GET /api/careers/me/` – List authenticated alumnus career progression timeline.
- `POST /api/careers/me/` – Add new career position (auto-manages current role toggle).
- `PUT /api/careers/me/<id>/` – Update career record.
- `DELETE /api/careers/me/<id>/` – Remove career milestone.
- `GET /api/careers/stats/` – Summary statistics of employment status and top hiring industries.

### 4. Communications & Engagement (`/api/communications/`)
- `GET /api/communications/` – Feed of announcements, events, jobs, mentorship (`?category=`, `?target_year=`).
- `POST /api/communications/` – **[Admin Only]** Publish a new broadcast and dispatch FCM push notifications.
- `POST /api/communications/<id>/rsvp/` – Submit or change RSVP (`ATTENDING`, `INTERESTED`, `APPLIED`).
- `DELETE /api/communications/<id>/rsvp/` – Cancel RSVP.
- `GET /api/communications/<id>/rsvps/` – **[Admin Only]** View list of alumni who responded.

### 5. Reporting & Exports (`/api/reports/`)
- `GET /api/reports/summary/` – **[Admin Only]** Summary metrics for dashboard charts.
- `GET /api/reports/export/csv/` – **[Admin Only]** Download cohort data as CSV file.
- `GET /api/reports/export/pdf/` – **[Admin Only]** Download official formatted PDF departmental report.

---

## 🔔 Firebase Cloud Messaging (Push Notifications)

The system includes a dedicated `FCMNotificationService` in `backend/communications/fcm_service.py`.
- When an administrator publishes an announcement, event, or job posting, push notifications are dispatched to the `alumni_broadcasts` topic.
- To connect production Firebase credentials, simply place your Firebase service account JSON file in the backend directory and set `FCM_SERVER_KEY` in `backend/.env`.
