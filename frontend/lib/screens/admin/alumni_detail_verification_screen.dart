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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current Employment Card
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
                  const Text('Current Career Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                  const SizedBox(height: 12),
                  if (alumnus.currentJob != null) ...[
                    _buildDetailRow('Job Title', alumnus.currentJob!.jobTitle ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Employer', alumnus.currentJob!.employer ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Industry', alumnus.currentJob!.industrySector ?? 'N/A'),
                    const Divider(height: 16),
                    _buildDetailRow('Status', alumnus.currentJob!.employmentStatus ?? 'N/A'),
                  ] else ...[
                    const Text('No current job record specified by alumnus.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
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
