class CareerRecordModel {
  final int id;
  final int? alumnusId;
  final String? alumnusName;
  final String jobTitle;
  final String employer;
  final String employmentStatus;
  final String statusDisplay;
  final String industrySector;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String? furtherEducationInstitution;
  final String? furtherEducationProgramme;
  final String? description;

  CareerRecordModel({
    required this.id,
    this.alumnusId,
    this.alumnusName,
    required this.jobTitle,
    required this.employer,
    required this.employmentStatus,
    required this.statusDisplay,
    required this.industrySector,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    this.furtherEducationInstitution,
    this.furtherEducationProgramme,
    this.description,
  });

  factory CareerRecordModel.fromJson(Map<String, dynamic> json) {
    return CareerRecordModel(
      id: json['id'] ?? 0,
      alumnusId: json['alumnus'],
      alumnusName: json['alumnus_name'],
      jobTitle: json['job_title'] ?? '',
      employer: json['employer'] ?? '',
      employmentStatus: json['employment_status'] ?? 'EMPLOYED',
      statusDisplay: json['status_display'] ?? 'Employed',
      industrySector: json['industry_sector'] ?? 'Software & IT Services',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      isCurrent: json['is_current'] ?? false,
      furtherEducationInstitution: json['further_education_institution'],
      furtherEducationProgramme: json['further_education_programme'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_title': jobTitle,
      'employer': employer,
      'employment_status': employmentStatus,
      'industry_sector': industrySector,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'further_education_institution': furtherEducationInstitution,
      'further_education_programme': furtherEducationProgramme,
      'description': description,
    };
  }
}
