import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/alumni_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileViewEditScreen extends StatefulWidget {
  const ProfileViewEditScreen({super.key});

  @override
  State<ProfileViewEditScreen> createState() => _ProfileViewEditScreenState();
}

class _ProfileViewEditScreenState extends State<ProfileViewEditScreen> {
  void _showEditDialog() {
    final alumniProvider = Provider.of<AlumniProvider>(context, listen: false);
    final profile = alumniProvider.myProfile;
    if (profile == null) return;

    final phoneController = TextEditingController(text: profile.phoneNumber ?? '');
    final addressController = TextEditingController(text: profile.address ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');
    final linkedinController = TextEditingController(text: profile.linkedinUrl ?? '');
    final githubController = TextEditingController(text: profile.githubUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: phoneController,
                label: 'Phone Number',
                hint: '+263 77 123 4567',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: addressController,
                label: 'Residential / City Location',
                hint: 'e.g. Harare, Zimbabwe',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: linkedinController,
                label: 'LinkedIn Profile URL',
                hint: 'https://linkedin.com/in/...',
                prefixIcon: Icons.link_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: githubController,
                label: 'GitHub / Portfolio URL',
                hint: 'https://github.com/...',
                prefixIcon: Icons.code_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: bioController,
                label: 'Professional Bio',
                hint: 'Tell your alumni network about yourself...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Changes',
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await alumniProvider.updateMyProfile({
                    'phone_number': phoneController.text.trim(),
                    'address': addressController.text.trim(),
                    'bio': bioController.text.trim(),
                    'linkedin_url': linkedinController.text.trim(),
                    'github_url': githubController.text.trim(),
                  });
                  if (mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumniProvider = Provider.of<AlumniProvider>(context);
    final profile = alumniProvider.myProfile;

    if (alumniProvider.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile information not loaded.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => alumniProvider.fetchMyProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => alumniProvider.fetchMyProfile(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Reg & Class Badge
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        backgroundColor: AppColors.surfaceElevated,
                        label: Text(
                          profile.registrationNumber,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                      ),
                      Chip(
                        backgroundColor: AppColors.accentGold.withOpacity(0.15),
                        label: Text(
                          'Class of ${profile.graduationYear}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CustomButton(
                    text: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    isOutlined: true,
                    height: 44,
                    onPressed: _showEditDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Academic & Career Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.school_outlined, 'Programme', profile.programme),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.business_outlined, 'Department', 'Department of Computer Science'),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.account_balance_outlined, 'Institution', 'Midlands State University'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Social Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact & Links',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', profile.phoneNumber ?? 'Not provided'),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.location_on_outlined, 'Location', profile.address ?? 'Not specified'),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.link_rounded, 'LinkedIn', profile.linkedinUrl ?? 'Not added'),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.code_rounded, 'GitHub / Web', profile.githubUrl ?? 'Not added'),
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildInfoRow(Icons.description_outlined, 'Bio', profile.bio!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
