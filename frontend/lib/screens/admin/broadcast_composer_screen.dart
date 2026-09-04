import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/communication_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BroadcastComposerScreen extends StatefulWidget {
  const BroadcastComposerScreen({super.key});

  @override
  State<BroadcastComposerScreen> createState() => _BroadcastComposerScreenState();
}

class _BroadcastComposerScreenState extends State<BroadcastComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedCategory = 'ANNOUNCEMENT';
  int? _targetYear;
  DateTime? _eventDate;
  DateTime? _deadlineDate;

  final Map<String, String> _categories = {
    'ANNOUNCEMENT': 'Department Announcement',
    'EVENT': 'Alumni Event & Reunion',
    'JOB_VACANCY': 'Career / Job Opportunity',
    'MENTORSHIP': 'Mentorship Initiative',
  };

  final List<int> _years = [0, 2026, 2025, 2024, 2023, 2022, 2021, 2020];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isEvent) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      final dt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 0,
        pickedTime?.minute ?? 0,
      );
      setState(() {
        if (isEvent) {
          _eventDate = dt;
        } else {
          _deadlineDate = dt;
        }
      });
    }
  }

  Future<void> _publishBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    final commProvider = Provider.of<CommunicationProvider>(context, listen: false);
    final payload = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'category': _selectedCategory,
      'target_graduation_year': (_targetYear == null || _targetYear == 0) ? null : _targetYear,
      'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      'external_link': _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null,
      'event_date': _eventDate?.toIso8601String(),
      'application_deadline': _deadlineDate?.toIso8601String(),
    };

    final success = await commProvider.createBroadcast(payload);

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _contentController.clear();
      _locationController.clear();
      _linkController.clear();
      setState(() {
        _eventDate = null;
        _deadlineDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast published and push notifications dispatched! 🚀'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commProvider.errorMessage ?? 'Failed to send broadcast'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commProvider = Provider.of<CommunicationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Push Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: AppColors.accentGold, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Push Notification Dispatcher',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Posts trigger instant alerts to alumni devices via Firebase Cloud Messaging.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Category Selection
                  const Text('COMMUNICATION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _titleController,
                    label: 'Headline / Title',
                    hint: 'e.g. 2026 Innovation Hackathon Registration Open',
                    prefixIcon: Icons.title_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Target Cohort
                  const Text('TARGET COHORT (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _targetYear ?? 0,
                    items: _years.map((y) {
                      return DropdownMenuItem(value: y, child: Text(y == 0 ? 'Broadcast to All Cohorts' : 'Class of $y Only', style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _targetYear = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Event Specific fields
                  if (_selectedCategory == 'EVENT') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_rounded, size: 16),
                            label: Text(
                              _eventDate != null ? DateFormat('d MMM yyyy, h:mm a').format(_eventDate!) : 'Pick Event Date & Time',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickDateTime(true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Venue / Virtual Link',
                      hint: 'e.g. Great Hall, MSU Gweru or Zoom link',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Job Specific fields
                  if (_selectedCategory == 'JOB_VACANCY') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.alarm_rounded, size: 16),
                            label: Text(
                              _deadlineDate != null ? 'Deadline: ${DateFormat('d MMM yyyy').format(_deadlineDate!)}' : 'Pick Application Deadline',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickDateTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  CustomTextField(
                    controller: _linkController,
                    label: 'External Link / Registration URL (Optional)',
                    hint: 'https://...',
                    prefixIcon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _contentController,
                    label: 'Announcement Body / Details',
                    hint: 'Write full information, instructions, and requirements...',
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Content body is required' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Publish & Dispatch Broadcast',
                    icon: Icons.send_rounded,
                    isLoading: commProvider.isLoading,
                    onPressed: _publishBroadcast,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
