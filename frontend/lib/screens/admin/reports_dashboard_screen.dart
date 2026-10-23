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
                const SizedBox(height: 18),

                // Objective 5: Time to First Job
                if (summary.timeToFirstJob != null) ...[
                  _buildTimeToFirstJobCard(summary.timeToFirstJob!),
                  const SizedBox(height: 18),
                ],

                // Objective 5: Career Progression Tracking
                if (summary.careerProgression != null) ...[
                  _buildCareerProgressionCard(summary.careerProgression!),
                  const SizedBox(height: 18),
                ],

                // Objective 5: Cohort Employment Trends
                if (summary.cohortTrends.isNotEmpty) ...[
                  _buildCohortTrendsCard(summary.cohortTrends),
                  const SizedBox(height: 18),
                ],

                // Objective 5: Tracer Survey Satisfaction
                if (summary.tracerSurveySummary != null && (summary.tracerSurveySummary!['total_responses'] ?? 0) > 0) ...[
                  _buildTracerSurveyCard(summary.tracerSurveySummary!),
                  const SizedBox(height: 18),
                ],

                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeToFirstJobCard(Map<String, dynamic> data) {
    final avg = data['average_months'] ?? 0.0;
    final sample = data['sample_size'] ?? 0;
    final dist = (data['distribution'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20, color: AppColors.primaryNavy),
                  SizedBox(width: 8),
                  Text(
                    'Time to First Job After Graduation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Avg $avg months', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.info)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Computed across $sample alumni with verified start dates', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...dist.map((d) {
            final label = d['label'] ?? '';
            final count = d['count'] ?? 0;
            final pct = (d['percentage'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('$count ($pct%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCareerProgressionCard(Map<String, dynamic> data) {
    final multiple = data['alumni_with_multiple_roles'] ?? 0;
    final rate = data['progression_rate'] ?? 0.0;
    final leadership = data['leadership_roles_count'] ?? 0;
    final leadPct = data['leadership_percentage'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 20, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Career Progression & Mobility',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Alumni advancing from entry roles to senior leadership', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promotions / Role Changes', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('$multiple alumni', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                      Text('$rate% mobility rate', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Senior / Leadership Roles', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('$leadership alumni', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                      Text('$leadPct% of employed', style: const TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCohortTrendsCard(List<Map<String, dynamic>> trends) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.accentGold),
              SizedBox(width: 8),
              Text(
                'Year-over-Year Cohort Employment Rates',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Employment rate comparison across graduating classes', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...trends.map((t) {
            final year = t['year'] ?? '';
            final total = t['total_alumni'] ?? 0;
            final employed = t['employed_count'] ?? 0;
            final rate = (t['employment_rate'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Class of $year', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('$rate% ($employed/$total)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 80 ? AppColors.success : (rate >= 60 ? AppColors.accentGold : AppColors.info),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTracerSurveyCard(Map<String, dynamic> data) {
    final total = data['total_responses'] ?? 0;
    final careerSat = data['avg_career_satisfaction'] ?? 0.0;
    final currSat = data['avg_curriculum_satisfaction'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.school_rounded, size: 20, color: AppColors.catEvent),
                  SizedBox(width: 8),
                  Text(
                    'Tracer Survey Feedback',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                ],
              ),
              Text('$total Responses', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.catEvent)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Career Satisfaction', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('★ $careerSat / 5.0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Curriculum Prep Rating', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('★ $currSat / 5.0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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

