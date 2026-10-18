class CommunicationCounts {
  final int totalResponses;
  final int attending;
  final int interested;
  final int applied;

  CommunicationCounts({
    required this.totalResponses,
    required this.attending,
    required this.interested,
    required this.applied,
  });

  factory CommunicationCounts.fromJson(Map<String, dynamic> json) {
    return CommunicationCounts(
      totalResponses: json['total_responses'] ?? 0,
      attending: json['attending'] ?? 0,
      interested: json['interested'] ?? 0,
      applied: json['applied'] ?? 0,
    );
  }
}

class UserRSVPInfo {
  final String responseType;
  final String? createdAt;

  UserRSVPInfo({
    required this.responseType,
    this.createdAt,
  });

  factory UserRSVPInfo.fromJson(Map<String, dynamic> json) {
    return UserRSVPInfo(
      responseType: json['response_type'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class CommunicationModel {
  final int id;
  final String title;
  final String content;
  final String category; // 'EVENT', 'JOB_VACANCY', 'MENTORSHIP', 'ANNOUNCEMENT'
  final String categoryDisplay;
  final int? targetGraduationYear;
  final String? targetProgramme;
  final String? eventDate;
  final String? location;
  final String? applicationDeadline;
  final String? externalLink;
  final String? authorName;
  final CommunicationCounts counts;
  final UserRSVPInfo? myRsvp;
  final String createdAt;

  CommunicationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.categoryDisplay,
    this.targetGraduationYear,
    this.targetProgramme,
    this.eventDate,
    this.location,
    this.applicationDeadline,
    this.externalLink,
    this.authorName,
    required this.counts,
    this.myRsvp,
    required this.createdAt,
  });

  bool get isEvent => category == 'EVENT';
  bool get isJob => category == 'JOB_VACANCY';
  bool get isMentorship => category == 'MENTORSHIP';
  bool get isAnnouncement => category == 'ANNOUNCEMENT';

  factory CommunicationModel.fromJson(Map<String, dynamic> json) {
    return CommunicationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'ANNOUNCEMENT',
      categoryDisplay: json['category_display'] ?? 'Announcement',
      targetGraduationYear: json['target_graduation_year'],
      targetProgramme: json['target_programme'],
      eventDate: json['event_date'],
      location: json['location'],
      applicationDeadline: json['application_deadline'],
      externalLink: json['external_link'],
      authorName: json['author_name'] ?? 'DCS Department',
      counts: json['counts'] != null
          ? CommunicationCounts.fromJson(json['counts'])
          : CommunicationCounts(totalResponses: 0, attending: 0, interested: 0, applied: 0),
      myRsvp: json['my_rsvp'] != null ? UserRSVPInfo.fromJson(json['my_rsvp']) : null,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FeedbackItemModel {
  final int id;
  final int communicationId;
  final int alumnusId;
  final String alumnusName;
  final String alumnusReg;
  final String? alumnusEmail;
  final String? alumnusProgramme;
  final int? alumnusGradYear;
  final String communicationTitle;
  final String communicationCategory;
  final String communicationCategoryDisplay;
  final String responseType;
  final String notes;
  final String createdAt;

  FeedbackItemModel({
    required this.id,
    required this.communicationId,
    required this.alumnusId,
    required this.alumnusName,
    required this.alumnusReg,
    this.alumnusEmail,
    this.alumnusProgramme,
    this.alumnusGradYear,
    required this.communicationTitle,
    required this.communicationCategory,
    required this.communicationCategoryDisplay,
    required this.responseType,
    required this.notes,
    required this.createdAt,
  });

  factory FeedbackItemModel.fromJson(Map<String, dynamic> json) {
    return FeedbackItemModel(
      id: json['id'] ?? 0,
      communicationId: json['communication'] ?? 0,
      alumnusId: json['alumnus'] ?? 0,
      alumnusName: json['alumnus_name'] ?? 'Alumnus',
      alumnusReg: json['alumnus_reg'] ?? '',
      alumnusEmail: json['alumnus_email'],
      alumnusProgramme: json['alumnus_programme'],
      alumnusGradYear: json['alumnus_grad_year'],
      communicationTitle: json['communication_title'] ?? '',
      communicationCategory: json['communication_category'] ?? '',
      communicationCategoryDisplay: json['communication_category_display'] ?? '',
      responseType: json['response_type'] ?? 'INTERESTED',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SystemSurveyModel {
  final int id;
  final int? userId;
  final String userName;
  final String? userEmail;
  final String userRole;
  final int overallRating;
  final int easeOfUseRating;
  final int featuresRating;
  final int performanceRating;
  final String systemAspect;
  final String aspectDisplay;
  final String whatWorksWell;
  final String improvementsNeeded;
  final bool wouldRecommend;
  final String createdAt;

  SystemSurveyModel({
    required this.id,
    this.userId,
    required this.userName,
    this.userEmail,
    required this.userRole,
    required this.overallRating,
    required this.easeOfUseRating,
    required this.featuresRating,
    required this.performanceRating,
    required this.systemAspect,
    required this.aspectDisplay,
    required this.whatWorksWell,
    required this.improvementsNeeded,
    required this.wouldRecommend,
    required this.createdAt,
  });

  factory SystemSurveyModel.fromJson(Map<String, dynamic> json) {
    return SystemSurveyModel(
      id: json['id'] ?? 0,
      userId: json['user'],
      userName: json['user_name'] ?? 'User',
      userEmail: json['user_email'],
      userRole: json['user_role'] ?? 'ALUMNI',
      overallRating: json['overall_rating'] ?? 5,
      easeOfUseRating: json['ease_of_use_rating'] ?? 5,
      featuresRating: json['features_rating'] ?? 5,
      performanceRating: json['performance_rating'] ?? 5,
      systemAspect: json['system_aspect'] ?? 'GENERAL',
      aspectDisplay: json['aspect_display'] ?? 'General System Performance',
      whatWorksWell: json['what_works_well'] ?? '',
      improvementsNeeded: json['improvements_needed'] ?? '',
      wouldRecommend: json['would_recommend'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class DepartmentFeedbackModel {
  final int id;
  final int? alumnusId;
  final String alumnusName;
  final String alumnusReg;
  final String? alumnusEmail;
  final String subject;
  final String category;
  final String categoryDisplay;
  final String message;
  final bool isReviewed;
  final String createdAt;

  DepartmentFeedbackModel({
    required this.id,
    this.alumnusId,
    required this.alumnusName,
    required this.alumnusReg,
    this.alumnusEmail,
    required this.subject,
    required this.category,
    required this.categoryDisplay,
    required this.message,
    required this.isReviewed,
    required this.createdAt,
  });

  factory DepartmentFeedbackModel.fromJson(Map<String, dynamic> json) {
    return DepartmentFeedbackModel(
      id: json['id'] ?? 0,
      alumnusId: json['alumnus'],
      alumnusName: json['alumnus_name'] ?? 'Alumnus',
      alumnusReg: json['alumnus_reg'] ?? '',
      alumnusEmail: json['alumnus_email'],
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'GENERAL',
      categoryDisplay: json['category_display'] ?? 'General',
      message: json['message'] ?? '',
      isReviewed: json['is_reviewed'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

