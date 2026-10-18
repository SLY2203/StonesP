class MentorModel {
  final int id;
  final String fullName;
  final String email;
  final String programme;
  final int graduationYear;
  final String? currentJobTitle;
  final String? currentEmployer;
  final String? skills;
  final List<String> skillsList;
  final String? mentorshipAreas;
  final String? linkedinUrl;
  final String? bio;

  MentorModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.programme,
    required this.graduationYear,
    this.currentJobTitle,
    this.currentEmployer,
    this.skills,
    this.skillsList = const [],
    this.mentorshipAreas,
    this.linkedinUrl,
    this.bio,
  });

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills_list'];
    List<String> parsedSkills = [];
    if (rawSkills is List) {
      parsedSkills = rawSkills.map((e) => e.toString()).toList();
    } else if (json['skills'] != null && json['skills'].toString().isNotEmpty) {
      parsedSkills = json['skills'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return MentorModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      programme: json['programme'] ?? '',
      graduationYear: json['graduation_year'] ?? 2024,
      currentJobTitle: json['current_job_title'],
      currentEmployer: json['current_employer'],
      skills: json['skills'],
      skillsList: parsedSkills,
      mentorshipAreas: json['mentorship_areas'],
      linkedinUrl: json['linkedin_url'],
      bio: json['bio'],
    );
  }
}

class MentorshipRequestModel {
  final int id;
  final int mentorId;
  final String mentorName;
  final String mentorEmail;
  final String mentorJob;
  final int menteeId;
  final String menteeName;
  final String menteeEmail;
  final String menteeProgramme;
  final int menteeGradYear;
  final String topic;
  final String message;
  final String status;
  final String? responseMessage;
  final String createdAt;

  MentorshipRequestModel({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.mentorEmail,
    required this.mentorJob,
    required this.menteeId,
    required this.menteeName,
    required this.menteeEmail,
    required this.menteeProgramme,
    required this.menteeGradYear,
    required this.topic,
    required this.message,
    required this.status,
    this.responseMessage,
    required this.createdAt,
  });

  factory MentorshipRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorshipRequestModel(
      id: json['id'] ?? 0,
      mentorId: json['mentor'] ?? 0,
      mentorName: json['mentor_name'] ?? '',
      mentorEmail: json['mentor_email'] ?? '',
      mentorJob: json['mentor_job'] ?? 'Alumnus',
      menteeId: json['mentee'] ?? 0,
      menteeName: json['mentee_name'] ?? '',
      menteeEmail: json['mentee_email'] ?? '',
      menteeProgramme: json['mentee_programme'] ?? '',
      menteeGradYear: json['mentee_grad_year'] ?? 2024,
      topic: json['topic'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'PENDING',
      responseMessage: json['response_message'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
