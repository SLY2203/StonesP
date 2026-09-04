import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/communication_provider.dart';
import '../../providers/career_provider.dart';
import '../../providers/alumni_provider.dart';
import '../../widgets/communication_card.dart';
import 'career_timeline_screen.dart';
import 'profile_view_edit_screen.dart';
import '../auth/login_screen.dart';

class AlumniHomeScreen extends StatefulWidget {
  const AlumniHomeScreen({super.key});

  @override
  State<AlumniHomeScreen> createState() => _AlumniHomeScreenState();
}

class _AlumniHomeScreenState extends State<AlumniHomeScreen> {
  int _currentIndex = 0;

  final List<String> _categories = [
    'ALL',
    'ANNOUNCEMENT',
    'EVENT',
    'JOB_VACANCY',
    'MENTORSHIP',
  ];

  final Map<String, String> _categoryLabels = {
    'ALL': 'All Posts',
    'ANNOUNCEMENT': 'Announcements',
    'EVENT': 'Events & Galas',
    'JOB_VACANCY': 'Jobs & Careers',
    'MENTORSHIP': 'Mentorship',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunicationProvider>(context, listen: false).fetchFeed();
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

  Widget _buildFeedView() {
    final commProvider = Provider.of<CommunicationProvider>(context);

    return RefreshIndicator(
      onRefresh: () => commProvider.fetchFeed(),
      child: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = commProvider.selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _categoryLabels[cat] ?? cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryNavy : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      commProvider.fetchFeed(category: cat);
                    },
                  ),
                );
              },
            ),
          ),

          // Feed List
          Expanded(
            child: commProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : commProvider.feed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No updates found in this category',
                              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: commProvider.feed.length,
                        itemBuilder: (context, index) {
                          final item = commProvider.feed[index];
                          return CommunicationCard(
                            communication: item,
                            onRSVP: (responseType) {
                              commProvider.submitRSVP(item.id, responseType);
                            },
                            onCancelRSVP: () {
                              commProvider.cancelRSVP(item.id);
                            },
                          );
                        },
                      ),
          ),
        ],
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
          _FeedShell(),
          CareerTimelineScreen(),
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
            icon: Icon(Icons.feed_outlined),
            activeIcon: Icon(Icons.feed),
            label: 'Feed & Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Career Tracker',
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

class _FeedShell extends StatelessWidget {
  const _FeedShell();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AlumniHomeScreenState>();
    return state?._buildFeedView() ?? const SizedBox();
  }
}
