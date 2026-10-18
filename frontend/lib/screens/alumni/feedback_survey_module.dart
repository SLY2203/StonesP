import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/communication_provider.dart';
import '../../models/communication_model.dart';

class FeedbackSurveyModule extends StatefulWidget {
  const FeedbackSurveyModule({super.key});

  @override
  State<FeedbackSurveyModule> createState() => _FeedbackSurveyModuleState();
}

class _FeedbackSurveyModuleState extends State<FeedbackSurveyModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // System Survey Form State
  int _overallRating = 5;
  int _easeOfUseRating = 5;
  int _featuresRating = 5;
  int _performanceRating = 5;
  String _systemAspect = 'GENERAL';
  final TextEditingController _worksWellController = TextEditingController();
  final TextEditingController _improvementsController = TextEditingController();
  bool _wouldRecommend = true;
  bool _isSubmittingSurvey = false;

  // Department Feedback Form State
  final _deptSubjectController = TextEditingController();
  final _deptMessageController = TextEditingController();
  String _deptCategory = 'GENERAL';
  bool _isSubmittingDept = false;

  final Map<String, String> _aspectLabels = {
    'GENERAL': 'General System Performance',
    'CAREER_TRACKING': 'Career Progression & Milestones',
    'DIRECTORY': 'Alumni Directory & Search',
    'VERIFICATION': 'Verification & Registration Flow',
    'JOBS_EVENTS': 'Jobs, Broadcasts & RSVPs',
    'MENTORSHIP': 'Mentorship Program',
  };

  final Map<String, String> _deptCategories = {
    'CURRICULUM': 'Curriculum & Courses Feedback',
    'CAREER_SERVICES': 'Career Services & Industry Linkages',
    'FACILITIES': 'Department Facilities & Resources',
    'ALUMNI_EVENTS': 'Alumni Events & Engagement',
    'GENERAL': 'General Suggestion / Feedback',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final comm = Provider.of<CommunicationProvider>(context, listen: false);
      comm.fetchSurveys();
      comm.fetchSurveyAnalytics();
      comm.fetchDepartmentFeedbacks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _worksWellController.dispose();
    _improvementsController.dispose();
    _deptSubjectController.dispose();
    _deptMessageController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('d MMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '1/5 - Poor';
      case 2:
        return '2/5 - Fair';
      case 3:
        return '3/5 - Good';
      case 4:
        return '4/5 - Very Good';
      case 5:
      default:
        return '5/5 - Excellent!';
    }
  }

  Future<void> _submitSurvey() async {
    setState(() => _isSubmittingSurvey = true);
    final commProvider = Provider.of<CommunicationProvider>(context, listen: false);

    final success = await commProvider.submitSystemSurvey(
      overallRating: _overallRating,
      easeOfUseRating: _easeOfUseRating,
      featuresRating: _featuresRating,
      performanceRating: _performanceRating,
      systemAspect: _systemAspect,
      whatWorksWell: _worksWellController.text.trim(),
      improvementsNeeded: _improvementsController.text.trim(),
      wouldRecommend: _wouldRecommend,
    );

    if (!mounted) return;
    setState(() => _isSubmittingSurvey = false);

    if (success) {
      _worksWellController.clear();
      _improvementsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Thank you! Your survey on system experience was submitted.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commProvider.errorMessage ?? 'Failed to submit survey.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitDeptFeedback() async {
    if (_deptSubjectController.text.trim().isEmpty || _deptMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both subject and message.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmittingDept = true);
    final commProvider = Provider.of<CommunicationProvider>(context, listen: false);

    final success = await commProvider.submitDepartmentFeedback(
      subject: _deptSubjectController.text.trim(),
      category: _deptCategory,
      message: _deptMessageController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmittingDept = false);

    if (success) {
      _deptSubjectController.clear();
      _deptMessageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted to Department of Computer Science.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commProvider.errorMessage ?? 'Failed to submit feedback.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStarRatingBar(int currentRating, Function(int) onRatingChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          icon: Icon(
            starValue <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: starValue <= currentRating ? AppColors.accentGold : AppColors.border,
            size: 28,
          ),
          onPressed: () => onRatingChanged(starValue),
        );
      }),
    );
  }

  Widget _buildSystemSurveyTab() {
    final commProvider = Provider.of<CommunicationProvider>(context);
    final analytics = commProvider.surveyAnalytics;
    final pastSurveys = commProvider.surveys;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Summary Card
          if (analytics != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                      const Icon(Icons.analytics_outlined, color: AppColors.primaryNavy, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'System Health & Alumni Satisfaction',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${analytics['total_surveys'] ?? 0} Responses',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Overall Rating',
                          '${analytics['average_overall_rating'] ?? 5.0} ★',
                          AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Ease of Use',
                          '${analytics['average_ease_of_use'] ?? 5.0} ★',
                          AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Recommend',
                          '${analytics['recommend_rate'] ?? 100}%',
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Survey Submission Form Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.rate_review, color: AppColors.primaryNavy, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How is the System Working?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Rate portal speed, features, and tell us your experience.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  // Overall Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Satisfaction:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _getRatingText(_overallRating),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(child: _buildStarRatingBar(_overallRating, (val) => setState(() => _overallRating = val))),
                  const SizedBox(height: 12),

                  // Ease of navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ease of Navigation & UI:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      _buildStarRatingBar(_easeOfUseRating, (val) => setState(() => _easeOfUseRating = val)),
                    ],
                  ),

                  // Features
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Features & Functionality:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      _buildStarRatingBar(_featuresRating, (val) => setState(() => _featuresRating = val)),
                    ],
                  ),

                  // Speed & responsiveness
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Speed & Responsiveness:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      _buildStarRatingBar(_performanceRating, (val) => setState(() => _performanceRating = val)),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Text('System Module / Aspect:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      color: AppColors.background,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _systemAspect,
                        isExpanded: true,
                        items: _aspectLabels.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _systemAspect = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('What works well in the system?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _worksWellController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Career milestones tracking is clear, RSVP responses are instant...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('What improvements or bugs did you encounter?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _improvementsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Add PDF export for career timeline, send email notification on new events...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Would you recommend the portal to other alumni?',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _wouldRecommend,
                        activeColor: AppColors.primaryNavy,
                        onChanged: (val) => setState(() => _wouldRecommend = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmittingSurvey ? null : _submitSurvey,
                      child: _isSubmittingSurvey
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Survey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // History of past surveys
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Submitted Surveys',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                '${pastSurveys.length} submitted',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (pastSurveys.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No surveys submitted yet. Submit your first feedback above!',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastSurveys.length,
              itemBuilder: (context, index) {
                final s = pastSurveys[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 13, color: AppColors.primaryNavy),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${s.overallRating}/5 Rating',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.aspectDisplay,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(s.createdAt),
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        if (s.whatWorksWell.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Working well: ${s.whatWorksWell}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                        if (s.improvementsNeeded.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Suggestions: ${s.improvementsNeeded}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDeptFeedbackTab() {
    final commProvider = Provider.of<CommunicationProvider>(context);
    final feedbacks = commProvider.departmentFeedbacks;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: AppColors.primaryNavy, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Direct Department Feedback',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Share curriculum inputs, facilities suggestions, and partnership links.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  const Text('Category:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      color: AppColors.background,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _deptCategory,
                        isExpanded: true,
                        items: _deptCategories.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _deptCategory = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Subject:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _deptSubjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Industry curriculum recommendation: Cloud Architecture',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Message / Details:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _deptMessageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe your suggestion, resource proposal, or observation for the department...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmittingDept ? null : _submitDeptFeedback,
                      child: _isSubmittingDept
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit to DCS Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department Feedback History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                '${feedbacks.length} submitted',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (feedbacks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No department feedbacks submitted yet.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final fb = feedbacks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: fb.isReviewed ? AppColors.successBg : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                fb.isReviewed ? 'Reviewed ✓' : 'Under Review',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: fb.isReviewed ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fb.subject,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatDate(fb.createdAt),
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fb.message,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Header
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryNavy,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.accentGold,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.rate_review_outlined, size: 20),
                text: 'System Survey',
              ),
              Tab(
                icon: Icon(Icons.school_outlined, size: 20),
                text: 'Department Feedback',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSystemSurveyTab(),
              _buildDeptFeedbackTab(),
            ],
          ),
        ),
      ],
    );
  }
}
