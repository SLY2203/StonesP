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
