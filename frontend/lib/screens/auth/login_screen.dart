import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'pending_approval_screen.dart';
import '../alumni/alumni_home_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Role selection state: null = on Step 1 (Role Selection), 'ALUMNI' or 'ADMIN' = on Step 2 (Credentials)
  String? _selectedRole;
  String? _loadingDemoEmail;
  bool _showAllDemoAccounts = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _resetRole() {
    setState(() {
      _selectedRole = null;
      _emailController.clear();
      _passwordController.clear();
      _showAllDemoAccounts = false;
    });
  }

  void _fillDemo(String email, String password, String role) {
    setState(() {
      _selectedRole = role;
      _emailController.text = email;
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected ${role == "ADMIN" ? "Administrator" : "Alumnus"} role & filled $email.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryNavy,
      ),
    );
  }

  Future<void> _quickLogin(String email, String password, String role) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading || _loadingDemoEmail != null) return;

    setState(() {
      _selectedRole = role;
      _loadingDemoEmail = email;
      _emailController.text = email;
      _passwordController.text = password;
    });

    try {
      final success = await auth.login(email.trim(), password, role: role);

      if (!mounted) return;

      if (success) {
        if (auth.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        } else if (auth.isAlumnus) {
          if (auth.isVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlumniHomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Demo login failed. Check backend connection.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingDemoEmail = null;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      // Role mismatch protection
      if (_selectedRole == 'ADMIN' && !auth.isAdmin) {
        await auth.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access Denied: This account is registered as an Alumnus, not an Administrator. Please select the Alumni role.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_selectedRole == 'ALUMNI' && !auth.isAlumnus) {
        await auth.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access Denied: This account is a Department Staff account. Please select the Administrator role.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }


      if (auth.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else if (auth.isAlumnus) {
        if (auth.isVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AlumniHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed. Check your credentials.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showApiSettings() {
    final client = ApiClient();
    final urlController = TextEditingController(text: client.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Base URL Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or enter backend host:\n• Emulator: http://10.0.2.2:8000/api\n• Localhost / Windows: http://127.0.0.1:8000/api',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Backend URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              client.setBaseUrl(AppConstants.localApiUrl);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Switched to Localhost (127.0.0.1:8000)')),
              );
            },
            child: const Text('Set 127.0.0.1'),
          ),
          ElevatedButton(
            onPressed: () {
              client.setBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isRoleSelected = _selectedRole != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isRoleSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                tooltip: 'Back to Role Selection',
                onPressed: _resetRole,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryNavy),
            tooltip: 'Server Settings',
            onPressed: _showApiSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.accentGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/msu_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'MSU DCS Alumni Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    isRoleSelected
                        ? 'Department of Computer Science • Sign In'
                        : 'Department of Computer Science • Select Role',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step Progression Indicator
                  _buildStepIndicator(isRoleSelected),
                  const SizedBox(height: 20),

                  // Content switch: Step 1 (Role Selection) vs Step 2 (Credentials Form)
                  if (!isRoleSelected)
                    _buildStep1RoleSelection()
                  else
                    _buildStep2CredentialsForm(auth),

                  const SizedBox(height: 24),

                  // Quick Demo Accounts Section
                  _buildDemoSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Step Indicator Widget ---
  Widget _buildStepIndicator(bool isStep2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Step 1 node
          _buildStepNode(
            stepNumber: '1',
            label: 'Select Role',
            isActive: !isStep2,
            isCompleted: isStep2,
            onTap: isStep2 ? _resetRole : null,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isStep2 ? AppColors.accentGold : AppColors.border,
            ),
          ),
          // Step 2 node
          _buildStepNode(
            stepNumber: '2',
            label: 'Enter Credentials',
            isActive: isStep2,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required String stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final color = isActive
        ? AppColors.primaryNavy
        : (isCompleted ? AppColors.accentGold : AppColors.textMuted);

    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.accentGold
                : (isActive ? AppColors.primaryNavy : AppColors.border),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  stepNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: widget,
        ),
      );
    }
    return widget;
  }

  // --- Step 1: Role Selection Cards ---
  Widget _buildStep1RoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primaryNavyLight),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please select your portal role first before entering your login credentials.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Alumni Role Card
        _buildRoleSelectionCard(
          role: 'ALUMNI',
          title: 'DCS Alumnus / Graduate',
          badgeText: 'Alumni Portal',
          badgeColor: AppColors.info,
          badgeBg: AppColors.infoBg,
          icon: Icons.school_rounded,
          accentColor: AppColors.primaryNavy,
          description:
              'For graduates of Computer Science. Track career milestones, access mentorship, RSVP to events, and connect with fellow alumni.',
          features: [
            'Career progression timeline & profile',
            'Mentorship program & alumni directory',
            'Department events, reunions & job alerts',
          ],
        ),
        const SizedBox(height: 14),

        // Admin Role Card
        _buildRoleSelectionCard(
          role: 'ADMIN',
          title: 'Department Administrator',
          badgeText: 'Staff / Faculty',
          badgeColor: AppColors.primaryNavyDark,
          badgeBg: const Color(0xFFFEF3C7),
          icon: Icons.admin_panel_settings_rounded,
          accentColor: AppColors.accentGold,
          description:
              'For DCS departmental faculty and administrative staff. Manage alumni approvals, dispatch notices, and generate department reports.',
          features: [
            'Review and 1-tap verify alumni registrations',
            'Broadcast announcements, reunions & jobs',
            'Generate CSV & PDF departmental KPI reports',
          ],
        ),
        const SizedBox(height: 16),

        // Registration Callout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'New DCS Graduate? ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Register your profile here',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCard({
    required String role,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
    required Color accentColor,
    required String description,
    required List<String> features,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () => _selectRole(role),
        borderRadius: BorderRadius.circular(18),
        hoverColor: AppColors.surfaceElevated,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.25)),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role == 'ADMIN'
                              ? 'Staff & Faculty Access'
                              : 'Graduates & Alumni Access',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Select Role & Proceed',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Credentials Form ---
  Widget _buildStep2CredentialsForm(AuthProvider auth) {
    final isAdmin = _selectedRole == 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected Role Header Banner with Change Role button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdmin ? AppColors.accentGold.withOpacity(0.5) : const Color(0xFF93C5FD),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.school_rounded,
                    color: isAdmin ? AppColors.primaryNavyDark : AppColors.primaryNavy,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Administrator Portal' : 'Alumni Portal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isAdmin ? AppColors.primaryNavyDark : AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          isAdmin
                              ? 'Signing in as Department Staff'
                              : 'Signing in as DCS Alumnus',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetRole,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inline Role Selector Pills
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRoleTab(
                      label: '🎓 DCS Alumnus',
                      role: 'ALUMNI',
                      isSelected: !isAdmin,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildRoleTab(
                      label: '🛡️ Administrator',
                      role: 'ADMIN',
                      isSelected: isAdmin,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            CustomTextField(
              controller: _emailController,
              label: isAdmin ? 'Staff / Admin Email' : 'Alumni Email Address',
              hint: isAdmin ? 'admin@dcs.msu.ac.zw' : 'your.email@alumni.msu.ac.zw',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your email address' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 22),

            CustomButton(
              text: isAdmin ? 'Sign In as Administrator' : 'Sign In as Alumnus',
              isLoading: auth.isLoading && _loadingDemoEmail == null,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 16),

            // Secondary links based on role
            if (!isAdmin)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "New DCS Alumnus? ",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register here',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Center(
                child: Text(
                  'Department Staff accounts are managed by DCS Faculty.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required String label,
    required String role,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectRole(role),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- Demo Section with Role Awareness ---
  Widget _buildDemoSection() {
    final isRoleSelected = _selectedRole != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavyDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRoleSelected
                      ? (_selectedRole == 'ADMIN'
                          ? 'Demo Administrator Credentials'
                          : 'Demo Alumni Credentials')
                      : 'Quick Demo Logins',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                'Password: stones123',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isRoleSelected
                ? 'Accounts below match your selected ${_selectedRole == "ADMIN" ? "Administrator" : "Alumni"} role.'
                : 'Select an account below to auto-select its role and test the portal.',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Role-filtered demo accounts
          if (!isRoleSelected || _showAllDemoAccounts || _selectedRole == 'ADMIN') ...[
            _buildDemoCard(
              title: 'Prof. Tendai Marufu',
              subtitle: 'Department Admin / Coordinator',
              email: 'admin@dcs.msu.ac.zw',
              password: 'stones123',
              role: 'ADMIN',
              roleBadge: 'Admin Portal',
              badgeColor: AppColors.primaryNavy,
              badgeBgColor: const Color(0xFFDBEAFE),
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AppColors.primaryNavy,
              description: 'Alumni approvals, broadcast announcements & analytics.',
            ),
            if (!isRoleSelected || _showAllDemoAccounts) const SizedBox(height: 8),
          ],

          if (!isRoleSelected || _showAllDemoAccounts || _selectedRole == 'ALUMNI') ...[
            _buildDemoCard(
              title: 'Tinashe Moyo',
              subtitle: 'Senior Software Engineer (EcoCash)',
              email: 'tinashe.moyo@alumni.msu.ac.zw',
              password: 'stones123',
              role: 'ALUMNI',
              roleBadge: 'Verified Alumnus & Mentor',
              badgeColor: AppColors.success,
              badgeBgColor: AppColors.successBg,
              icon: Icons.verified_user_rounded,
              accentColor: AppColors.success,
              description: 'Full portal: career timeline, mentorship hub & RSVPs.',
            ),
            const SizedBox(height: 8),

            _buildDemoCard(
              title: 'Nyasha Chidambazina',
              subtitle: 'Cloud Solutions Engineer (AWS)',
              email: 'nyasha.chidambazina@alumni.msu.ac.zw',
              password: 'stones123',
              role: 'ALUMNI',
              roleBadge: 'Alumna & Mentee',
              badgeColor: const Color(0xFF6366F1),
              badgeBgColor: const Color(0xFFEEF2FF),
              icon: Icons.cloud_done_rounded,
              accentColor: const Color(0xFF6366F1),
              description: 'Active mentorship requests, certifications & directory.',
            ),
            const SizedBox(height: 8),

            _buildDemoCard(
              title: 'Blessing Munemo',
              subtitle: 'Graduate (Class of 2024)',
              email: 'blessing.munemo@alumni.msu.ac.zw',
              password: 'stones123',
              role: 'ALUMNI',
              roleBadge: 'Pending Verification',
              badgeColor: AppColors.warning,
              badgeBgColor: AppColors.warningBg,
              icon: Icons.pending_actions_rounded,
              accentColor: AppColors.warning,
              description: 'Demonstrates the pending verification & approval flow.',
            ),
          ],

          if (isRoleSelected) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAllDemoAccounts = !_showAllDemoAccounts;
                  });
                },
                child: Text(
                  _showAllDemoAccounts
                      ? 'Show only ${_selectedRole == "ADMIN" ? "Administrator" : "Alumni"} accounts'
                      : 'Show all demo accounts',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String subtitle,
    required String email,
    required String password,
    required String role,
    required String roleBadge,
    required Color badgeColor,
    required Color badgeBgColor,
    required IconData icon,
    required Color accentColor,
    required String description,
  }) {
    final isLoggingIn = _loadingDemoEmail == email;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoggingIn ? null : () => _quickLogin(email, password, role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLoggingIn ? accentColor : AppColors.border,
              width: isLoggingIn ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleBadge,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Action Buttons
                  if (isLoggingIn)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Select role and fill credentials',
                          child: InkWell(
                            onTap: () => _fillDemo(email, password, role),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _quickLogin(email, password, role),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            '⚡ Login',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: accentColor.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
