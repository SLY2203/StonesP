class AppConstants {
  static const String appName = 'MSU DCS Alumni';
  static const String departmentName = 'Department of Computer Science';
  static const String universityName = 'Midlands State University';

  // API Base URLs
  // For standard Android Emulator: http://10.0.2.2:8000/api
  // For Windows / Web / iOS simulator: http://127.0.0.1:8000/api
  // For Production on Render: https://msu-dcs-alumni-backend.onrender.com/api
  static const String defaultApiUrl = 'http://10.0.2.2:8000/api';
  static const String localApiUrl = 'http://127.0.0.1:8000/api';
  static const String productionApiUrl = 'https://msu-dcs-alumni-backend.onrender.com/api';

  // Token storage keys
  static const String keyAccessToken = 'msu_access_token';
  static const String keyRefreshToken = 'msu_refresh_token';
  static const String keyUserData = 'msu_user_data';

  // Programmes offered by DCS
  static const List<String> dcsProgrammes = [
    'BSc Hons Computer Science',
    'BSc Hons Information Systems',
    'BSc Hons Information Technology',
    'BSc Hons Software Engineering',
    'BSc Hons Cybersecurity & Digital Forensics',
    'MSc Information Technology',
    'MPhil / PhD Computer Science',
    'Other DCS Programme',
  ];

  // Industry sectors
  static const List<String> industrySectors = [
    'Software & IT Services',
    'FinTech & Banking',
    'Telecommunications',
    'E-Commerce & Retail',
    'Education & Research',
    'Mining & Energy',
    'Public Sector & Gov',
    'HealthTech & Medical',
    'Media & Creative',
    'Other Industry',
  ];

  // Employment statuses
  static const Map<String, String> employmentStatusMap = {
    'EMPLOYED': 'Employed (Full-time / Part-time)',
    'SELF_EMPLOYED': 'Self-Employed / Founder',
    'FURTHER_STUDIES': 'Pursuing Further Studies',
    'UNEMPLOYED': 'Seeking Employment',
  };
}
