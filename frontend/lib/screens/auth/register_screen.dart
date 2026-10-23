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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNumController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedGradYear = 2023;
  String _selectedProgramme = AppConstants.dcsProgrammes[0];

  final List<int> _years = List.generate(16, (i) => 2026 - i);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNumController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
      );
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
        title: const Text('Alumni Self-Registration'),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: MsuLogo(size: 64, showBorder: true, borderRadius: 16),
                    ),
                    const SizedBox(height: 16),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.info, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'To maintain database integrity, new registrations are reviewed and verified by DCS staff before full portal activation.',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryNavy, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personal details
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            hint: 'e.g. Tendai',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            hint: 'e.g. Moyo',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'your.name@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimum 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _regNumController,
                      label: 'MSU Registration Number',
                      hint: 'e.g. R201456B',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Registration number is required';
                        final reg = v.trim().toUpperCase();
                        if (!RegExp(r'^R\d{4,6}[A-Z]$').hasMatch(reg)) {
                          return 'Pattern: R followed by 4-6 digits & letter (e.g. R201456B)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Programme Dropdown
                    const Text(
                      'Degree Programme',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedProgramme,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: AppConstants.dcsProgrammes.map((prog) {
                        return DropdownMenuItem(
                          value: prog,
                          child: Text(prog, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProgramme = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Graduation Year Dropdown
                    const Text(
                      'Graduation Year',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedGradYear,
                      decoration: const InputDecoration(),
                      items: _years.map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text('Class of $y', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGradYear = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number (Optional)',
                      hint: '+263 77 123 4567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Submit Registration',
                      isLoading: auth.isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 16),
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
