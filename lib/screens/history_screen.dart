import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_history_record.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';
import 'capture_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryRecord> _scans = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Infected', 'Healthy'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final scans = await HistoryService.getScans();
    if (mounted) {
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteScan(String id) async {
    final success = await HistoryService.deleteScan(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan record deleted'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadHistory();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear History?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all saved crop disease scan records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await HistoryService.clearAllScans();
      _loadHistory();
    }
  }

  List<ScanHistoryRecord> get _filteredScans {
    return _scans.where((scan) {
      // Filter by status
      if (_selectedFilter == 'Infected' && scan.isHealthy) return false;
      if (_selectedFilter == 'Healthy' && !scan.isHealthy) return false;

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = scan.diseaseName.toLowerCase().contains(q);
        final matchDesc = scan.description.toLowerCase().contains(q);
        return matchName || matchDesc;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredScans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_scans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary),
              tooltip: 'Clear All History',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppTheme.background,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by crop disease name...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Chips Tabs
                  Row(
                    children: [
                      _buildFilterChip('All', _scans.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Infected',
                        _scans.where((s) => !s.isHealthy).length,
                        activeColor: AppTheme.diseasedRed,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Healthy',
                        _scans.where((s) => s.isHealthy).length,
                        activeColor: AppTheme.healthyGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content List / Loading / Empty State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: AppTheme.primary,
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final scan = filtered[idx];
                              return _buildHistoryCard(scan);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? activeColor}) {
    final bool isSelected = _selectedFilter == label;
    final Color primaryColor = activeColor ?? AppTheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : AppTheme.borderColor,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(64)
                    : AppTheme.accentPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryRecord scan) {
    final String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(scan.timestamp);
    final double confidencePct = (scan.confidence * 100).clamp(0.0, 100.0);
    final hasBase64 = scan.imageBase64 != null && scan.imageBase64!.isNotEmpty;

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) => _deleteScan(scan.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Open full results screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  result: scan.toPlantDiseaseResult(),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor, width: 1),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leaf Image Thumbnail or Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasBase64
                      ? Image.memory(
                          base64Decode(scan.imageBase64!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),

                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Confidence
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scan.isHealthy
                                  ? AppTheme.healthyBackground
                                  : AppTheme.diseasedBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scan.isHealthy
                                    ? AppTheme.healthyGreen
                                    : AppTheme.diseasedRed,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  scan.isHealthy
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  size: 12,
                                  color: scan.isHealthy
                                      ? AppTheme.healthyGreen
                                      : AppTheme.diseasedRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  scan.isHealthy ? 'Healthy' : 'Infected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: scan.isHealthy
                                        ? AppTheme.healthyGreen
                                        : AppTheme.diseasedRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${confidencePct.toStringAsFixed(0)}% Match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Disease Title
                      Text(
                        scan.diseaseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Date Time Stamp
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 72,
      height: 72,
      color: AppTheme.accentPale,
      child: const Center(
        child: Icon(
          Icons.eco_rounded,
          color: AppTheme.primary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isFiltered = _searchQuery.isNotEmpty || _selectedFilter != 'All';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentPale,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.search_off_rounded : Icons.history_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No Scans Found' : 'No Scan History Yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isFiltered
                  ? 'No scan records match your active search or filter selection.'
                  : 'Scanned crop leaves and diagnosis treatment plans will automatically save here for future reference.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.center_focus_strong_rounded),
              label: Text(
                isFiltered ? 'Reset Filters' : 'Scan a Crop Leaf',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                if (isFiltered) {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'All';
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CaptureScreen(),
                    ),
                  ).then((_) => _loadHistory());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
