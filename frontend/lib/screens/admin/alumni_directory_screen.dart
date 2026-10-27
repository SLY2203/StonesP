import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/alumni_provider.dart';
import '../../models/profile_model.dart';
import '../../models/roster_model.dart';
import 'alumni_detail_verification_screen.dart';

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _rosterSearchController = TextEditingController();

  String _filterStatus = 'ALL'; // 'ALL', 'PENDING', 'VERIFIED'
  int? _selectedYear;
  String? _selectedSkill;

  final List<int> _years = [0, 2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018];
  final List<String> _popularSkills = ['All Skills', 'Python', 'Flutter', 'Django', 'AWS', 'PostgreSQL', 'Docker', 'React'];

  final List<String> _programmes = [
    'BSc Hons Computer Science',
    'BSc Hons Information Systems',
    'BSc Hons Information Technology',
    'BSc Hons Software Engineering',
    'BSc Hons Cybersecurity & Digital Forensics',
    'MSc Information Technology',
    'MPhil / PhD Computer Science',
    'Other DCS Programme',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        final provider = Provider.of<AlumniProvider>(context, listen: false);
        if (provider.rosterRecords.isEmpty) {
          provider.fetchGraduationRoster();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _rosterSearchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    bool? isVer;
    if (_filterStatus == 'PENDING') isVer = false;
    if (_filterStatus == 'VERIFIED') isVer = true;

    final skill = (_selectedSkill == null || _selectedSkill == 'All Skills') ? null : _selectedSkill;

    provider.fetchDirectory(
      q: _searchController.text.trim(),
      skill: skill,
      gradYear: _selectedYear == 0 ? null : _selectedYear,
      isVerified: isVer,
    );
  }

  void _applyRosterFilter() {
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    provider.fetchGraduationRoster(q: _rosterSearchController.text.trim());
  }

  // ===========================================================================
  // ADD ALUMNUS DIALOG (Direct Database Insertion)
  // ===========================================================================
  void _showAddAlumnusDialog() {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final regNumCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'MsuAlumni@2025');
    final jobTitleCtrl = TextEditingController();
    final employerCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    int selectedGradYear = DateTime.now().year;
    String selectedProgramme = _programmes[0];
    bool isVerified = true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryNavy, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Add Alumnus to Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                      Text('Create official alumnus account & profile in DB', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(dialogError!, style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Section 1: Graduate Identity
                      _buildSectionLabel('1. Graduate Identity & Account'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameCtrl,
                              decoration: const InputDecoration(labelText: 'First Name *', hintText: 'e.g. Tendai'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameCtrl,
                              decoration: const InputDecoration(labelText: 'Last Name *', hintText: 'e.g. Moyo'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'tendai.moyo@gmail.com', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: passwordCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Initial Password',
                                hintText: 'MsuAlumni@2025',
                                prefixIcon: Icon(Icons.lock_outline, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+263 77 123 4567', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Academic Record
                      _buildSectionLabel('2. Academic & DCS Record'),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: regNumCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(labelText: 'MSU Reg Number *', hintText: 'e.g. R201456B', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Reg # required';
                                final reg = v.trim().toUpperCase();
                                if (!RegExp(r'^R\d{4,6}[A-Z]$').hasMatch(reg)) {
                                  return 'Format: R123456B';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              value: selectedGradYear,
                              decoration: const InputDecoration(labelText: 'Grad Year'),
                              items: List.generate(20, (i) => 2026 - i).map((y) {
                                return DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedGradYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: selectedProgramme,
                        decoration: const InputDecoration(labelText: 'Programme *', prefixIcon: Icon(Icons.school_outlined, size: 18)),
                        isExpanded: true,
                        items: _programmes.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedProgramme = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Professional Info (Optional)
                      _buildSectionLabel('3. Professional & Career Details (Optional)'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: jobTitleCtrl,
                              decoration: const InputDecoration(labelText: 'Current Job Title', hintText: 'e.g. Software Engineer'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: employerCtrl,
                              decoration: const InputDecoration(labelText: 'Employer / Company', hintText: 'e.g. Econet Wireless'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: skillsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Key Skills (comma-separated)',
                          hintText: 'e.g. Python, Flutter, Django, PostgreSQL, Docker',
                          prefixIcon: Icon(Icons.code_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 4: Verification Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_rounded, size: 22, color: isVerified ? AppColors.success : AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Mark as Verified Alumnus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                                  Text('Alumnus can immediately log in and participate as verified', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isVerified,
                              activeColor: AppColors.success,
                              onChanged: (val) => setDialogState(() => isVerified = val),
                            ),
                          ],
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(isSubmitting ? 'Saving to DB...' : 'Save Alumnus'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        final provider = Provider.of<AlumniProvider>(context, listen: false);
                        final payload = {
                          'first_name': firstNameCtrl.text.trim(),
                          'last_name': lastNameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'password': passwordCtrl.text.trim().isEmpty ? 'MsuAlumni@2025' : passwordCtrl.text.trim(),
                          'registration_number': regNumCtrl.text.trim().toUpperCase(),
                          'graduation_year': selectedGradYear,
                          'programme': selectedProgramme,
                          'phone_number': phoneCtrl.text.trim(),
                          'current_job_title': jobTitleCtrl.text.trim(),
                          'current_employer': employerCtrl.text.trim(),
                          'skills': skillsCtrl.text.trim(),
                          'is_verified': isVerified,
                        };

                        final success = await provider.createAlumnus(payload);
                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Alumnus ${firstNameCtrl.text} ${lastNameCtrl.text} (${regNumCtrl.text.toUpperCase()}) added to database successfully!'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = provider.errorMessage ?? 'Failed to add alumnus. Please verify credentials.';
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ADD GRADUATION ROSTER RECORD DIALOG
  // ===========================================================================
  void _showAddRosterDialog() {
    final formKey = GlobalKey<FormState>();
    final regNumCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    int selectedGradYear = DateTime.now().year;
    String selectedProgramme = _programmes[0];
    String selectedClass = 'Pass';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.school_rounded, color: AppColors.primaryNavy),
                SizedBox(width: 8),
                Text('Add Graduation Record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: regNumCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Registration Number *', hintText: 'e.g. R215420X'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Graduate Name *', hintText: 'e.g. Tinashe Chigumba'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedGradYear,
                            decoration: const InputDecoration(labelText: 'Year'),
                            items: List.generate(20, (i) => 2026 - i).map((y) {
                              return DropdownMenuItem(value: y, child: Text('$y'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedGradYear = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: const InputDecoration(labelText: 'Degree Class'),
                            items: ['First Class', '2.1 (Upper Second)', '2.2 (Lower Second)', 'Pass', 'Distinction', 'Merit'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)));
                            }).toList>,
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedClass = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedProgramme,
                      decoration: const InputDecoration(labelText: 'Programme'),
                      isExpanded: true,
                      items: _programmes.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedProgramme = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        final provider = Provider.of<AlumniProvider>(context, listen: false);
                        final success = await provider.addRosterRecord({
                          'registration_number': regNumCtrl.text.trim().toUpperCase(),
                          'full_name': fullNameCtrl.text.trim(),
                          'graduation_year': selectedGradYear,
                          'programme': selectedProgramme,
                          'degree_class': selectedClass,
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Graduation roster record added!'), backgroundColor: AppColors.success),
                          );
                        }
                      },
                child: const Text('Add Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRosterAutoVerifyDialog() {
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 8),
            Text('Graduation Roster Verify', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Match all currently pending alumni against the official DCS Graduation Roster records in the database.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            SizedBox(height: 12),
            Text(
              '• Alumni with authentic graduation registration numbers (e.g. R208899B) will be verified automatically.\n• Any unrecognized registrations remain pending for manual review.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Run Auto-Verify'),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await provider.autoVerifyPendingAlumni();
                if (mounted) {
                  final verifiedCount = result['verified_count'] ?? 0;
                  final verifiedList = (result['verified_alumni'] as List?)?.join(', ') ?? '';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(verifiedCount > 0
                          ? 'Auto-verified $verifiedCount alumni: $verifiedList'
                          : 'No pending accounts matched the official graduation roster.'),
                      backgroundColor: verifiedCount > 0 ? AppColors.success : AppColors.primaryNavy,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification check failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy, letterSpacing: 0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumniProvider = Provider.of<AlumniProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(_tabController.index == 0 ? Icons.person_add_alt_1_rounded : Icons.school_rounded, size: 20),
        label: Text(
          _tabController.index == 0 ? 'Add Alumnus' : 'Add Graduate',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddAlumnusDialog();
          } else {
            _showAddRosterDialog();
          }
        },
      ),
      body: Column(
        children: [
          // Top Navigation & Database Tab Switcher
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Top Title & Primary Action Buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storage_rounded, size: 20, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Alumni Database', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        Text('Manage graduates & verified profiles', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    // Top Add Alumnus Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Alumnus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _showAddAlumnusDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Database Tabs (Alumni Profiles vs Official Roster Database)
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryNavy,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.accentGold,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 17),
                          const SizedBox(width: 6),
                          const Text('Alumni Profiles'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('${alumniProvider.directory.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 17),
                          const SizedBox(width: 6),
                          const Text('Graduation Roster DB'),
                          const SizedBox(width: 6),
                          if (alumniProvider.rosterRecords.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                              child: Text('${alumniProvider.rosterRecords.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlumniProfilesTab(alumniProvider),
                _buildGraduationRosterTab(alumniProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ALUMNI PROFILES DIRECTORY
  // ===========================================================================
  Widget _buildAlumniProfilesTab(AlumniProvider alumniProvider) {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input & Auto-Verify Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _applyFilter(),
                      decoration: InputDecoration(
                        hintText: 'Search by name, reg #, employer, or skill...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilter();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Auto-verify pending against Graduation Roster DB',
                    child: InkWell(
                      onTap: _showRosterAutoVerifyDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentGold),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.bolt_rounded, size: 18, color: AppColors.primaryNavy),
                            SizedBox(width: 4),
                            Text('Auto-Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Chips + Year Filter
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip('All (${alumniProvider.directory.length})', 'ALL'),
                          const SizedBox(width: 6),
                          _buildStatusChip('⏳ Pending', 'PENDING'),
                          const SizedBox(width: 6),
                          _buildStatusChip('✅ Verified', 'VERIFIED'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Year Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear ?? 0,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                        items: _years.map((y) {
                          return DropdownMenuItem(
                            value: y,
                            child: Text(y == 0 ? 'Any Year' : '$y'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedYear = val);
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Skills quick-filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularSkills.map((sk) {
                    final isSelected = (_selectedSkill == sk) || (_selectedSkill == null && sk == 'All Skills');
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(sk, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryNavy,
                        backgroundColor: AppColors.surfaceElevated,
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onSelected: (val) {
                          setState(() {
                            _selectedSkill = sk;
                          });
                          _applyFilter();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Alumni List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applyFilter(),
            child: alumniProvider.isLoading && alumniProvider.directory.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : alumniProvider.directory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No alumni match the filter criteria',
                              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('Add First Alumnus'),
                              onPressed: _showAddAlumnusDialog,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: alumniProvider.directory.length,
                        itemBuilder: (context, index) {
                          final item = alumniProvider.directory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AlumniDetailVerificationScreen(alumnusId: item.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primaryNavy,
                                      child: Text(
                                        item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.fullName,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                ),
                                              ),
                                              _buildVerificationBadge(item.isVerified),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item.registrationNumber} • Class of ${item.graduationYear}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            item.programme,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                          if (item.currentJobTitle != null && item.currentEmployer != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.work_outline, size: 13, color: AppColors.primaryNavy),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${item.currentJobTitle} at ${item.currentEmployer}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],

                                          if (item.skillsList.isNotEmpty || item.isAvailableForMentorship) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                if (item.isAvailableForMentorship)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentGold.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text('🤝 Mentor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                                                  ),
                                                ...item.skillsList.take(3).map((sk) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceElevated,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Text(sk, style: const TextStyle(fontSize: 10, color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                                                )),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: GRADUATION ROSTER DATABASE (Official MSU DCS Records)
  // ===========================================================================
  Widget _buildGraduationRosterTab(AlumniProvider alumniProvider) {
    return Column(
      children: [
        // Roster Search & Action Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rosterSearchController,
                  onSubmitted: (_) => _applyRosterFilter(),
                  decoration: InputDecoration(
                    hintText: 'Search roster by reg # or full graduate name...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _rosterSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _rosterSearchController.clear();
                              _applyRosterFilter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Graduate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _showAddRosterDialog,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Roster Record List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applyRosterFilter(),
            child: alumniProvider.isLoading && alumniProvider.rosterRecords.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : alumniProvider.rosterRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('No graduation roster records loaded', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => alumniProvider.fetchGraduationRoster(),
                              child: const Text('Load Graduation Records'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: alumniProvider.rosterRecords.length,
                        itemBuilder: (context, index) {
                          final rec = alumniProvider.rosterRecords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.school_rounded, color: AppColors.primaryNavy, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rec.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rec.degreeClass,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      rec.registrationNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy, fontSize: 12),
                                    ),
                                    const Text(' • '),
                                    Text('Class of ${rec.graduationYear}', style: const TextStyle(fontSize: 12)),
                                    const Text(' • '),
                                    Expanded(
                                      child: Text(
                                        rec.programme,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        if (val) {
          setState(() => _filterStatus = status);
          _applyFilter();
        }
      },
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
        child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
      child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
    );
  }
}
