import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/alumni_provider.dart';
import '../../widgets/custom_button.dart';

class AlumniDetailVerificationScreen extends StatefulWidget {
  final int alumnusId;

  const AlumniDetailVerificationScreen({super.key, required this.alumnusId});

  @override
  State<AlumniDetailVerificationScreen> createState() => _AlumniDetailVerificationScreenState();
}

class _AlumniDetailVerificationScreenState extends State<AlumniDetailVerificationScreen> {
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlumniProvider>(context, listen: false).fetchAlumnusDetail(widget.alumnusId);
    });
  }

  Future<void> _handleToggle(int userId, bool newStatus) async {
    setState(() => _toggling = true);
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    final success = await provider.toggleVerification(userId, newStatus);
    if (success) {
      await provider.fetchAlumnusDetail(widget.alumnusId);
    }
    setState(() => _toggling = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Alumnus verified & activated!' : 'Alumnus status set to unverified.'),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlumniProvider>(context);
    final alumnus = provider.selectedAlumnus;

    if (provider.isLoading && alumnus == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alumnus Record')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (alumnus == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alumnus Record')),
        body: const Center(child: Text('Alumnus record not found.')),
      );
    }

    final userId = alumnus.user?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alumnus Profile & Verification'),
        backgroundColor: AppColors.primaryNavy,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: alumnus.isVerified
            ? CustomButton(
                text: 'Revoke Verification',
                icon: Icons.block_rounded,
                isOutlined: true,
                textColor: AppColors.error,
                backgroundColor: AppColors.error,
                isLoading: _toggling,
                onPressed: () => _handleToggle(userId, false),
              )
            : CustomButton(
                text: 'Verify & Activate Alumnus',
                icon: Icons.verified_rounded,
                backgroundColor: AppColors.success,
                isLoading: _toggling,
                onPressed: () => _handleToggle(userId, true),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: alumnus.isVerified ? AppColors.primaryNavy : AppColors.warningBg,
                    child: Text(
                      alumnus.fullName.isNotEmpty ? alumnus.fullName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: alumnus.isVerified ? Colors.white : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alumnus.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alumnus.email,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Status Indicator Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: alumnus.isVerified ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          alumnus.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                          size: 16,
                          color: alumnus.isVerified ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alumnus.isVerified ? 'VERIFIED ALUMNUS ACCOUNT' : 'PENDING DEPARTMENT VERIFICATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: alumnus.isVerified ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Information and Date Shared Banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.how_to_reg_rounded, size: 14, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date Registered', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(
                                  alumnus.createdAt != null && alumnus.createdAt!.length >= 10
                                      ? alumnus.createdAt!.substring(0, 10)
                                      : (alumnus.createdAt ?? 'N/A'),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(height: 24, width: 1, color: AppColors.border),
                        Row(
                          children: [
                            const Icon(Icons.update_rounded, size: 14, color: AppColors.accentGold),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Last Info Updated', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(
                                  alumnus.updatedAt != null && alumnus.updatedAt!.length >= 10
                                      ? alumnus.updatedAt!.substring(0, 10)
                                      : (alumnus.updatedAt ?? 'N/A'),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Academic Record Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Academic Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Registration Number', alumnus.registrationNumber),
                  const Divider(height: 16),
                  _buildDetailRow('Graduation Year', '${alumnus.graduationYear}'),
                  const Divider(height: 16),
                  _buildDetailRow('Programme', alumnus.programme),
                  const Divider(height: 16),
                  _buildDetailRow('Phone Number', alumnus.phoneNumber ?? 'N/A'),
                  const Divider(height: 16),
                  _buildDetailRow('Location', alumnus.address ?? 'N/A'),
                  if (alumnus.bio != null && alumnus.bio!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('Bio / About', alumnus.bio!),
                  ],
                  if (alumnus.linkedinUrl != null && alumnus.linkedinUrl!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('LinkedIn', alumnus.linkedinUrl!),
                  ],
                  if (alumnus.githubUrl != null && alumnus.githubUrl!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('GitHub', alumnus.githubUrl!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current Employment & Career Status
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Career Record', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                      if (alumnus.currentJob != null && alumnus.currentJob!.updatedAt != null)
                        Text(
                          'Shared: ${alumnus.currentJob!.updatedAt!.length >= 10 ? alumnus.currentJob!.updatedAt!.substring(0, 10) : alumnus.currentJob!.updatedAt}',
                          style: const TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (alumnus.currentJob != null) ...[
                    _buildDetailRow('Job Title', alumnus.currentJob!.jobTitle ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Employer', alumnus.currentJob!.employer ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Industry', alumnus.currentJob!.industrySector ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Employment Status', alumnus.currentJob!.employmentStatus ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Position Duration',
                      '${alumnus.currentJob!.startDate ?? 'N/A'} - ${alumnus.currentJob!.isCurrent ? 'Present' : (alumnus.currentJob!.endDate ?? 'N/A')}',
                    ),
                    if (alumnus.currentJob!.skillsUsed != null && alumnus.currentJob!.skillsUsed!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildDetailRow('Skills Used', alumnus.currentJob!.skillsUsed!),
                    ],
                    if (alumnus.currentJob!.description != null && alumnus.currentJob!.description!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildDetailRow('Job Description', alumnus.currentJob!.description!),
                    ],
                  ] else ...[
                    const Text('No current job record specified by alumnus.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Skills & Mentorship Details Shared
            if (alumnus.skillsList.isNotEmpty || alumnus.isAvailableForMentorship) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Competencies & Mentorship', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    const SizedBox(height: 12),
                    if (alumnus.skillsList.isNotEmpty) ...[
                      const Text('Technical Skills Shared:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: alumnus.skillsList.map((sk) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(sk, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (alumnus.isAvailableForMentorship) ...[
                      Row(
                        children: const [
                          Icon(Icons.volunteer_activism_rounded, size: 16, color: AppColors.accentGold),
                          SizedBox(width: 6),
                          Text('Available for Mentorship', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        ],
                      ),
                      if (alumnus.mentorshipAreas != null && alumnus.mentorshipAreas!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Areas: ${alumnus.mentorshipAreas}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full Career Progression History Timeline
            if (alumnus.careerRecords.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Career History Timeline',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        Text(
                          '${alumnus.careerRecords.length} records',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: alumnus.careerRecords.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (ctx, idx) {
                        final rec = alumnus.careerRecords[idx];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: rec.isCurrent ? AppColors.successBg : AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                rec.isCurrent ? Icons.check_circle_rounded : Icons.work_outline_rounded,
                                size: 16,
                                color: rec.isCurrent ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          rec.jobTitle,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (rec.isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('CURRENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success)),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${rec.employer} • ${rec.industrySector}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryNavy),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.date_range_rounded, size: 12, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rec.startDate} - ${rec.isCurrent ? 'Present' : (rec.endDate ?? 'N/A')}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (rec.description != null && rec.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      rec.description!,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
