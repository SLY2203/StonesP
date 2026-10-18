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

                    CustomButton(
                      text: 'Check Status Now',
                      icon: Icons.refresh_rounded,
                      isLoading: _checking,
                      onPressed: _checkStatus,
                    ),
                    const SizedBox(height: 12),

                    CustomButton(
                      text: 'Sign Out',
                      isOutlined: true,
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
