import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/career_model.dart';
import '../../providers/career_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditCareerScreen extends StatefulWidget {
  final CareerRecordModel? existingRecord;

  const AddEditCareerScreen({super.key, this.existingRecord});

  @override
  State<AddEditCareerScreen> createState() => _AddEditCareerScreenState();
}

class _AddEditCareerScreenState extends State<AddEditCareerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _employerController;
  late TextEditingController _descController;
  late TextEditingController _furtherInstController;
  late TextEditingController _furtherProgController;
  late TextEditingController _skillsController;

  String _employmentStatus = 'EMPLOYED';
  String _industrySector = AppConstants.industrySectors[0];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime? _endDate;
  bool _isCurrent = true;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final rec = widget.existingRecord;
    _titleController = TextEditingController(text: rec?.jobTitle ?? '');
    _employerController = TextEditingController(text: rec?.employer ?? '');
    _descController = TextEditingController(text: rec?.description ?? '');
    _furtherInstController = TextEditingController(text: rec?.furtherEducationInstitution ?? '');
    _furtherProgController = TextEditingController(text: rec?.furtherEducationProgramme ?? '');
    _skillsController = TextEditingController(text: rec?.skillsUsed ?? '');

    if (rec != null) {
      _employmentStatus = rec.employmentStatus;
      _industrySector = rec.industrySector;
      _isCurrent = rec.isCurrent;
      try {
        _startDate = DateTime.parse(rec.startDate);
      } catch (_) {}
      if (rec.endDate != null) {
        try {
          _endDate = DateTime.parse(rec.endDate!);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _employerController.dispose();
    _descController.dispose();
    _furtherInstController.dispose();
    _furtherProgController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CareerProvider>(context, listen: false);
    final record = CareerRecordModel(
      id: widget.existingRecord?.id ?? 0,
      jobTitle: _titleController.text.trim(),
      employer: _employerController.text.trim(),
      employmentStatus: _employmentStatus,
      statusDisplay: AppConstants.employmentStatusMap[_employmentStatus] ?? _employmentStatus,
      industrySector: _industrySector,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: (_isCurrent || _endDate == null) ? null : DateFormat('yyyy-MM-dd').format(_endDate!),
      isCurrent: _isCurrent,
      furtherEducationInstitution: _employmentStatus == 'FURTHER_STUDIES' ? _furtherInstController.text.trim() : null,
      furtherEducationProgramme: _employmentStatus == 'FURTHER_STUDIES' ? _furtherProgController.text.trim() : null,
      description: _descController.text.trim(),
      skillsUsed: _skillsController.text.trim(),
    );

    bool success;
    if (isEditing) {
      success = await provider.updateCareerRecord(widget.existingRecord!.id, record);
    } else {
      success = await provider.addCareerRecord(record);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Position updated successfully' : 'Milestone added to timeline'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save position'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CareerProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Career Position' : 'Add Career Milestone'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _titleController,
                    label: 'Job Title / Role',
                    hint: 'e.g. Senior Software Engineer, IT Officer',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Job title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _employerController,
                    label: 'Employer / Company Name',
                    hint: 'e.g. EcoCash, Econet, Freelance',
                    prefixIcon: Icons.business_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Employer is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Employment Status Dropdown
                  const Text(
                    'Employment Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _employmentStatus,
                    isExpanded: true,
                    items: AppConstants.employmentStatusMap.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _employmentStatus = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Industry Dropdown
                  const Text(
                    'Industry Sector',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _industrySector,
                    isExpanded: true,
                    items: AppConstants.industrySectors.map((ind) {
                      return DropdownMenuItem(value: ind, child: Text(ind, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _industrySector = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // If Further Studies, show postgrad fields
                  if (_employmentStatus == 'FURTHER_STUDIES') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Further Education Details',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _furtherInstController,
                            label: 'Institution Name',
                            hint: 'e.g. Midlands State University',
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _furtherProgController,
                            label: 'Degree / Programme',
                            hint: 'e.g. MSc in Artificial Intelligence',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Currently holding role switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I currently hold this role',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    value: _isCurrent,
                    activeColor: AppColors.primaryNavy,
                    onChanged: (val) => setState(() => _isCurrent = val),
                  ),
                  const SizedBox(height: 10),

                  // Date Pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            'Start: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _pickDate(true),
                        ),
                      ),
                      if (!_isCurrent) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_busy_rounded, size: 16),
                            label: Text(
                              _endDate != null ? 'End: ${DateFormat('yyyy-MM-dd').format(_endDate!)}' : 'Set End Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _skillsController,
                    label: 'Technologies & Skills Used (comma separated)',
                    hint: 'e.g. Flutter, Django, PostgreSQL, Docker, AWS',
                    prefixIcon: Icons.psychology_outlined,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      'Python', 'Flutter', 'Django', 'PostgreSQL', 'Docker', 'AWS', 'React', 'Linux'
                    ].map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.surfaceElevated,
                      onPressed: () {
                        final current = _skillsController.text.trim();
                        if (!current.toLowerCase().contains(s.toLowerCase())) {
                          _skillsController.text = current.isEmpty ? s : '$current, $s';
                        }
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _descController,
                    label: 'Description & Achievements (Optional)',
                    hint: 'Summarize key projects, responsibilities, and achievements...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: isEditing ? 'Update Position' : 'Add to Timeline',
                    isLoading: provider.isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
