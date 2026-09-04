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
    );
  }
}

class CountItem {
  final String label;
  final int count;

  CountItem({required this.label, required this.count});
}

class ReportSummaryModel {
  final ReportMetrics metrics;
  final List<CountItem> programmes;
  final List<CountItem> graduationYears;
  final List<CountItem> topIndustries;
  final List<CountItem> topEmployers;
  final String generatedAt;

  ReportSummaryModel({
    required this.metrics,
    required this.programmes,
    required this.graduationYears,
    required this.topIndustries,
    required this.topEmployers,
    required this.generatedAt,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawProgs = (json['programmes'] as List?) ?? [];
    var rawYears = (json['graduation_years'] as List?) ?? [];
    var rawInds = (json['top_industries'] as List?) ?? [];
    var rawEmps = (json['top_employers'] as List?) ?? [];

    return ReportSummaryModel(
      metrics: ReportMetrics.fromJson(json['metrics'] ?? {}),
      programmes: rawProgs.map((e) => CountItem(label: e['programme'] ?? '', count: e['count'] ?? 0)).toList(),
      graduationYears: rawYears.map((e) => CountItem(label: e['graduation_year'].toString(), count: e['count'] ?? 0)).toList(),
      topIndustries: rawInds.map((e) => CountItem(label: e['industry_sector'] ?? '', count: e['count'] ?? 0)).toList(),
      topEmployers: rawEmps.map((e) => CountItem(label: e['employer'] ?? '', count: e['count'] ?? 0)).toList(),
      generatedAt: json['generated_at'] ?? '',
    );
  }
}
