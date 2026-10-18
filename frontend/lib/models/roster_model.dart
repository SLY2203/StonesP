class GraduationRosterModel {
  final int id;
  final String registrationNumber;
  final String fullName;
  final int graduationYear;
  final String programme;
  final String degreeClass;
  final String createdAt;

  GraduationRosterModel({
    required this.id,
    required this.registrationNumber,
    required this.fullName,
    required this.graduationYear,
    required this.programme,
    required this.degreeClass,
    required this.createdAt,
  });

  factory GraduationRosterModel.fromJson(Map<String, dynamic> json) {
    return GraduationRosterModel(
      id: json['id'] ?? 0,
      registrationNumber: json['registration_number'] ?? '',
      fullName: json['full_name'] ?? '',
      graduationYear: json['graduation_year'] ?? 2024,
      programme: json['programme'] ?? '',
      degreeClass: json['degree_class'] ?? 'Pass',
      createdAt: json['created_at'] ?? '',
    );
  }
}
