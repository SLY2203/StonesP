import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/job_service.dart';

class MatchedJobsScreen extends StatefulWidget {
  const MatchedJobsScreen({super.key});

  @override
  State<MatchedJobsScreen> createState() => _MatchedJobsScreenState();
}

class _MatchedJobsScreenState extends State<MatchedJobsScreen> with SingleTickerProviderStateMixin {
  final JobService _jobService = JobService();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _matchedJobs = [];
  List<Map<String, dynamic>> _allJobs = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _jobService.getMatchedJobs();
      final all = await _jobService.browseJobs(query: _searchQuery);

      if (mounted) {
        setState(() {
          _matchedJobs = matches;
          _allJobs = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showApplyModal(Map<String, dynamic> job, {int? matchId}) {
    final coverNoteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Apply to ${job['title']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  '${job['company']} • ${job['location']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: coverNoteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Cover Note / Introduction (Optional)',
                    hintText: 'Share a brief message about your DCS background and relevant projects...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await _jobService.applyToJob(
                              job['id'],
                              coverNote: coverNoteController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Application submitted successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              _loadJobs();
                            }
                          } catch (err) {
                            setModalState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submission failed: $err'), backgroundColor: AppColors.error),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Job Match & Vacancies'),
        backgroundColor: AppColors.primaryNavy,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 6),
                  Text('AI Matches (${_matchedJobs.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('All Vacancies (${_allJobs.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchedJobsTab(),
                _buildAllJobsTab(),
              ],
            ),
    );
  }

  Widget _buildMatchedJobsTab() {
    if (_matchedJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.primaryNavy.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text(
                'No Job Matches Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your profile skills and career history are updated so our AI matcher can recommend relevant vacancies.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _matchedJobs.length,
        itemBuilder: (context, index) {
          final match = _matchedJobs[index];
          final job = match['job'] as Map<String, dynamic>;
          final score = match['match_score'] ?? 0;
          final overlap = match['skills_overlap'] as String? ?? '';
          final reasons = (match['match_reasons'] as List?)?.cast<String>() ?? [];
          final myApp = match['my_application'];

          return _buildJobCard(
            job: job,
            score: score,
            skillsOverlap: overlap,
            reasons: reasons,
            isApplied: myApp != null,
          );
        },
      ),
    );
  }

  Widget _buildAllJobsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) {
              _searchQuery = val;
              _loadJobs();
            },
            decoration: InputDecoration(
              hintText: 'Search jobs by title, company, or skills...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
        Expanded(
          child: _allJobs.isEmpty
              ? const Center(child: Text('No vacancies currently match your search.'))
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _allJobs.length,
                    itemBuilder: (context, index) {
                      final job = _allJobs[index];
                      return _buildJobCard(job: job, isApplied: false);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildJobCard({
    required Map<String, dynamic> job,
    int? score,
    String? skillsOverlap,
    List<String>? reasons,
    bool isApplied = false,
  }) {
    Color scoreColor = AppColors.info;
    if (score != null) {
      if (score >= 75) scoreColor = AppColors.success;
      else if (score >= 50) scoreColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: score != null && score >= 75 ? AppColors.success.withOpacity(0.5) : AppColors.border),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Position',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job['company']} • ${job['location']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: scoreColor),
                      const SizedBox(width: 4),
                      Text(
                        '$score% Match',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: scoreColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges: type, experience, sector
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (job['experience_display'] != null)
                _buildChip(job['experience_display'], Icons.school_outlined),
              if (job['type_display'] != null)
                _buildChip(job['type_display'], Icons.work_outline),
              if (job['salary_range'] != null && (job['salary_range'] as String).isNotEmpty)
                _buildChip(job['salary_range'], Icons.attach_money),
            ],
          ),

          if (skillsOverlap != null && skillsOverlap.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Matched Skills: $skillsOverlap',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavyDark),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (reasons != null && reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded, size: 16, color: AppColors.textSecondary),
                      Expanded(
                        child: Text(r, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                )),
          ],

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (job['application_deadline'] != null)
                Text(
                  'Deadline: ${job['application_deadline']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: isApplied ? null : () => _showApplyModal(job),
                icon: Icon(isApplied ? Icons.check_circle : Icons.send_rounded, size: 16, color: Colors.white),
                label: Text(
                  isApplied ? 'Applied' : 'Express Interest',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApplied ? AppColors.textMuted : AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
