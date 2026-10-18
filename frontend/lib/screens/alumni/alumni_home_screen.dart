import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/communication_provider.dart';
import '../../providers/career_provider.dart';
import '../../providers/alumni_provider.dart';
import '../../widgets/msu_logo.dart';
import 'feeds_module_view.dart';
import 'events_module_view.dart';
import 'job_applications_module.dart';
import 'feedback_survey_module.dart';
import 'career_timeline_screen.dart';
import 'profile_view_edit_screen.dart';
import 'mentorship_hub_screen.dart';
import '../auth/login_screen.dart';

class AlumniHomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const AlumniHomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AlumniHomeScreen> createState() => _AlumniHomeScreenState();
}

class _AlumniHomeScreenState extends State<AlumniHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final comm = Provider.of<CommunicationProvider>(context, listen: false);
      comm.fetchFeed();
      comm.fetchSurveys();
      comm.fetchSurveyAnalytics();
      comm.fetchDepartmentFeedbacks();
      Provider.of<CareerProvider>(context, listen: false).fetchMyCareers();
      Provider.of<AlumniProvider>(context, listen: false).fetchMyProfile();
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGold, width: 1.2),
            ),
            child: const MsuLogo(size: 28),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MSU DCS Alumni',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Welcome, ${user?.firstName ?? 'Alumnus'}',
              style: const TextStyle(fontSize: 11, color: AppColors.accentGold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, size: 12, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardShell(),
          CareerTimelineScreen(),
          MentorshipHubScreen(),
          FeedbackSurveyModule(),
          ProfileViewEditScreen(),
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Career Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Mentorship',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Survey',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              indicatorColor: AppColors.accentGold,
              indicatorWeight: 3,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  icon: Icon(Icons.campaign_outlined, size: 19),
                  text: 'Feeds & Notices',
                ),
                Tab(
                  icon: Icon(Icons.event_available_outlined, size: 19),
                  text: 'Events & Reunions',
                ),
                Tab(
                  icon: Icon(Icons.work_outline, size: 19),
                  text: 'Job Applications',
                ),
                Tab(
                  icon: Icon(Icons.rate_review_outlined, size: 19),
                  text: 'Feedback & Survey',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const Expanded(
            child: TabBarView(
              children: [
                FeedsModuleView(),
                EventsModuleView(),
                JobApplicationsModule(),
                FeedbackSurveyModule(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
