import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/prevention_model.dart';
import '../services/prevention_history_service.dart';
import '../theme/app_theme.dart';
import 'prevention_result_screen.dart';

class PreventionHistoryScreen extends StatefulWidget {
  const PreventionHistoryScreen({super.key});

  @override
  State<PreventionHistoryScreen> createState() =>
      _PreventionHistoryScreenState();
}

class _PreventionHistoryScreenState extends State<PreventionHistoryScreen> {
  List<PreventionHistoryRecord> _records = [];
  bool _isLoading = true;
  String _filter = 'All'; // 'All', 'High Risk', 'Safe'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await PreventionHistoryService.getRecords();
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    final success = await PreventionHistoryService.deleteRecord(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment record deleted'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadHistory();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Prevention History?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete all past microclimate risk evaluations.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.diseasedRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PreventionHistoryService.clearAll();
      _loadHistory();
    }
  }

  List<PreventionHistoryRecord> get _filteredRecords {
    if (_filter == 'High Risk') {
      return _records.where((r) => r.prediction.riskScore >= 0.65).toList();
    } else if (_filter == 'Safe') {
      return _records.where((r) => r.prediction.riskScore < 0.35).toList();
    }
    return _records;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prevention History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: ['All', 'High Risk', 'Safe'].map((type) {
                  final isSelected = _filter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _filter = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 64, color: AppTheme.borderColor),
                              const SizedBox(height: 12),
                              Text(
                                'No prevention assessments found',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Run the weather ANN model to log assessments here.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: list.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final pred = item.prediction;
                            final isHigh = pred.riskScore >= 0.65;
                            final isMod = pred.riskScore >= 0.35 && !isHigh;
                            final color = isHigh
                                ? AppTheme.diseasedRed
                                : (isMod
                                    ? AppTheme.warningOrange
                                    : AppTheme.healthyGreen);

                            final dateStr = DateFormat('dd MMM yyyy, hh:mm a')
                                .format(item.timestamp);

                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.diseasedRed,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteRecord(item.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: AppTheme.borderColor),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: color.withAlpha(35),
                                    child: Text(
                                      '${(pred.riskScore * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${item.inputData.cropName} • ${item.inputData.location}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pred.riskCategory} • ${item.inputData.temperature}°C, ${item.inputData.relativeHumidity}% RH',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary
                                              .withAlpha(160),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.primary),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PreventionResultScreen(
                                          inputData: item.inputData,
                                          prediction: pred,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

