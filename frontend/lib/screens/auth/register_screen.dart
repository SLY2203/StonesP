import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/msu_logo.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNumController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedGradYear = 2024;
  String _selectedProgramme = AppConstants.dcsProgrammes[0];

  bool _isLookingUp = false;
  Map<String, dynamic>? _verifiedRecord;
  String? _lookupError;
  bool _isNotInRoster = false;

  @override
  void dispose() {
    _regNumController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    final reg = _regNumController.text.trim().toUpperCase();
    if (reg.isEmpty) {
      setState(() => _lookupError = 'Please enter your student registration number.');
      return;
    }

    if (!RegExp(r'^R\d{4,6}[A-Z]$').hasMatch(reg)) {
      setState(() => _lookupError = 'Expected pattern: R followed by 4-6 digits and a letter (e.g. R201456B).');
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _verifiedRecord = null;
      _isNotInRoster = false;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.lookupGraduate(reg);

    if (!mounted) return;

    if (result != null && result['status'] == 'VERIFIED') {
      setState(() {
        _isLookingUp = false;
        _isNotInRoster = false;
        _verifiedRecord = result;
        _firstNameController.text = result['first_name'] ?? '';
        _lastNameController.text = result['last_name'] ?? '';
        _selectedGradYear = result['graduation_year'] ?? 2024;
        final prog = result['programme'] ?? '';
        if (AppConstants.dcsProgrammes.contains(prog)) {
          _selectedProgramme = prog;
        } else {
          _selectedProgramme = AppConstants.dcsProgrammes[0];
        }
      });
    } else if (result != null && result['status'] == 'NOT_IN_ROSTER') {
      setState(() {
        _isLookingUp = false;
        _isNotInRoster = true;
        _verifiedRecord = result;
        _lookupError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Department Administrator has been automatically notified about $reg.'),
          backgroundColor: AppColors.accentGold,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // If result is null or 404 from server, automatically alert admin and unlock registration
      setState(() {
        _isLookingUp = false;
        _isNotInRoster = true;
        _verifiedRecord = {'status': 'NOT_IN_ROSTER', 'registration_number': reg};
        _lookupError = null;
      });
      auth.requestVerification(
        registrationNumber: reg,
        message: 'Student attempted registration on mobile app; registration number was not found in graduation roster.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Department Administrator has been automatically notified about $reg.'),
          backgroundColor: AppColors.accentGold,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  bool _alertSent = false;

  void _showNotifyAdminDialog() {
    final reg = _regNumController.text.trim().toUpperCase();
    final nameCtrl = TextEditingController(text: '${_firstNameController.text} ${_lastNameController.text}'.trim());
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final noteCtrl = TextEditingController();
    int selectedGradYear = _selectedGradYear;
    String selectedProgramme = _selectedProgramme;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryNavy, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Notify Admin to Verify', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'If your registration number is not yet recognized on the roster, send an alert to the Department Administrator to verify your graduation records.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: reg),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Registration Number', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'e.g. Michael Sowa', prefixIcon: Icon(Icons.person_outline, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'e.g. msowa@gmail.com', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Message for Admin (optional)',
                        hintText: 'e.g. Graduated BSc Hons Computer Science in 2023.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isSubmitting ? 'Sending...' : 'Send Request'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your name and email address.')),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final success = await auth.requestVerification(
                          registrationNumber: reg,
                          fullName: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          graduationYear: selectedGradYear,
                          programme: selectedProgramme,
                          message: noteCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (success) {
                          setState(() => _alertSent = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notification sent to Administrator for $reg! Staff will verify your record.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(auth.errorMessage ?? 'Failed to send notification.'),
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

  Future<void> _handleRegister() async {
    if (_verifiedRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your registration number against the graduation database first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isNotInRoster) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your first and last name.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.registerAlumni(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      registrationNumber: _regNumController.text.trim().toUpperCase(),
      graduationYear: _selectedGradYear,
      programme: _selectedProgramme,
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (auth.currentUser?.isVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful & automatically verified against the graduation database! Please log in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account submitted! Administrator has been alerted to review and verify your record.'),
            backgroundColor: AppColors.primaryNavy,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed. Check inputs.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alumni Registration'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: MsuLogo(size: 64, showBorder: true, borderRadius: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Midlands State University',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const Text(
                      'Department of Computer Science',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Step 1: Graduate Database Verification
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _verifiedRecord != null
                              ? AppColors.success.withOpacity(0.5)
                              : AppColors.border,
                          width: _verifiedRecord != null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.school, size: 18, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Step 1: Verify Graduate Record',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your official student registration number to validate against the DCS Graduation Database.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _regNumController,
                                  label: 'Registration Number',
                                  hint: 'e.g. R210045K',
                                  prefixIcon: Icons.badge_outlined,
                                  textCapitalization: TextCapitalization.characters,
                                  enabled: _verifiedRecord == null,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Registration number is required';
                                    final reg = v.trim().toUpperCase();
                                    if (!RegExp(r'^R\d{4,6}[A-Z]$').hasMatch(reg)) {
                                      return 'Format: R followed by 4-6 digits and a letter';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: _verifiedRecord == null
                                    ? ElevatedButton(
                                        onPressed: _isLookingUp ? null : _handleLookup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryNavy,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: _isLookingUp
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                                        tooltip: 'Change registration number',
                                        onPressed: () {
                                          setState(() {
                                            _verifiedRecord = null;
                                            _lookupError = null;
                                            _isNotInRoster = false;
                                            _firstNameController.clear();
                                            _lastNameController.clear();
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),

                          // Lookup error alert
                          if (_lookupError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _lookupError!,
                                          style: const TextStyle(fontSize: 12, color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_alertSent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                          SizedBox(width: 6),
                                          Text('Verification request sent to Administrator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                                        ],
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryNavy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.notifications_active_rounded, size: 15),
                                      label: const Text('Notify Admin to Verify My Record', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: _showNotifyAdminDialog,
                                    ),
                                ],
                              ),
                            ),
                          ],

                          // Not in roster auto-notification card
                          if (_verifiedRecord != null && _isNotInRoster) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accentGold.withOpacity(0.6)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryNavy,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Administrator Automatically Notified',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Registration number \'${_regNumController.text.trim().toUpperCase()}\' was not found in the DCS graduation database.\n\nAn alert has been dispatched directly to the Department Administrator for record verification. Please complete your details below so your account can be submitted for review.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Verified record card
                          if (_verifiedRecord != null && !_isNotInRoster) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.successBg.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.success.withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Graduate Record Confirmed',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Text(
                                    _verifiedRecord!['full_name'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_verifiedRecord!['programme']} • Class of ${_verifiedRecord!['graduation_year']}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  if (_verifiedRecord!['degree_class'] != null && _verifiedRecord!['degree_class'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Classification: ${_verifiedRecord!['degree_class']}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Name & degree details are locked to the official roster record.',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Step 2: Account Credentials & Details
                    if (_verifiedRecord != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.lock_person, size: 18, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isNotInRoster ? 'Step 2: Enter Details & Credentials' : 'Step 2: Create Account Credentials',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_isNotInRoster) ...[
                              CustomTextField(
                                controller: _firstNameController,
                                label: 'First Name *',
                                hint: 'e.g. Tinashe',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                              ),
                              const SizedBox(height: 14),

                              CustomTextField(
                                controller: _lastNameController,
                                label: 'Last Name *',
                                hint: 'e.g. Moyo',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: _selectedProgramme,
                                decoration: InputDecoration(
                                  labelText: 'Degree Programme',
                                  prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primaryNavy),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.surfaceElevated,
                                ),
                                isExpanded: true,
                                items: AppConstants.dcsProgrammes
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedProgramme = val);
                                },
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<int>(
                                value: _selectedGradYear,
                                decoration: InputDecoration(
                                  labelText: 'Graduation Year',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryNavy),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.surfaceElevated,
                                ),
                                items: List.generate(26, (i) => 2000 + i)
                                    .reversed
                                    .map((yr) => DropdownMenuItem(value: yr, child: Text(yr.toString())))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGradYear = val);
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

                            CustomTextField(
                              controller: _emailController,
                              label: 'Personal / Work Email *',
                              hint: 'e.g. tinashe.moyo@gmail.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
                            ),
                            const SizedBox(height: 14),

                            CustomTextField(
                              controller: _passwordController,
                              label: 'Choose Password *',
                              hint: 'Minimum 6 characters',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                            ),
                            const SizedBox(height: 14),

                            CustomTextField(
                              controller: _phoneController,
                              label: 'Phone Number (Optional)',
                              hint: '+263 77 123 4567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),

                            CustomButton(
                              text: _isNotInRoster ? 'Submit Account for Review' : 'Complete & Activate Account',
                              isLoading: auth.isLoading,
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
