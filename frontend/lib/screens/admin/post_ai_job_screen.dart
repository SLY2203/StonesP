import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/job_service.dart';

class PostAiJobScreen extends StatefulWidget {
  const PostAiJobScreen({super.key});

  @override
  State<PostAiJobScreen> createState() => _PostAiJobScreenState();
}

class _PostAiJobScreenState extends State<PostAiJobScreen> {
  final JobService _jobService = JobService();
  final _rawAdvertController = TextEditingController();

  // Editable Extracted Fields
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _urlController = TextEditingController();

  String _experienceLevel = 'ANY';
  String _jobType = 'FULL_TIME';
  String _industrySector = 'Software & IT Services';

  bool _isExtracting = false;
  bool _isPublishing = false;
  int? _draftJobId;
  Map<String, dynamic>? _matchResults;

  final List<String> _experienceLevels = [
    'ENTRY',
    'JUNIOR',
    'MID',
    'SENIOR',
    'LEAD',
    'ANY',
  ];

  final List<String> _jobTypes = [
    'FULL_TIME',
    'PART_TIME',
    'CONTRACT',
    'INTERNSHIP',
    'REMOTE',
  ];

  final List<String> _industries = [
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

  @override
  void dispose() {
    _rawAdvertController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    _qualificationsController.dispose();
    _responsibilitiesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _extractWithAi() async {
    final rawText = _rawAdvertController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a job vacancy advert first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isExtracting = true);
    try {
      final res = await _jobService.extractJobFromAdvert(rawText);
      final fields = res['ai_extracted_fields'] ?? {};
      final job = res['job'] ?? {};

      setState(() {
        _draftJobId = job['id'];
        _titleController.text = fields['title'] ?? '';
        _companyController.text = fields['company'] ?? '';
        _locationController.text = fields['location'] ?? '';
        _salaryController.text = fields['salary_range'] ?? '';
        _skillsController.text = fields['required_skills'] ?? '';
        _qualificationsController.text = fields['qualifications'] ?? '';
        _responsibilitiesController.text = fields['responsibilities'] ?? '';
        _urlController.text = fields['application_url'] ?? '';

        if (_experienceLevels.contains(fields['experience_level'])) {
          _experienceLevel = fields['experience_level'];
        }
        if (_jobTypes.contains(fields['job_type'])) {
          _jobType = fields['job_type'];
        }
        if (_industries.contains(fields['industry_sector'])) {
          _industrySector = fields['industry_sector'];
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI extraction complete! Please review and refine the fields below.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extraction failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _publishAndMatch() async {
    if (_draftJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please extract and verify the job details first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final res = await _jobService.publishJobAndMatch(_draftJobId!);
      if (!mounted) return;
      setState(() => _matchResults = res);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 Published! ${res['total_matches']} alumni matched.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publishing failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Job Vacancy Extractor & Matcher'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20),
                _buildRawAdvertInput(),
                const SizedBox(height: 20),
                if (_titleController.text.isNotEmpty || _draftJobId != null) ...[
                  _buildExtractedDetailsForm(),
                  const SizedBox(height: 20),
                  _buildPublishSection(),
                ],
                if (_matchResults != null) ...[
                  const SizedBox(height: 24),
                  _buildMatchResultsView(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryNavyDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objective 3: AI-Based Job Matching',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Paste an unstructured vacancy advert below. AI will extract structured requirements and match against verified DCS alumni profiles.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawAdvertInput() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raw Job Advert Text',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Paste job post from LinkedIn, WhatsApp message, email, or newspaper clipping:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rawAdvertController,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'e.g. "We are looking for a Senior Flutter & Python Developer at Cassava Smartech in Harare. Must have 3+ years experience with REST APIs, PostgreSQL, and cloud deployments..."',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExtracting ? null : _extractWithAi,
              icon: _isExtracting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.psychology_rounded, color: Colors.white),
              label: Text(
                _isExtracting ? 'Analyzing with AI...' : 'Extract Job Details with AI',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Extracted & Structured Fields',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Review and fine-tune extracted attributes before matching:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Job Title *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    labelText: 'Hiring Company *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Remote',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _skillsController,
            decoration: InputDecoration(
              labelText: 'Required Skills (Comma separated)',
              hintText: 'e.g. Flutter, Dart, Python, Django, PostgreSQL, Docker',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.code_rounded),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _experienceLevel,
                  decoration: InputDecoration(
                    labelText: 'Experience Level',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _experienceLevels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _experienceLevel = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _jobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _jobTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _jobType = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _industrySector,
            decoration: InputDecoration(
              labelText: 'Industry Sector',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.domain),
            ),
            items: _industries.map((ind) => DropdownMenuItem(value: ind, child: Text(ind, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _industrySector = v!),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary Range',
                    hintText: 'e.g. \$1,200 - \$2,000 / mo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Application URL / Email',
                    hintText: 'https:// or jobs@company.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublishSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to Publish & Match',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavyDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Publishing will make this job visible to verified alumni and automatically run the matching engine to score candidate alumni profiles.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishAndMatch,
              icon: _isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.rocket_launch_rounded, color: Colors.white),
              label: Text(
                _isPublishing ? 'Matching Alumni...' : 'Publish Vacancy & Run Matching Engine',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchResultsView() {
    final topMatches = _matchResults?['top_matches'] as List? ?? [];
    final total = _matchResults?['total_matches'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Match Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$total Alumni Matched', style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topMatches.isEmpty)
            const Text('No alumni met the minimum match threshold (30%).')
          else
            ...topMatches.map((m) {
              final score = m['score'] ?? 0;
              final name = m['alumnus_name'] ?? 'Alumnus';
              final overlap = m['skills_overlap'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: score >= 75 ? AppColors.success : (score >= 50 ? AppColors.warning : AppColors.info),
                      child: Text('$score%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (overlap.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Matching skills: $overlap', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
