import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/communication_provider.dart';
import '../../models/communication_model.dart';
import 'alumni_detail_verification_screen.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _selectedResponseType = 'ALL';
  bool _onlyWithNotes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedbacks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFeedbacks() {
    Provider.of<CommunicationProvider>(context, listen: false).fetchFeedbacks(
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
      responseType: _selectedResponseType == 'ALL' ? null : _selectedResponseType,
      withNotes: _onlyWithNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final commProvider = Provider.of<CommunicationProvider>(context);
    final feedbacks = commProvider.feedbacks;

    // Filter by search query if any
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? feedbacks
        : feedbacks.where((f) {
            return f.alumnusName.toLowerCase().contains(query) ||
                f.alumnusReg.toLowerCase().contains(query) ||
                f.communicationTitle.toLowerCase().contains(query) ||
                f.notes.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alumni Feedbacks & Responses'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Feedbacks',
            onPressed: _loadFeedbacks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search feedbacks by alumnus name, reg #, or topic...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Topics', 'ALL', _selectedCategory, (val) {
                        setState(() => _selectedCategory = val);
                        _loadFeedbacks();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('💼 Job Vacancies', 'JOB_VACANCY', _selectedCategory, (val) {
                        setState(() => _selectedCategory = val);
                        _loadFeedbacks();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('📅 Events & Reunions', 'EVENT', _selectedCategory, (val) {
                        setState(() => _selectedCategory = val);
                        _loadFeedbacks();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('📢 Announcements', 'ANNOUNCEMENT', _selectedCategory, (val) {
                        setState(() => _selectedCategory = val);
                        _loadFeedbacks();
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Response Type Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTypeFilterChip('All Types', 'ALL'),
                            const SizedBox(width: 6),
                            _buildTypeFilterChip('Applied', 'APPLIED'),
                            const SizedBox(width: 6),
                            _buildTypeFilterChip('Interested', 'INTERESTED'),
                            const SizedBox(width: 6),
                            _buildTypeFilterChip('Attending', 'ATTENDING'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('With Notes Only', style: TextStyle(fontSize: 11)),
                      selected: _onlyWithNotes,
                      selectedColor: AppColors.accentGold.withOpacity(0.3),
                      checkmarkColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      onSelected: (val) {
                        setState(() => _onlyWithNotes = val);
                        _loadFeedbacks();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Feedbacks List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadFeedbacks(),
              child: commProvider.isLoading && filtered.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.mark_chat_unread_outlined, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No alumni feedback found for this filter.',
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            return _buildFeedbackCard(item);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelect) {
    final isSelected = selectedValue == value;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val) onSelect(value);
      },
    );
  }

  Widget _buildTypeFilterChip(String label, String value) {
    final isSelected = _selectedResponseType == value;
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
      selectedColor: AppColors.primaryNavyLight,
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedResponseType = value);
          _loadFeedbacks();
        }
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackItemModel item) {
    final isApplied = item.responseType == 'APPLIED';
    final isAttending = item.responseType == 'ATTENDING';

    Color badgeColor = AppColors.info;
    Color badgeBg = AppColors.infoBg;
    if (isApplied) {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successBg;
    } else if (isAttending) {
      badgeColor = AppColors.catEvent;
      badgeBg = const Color(0xFFF3E8FF);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alumnus & Post Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                child: Text(
                  item.alumnusName.isNotEmpty ? item.alumnusName[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.alumnusName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.responseType,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.alumnusReg}${item.alumnusGradYear != null ? ' • Class of ${item.alumnusGradYear}' : ''}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Associated Communication/Job badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  item.communicationCategory == 'JOB_VACANCY'
                      ? Icons.work_outline_rounded
                      : (item.communicationCategory == 'EVENT' ? Icons.event_rounded : Icons.campaign_rounded),
                  size: 14,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.communicationTitle,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Feedback / Notes text
          if (item.notes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item.notes,
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Footer with Date and Profile Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.createdAt.length >= 16 ? item.createdAt.substring(0, 16) : item.createdAt,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlumniDetailVerificationScreen(alumnusId: item.alumnusId),
                    ),
                  );
                },
                icon: const Icon(Icons.person_search_rounded, size: 14),
                label: const Text('View Profile', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
