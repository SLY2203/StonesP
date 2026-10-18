import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/communication_provider.dart';
import '../../models/communication_model.dart';

class EventsModuleView extends StatefulWidget {
  const EventsModuleView({super.key});

  @override
  State<EventsModuleView> createState() => _EventsModuleViewState();
}

class _EventsModuleViewState extends State<EventsModuleView> {
  final TextEditingController _searchController = TextEditingController();
  bool _filterOnlyMyRSVPs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunicationProvider>(context, listen: false)
          .fetchFeed(category: 'EVENT');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Date TBA';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('EEE, d MMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Map<String, String> _splitDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return {'day': '--', 'month': 'TBA'};
    }
    try {
      final dt = DateTime.parse(isoString);
      return {
        'day': dt.day.toString().padLeft(2, '0'),
        'month': DateFormat('MMM').format(dt).toUpperCase(),
      };
    } catch (_) {
      return {'day': '--', 'month': 'TBA'};
    }
  }

  Future<void> _handleRSVP(int commId, String responseType) async {
    final commProvider = Provider.of<CommunicationProvider>(context, listen: false);
    final success = await commProvider.submitRSVP(commId, responseType);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseType == 'ATTENDING'
                ? 'Great! Marked as Attending event.'
                : 'Marked as Interested in this event.',
          ),
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelRSVP(int commId) async {
    final commProvider = Provider.of<CommunicationProvider>(context, listen: false);
    final success = await commProvider.cancelRSVP(commId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RSVP response withdrawn.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commProvider = Provider.of<CommunicationProvider>(context);
    final allEvents = commProvider.feed.where((item) => item.category == 'EVENT').toList();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allEvents.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query) ||
          (item.location ?? '').toLowerCase().contains(query);
      final matchesRSVP = !_filterOnlyMyRSVPs || item.myRsvp != null;
      return matchesQuery && matchesRSVP;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => commProvider.fetchFeed(category: 'EVENT'),
      color: AppColors.primaryNavy,
      child: CustomScrollView(
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1B4E), Color(0xFF4C2A85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4C2A85).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.accentGold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events & Reunions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reunions, annual galas, and networking meetups for DCS alumni.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events by name, location...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() => _searchController.clear());
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('All Events', style: TextStyle(fontSize: 12)),
                        selected: !_filterOnlyMyRSVPs,
                        selectedColor: AppColors.primaryNavy,
                        labelStyle: TextStyle(
                          color: !_filterOnlyMyRSVPs ? Colors.white : AppColors.textSecondary,
                          fontWeight: !_filterOnlyMyRSVPs ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          if (selected) setState(() => _filterOnlyMyRSVPs = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('My RSVPs', style: TextStyle(fontSize: 12)),
                        selected: _filterOnlyMyRSVPs,
                        selectedColor: AppColors.primaryNavy,
                        labelStyle: TextStyle(
                          color: _filterOnlyMyRSVPs ? Colors.white : AppColors.textSecondary,
                          fontWeight: _filterOnlyMyRSVPs ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          setState(() => _filterOnlyMyRSVPs = selected);
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} Event${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Events List
          if (commProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C2A85).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Color(0xFF4C2A85),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterOnlyMyRSVPs ? 'No RSVPs Yet' : 'No upcoming events found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filterOnlyMyRSVPs
                            ? 'You have not RSVP\'d to any events yet. Browse all events and tap "Attending" or "Interested".'
                            : 'Stay tuned! Department galas, homecomings, and hackathons will appear here.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return _buildEventCard(item);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CommunicationModel item) {
    final dateParts = _splitDate(item.eventDate);
    final userRsvp = item.myRsvp?.responseType;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Box
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dateParts['month'] ?? 'TBA',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateParts['day'] ?? '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Title and Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.catEvent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EVENT & REUNION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.catEvent,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (userRsvp != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: userRsvp == 'ATTENDING'
                                    ? AppColors.successBg
                                    : AppColors.accentGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userRsvp == 'ATTENDING' ? Icons.check_circle : Icons.star,
                                    size: 11,
                                    color: userRsvp == 'ATTENDING' ? AppColors.success : AppColors.primaryNavy,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userRsvp == 'ATTENDING' ? 'Attending' : 'Interested',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: userRsvp == 'ATTENDING' ? AppColors.success : AppColors.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateTime(item.eventDate),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (item.location != null && item.location!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              item.content,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // RSVP and Attendee Stats
            Row(
              children: [
                // Response Stats
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      '${item.counts.attending} attending • ${item.counts.interested} interested',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),

                // Action Buttons
                if (userRsvp == null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.star_border, size: 14),
                    label: const Text('Interested', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () => _handleRSVP(item.id, 'INTERESTED'),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Going', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _handleRSVP(item.id, 'ATTENDING'),
                  ),
                ] else ...[
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 13, color: AppColors.error),
                    label: const Text(
                      'Cancel RSVP',
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _cancelRSVP(item.id),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
