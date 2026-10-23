import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/career_service.dart';

class TracerSurveyScreen extends StatefulWidget {
  const TracerSurveyScreen({super.key});

  @override
  State<TracerSurveyScreen> createState() => _TracerSurveyScreenState();
}

class _TracerSurveyScreenState extends State<TracerSurveyScreen> {
  final CareerService _careerService = CareerService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAlreadyCompleted = false;
  int _currentStep = 0;

  // Survey Form Fields
  bool _hadJobBeforeGraduation = false;
  int _monthsToFirstJob = 3;
  final TextEditingController _firstJobTitleController = TextEditingController();
  final TextEditingController _firstEmployerController = TextEditingController();
  String _firstJobSector = 'Software & IT Services';

  String _currentSalaryBand = '500_1000';
  String _degreeRelevance = 'HIGHLY_RELEVANT';
  String _jobSearchMethod = 'ONLINE_PORTAL';

  int _careerSatisfaction = 4;
  int _curriculumSatisfaction = 4;
  final TextEditingController _skillsGapController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  final List<String> _sectors = [
    'Software & IT Services',
    'FinTech & Banking',
    'Telecommunications',
    'E-Commerce & Retail',
    'Education & Research',
    'Mining & Energy',
    'Public Sector & Gov',
    'HealthTech & Medical',
    'Media & Creative',
    'Other Industry',
  ];

  final Map<String, String> _salaryBands = {
    'UNPAID': 'Unpaid / Internship / Volunteer',
    'BELOW_500': 'Below \$500 / month',
    '500_1000': '\$500 – \$1,000 / month',
    '1000_2000': '\$1,000 – \$2,000 / month',
    '2000_5000': '\$2,000 – \$5,000 / month',
    'ABOVE_5000': 'Above \$5,000 / month',
    'PREFER_NOT': 'Prefer not to say',
  };

  final Map<String, String> _relevanceOptions = {
    'HIGHLY_RELEVANT': 'Highly Relevant – Directly related to my DCS degree',
    'SOMEWHAT_RELEVANT': 'Somewhat Relevant – Partially related to IT / CS',
    'NOT_RELEVANT': 'Not Relevant – Unrelated to my degree',
    'NOT_APPLICABLE': 'Not Applicable – Currently not employed',
  };

  final Map<String, String> _searchMethods = {
    'ONLINE_PORTAL': 'Online Job Portal (LinkedIn, Indeed, etc.)',
    'REFERRAL': 'Alumni Referral / Personal Networking',
    'CAMPUS_RECRUITMENT': 'Campus Career Fair / DCS Placement',
    'DIRECT_APPLICATION': 'Direct Cold Application to Employer',
    'STARTED_OWN': 'Started Own Company / Freelancing',
    'FURTHER_STUDIES': 'Pursued Further / Postgraduate Studies',
    'OTHER': 'Other Method',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingSurvey();
  }

  @override
  void dispose() {
    _firstJobTitleController.dispose();
    _firstEmployerController.dispose();
    _skillsGapController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSurvey() async {
    setState(() => _isLoading = true);
    final data = await _careerService.getMyTracerSurvey();
    if (data != null && mounted) {
      setState(() {
        _hadJobBeforeGraduation = data['had_job_before_graduation'] ?? false;
        _monthsToFirstJob = data['months_to_first_job'] ?? 3;
        _firstJobTitleController.text = data['first_job_title'] ?? '';
        _firstEmployerController.text = data['first_employer'] ?? '';
        if (_sectors.contains(data['first_job_sector'])) {
          _firstJobSector = data['first_job_sector'];
        }
        _currentSalaryBand = data['current_salary_band'] ?? '500_1000';
        _degreeRelevance = data['degree_relevance'] ?? 'HIGHLY_RELEVANT';
        _jobSearchMethod = data['job_search_method'] ?? 'ONLINE_PORTAL';
        _careerSatisfaction = data['career_satisfaction'] ?? 4;
        _curriculumSatisfaction = data['curriculum_satisfaction'] ?? 4;
        _skillsGapController.text = data['skills_gap'] ?? '';
        _commentsController.text = data['additional_comments'] ?? '';
        _isAlreadyCompleted = data['is_complete'] ?? false;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'had_job_before_graduation': _hadJobBeforeGraduation,
        'months_to_first_job': _hadJobBeforeGraduation ? 0 : _monthsToFirstJob,
        'first_job_title': _firstJobTitleController.text.trim(),
        'first_employer': _firstEmployerController.text.trim(),
        'first_job_sector': _firstJobSector,
        'current_salary_band': _currentSalaryBand,
        'degree_relevance': _degreeRelevance,
        'job_search_method': _jobSearchMethod,
        'career_satisfaction': _careerSatisfaction,
        'curriculum_satisfaction': _curriculumSatisfaction,
        'skills_gap': _skillsGapController.text.trim(),
        'additional_comments': _commentsController.text.trim(),
        'is_complete': true,
      };

      await _careerService.submitTracerSurvey(payload);

      if (!mounted) return;
      setState(() => _isAlreadyCompleted = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Tracer Survey successfully submitted! Thank you for contributing to DCS outcomes research.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alumni Tracer Survey', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSurveyHeroHeader(),
                        const SizedBox(height: 16),
                        _buildStepProgress(),
                        const SizedBox(height: 20),
                        if (_currentStep == 0) _buildStepOneFirstJob(),
                        if (_currentStep == 1) _buildStepTwoSalaryRelevance(),
                        if (_currentStep == 2) _buildStepThreeSatisfaction(),
                        const SizedBox(height: 24),
                        _buildNavigationButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSurveyHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.primaryNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.poll_rounded, color: AppColors.accentGold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DCS Graduate Career Tracer',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isAlreadyCompleted ? 'Status: Completed (Editable anytime)' : 'Help us evaluate curriculum & employment outcomes',
                      style: TextStyle(
                        color: _isAlreadyCompleted ? AppColors.accentGold : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    final steps = ['1. First Job', '2. Relevance & Salary', '3. Satisfaction'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isSelected = _currentStep == index;
        final isDone = _currentStep > index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _currentStep = index),
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryNavy
                    : (isDone ? AppColors.successBg : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryNavy
                      : (isDone ? AppColors.success : AppColors.border),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDone ? AppColors.success : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepOneFirstJob() {
    return _buildCard(
      title: 'Post-Graduation First Job',
      subtitle: 'Tell us how quickly you transitioned into your first professional role.',
      icon: Icons.work_outline_rounded,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Employed Before Graduation?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text('Were you already working prior to completing your degree?'),
          activeColor: AppColors.accentGold,
          value: _hadJobBeforeGraduation,
          onChanged: (val) => setState(() => _hadJobBeforeGraduation = val),
        ),
        const Divider(height: 24),
        if (!_hadJobBeforeGraduation) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Months to First Job:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _monthsToFirstJob == 0
                      ? 'Immediate (< 1 mo)'
                      : '$_monthsToFirstJob months',
                  style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Slider(
            value: _monthsToFirstJob.toDouble(),
            min: 0,
            max: 24,
            divisions: 24,
            activeColor: AppColors.primaryNavy,
            label: '$_monthsToFirstJob mo',
            onChanged: (v) => setState(() => _monthsToFirstJob = v.round()),
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _firstJobTitleController,
          decoration: InputDecoration(
            labelText: 'First Job Title *',
            hintText: 'e.g. Junior Web Developer, IT Associate',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first job title' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstEmployerController,
          decoration: InputDecoration(
            labelText: 'First Employer / Company *',
            hintText: 'e.g. Econet Wireless, CBZ Bank, Freelance',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.business_rounded),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter employer name' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _firstJobSector,
          decoration: InputDecoration(
            labelText: 'Industry Sector',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.domain_rounded),
          ),
          items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _firstJobSector = val);
          },
        ),
      ],
    );
  }

  Widget _buildStepTwoSalaryRelevance() {
    return _buildCard(
      title: 'Degree Relevance & Salary Band',
      subtitle: 'Information is kept strictly confidential and used only in aggregate statistics.',
      icon: Icons.attach_money_rounded,
      children: [
        const Text('Degree Relevance to Work:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ..._relevanceOptions.entries.map((entry) {
          final isSelected = _degreeRelevance == entry.key;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryNavy.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryNavy : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: RadioListTile<String>(
              title: Text(entry.value, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              value: entry.key,
              groupValue: _degreeRelevance,
              activeColor: AppColors.primaryNavy,
              onChanged: (val) => setState(() => _degreeRelevance = val!),
            ),
          );
        }),
        const Divider(height: 24),
        DropdownButtonFormField<String>(
          value: _currentSalaryBand,
          decoration: InputDecoration(
            labelText: 'Current Monthly Compensation Band',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
          items: _salaryBands.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _currentSalaryBand = val);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _jobSearchMethod,
          decoration: InputDecoration(
            labelText: 'How did you find your first job?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.explore_outlined),
          ),
          items: _searchMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _jobSearchMethod = val);
          },
        ),
      ],
    );
  }

  Widget _buildStepThreeSatisfaction() {
    return _buildCard(
      title: 'Curriculum & Career Evaluation',
      subtitle: 'Your suggestions directly influence curriculum revisions for upcoming cohorts.',
      icon: Icons.rate_review_outlined,
      children: [
        _buildRatingSection(
          title: 'Career Trajectory Satisfaction',
          subtitle: 'How satisfied are you with your professional development so far?',
          value: _careerSatisfaction,
          onChanged: (v) => setState(() => _careerSatisfaction = v),
        ),
        const Divider(height: 24),
        _buildRatingSection(
          title: 'Curriculum Preparation Rating',
          subtitle: 'Did the DCS curriculum adequately equip you with real-world technical skills?',
          value: _curriculumSatisfaction,
          onChanged: (v) => setState(() => _curriculumSatisfaction = v),
        ),
        const Divider(height: 24),
        TextFormField(
          controller: _skillsGapController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Curriculum Skills Gap Recommendations',
            hintText: 'What tools, frameworks, or subjects do you wish were part of the DCS curriculum? (e.g. Docker, Cloud, DevOps, Flutter, CI/CD)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _commentsController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Any other comments / suggestions for the department?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection({
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: star <= value ? AppColors.accentGold : AppColors.border,
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryNavy, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _submitSurvey();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == 2 ? AppColors.success : AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentStep < 2 ? 'Continue' : (_isAlreadyCompleted ? 'Update Survey' : 'Submit Tracer Survey'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
