import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/report_provider.dart';
import '../../widgets/stat_card.dart';
import '../../services/file_saver.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  int? _filterYear;
  String? _filterProg;

  final List<int> _years = [0, 2024, 2023, 2022, 2021, 2020, 2019];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchSummary();
    });
  }

  void _applyFilter() {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    provider.fetchSummary(
      year: _filterYear == 0 ? null : _filterYear,
      programme: _filterProg,
    );
  }

  Future<void> _handleDownload(String type, String url) async {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Generating $type report from backend...'),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final bytes = await provider.downloadReport(
        type,
        year: _filterYear == 0 ? null : _filterYear,
        programme: _filterProg,
      );

      final ext = type.toLowerCase();
      final mime = type == 'PDF' ? 'application/pdf' : 'text/csv';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'msu_dcs_alumni_report_$timestamp.$ext';

      FileSaver.saveFile(
        bytes: bytes,
        filename: filename,
        mimeType: mime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $type report exported successfully! ($filename)'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Direct URL',
              textColor: Colors.white,
              onPressed: () => FileSaver.openUrl(url),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fallback: open direct URL
        FileSaver.openUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export downloading via browser link: ${e.toString()}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  void _showExportDialog(String type) {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final url = type == 'PDF' ? provider.getPDFExportUrl() : provider.getCSVExportUrl();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(type == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.table_view_rounded,
                color: type == 'PDF' ? AppColors.error : AppColors.success),
            const SizedBox(width: 10),
            Text('Export $type Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The report will be generated for the current active filters:\n• Cohort Year: ${_filterYear == null || _filterYear == 0 ? 'All Years' : _filterYear}\n• Programme: ${_filterProg ?? 'All DCS Degrees'}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'Authenticated Download Endpoint:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primaryNavy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open URL'),
            onPressed: () {
              Navigator.pop(ctx);
              FileSaver.openUrl(url);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Download $type'),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDownload(type, url);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final summary = reportProvider.summary;
    final metrics = summary?.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => reportProvider.fetchSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls & Export Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Filters',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Year Filter
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _filterYear ?? 0,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Cohort Year', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            items: _years.map((y) {
                              return DropdownMenuItem(value: y, child: Text(y == 0 ? 'All Cohorts' : 'Class of $y', style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _filterYear = val);
                              _applyFilter();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Programme Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterProg ?? '',
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Programme', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('All Programmes', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ...AppConstants.dcsProgrammes.map((p) {
                                return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _filterProg = (val == null || val.isEmpty) ? null : val);
                              _applyFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Export Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text('Export PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () => _showExportDialog('PDF'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryNavy,
                              side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.table_view_rounded, size: 16),
                            label: const Text('Export CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () => _showExportDialog('CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (reportProvider.isLoading && summary == null)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (metrics != null && summary != null) ...[
                // KPI Metrics Section
                const Text(
                  'AGGREGATE EMPLOYMENT OUTCOMES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    StatCard(
                      title: 'Employed (Full/Part)',
                      value: '${metrics.employedCount}',
                      icon: Icons.work_rounded,
                      iconColor: AppColors.primaryNavy,
                      iconBgColor: AppColors.infoBg,
                    ),
                    StatCard(
                      title: 'Founders / Self-Employed',
                      value: '${metrics.selfEmployedCount}',
                      icon: Icons.lightbulb_rounded,
                      iconColor: AppColors.accentGold,
                      iconBgColor: AppColors.warningBg,
                    ),
                    StatCard(
                      title: 'Further Studies / Postgrad',
                      value: '${metrics.furtherStudiesCount}',
                      icon: Icons.school_rounded,
                      iconColor: AppColors.catEvent,
                      iconBgColor: const Color(0xFFF3E8FF),
                    ),
                    StatCard(
                      title: 'Seeking Opportunities',
                      value: '${metrics.unemployedCount}',
                      icon: Icons.search_rounded,
                      iconColor: AppColors.textSecondary,
                      iconBgColor: AppColors.surfaceElevated,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Employment Breakdown Chart Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employment Status Distribution',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calculated across ${metrics.trackedEmploymentCount} tracked alumni',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.primaryNavy,
                                value: (metrics.employedCount > 0 ? metrics.employedCount : 1).toDouble(),
                                title: '${metrics.employedCount}',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: AppColors.accentGold,
                                value: (metrics.selfEmployedCount > 0 ? metrics.selfEmployedCount : 0.001).toDouble(),
                                title: '${metrics.selfEmployedCount}',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: AppColors.catEvent,
                                value: (metrics.furtherStudiesCount > 0 ? metrics.furtherStudiesCount : 0.001).toDouble(),
                                title: '${metrics.furtherStudiesCount}',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: AppColors.textMuted,
                                value: (metrics.unemployedCount > 0 ? metrics.unemployedCount : 0.001).toDouble(),
                                title: '${metrics.unemployedCount}',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Legend
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _buildLegendItem('Employed', AppColors.primaryNavy),
                          _buildLegendItem('Self-Employed', AppColors.accentGold),
                          _buildLegendItem('Further Studies', AppColors.catEvent),
                          _buildLegendItem('Seeking Employment', AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Top Industries Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leading Industry Sectors',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 12),
                      if (summary.topIndustries.isEmpty)
                        const Text('No industry records recorded.', style: TextStyle(color: AppColors.textMuted))
                      else
                        ...summary.topIndustries.map((ind) {
                          double pct = metrics.trackedEmploymentCount > 0
                              ? (ind.count / metrics.trackedEmploymentCount)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(ind.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('${ind.count} alumni', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: AppColors.surfaceElevated,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Top Employers Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Employers of DCS Alumni',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 12),
                      if (summary.topEmployers.isEmpty)
                        const Text('No employer records found.', style: TextStyle(color: AppColors.textMuted))
                      else
                        ...summary.topEmployers.map((emp) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.apartment_rounded, size: 16, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    emp.label,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${emp.count} hires',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }
}
