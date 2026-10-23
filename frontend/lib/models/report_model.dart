class ReportMetrics {
  final int totalAlumni;
  final int verifiedAlumni;
  final int pendingVerification;
  final int trackedEmploymentCount;
  final int employedCount;
  final int selfEmployedCount;
  final int furtherStudiesCount;
  final int unemployedCount;
  final double overallEmploymentRate;
  final int totalBroadcasts;
  final int totalRsvps;
  final int totalFeedbacks;

  ReportMetrics({
    required this.totalAlumni,
    required this.verifiedAlumni,
    required this.pendingVerification,
    required this.trackedEmploymentCount,
    required this.employedCount,
    required this.selfEmployedCount,
    required this.furtherStudiesCount,
    required this.unemployedCount,
    required this.overallEmploymentRate,
    required this.totalBroadcasts,
    required this.totalRsvps,
    this.totalFeedbacks = 0,
  });

  factory ReportMetrics.fromJson(Map<String, dynamic> json) {
    return ReportMetrics(
      totalAlumni: json['total_alumni'] ?? 0,
      verifiedAlumni: json['verified_alumni'] ?? 0,
      pendingVerification: json['pending_verification'] ?? 0,
      trackedEmploymentCount: json['tracked_employment_count'] ?? 0,
      employedCount: json['employed_count'] ?? 0,
      selfEmployedCount: json['self_employed_count'] ?? 0,
      furtherStudiesCount: json['further_studies_count'] ?? 0,
      unemployedCount: json['unemployed_count'] ?? 0,
      overallEmploymentRate: (json['overall_employment_rate'] as num?)?.toDouble() ?? 0.0,
      totalBroadcasts: json['total_broadcasts'] ?? 0,
      totalRsvps: json['total_rsvps'] ?? 0,
      totalFeedbacks: json['total_feedbacks'] ?? 0,
    );
  }
}

class CountItem {
  final String label;
  final int count;

  CountItem({required this.label, required this.count});
}

class RecentAlumnusRegistrationModel {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String registrationNumber;
  final int graduationYear;
  final String programme;
  final String? phoneNumber;
  final String? address;
  final bool isVerified;
  final String? createdAt;
  final String? updatedAt;
  final String? currentJobTitle;
  final String? currentEmployer;
  final String? currentStatus;

  RecentAlumnusRegistrationModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.registrationNumber,
    required this.graduationYear,
    required this.programme,
    this.phoneNumber,
    this.address,
    required this.isVerified,
    this.createdAt,
    this.updatedAt,
    this.currentJobTitle,
    this.currentEmployer,
    this.currentStatus,
  });

  factory RecentAlumnusRegistrationModel.fromJson(Map<String, dynamic> json) {
    return RecentAlumnusRegistrationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      graduationYear: json['graduation_year'] ?? 2024,
      programme: json['programme'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      currentJobTitle: json['current_job_title'],
      currentEmployer: json['current_employer'],
      currentStatus: json['current_status'],
    );
  }
}

class RecentCareerUpdateModel {
  final int id;
  final int alumnusId;
  final String alumnusName;
  final String registrationNumber;
  final String jobTitle;
  final String employer;
  final String employmentStatus;
  final String statusDisplay;
  final String industrySector;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final String? skillsUsed;
  final String? createdAt;
  final String? updatedAt;

  RecentCareerUpdateModel({
    required this.id,
    required this.alumnusId,
    required this.alumnusName,
    required this.registrationNumber,
    required this.jobTitle,
    required this.employer,
    required this.employmentStatus,
    required this.statusDisplay,
    required this.industrySector,
    this.startDate,
    this.endDate,
    required this.isCurrent,
    this.description,
    this.skillsUsed,
    this.createdAt,
    this.updatedAt,
  });

  factory RecentCareerUpdateModel.fromJson(Map<String, dynamic> json) {
    return RecentCareerUpdateModel(
      id: json['id'] ?? 0,
      alumnusId: json['alumnus_id'] ?? 0,
      alumnusName: json['alumnus_name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      jobTitle: json['job_title'] ?? '',
      employer: json['employer'] ?? '',
      employmentStatus: json['employment_status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      industrySector: json['industry_sector'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      isCurrent: json['is_current'] ?? false,
      description: json['description'],
      skillsUsed: json['skills_used'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class RecentFeedbackItemModel {
  final int id;
  final int alumnusId;
  final String alumnusName;
  final String alumnusReg;
  final int communicationId;
  final String communicationTitle;
  final String communicationCategory;
  final String responseType;
  final String notes;
  final String? createdAt;

  RecentFeedbackItemModel({
    required this.id,
    required this.alumnusId,
    required this.alumnusName,
    required this.alumnusReg,
    required this.communicationId,
    required this.communicationTitle,
    required this.communicationCategory,
    required this.responseType,
    required this.notes,
    this.createdAt,
  });

  factory RecentFeedbackItemModel.fromJson(Map<String, dynamic> json) {
    return RecentFeedbackItemModel(
      id: json['id'] ?? 0,
      alumnusId: json['alumnus_id'] ?? 0,
      alumnusName: json['alumnus_name'] ?? '',
      alumnusReg: json['alumnus_reg'] ?? '',
      communicationId: json['communication_id'] ?? 0,
      communicationTitle: json['communication_title'] ?? '',
      communicationCategory: json['communication_category'] ?? '',
      responseType: json['response_type'] ?? 'INTERESTED',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class ReportSummaryModel {
  final ReportMetrics metrics;
  final List<CountItem> programmes;
  final List<CountItem> graduationYears;
  final List<CountItem> topIndustries;
  final List<CountItem> topEmployers;
  final List<RecentAlumnusRegistrationModel> recentRegistrations;
  final List<RecentCareerUpdateModel> recentCareerUpdates;
  final List<RecentFeedbackItemModel> recentFeedbacks;
  final Map<String, dynamic>? timeToFirstJob;
  final List<Map<String, dynamic>> sectorDistribution;
  final Map<String, dynamic>? careerProgression;
  final List<Map<String, dynamic>> cohortTrends;
  final Map<String, dynamic>? tracerSurveySummary;
  final String generatedAt;

  ReportSummaryModel({
    required this.metrics,
    required this.programmes,
    required this.graduationYears,
    required this.topIndustries,
    required this.topEmployers,
    this.recentRegistrations = const [],
    this.recentCareerUpdates = const [],
    this.recentFeedbacks = const [],
    this.timeToFirstJob,
    this.sectorDistribution = const [],
    this.careerProgression,
    this.cohortTrends = const [],
    this.tracerSurveySummary,
    required this.generatedAt,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawProgs = (json['programmes'] as List?) ?? [];
    var rawYears = (json['graduation_years'] as List?) ?? [];
    var rawInds = (json['top_industries'] as List?) ?? [];
    var rawEmps = (json['top_employers'] as List?) ?? [];
    var rawRegs = (json['recent_registrations'] as List?) ?? [];
    var rawCareers = (json['recent_career_updates'] as List?) ?? [];
    var rawFeedbacks = (json['recent_feedbacks'] as List?) ?? [];
    var rawSectorDist = (json['sector_distribution'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    var rawCohortTrends = (json['cohort_trends'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ReportSummaryModel(
      metrics: ReportMetrics.fromJson(json['metrics'] ?? {}),
      programmes: rawProgs.map((e) => CountItem(label: e['programme'] ?? '', count: e['count'] ?? 0)).toList(),
      graduationYears: rawYears.map((e) => CountItem(label: e['graduation_year'].toString(), count: e['count'] ?? 0)).toList(),
      topIndustries: rawInds.map((e) => CountItem(label: e['industry_sector'] ?? '', count: e['count'] ?? 0)).toList(),
      topEmployers: rawEmps.map((e) => CountItem(label: e['employer'] ?? '', count: e['count'] ?? 0)).toList(),
      recentRegistrations: rawRegs.map((e) => RecentAlumnusRegistrationModel.fromJson(e)).toList(),
      recentCareerUpdates: rawCareers.map((e) => RecentCareerUpdateModel.fromJson(e)).toList(),
      recentFeedbacks: rawFeedbacks.map((e) => RecentFeedbackItemModel.fromJson(e)).toList(),
      timeToFirstJob: json['time_to_first_job'] as Map<String, dynamic>?,
      sectorDistribution: rawSectorDist,
      careerProgression: json['career_progression'] as Map<String, dynamic>?,
      cohortTrends: rawCohortTrends,
      tracerSurveySummary: json['tracer_survey_summary'] as Map<String, dynamic>?,
      generatedAt: json['generated_at'] ?? '',
    );
  }
}

