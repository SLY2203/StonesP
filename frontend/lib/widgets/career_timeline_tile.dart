import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/career_model.dart';

class CareerTimelineTile extends StatelessWidget {
  final CareerRecordModel record;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CareerTimelineTile({
    super.key,
    required this.record,
    this.isFirst = false,
    this.isLast = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node & Vertical Line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: isFirst ? Colors.transparent : AppColors.border,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: record.isCurrent ? AppColors.accentGold : AppColors.primaryNavy,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Milestone Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: record.isCurrent ? AppColors.accentGold.withOpacity(0.4) : AppColors.border,
                  width: record.isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          record.jobTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (onEdit != null || onDelete != null)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          onSelected: (val) {
                            if (val == 'edit' && onEdit != null) onEdit!();
                            if (val == 'delete' && onDelete != null) onDelete!();
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryNavy),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Employer
                  Text(
                    record.employer,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges (Status + Industry)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (record.isCurrent)
                        _buildPill('Current Role', AppColors.successBg, AppColors.success),
                      _buildPill(record.statusDisplay, AppColors.surfaceElevated, AppColors.textSecondary),
                      _buildPill(record.industrySector, AppColors.infoBg, AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dates
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${record.startDate} - ${record.isCurrent ? 'Present' : (record.endDate ?? '')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Further studies note if present
                  if (record.furtherEducationInstitution != null &&
                      record.furtherEducationInstitution!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined, size: 16, color: AppColors.primaryNavy),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${record.furtherEducationProgramme ?? 'Postgrad'} at ${record.furtherEducationInstitution}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (record.description != null && record.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      record.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
      ),
    );
  }
}
