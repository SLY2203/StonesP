import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/communication_model.dart';

class CommunicationCard extends StatelessWidget {
  final CommunicationModel communication;
  final Function(String responseType)? onRSVP;
  final VoidCallback? onCancelRSVP;
  final bool isAdmin;

  const CommunicationCard({
    super.key,
    required this.communication,
    this.onRSVP,
    this.onCancelRSVP,
    this.isAdmin = false,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'EVENT':
        return AppColors.catEvent;
      case 'JOB_VACANCY':
        return AppColors.catJob;
      case 'MENTORSHIP':
        return AppColors.catMentorship;
      case 'ANNOUNCEMENT':
      default:
        return AppColors.catAnnouncement;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'EVENT':
        return Icons.event_rounded;
      case 'JOB_VACANCY':
        return Icons.work_outline_rounded;
      case 'MENTORSHIP':
        return Icons.school_outlined;
      case 'ANNOUNCEMENT':
      default:
        return Icons.campaign_outlined;
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('EEE, d MMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(communication.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Badge & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getCategoryIcon(communication.category), size: 14, color: catColor),
                      const SizedBox(width: 5),
                      Text(
                        communication.categoryDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (communication.targetGraduationYear != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Class of ${communication.targetGraduationYear}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              communication.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Content body
            Text(
              communication.content,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Extra Metadata (Venue, Event Date, Deadline)
            if (communication.eventDate != null) ...[
              _buildMetaRow(
                Icons.calendar_today_rounded,
                _formatDate(communication.eventDate),
                AppColors.primaryNavy,
              ),
              const SizedBox(height: 6),
            ],
            if (communication.location != null && communication.location!.isNotEmpty) ...[
              _buildMetaRow(
                Icons.location_on_outlined,
                communication.location!,
                AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
            ],
            if (communication.applicationDeadline != null) ...[
              _buildMetaRow(
                Icons.alarm_rounded,
                'Deadline: ${_formatDate(communication.applicationDeadline)}',
                AppColors.warning,
              ),
              const SizedBox(height: 6),
            ],

            const Divider(height: 20),

            // Bottom Action & Engagement Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Author & Response Counter
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${communication.counts.totalResponses} Responded',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // RSVP Actions
                if (!isAdmin && onRSVP != null) ...[
                  if (communication.myRsvp != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            communication.myRsvp!.responseType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          if (onCancelRSVP != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onCancelRSVP,
                              child: const Icon(Icons.close, size: 14, color: AppColors.success),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    PopupMenuButton<String>(
                      onSelected: onRSVP,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        if (communication.isEvent || communication.isMentorship)
                          const PopupMenuItem(
                            value: 'ATTENDING',
                            child: Row(
                              children: [
                                Icon(Icons.check, size: 16, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Attending'),
                              ],
                            ),
                          ),
                        if (communication.isJob)
                          const PopupMenuItem(
                            value: 'APPLIED',
                            child: Row(
                              children: [
                                Icon(Icons.send, size: 16, color: AppColors.primaryNavy),
                                SizedBox(width: 8),
                                Text('Applied'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'INTERESTED',
                          child: Row(
                            children: [
                              Icon(Icons.star_outline, size: 16, color: AppColors.accentGold),
                              SizedBox(width: 8),
                              Text('Interested'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'RSVP / React',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
