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
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.lookupGraduate(reg);

    if (!mounted) return;

    if (result != null && result['status'] == 'VERIFIED') {
      setState(() {
        _isLookingUp = false;
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
    } else {
      setState(() {
        _isLookingUp = false;
        _lookupError = auth.errorMessage ?? 'Student registration number was not found in the DCS Graduation Database.';
      });
    }
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
                              child: Row(
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
                            ),
                          ],

                          // Verified record card
                          if (_verifiedRecord != null) ...[
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

                    // Step 2: Account Credentials (visible when record verified)
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
                                const Text(
                                  'Step 2: Create Account Credentials',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            CustomTextField(
                              controller: _emailController,
                              label: 'Personal / Work Email',
                              hint: 'e.g. tinashe.moyo@gmail.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
                            ),
                            const SizedBox(height: 14),

                            CustomTextField(
                              controller: _passwordController,
                              label: 'Choose Password',
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
                              text: 'Complete & Activate Account',
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
