import 'user_model.dart';

class CurrentJobInfo {
  final String? jobTitle;
  final String? employer;
  final String? employmentStatus;
  final String? industrySector;

  CurrentJobInfo({
    this.jobTitle,
    this.employer,
    this.employmentStatus,
    this.industrySector,
  });

  factory CurrentJobInfo.fromJson(Map<String, dynamic> json) {
    return CurrentJobInfo(
      jobTitle: json['job_title'],
      employer: json['employer'],
      employmentStatus: json['employment_status'],
      industrySector: json['industry_sector'],
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
  });

  factory AlumniProfileModel.fromJson(Map<String, dynamic> json) {
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
  final String? currentJobTitle;
  final String? currentEmployer;
  final String? currentStatus;

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
    this.currentJobTitle,
    this.currentEmployer,
    this.currentStatus,
  });

  factory AlumniDirectoryItemModel.fromJson(Map<String, dynamic> json) {
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
      currentJobTitle: json['current_job_title'],
      currentEmployer: json['current_employer'],
      currentStatus: json['current_status'],
    );
  }
}
