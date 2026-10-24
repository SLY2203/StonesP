import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/profile_model.dart';
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
    final skillsController = TextEditingController(text: profile.skills ?? '');
    final mentorshipAreasController = TextEditingController(text: profile.mentorshipAreas ?? '');
    bool isAvailableForMentorship = profile.isAvailableForMentorship;
    bool isOpenToOpportunities = profile.isOpenToOpportunities;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(
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

                // Technical Skills Field
                CustomTextField(
                  controller: skillsController,
                  label: 'Technical Skills & Technologies (comma separated)',
                  hint: 'e.g. Python, Flutter, Django, PostgreSQL, AWS, Docker',
                  prefixIcon: Icons.psychology_outlined,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    'Python', 'Flutter', 'Django', 'PostgreSQL', 'AWS', 'Docker', 'React', 'Machine Learning'
                  ].map((s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.surfaceElevated,
                    onPressed: () {
                      final current = skillsController.text.trim();
                      if (!current.toLowerCase().contains(s.toLowerCase())) {
                        skillsController.text = current.isEmpty ? s : '$current, $s';
                      }
                    },
                  )).toList(),
                ),
                const SizedBox(height: 14),

                // Mentorship Switch & Areas
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Available for Mentorship',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        subtitle: const Text(
                          'Help junior alumni & current DCS finalists with guidance',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        activeColor: AppColors.primaryNavy,
                        value: isAvailableForMentorship,
                        onChanged: (val) {
                          setModalState(() {
                            isAvailableForMentorship = val;
                          });
                        },
                      ),
                      if (isAvailableForMentorship) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: mentorshipAreasController,
                          label: 'Mentorship Focus Areas',
                          hint: 'e.g. CV Review, Mock Technical Interviews, FinTech Advice',
                          prefixIcon: Icons.school_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Open to Opportunities Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Open to Job Opportunities',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    subtitle: const Text(
                      'Allow DCS AI job matching to recommend your profile for department vacancy alerts',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    activeColor: AppColors.success,
                    value: isOpenToOpportunities,
                    onChanged: (val) {
                      setModalState(() {
                        isOpenToOpportunities = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),

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
                      'skills': skillsController.text.trim(),
                      'is_available_for_mentorship': isAvailableForMentorship,
                      'mentorship_areas': mentorshipAreasController.text.trim(),
                      'is_open_to_opportunities': isOpenToOpportunities,
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
                      Chip(
                        backgroundColor: (profile.isOpenToOpportunities ? AppColors.success : AppColors.textMuted).withOpacity(0.12),
                        avatar: Icon(
                          profile.isOpenToOpportunities ? Icons.work_outline : Icons.work_off_outlined,
                          size: 14,
                          color: profile.isOpenToOpportunities ? AppColors.success : AppColors.textMuted,
                        ),
                        label: Text(
                          profile.isOpenToOpportunities ? 'Open to Opportunities' : 'Not Looking',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: profile.isOpenToOpportunities ? AppColors.success : AppColors.textMuted,
                          ),
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

            // Profile Completeness Card (Recommendation 1.2)
            _buildProfileCompletenessCard(profile),
            const SizedBox(height: 16),

            // Technical Skills & Competencies Card (Suggestion 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Technical Skills & Stack',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      Icon(Icons.code_rounded, size: 20, color: AppColors.primaryNavy.withOpacity(0.7)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (profile.skillsList.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skillsList.map((skill) => Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                        ),
                        backgroundColor: AppColors.surfaceElevated,
                        side: const BorderSide(color: AppColors.border),
                        avatar: const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.accentGold,
                        ),
                      )).toList(),
                    )
                  else
                    const Text(
                      'No skills listed yet. Tap "Edit Profile" to add your programming languages and technical competencies.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mentorship Status Card (Suggestion 3)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mentorship Program',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: profile.isAvailableForMentorship ? AppColors.success.withOpacity(0.12) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          profile.isAvailableForMentorship ? 'Active Mentor' : 'Not Enrolled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: profile.isAvailableForMentorship ? AppColors.success : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (profile.isAvailableForMentorship) ...[
                    const Text(
                      'You are visible to students and fellow alumni as a volunteer mentor.',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                    if (profile.mentorshipAreas != null && profile.mentorshipAreas!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Focus: ${profile.mentorshipAreas!}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ],
                  ] else
                    const Text(
                      'Turn on "Available for Mentorship" in your profile settings to guide junior alumni and students with career and technical advice.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Academic Information Card
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

  Widget _buildProfileCompletenessCard(AlumniProfileModel profile) {
    final percent = profile.profileCompletenessPercent;
    final isComplete = percent >= 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete ? AppColors.success.withOpacity(0.5) : AppColors.accentGold.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete ? Icons.verified_rounded : Icons.pie_chart_outline_rounded,
                    size: 20,
                    color: isComplete ? AppColors.success : AppColors.accentGold,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profile Completeness',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isComplete ? AppColors.success : AppColors.accentGold).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? AppColors.success : AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percent / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.success : AppColors.accentGold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isComplete
                ? 'Your profile is 100% complete! You have maximum visibility for DCS AI job matches.'
                : 'Complete your bio, skills, LinkedIn, career timeline, and tracer survey to maximize AI job matching accuracy.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompletenessChip('Bio', (profile.bio ?? '').isNotEmpty),
                _buildCompletenessChip('Skills', (profile.skills ?? '').isNotEmpty),
                _buildCompletenessChip('LinkedIn', (profile.linkedinUrl ?? '').isNotEmpty),
                _buildCompletenessChip('Career Records', profile.careerRecords.isNotEmpty),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletenessChip(String label, bool isDone) {
    return Chip(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      avatar: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 14,
        color: isDone ? AppColors.success : AppColors.textMuted,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDone ? AppColors.success : AppColors.textSecondary,
          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isDone ? AppColors.successBg : AppColors.surfaceElevated,
    );
  }
}
