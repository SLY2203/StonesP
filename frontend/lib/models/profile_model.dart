import 'user_model.dart';
import 'career_model.dart';

class CurrentJobInfo {
  final int? id;
  final String? jobTitle;
  final String? employer;
  final String? employmentStatus;
  final String? industrySector;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final String? skillsUsed;
  final String? createdAt;
  final String? updatedAt;

  CurrentJobInfo({
    this.id,
    this.jobTitle,
    this.employer,
    this.employmentStatus,
    this.industrySector,
    this.startDate,
    this.endDate,
    this.isCurrent = true,
    this.description,
    this.skillsUsed,
    this.createdAt,
    this.updatedAt,
  });

  factory CurrentJobInfo.fromJson(Map<String, dynamic> json) {
    return CurrentJobInfo(
      id: json['id'],
      jobTitle: json['job_title'],
      employer: json['employer'],
      employmentStatus: json['employment_status'],
      industrySector: json['industry_sector'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isCurrent: json['is_current'] ?? true,
      description: json['description'],
      skillsUsed: json['skills_used'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class AlumniProfileModel {
  final int id;
  final UserModel? user;
  final String fullName;
  final String email;
  final bool isVerified;
  final String registrationNumber;
  final int graduationYear;
  final String programme;
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? profilePhoto;
  final CurrentJobInfo? currentJob;
  final List<CareerRecordModel> careerRecords;
  final String? skills;
  final List<String> skillsList;
  final bool isAvailableForMentorship;
  final String? mentorshipAreas;
  final String? createdAt;
  final String? updatedAt;

  AlumniProfileModel({
    required this.id,
    this.user,
    required this.fullName,
    required this.email,
    required this.isVerified,
    required this.registrationNumber,
    required this.graduationYear,
    required this.programme,
    this.phoneNumber,
    this.address,
    this.bio,
    this.linkedinUrl,
    this.githubUrl,
    this.profilePhoto,
    this.currentJob,
    this.careerRecords = const [],
    this.skills,
    this.skillsList = const [],
    this.isAvailableForMentorship = false,
    this.mentorshipAreas,
    this.createdAt,
    this.updatedAt,
  });

  factory AlumniProfileModel.fromJson(Map<String, dynamic> json) {
    final rawSkillsList = json['skills_list'];
    List<String> parsedSkills = [];
    if (rawSkillsList is List) {
      parsedSkills = rawSkillsList.map((e) => e.toString()).toList();
    } else if (json['skills'] != null && json['skills'].toString().isNotEmpty) {
      parsedSkills = json['skills'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    final rawCareers = json['career_records'];
    List<CareerRecordModel> parsedCareers = [];
    if (rawCareers is List) {
      parsedCareers = rawCareers.map((c) => CareerRecordModel.fromJson(c)).toList();
    }

    return AlumniProfileModel(
      id: json['id'] ?? 0,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      isVerified: json['is_verified'] ?? false,
      registrationNumber: json['registration_number'] ?? '',
      graduationYear: json['graduation_year'] ?? 2024,
      programme: json['programme'] ?? 'BSc Hons Computer Science',
      phoneNumber: json['phone_number'],
      address: json['address'],
      bio: json['bio'],
      linkedinUrl: json['linkedin_url'],
      githubUrl: json['github_url'],
      profilePhoto: json['profile_photo'],
      currentJob: json['current_job'] != null ? CurrentJobInfo.fromJson(json['current_job']) : null,
      careerRecords: parsedCareers,
      skills: json['skills'],
      skillsList: parsedSkills,
      isAvailableForMentorship: json['is_available_for_mentorship'] ?? false,
      mentorshipAreas: json['mentorship_areas'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class AlumniDirectoryItemModel {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final bool isVerified;
  final String registrationNumber;
  final int graduationYear;
  final String programme;
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? currentJobTitle;
  final String? currentEmployer;
  final String? currentStatus;
  final String? currentJobStartDate;
  final String? skills;
  final List<String> skillsList;
  final bool isAvailableForMentorship;
  final String? createdAt;
  final String? updatedAt;

  AlumniDirectoryItemModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.isVerified,
    required this.registrationNumber,
    required this.graduationYear,
    required this.programme,
    this.phoneNumber,
    this.address,
    this.bio,
    this.currentJobTitle,
    this.currentEmployer,
    this.currentStatus,
    this.currentJobStartDate,
    this.skills,
    this.skillsList = const [],
    this.isAvailableForMentorship = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AlumniDirectoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawSkillsList = json['skills_list'];
    List<String> parsedSkills = [];
    if (rawSkillsList is List) {
      parsedSkills = rawSkillsList.map((e) => e.toString()).toList();
    } else if (json['skills'] != null && json['skills'].toString().isNotEmpty) {
      parsedSkills = json['skills'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return AlumniDirectoryItemModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      isVerified: json['is_verified'] ?? false,
      registrationNumber: json['registration_number'] ?? '',
      graduationYear: json['graduation_year'] ?? 2024,
      programme: json['programme'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      bio: json['bio'],
      currentJobTitle: json['current_job_title'],
      currentEmployer: json['current_employer'],
      currentStatus: json['current_status'],
      currentJobStartDate: json['current_job_start_date'],
      skills: json['skills'],
      skillsList: parsedSkills,
      isAvailableForMentorship: json['is_available_for_mentorship'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
