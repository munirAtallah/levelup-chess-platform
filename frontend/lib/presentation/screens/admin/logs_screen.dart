/// Presentation Tier — Screen
/// Path: lib/presentation/screens/admin/logs_screen.dart
///
///  Zero business logic — search, filter, and log retrieval via AuditLogController
///  Zero mock data — logs from AuditLogRepository via controller
///  Uses ListenableBuilder for reactivity
library;

import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/audit_log_item.dart';
import '../../widgets/custom_date_time_range_dialog.dart';
import '../../../logic/controllers/audit_log_controller.dart';
import '../../../di/service_locator.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final AuditLogController _controller = getIt<AuditLogController>();

  String _localizedRoleLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'admin': return l10n.filterRoleAdmin;
      case 'instructor': return l10n.roleInstructor;
      case 'student': return l10n.studentRoleLabel;
      default: return l10n.allRoles;
    }
  }

  String _localizedTimeLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'today': return l10n.filterTimeToday;
      case '7days': return l10n.filterTime7Days;
      case '30days': return l10n.filterTime30Days;
      case 'custom': return 'Custom Range';
      default: return l10n.allTime;
    }
  }

  Future<void> _showCustomRangeDialog(BuildContext context) async {
    final result = await showCustomDateTimeRangeDialog(
      context,
      initialStartDate: _controller.customStartDate,
      initialEndDate: _controller.customEndDate,
      initialStartTime: _controller.customStartTime,
      initialEndTime: _controller.customEndTime,
    );
    if (result != null) {
      _controller.setCustomRange(
        startDate: result.startDate,
        endDate: result.endDate,
        startTime: result.startTime,
        endTime: result.endTime,
      );
    }
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'users': return 'Users';
      case 'groups': return 'Groups';
      case 'curriculum': return 'Curriculum';
      case 'assignments': return 'Assignments';
      case 'grading': return 'Grading';
      case 'submissions': return 'Submissions';
      default: return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final l10n = AppLocalizations.of(context)!;
        final filteredLogs = _controller.filteredLogs;
        final roleFilters = _controller.roleFilters;
        final timeFilters = _controller.timeFilters;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.auditLogsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)!.entriesCount((filteredLogs.length).toString()), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: () => _controller.refresh(),
                        tooltip: 'Refresh',
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      // Role Filter
                      PopupMenuButton<String>(
                        onSelected: (val) => _controller.setRoleFilter(val),
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(_localizedRoleLabel(_controller.roleFilter, l10n), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.mutedForeground),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          return roleFilters.map((f) => PopupMenuItem<String>(
                            value: f['value'],
                            child: Text(_localizedRoleLabel(f['value'] ?? '', l10n), style: const TextStyle(fontSize: 13)),
                          )).toList();
                        },
                      ),
                      const SizedBox(width: 12),
                      
                      // Time Filter
                      PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'custom') {
                            await _showCustomRangeDialog(context);
                          } else {
                            _controller.setTimeFilter(val);
                          }
                        },
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(_localizedTimeLabel(_controller.timeFilter, l10n), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.mutedForeground),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          return timeFilters.map((f) => PopupMenuItem<String>(
                            value: f['value'],
                            child: Text(_localizedTimeLabel(f['value'] ?? '', l10n), style: const TextStyle(fontSize: 13)),
                          )).toList();
                        },
                      ),
                    ],
                  ),
                ),
                // Category filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _controller.categoryFilters.map((f) {
                        final isSelected = _controller.categoryFilter == f['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _controller.setCategoryFilter(f['value']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                              ),
                              child: Text(
                                _categoryLabel(f['value']!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // List
                Expanded(
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        return AuditLogItem(log: filteredLogs[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
