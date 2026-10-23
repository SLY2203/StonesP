import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/communication_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final CommunicationService _commService = CommunicationService();
  bool _isLoading = true;
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _commService.getInAppNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = res['unread_count'] ?? 0;
          _notifications = res['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _commService.markAllNotificationsAsRead();
    _loadNotifications();
  }

  Future<void> _markOneRead(int id) async {
    await _commService.markNotificationAsRead(id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, color: AppColors.accentGold, size: 18),
              label: const Text('Mark all read', style: TextStyle(color: AppColors.accentGold, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You will receive alerts here for new broadcasts, AI job matches, and events.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isRead = item['is_read'] ?? false;
                      final category = item['category'] ?? 'SYSTEM';
                      final id = item['id'];

                      return InkWell(
                        onTap: () {
                          if (!isRead && id != null) _markOneRead(id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? AppColors.border : AppColors.primaryNavy.withOpacity(0.3),
                              width: isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryIcon(category),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] ?? 'Notification',
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accentGold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['message'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['category_display'] ?? category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getCategoryColor(category),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData icon;
    Color color = _getCategoryColor(category);

    switch (category) {
      case 'JOB_MATCH':
        icon = Icons.auto_awesome;
        break;
      case 'BROADCAST':
        icon = Icons.campaign_rounded;
        break;
      case 'EVENT':
        icon = Icons.event_rounded;
        break;
      case 'MENTORSHIP':
        icon = Icons.people_alt_rounded;
        break;
      default:
        icon = Icons.notifications_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'JOB_MATCH':
        return AppColors.accentGold;
      case 'BROADCAST':
        return AppColors.primaryNavy;
      case 'EVENT':
        return AppColors.catEvent;
      case 'MENTORSHIP':
        return AppColors.catMentorship;
      default:
        return AppColors.info;
    }
  }
}
