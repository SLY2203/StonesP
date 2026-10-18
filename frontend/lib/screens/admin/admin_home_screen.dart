import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alumni_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/communication_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/msu_logo.dart';
import 'alumni_directory_screen.dart';
import 'alumni_detail_verification_screen.dart';
import 'admin_feedback_screen.dart';
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
  int _recentTab = 0; // 0 = Career Milestones, 1 = Newly Registered, 2 = Feedbacks
  final _quickSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchSummary();
      Provider.of<AlumniProvider>(context, listen: false).fetchDirectory();
      Provider.of<CommunicationProvider>(context, listen: false).fetchFeed();
      Provider.of<CommunicationProvider>(context, listen: false).fetchFeedbacks(withNotes: true);
    });
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
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

  // --- Post Job Vacancy Modal ---
  void _showPostJobDialog() {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final locationController = TextEditingController(text: 'Harare / Remote');
    final linkController = TextEditingController();
    final descController = TextEditingController();
    DateTime? deadline = DateTime.now().add(const Duration(days: 30));
    int? targetYear;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.work_rounded, color: AppColors.primaryNavy, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Post Job Vacancy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Publish an employment opportunity directly to verified DCS alumni cohorts.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title *',
                          hintText: 'e.g. Junior Mobile App Engineer',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter job title' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'Hiring Company / Organization *',
                          hintText: 'e.g. EcoCash Holdings / Cassava Smartech',
                          prefixIcon: Icon(Icons.business_rounded, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                hintText: 'e.g. Harare / Hybrid',
                                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: targetYear,
                              decoration: const InputDecoration(
                                labelText: 'Target Cohort',
                                prefixIcon: Icon(Icons.school_outlined, size: 18),
                              ),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('All Cohorts')),
                                DropdownMenuItem(value: 2024, child: Text('Class of 2024')),
                                DropdownMenuItem(value: 2023, child: Text('Class of 2023')),
                                DropdownMenuItem(value: 2022, child: Text('Class of 2022')),
                                DropdownMenuItem(value: 2021, child: Text('Class of 2021')),
                              ],
                              onChanged: (val) => setDialogState(() => targetYear = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: 'Application Link / Email',
                          hintText: 'https://careers.company.com/apply or jobs@company.com',
                          prefixIcon: Icon(Icons.link_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Deadline picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => deadline = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                deadline == null
                                    ? 'Set Application Deadline'
                                    : 'Deadline: ${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const Spacer(),
                              const Text('Select Date', style: TextStyle(fontSize: 11.5, color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: descController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Job Description & Key Requirements *',
                          hintText: 'Describe responsibilities, required skills (e.g. Flutter, Django, PostgreSQL), and candidate criteria...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter job description' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isSubmitting ? 'Posting...' : 'Post Job Now'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);

                        final commProvider = Provider.of<CommunicationProvider>(context, listen: false);
                        final success = await commProvider.postJobVacancy(
                          title: titleController.text.trim(),
                          company: companyController.text.trim(),
                          description: descController.text.trim(),
                          location: locationController.text.trim(),
                          applicationDeadline: deadline,
                          applicationLink: linkController.text.trim(),
                          targetGraduationYear: targetYear,
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Job vacancy "${titleController.text.trim()}" published & dispatched!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          // Refresh summary metrics & broadcast feed
                          Provider.of<ReportProvider>(context, listen: false).fetchSummary();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(commProvider.errorMessage ?? 'Failed to post job.'),
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

  // --- Quick Alumni Search & Tracking Jump ---
  void _jumpToTrackAlumni(String query) {
    setState(() => _currentIndex = 1);
    Provider.of<AlumniProvider>(context, listen: false).fetchDirectory(q: query);
  }

  Widget _buildOverviewTab() {
    final reportProvider = Provider.of<ReportProvider>(context);
    final summary = reportProvider.summary;
    final metrics = summary?.metrics;

    return RefreshIndicator(
      onRefresh: () async {
        await reportProvider.fetchSummary();
        if (mounted) {
          await Provider.of<AlumniProvider>(context, listen: false).fetchDirectory();
          await Provider.of<CommunicationProvider>(context, listen: false).fetchFeedbacks(withNotes: true);
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
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const MsuLogo(size: 24, showBorder: true, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrative Control Hub',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track career progression, post job vacancies, and manage alumni feedback.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Post Job Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.work_rounded, size: 16),
                        label: const Text('Post Job Vacancy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: _showPostJobDialog,
                      ),
                      // See Feedbacks Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.forum_outlined, size: 16),
                        label: Text('Feedbacks (${metrics?.totalFeedbacks ?? 0})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
                          );
                        },
                      ),
                      // Broadcast button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.campaign_outlined, size: 16),
                        label: const Text('New Broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () => setState(() => _currentIndex = 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TRACK ALUMNI BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 20, color: AppColors.primaryNavy),
                      const SizedBox(width: 8),
                      const Text(
                        'TRACK ALUMNI CAREER PROGRESSION',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 1),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text('Open Directory →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quickSearchController,
                    onSubmitted: (q) => _jumpToTrackAlumni(q.trim()),
                    decoration: InputDecoration(
                      hintText: 'Track graduate by name, reg # (e.g. R201456B), or employer...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primaryNavy),
                        onPressed: () => _jumpToTrackAlumni(_quickSearchController.text.trim()),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick tracking filter pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTrackFilterPill('All Tracked (${metrics?.totalAlumni ?? 0})', () {
                          setState(() => _currentIndex = 1);
                          Provider.of<AlumniProvider>(context, listen: false).fetchDirectory();
                        }),
                        const SizedBox(width: 6),
                        _buildTrackFilterPill('Employed / Founder (${metrics?.overallEmploymentRate ?? 0}%)', () {
                          setState(() => _currentIndex = 1);
                          Provider.of<AlumniProvider>(context, listen: false).fetchDirectory(isVerified: true);
                        }),
                        const SizedBox(width: 6),
                        _buildTrackFilterPill('Pending Approval (${metrics?.pendingVerification ?? 0})', () {
                          setState(() => _currentIndex = 1);
                          Provider.of<AlumniProvider>(context, listen: false).fetchDirectory(isVerified: false);
                        }),
                        const SizedBox(width: 6),
                        _buildTrackFilterPill('Career Reports Dashboard', () {
                          setState(() => _currentIndex = 3);
                        }),
                      ],
                    ),
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

            // KPI Grid (5 Cards: Alumni, Employment Rate, Feedbacks, Verifications, Communications)
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
                  subtitle: '${metrics?.employedCount ?? 0} Employed / Founder',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  iconBgColor: AppColors.successBg,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                StatCard(
                  title: 'Alumni Feedbacks & Notes',
                  value: '${metrics?.totalFeedbacks ?? 0}',
                  subtitle: 'Job Applications & Inquiries',
                  icon: Icons.forum_rounded,
                  iconColor: const Color(0xFF6366F1),
                  iconBgColor: const Color(0xFFEEF2FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
                    );
                  },
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
              ],
            ),
            const SizedBox(height: 20),

            // Pending Approval Alert if pending > 0
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

            // LIVE FEED: Milestones, Registrations & Feedbacks
            _buildRecentActivitySection(summary),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackFilterPill(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ReportSummaryModel? summary) {
    final recentCareers = summary?.recentCareerUpdates ?? [];
    final recentRegs = summary?.recentRegistrations ?? [];
    final recentFeedbacks = summary?.recentFeedbacks ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_edu_rounded, size: 20, color: AppColors.primaryNavy),
                  SizedBox(width: 8),
                  Text(
                    'RECENT ACTIVITY & DATES SHARED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_recentTab == 2)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('View All Feedbacks →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('View Directory →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Live updates, career records, and feedback notes submitted by DCS graduates.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Sub-tabs: Career Milestones, Registrations, Feedbacks
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRecentFilterPill(
                  label: '💼 Milestones (${recentCareers.length})',
                  index: 0,
                ),
                const SizedBox(width: 6),
                _buildRecentFilterPill(
                  label: '🎓 Registrations (${recentRegs.length})',
                  index: 1,
                ),
                const SizedBox(width: 6),
                _buildRecentFilterPill(
                  label: '💬 Feedbacks (${recentFeedbacks.length})',
                  index: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // TAB 0: Career Milestones
          if (_recentTab == 0) ...[
            if (recentCareers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No career records shared recently.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentCareers.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (ctx, i) {
                  final item = recentCareers[i];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlumniDetailVerificationScreen(alumnusId: item.alumnusId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.work_rounded, size: 20, color: AppColors.primaryNavy),
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
                                        item.alumnusName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isCurrent ? AppColors.successBg : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.isCurrent ? 'Current' : 'Past',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: item.isCurrent ? AppColors.success : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.jobTitle} • ${item.employer}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (item.startDate != null) ...[
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text('Start: ${item.startDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(width: 10),
                                    ],
                                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.accentGold),
                                    const SizedBox(width: 4),
                                    Text('Shared: ${item.createdAt ?? 'Recent'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ]

          // TAB 1: New Registrations
          else if (_recentTab == 1) ...[
            if (recentRegs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No new alumni registrations yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRegs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (ctx, i) {
                  final reg = recentRegs[i];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlumniDetailVerificationScreen(alumnusId: reg.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: reg.isVerified ? AppColors.primaryNavy : AppColors.warningBg,
                            child: Text(
                              reg.fullName.isNotEmpty ? reg.fullName[0].toUpperCase() : 'A',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: reg.isVerified ? Colors.white : AppColors.warning,
                              ),
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
                                        reg.fullName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: reg.isVerified ? AppColors.successBg : AppColors.warningBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        reg.isVerified ? 'Verified' : 'Pending',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: reg.isVerified ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${reg.registrationNumber} • Class of ${reg.graduationYear}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                                if (reg.currentJobTitle != null && reg.currentEmployer != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${reg.currentJobTitle} at ${reg.currentEmployer}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.how_to_reg_rounded, size: 12, color: AppColors.accentGold),
                                    const SizedBox(width: 4),
                                    Text('Registered on: ${reg.createdAt ?? 'Recent'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ]

          // TAB 2: Feedbacks & Notes
          else if (_recentTab == 2) ...[
            if (recentFeedbacks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No feedback notes received yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentFeedbacks.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (ctx, i) {
                  final fb = recentFeedbacks[i];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlumniDetailVerificationScreen(alumnusId: fb.alumnusId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF6366F1)),
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
                                        fb.alumnusName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: fb.responseType == 'APPLIED' ? AppColors.successBg : AppColors.infoBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        fb.responseType,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: fb.responseType == 'APPLIED' ? AppColors.success : AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'On: ${fb.communicationTitle}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (fb.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '"${fb.notes}"',
                                      style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  fb.createdAt != null && fb.createdAt!.length >= 16 ? fb.createdAt!.substring(0, 16) : (fb.createdAt ?? ''),
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentFilterPill({required String label, required int index}) {
    final isSelected = _recentTab == index;
    return InkWell(
      onTap: () => setState(() => _recentTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryNavy : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
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
            const Text('MSU DCS Staff Admin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              '${user?.fullName ?? 'Department Staff'} (Administrator)',
              style: const TextStyle(fontSize: 11, color: AppColors.accentGold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline_rounded, size: 20),
            tooltip: 'Post Job Vacancy',
            onPressed: _showPostJobDialog,
          ),
          IconButton(
            icon: const Icon(Icons.forum_outlined, size: 20),
            tooltip: 'Alumni Feedbacks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
              );
            },
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
