import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/msu_logo.dart';
import '../alumni/alumni_home_screen.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;
  bool _alertSent = false;
  bool _isSendingAlert = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkVerificationStatus();
    setState(() => _checking = false);

    if (!mounted) return;

    if (auth.isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlumniHomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account still awaiting review. Staff will verify shortly.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showNotifyAdminDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryNavy, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('Notify Administrator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send an urgent verification notification directly to the Department of Computer Science administrators.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alumnus: ${user?.fullName ?? 'Graduate'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy)),
                        Text('Email: ${user?.email ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (user?.profile?.registrationNumber != null)
                          Text('Registration #: ${user!.profile!.registrationNumber}', style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Optional message for Staff',
                      hintText: 'e.g. Completed BSc Hons Computer Science in 2023. Kindly review and verify my profile.',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Alert to Admin'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isSendingAlert = true);
                  final success = await auth.requestVerification(
                    registrationNumber: user?.profile?.registrationNumber ?? 'PENDING',
                    fullName: user?.fullName,
                    email: user?.email,
                    message: noteController.text.trim(),
                  );
                  setState(() => _isSendingAlert = false);

                  if (!mounted) return;
                  if (success) {
                    setState(() => _alertSent = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('Verification alert sent! Department staff have been notified.')),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.errorMessage ?? 'Failed to send alert. Please try again.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: MsuLogo(size: 54, showBorder: true, borderRadius: 14),
                    ),
                    const SizedBox(height: 16),

                    // Pending Icon Circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.warning.withOpacity(0.4), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          size: 38,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Verification In Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Hello, ${user?.fullName ?? 'Alumnus'}!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Your alumni account has been created and is awaiting verification by the Department of Computer Science staff to confirm graduate status.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. Primary Action: Notify Admin to Verify
                    if (_alertSent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Verification alert sent to Administrator. Staff will review and verify your account shortly.',
                                style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      CustomButton(
                        text: 'Notify Admin to Verify',
                        icon: Icons.notifications_active_rounded,
                        isLoading: _isSendingAlert,
                        onPressed: _showNotifyAdminDialog,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2. Check Status Button
                    CustomButton(
                      text: 'Check Status Now',
                      icon: Icons.refresh_rounded,
                      isOutlined: true,
                      isLoading: _checking,
                      onPressed: _checkStatus,
                    ),
                    const SizedBox(height: 12),

                    // 3. Sign Out Button
                    TextButton.icon(
                      icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
                      label: const Text('Sign Out', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      onPressed: _signOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
