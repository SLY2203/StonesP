import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alumni_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/communication_provider.dart';
import '../../widgets/stat_card.dart';
import 'alumni_directory_screen.dart';
import 'broadcast_composer_screen.dart';
import 'reports_dashboard_screen.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchSummary();
      Provider.of<AlumniProvider>(context, listen: false).fetchDirectory();
      Provider.of<CommunicationProvider>(context, listen: false).fetchFeed();
    });
  }

  Future<void> _handleLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildOverviewTab() {
    final reportProvider = Provider.of<ReportProvider>(context);
    final metrics = reportProvider.summary?.metrics;

    return RefreshIndicator(
      onRefresh: () async {
        await reportProvider.fetchSummary();
        if (mounted) {
          await Provider.of<AlumniProvider>(context, listen: false).fetchDirectory();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Department Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavyDark, AppColors.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'DEPARTMENT OF COMPUTER SCIENCE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5),
                        ),
                      ),
                      const Icon(Icons.security_rounded, color: AppColors.accentGold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrative Control Hub',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Midlands State University • Faculty of Science & Tech',
                    style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.campaign_rounded, size: 16),
                        label: const Text('New Broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () => setState(() => _currentIndex = 2),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.assessment_outlined, size: 16),
                        label: const Text('View Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () => setState(() => _currentIndex = 3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'KEY DEPARTMENT METRICS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),

            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  title: 'Total Alumni Registered',
                  value: '${metrics?.totalAlumni ?? 0}',
                  icon: Icons.people_alt_rounded,
                  iconColor: AppColors.primaryNavy,
                  iconBgColor: AppColors.infoBg,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                StatCard(
                  title: 'Overall Employment Rate',
                  value: '${metrics?.overallEmploymentRate ?? 0}%',
                  subtitle: 'Employed / Founder',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  iconBgColor: AppColors.successBg,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                StatCard(
                  title: 'Pending Verifications',
                  value: '${metrics?.pendingVerification ?? 0}',
                  subtitle: metrics != null && metrics.pendingVerification > 0 ? 'Action Needed' : 'All Clear',
                  icon: Icons.pending_actions_rounded,
                  iconColor: AppColors.warning,
                  iconBgColor: AppColors.warningBg,
                  onTap: () {
                    setState(() => _currentIndex = 1);
                    Provider.of<AlumniProvider>(context, listen: false).fetchDirectory(isVerified: false);
                  },
                ),
                StatCard(
                  title: 'Active Communications',
                  value: '${metrics?.totalBroadcasts ?? 0}',
                  subtitle: '${metrics?.totalRsvps ?? 0} Responses',
                  icon: Icons.forum_rounded,
                  iconColor: AppColors.catEvent,
                  iconBgColor: const Color(0xFFF3E8FF),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions & Pending Alert
            if (metrics != null && metrics.pendingVerification > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${metrics.pendingVerification} Alumni Waiting for Approval',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Review signups and verify student registration numbers.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentIndex = 1);
                        Provider.of<AlumniProvider>(context, listen: false).fetchDirectory(isVerified: false);
                      },
                      child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MSU DCS Staff Admin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${user?.fullName ?? 'Department Staff'} (Administrator)', style: const TextStyle(fontSize: 11, color: AppColors.accentGold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          const AlumniDirectoryScreen(),
          const BroadcastComposerScreen(),
          const ReportsDashboardScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Directory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            activeIcon: Icon(Icons.send),
            label: 'Broadcast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
