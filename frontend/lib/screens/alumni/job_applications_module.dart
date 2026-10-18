import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/communication_provider.dart';
import '../../providers/alumni_provider.dart';
import '../../models/communication_model.dart';

class JobApplicationsModule extends StatefulWidget {
  const JobApplicationsModule({super.key});

  @override
  State<JobApplicationsModule> createState() => _JobApplicationsModuleState();
}

class _JobApplicationsModuleState extends State<JobApplicationsModule> {
  final TextEditingController _searchController = TextEditingController();
  bool _filterOnlyApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunicationProvider>(context, listen: false)
          .fetchFeed(category: 'JOB_VACANCY');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'No deadline specified';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  bool _isDeadlineApproaching(String? deadlineStr) {
    if (deadlineStr == null) return false;
    try {
      final dt = DateTime.parse(deadlineStr);
      final diff = dt.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 5;
    } catch (_) {
      return false;
    }
  }

  void _openApplyDialog(CommunicationModel job) {
    final alumniProfile = Provider.of<AlumniProvider>(context, listen: false).myProfile;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.catJob.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.work_outline, color: AppColors.catJob, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply for Position',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                job.title,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Applicant preview card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryNavy,
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alumniProfile?.fullName ?? 'Verified Alumnus',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${alumniProfile?.programme ?? 'Computer Science'} • Reg: ${alumniProfile?.registrationNumber ?? 'Verified'}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Application Notes / Cover Pitch',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Highlight your relevant skills, graduation year, or include a link to your online portfolio / CV...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.catJob,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                final commProvider = Provider.of<CommunicationProvider>(context, listen: false);
                                final success = await commProvider.submitRSVP(
                                  job.id,
                                  'APPLIED',
                                  notes: notesController.text.trim(),
                                );
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Application submitted successfully! Track it in "My Applications".'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }

                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commProvider = Provider.of<CommunicationProvider>(context);
    final allJobs = commProvider.feed.where((item) => item.category == 'JOB_VACANCY').toList();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allJobs.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query) ||
          (item.location ?? '').toLowerCase().contains(query);
      final isApplied = item.myRsvp?.responseType == 'APPLIED';
      final matchesFilter = !_filterOnlyApplied || isApplied;
      return matchesQuery && matchesFilter;
    }).toList();

    final totalAppliedCount = allJobs.where((j) => j.myRsvp?.responseType == 'APPLIED').length;

    return RefreshIndicator(
      onRefresh: () => commProvider.fetchFeed(category: 'JOB_VACANCY'),
      color: AppColors.primaryNavy,
      child: CustomScrollView(
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3B2E), Color(0xFF1E6B52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E6B52).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_rounded, color: AppColors.accentGold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Opportunities & Applications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Graduate recruitment, internships, and industry vacancies for DCS alumni.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search roles, company, skills, location...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() => _searchController.clear());
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('All Opportunities (${allJobs.length})', style: const TextStyle(fontSize: 12)),
                        selected: !_filterOnlyApplied,
                        selectedColor: const Color(0xFF1E6B52),
                        labelStyle: TextStyle(
                          color: !_filterOnlyApplied ? Colors.white : AppColors.textSecondary,
                          fontWeight: !_filterOnlyApplied ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          if (selected) setState(() => _filterOnlyApplied = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('My Applications ($totalAppliedCount)', style: const TextStyle(fontSize: 12)),
                        selected: _filterOnlyApplied,
                        selectedColor: const Color(0xFF1E6B52),
                        labelStyle: TextStyle(
                          color: _filterOnlyApplied ? Colors.white : AppColors.textSecondary,
                          fontWeight: _filterOnlyApplied ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          setState(() => _filterOnlyApplied = selected);
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} Vacanc${filtered.length == 1 ? 'y' : 'ies'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Job Vacancies List
          if (commProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6B52).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_off_outlined,
                          size: 48,
                          color: Color(0xFF1E6B52),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterOnlyApplied ? 'No Active Applications' : 'No job vacancies found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filterOnlyApplied
                            ? 'You have not submitted an application to any positions yet. Explore open vacancies and tap "Apply Now".'
                            : 'New career opportunities and industry links will appear here as soon as they are posted.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return _buildJobCard(item);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(CommunicationModel item) {
    final isApplied = item.myRsvp?.responseType == 'APPLIED';
    final hasDeadline = item.applicationDeadline != null && item.applicationDeadline!.isNotEmpty;
    final isApproaching = _isDeadlineApproaching(item.applicationDeadline);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isApplied ? AppColors.success.withOpacity(0.5) : AppColors.border,
          width: isApplied ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isApplied
                        ? AppColors.successBg
                        : AppColors.catJob.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isApplied ? Icons.check_circle : Icons.business_center,
                    color: isApplied ? AppColors.success : AppColors.catJob,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isApplied)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 12, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'Applied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              item.location!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content preview
            Text(
              item.content,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Badges row: Target programme, target year, deadline
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasDeadline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproaching
                          ? AppColors.errorBg
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isApproaching ? AppColors.error.withOpacity(0.4) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 12,
                          color: isApproaching ? AppColors.error : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: ${_formatDate(item.applicationDeadline)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isApproaching ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.targetProgramme != null && item.targetProgramme!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      item.targetProgramme!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                if (item.targetGraduationYear != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Target: Class of ${item.targetGraduationYear}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Bottom action row
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${item.counts.applied} applied',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                if (item.externalLink != null && item.externalLink!.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 13),
                    label: const Text('Portal Link', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('External Application Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          content: SelectableText(item.externalLink!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(width: 6),
                if (isApplied)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 14, color: AppColors.success),
                    label: const Text('Applied ✓', style: TextStyle(fontSize: 12, color: AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.success),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Your application has been received by DCS Career Linkages.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Apply Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF1E6B52),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _openApplyDialog(item),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
