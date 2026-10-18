import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/mentorship_model.dart';
import '../../providers/alumni_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class MentorshipHubScreen extends StatefulWidget {
  const MentorshipHubScreen({super.key});

  @override
  State<MentorshipHubScreen> createState() => _MentorshipHubScreenState();
}

class _MentorshipHubScreenState extends State<MentorshipHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _selectedSkill;

  final List<String> _popularSkills = ['All', 'Python', 'Flutter', 'AWS', 'Django', 'Architecture', 'DevOps'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AlumniProvider>(context, listen: false);
      provider.fetchMentors();
      provider.fetchMentorshipRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchMentors() {
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    final skill = (_selectedSkill == null || _selectedSkill == 'All') ? null : _selectedSkill;
    provider.fetchMentors(
      q: _searchController.text.trim(),
      skill: skill,
    );
  }

  void _showRequestModal(MentorModel mentor) {
    final topicController = TextEditingController(text: 'Career Guidance & Tech Advice');
    final messageController = TextEditingController();

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
                  Expanded(
                    child: Text(
                      'Request Mentorship from ${mentor.fullName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: topicController,
                label: 'Mentorship Topic',
                hint: 'e.g. CV Review, Architecture Guidance, Mock Interview',
                prefixIcon: Icons.topic_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: messageController,
                label: 'Personal Message / Goals',
                hint: 'Introduce yourself and share what specific guidance you are seeking...',
                prefixIcon: Icons.message_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Send Request',
                icon: Icons.send_rounded,
                onPressed: () async {
                  if (topicController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide both a topic and message.'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final provider = Provider.of<AlumniProvider>(context, listen: false);
                  final ok = await provider.sendMentorshipRequest(
                    mentorId: mentor.id,
                    topic: topicController.text.trim(),
                    message: messageController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Mentorship request sent to ${mentor.fullName}!' : 'Could not send request.'),
                        backgroundColor: ok ? AppColors.success : AppColors.error,
                      ),
                    );
                    if (ok) {
                      _tabController.animateTo(1);
                    }
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

  void _showRespondModal(MentorshipRequestModel req) {
    final responseController = TextEditingController();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Respond to ${req.menteeName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Topic: ${req.topic}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('"${req.message}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            CustomTextField(
              controller: responseController,
              label: 'Message / Next Steps (Optional)',
              hint: 'e.g. Happy to connect! Send me an email or let us schedule a Zoom call.',
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final provider = Provider.of<AlumniProvider>(context, listen: false);
                      await provider.respondToMentorshipRequest(
                        requestId: req.id,
                        status: 'DECLINED',
                        responseMessage: responseController.text.trim(),
                      );
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final provider = Provider.of<AlumniProvider>(context, listen: false);
                      await provider.respondToMentorshipRequest(
                        requestId: req.id,
                        status: 'ACCEPTED',
                        responseMessage: responseController.text.trim(),
                      );
                    },
                    child: const Text('Accept & Connect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlumniProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'Browse Mentors'),
            Tab(icon: Icon(Icons.mark_email_unread_rounded, size: 20), text: 'My Connections'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Browse Mentors
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchMentors(),
                      decoration: InputDecoration(
                        hintText: 'Search mentors by name, tech stack, or topic...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularSkills.map((sk) {
                          final isSelected = (_selectedSkill == sk) || (_selectedSkill == null && sk == 'All');
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
                                setState(() => _selectedSkill = sk);
                                _searchMentors();
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => provider.fetchMentors(),
                  child: provider.isLoading && provider.mentors.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.mentors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text('No mentors found matching your search.', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.mentors.length,
                              itemBuilder: (context, index) {
                                final mentor = provider.mentors[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: AppColors.primaryNavy,
                                              child: Text(
                                                mentor.fullName.isNotEmpty ? mentor.fullName[0].toUpperCase() : 'M',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mentor.fullName,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                  ),
                                                  if (mentor.currentJobTitle != null && mentor.currentEmployer != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${mentor.currentJobTitle} at ${mentor.currentEmployer}',
                                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${mentor.programme} • Class of ${mentor.graduationYear}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (mentor.mentorshipAreas != null && mentor.mentorshipAreas!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentGold.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.primaryNavy),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Focus: ${mentor.mentorshipAreas}',
                                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (mentor.skillsList.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: mentor.skillsList.map((sk) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceElevated,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: Text(sk, style: const TextStyle(fontSize: 10.5, color: AppColors.textPrimary)),
                                            )).toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryNavy,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            icon: const Icon(Icons.send_rounded, size: 14),
                                            label: const Text('Request Mentorship', style: TextStyle(fontSize: 12)),
                                            onPressed: () => _showRequestModal(mentor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),

          // Tab 2: Mentorship Requests & Connections
          RefreshIndicator(
            onRefresh: () async => provider.fetchMentorshipRequests(),
            child: provider.mentorshipRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No mentorship requests yet.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('Browse mentors to send your first connection request.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.mentorshipRequests.length,
                    itemBuilder: (context, index) {
                      final req = provider.mentorshipRequests[index];
                      final myId = provider.myProfile?.id;
                      final isMentor = req.mentorId == myId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isMentor ? 'From: ${req.menteeName}' : 'Mentor: ${req.mentorName}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                  ),
                                  _buildStatusBadge(req.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Topic: ${req.topic}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('"${req.message}"', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                              ),
                              if (req.responseMessage != null && req.responseMessage!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withOpacity(0.25)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Mentor Response:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                                      const SizedBox(height: 2),
                                      Text(req.responseMessage!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ],
                              if (isMentor && req.status == 'PENDING') ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryNavy,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.reply_rounded, size: 16),
                                    label: const Text('Respond', style: TextStyle(fontSize: 12)),
                                    onPressed: () => _showRespondModal(req),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'ACCEPTED':
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case 'DECLINED':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
