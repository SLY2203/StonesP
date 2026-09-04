import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/alumni_provider.dart';
import 'alumni_detail_verification_screen.dart';

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'ALL'; // 'ALL', 'PENDING', 'VERIFIED'
  int? _selectedYear;

  final List<int> _years = [0, 2024, 2023, 2022, 2021, 2020, 2019, 2018];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final provider = Provider.of<AlumniProvider>(context, listen: false);
    bool? isVer;
    if (_filterStatus == 'PENDING') isVer = false;
    if (_filterStatus == 'VERIFIED') isVer = true;

    provider.fetchDirectory(
      q: _searchController.text.trim(),
      gradYear: _selectedYear == 0 ? null : _selectedYear,
      isVerified: isVer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumniProvider = Provider.of<AlumniProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Search alumni by name, reg #, or employer...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Chips + Year Filter
                Row(
                  children: [
                    // Status segmented chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip('All Alumni', 'ALL'),
                            const SizedBox(width: 6),
                            _buildStatusChip('⏳ Pending', 'PENDING'),
                            const SizedBox(width: 6),
                            _buildStatusChip('✅ Verified', 'VERIFIED'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Year Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear ?? 0,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                          items: _years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text(y == 0 ? 'Any Year' : '$y'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedYear = val);
                            _applyFilter();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Alumni List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _applyFilter(),
              child: alumniProvider.isLoading && alumniProvider.directory.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : alumniProvider.directory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No alumni match the filter criteria',
                                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filterStatus = 'ALL';
                                    _selectedYear = 0;
                                  });
                                  _applyFilter();
                                },
                                child: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alumniProvider.directory.length,
                          itemBuilder: (context, index) {
                            final item = alumniProvider.directory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AlumniDetailVerificationScreen(alumnusId: item.id),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: item.isVerified ? AppColors.primaryNavy : AppColors.warningBg,
                                        child: Text(
                                          item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'A',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: item.isVerified ? Colors.white : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.fullName,
                                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                _buildVerificationBadge(item.isVerified),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.registrationNumber} • Class of ${item.graduationYear}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 6),
                                            if (item.currentJobTitle != null && item.currentEmployer != null) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.work_rounded, size: 13, color: AppColors.accentGold),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${item.currentJobTitle} at ${item.currentEmployer}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              Text(
                                                item.programme,
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isSelected = _filterStatus == status;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        if (val) {
          setState(() => _filterStatus = status);
          _applyFilter();
        }
      },
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
        child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
      child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
    );
  }
}
