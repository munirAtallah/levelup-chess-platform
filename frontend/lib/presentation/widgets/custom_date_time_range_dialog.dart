/// Presentation — Widget
/// Path: lib/presentation/widgets/custom_date_time_range_dialog.dart
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomRangeResult {
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const CustomRangeResult({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });
}

Future<CustomRangeResult?> showCustomDateTimeRangeDialog(
  BuildContext context, {
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  TimeOfDay? initialStartTime,
  TimeOfDay? initialEndTime,
}) {
  return showDialog<CustomRangeResult>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: _CustomDateTimeRangeDialog(
          initialStartDate: initialStartDate,
          initialEndDate: initialEndDate,
          initialStartTime: initialStartTime,
          initialEndTime: initialEndTime,
        ),
      ),
    ),
  );
}

class _CustomDateTimeRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  const _CustomDateTimeRangeDialog({
    this.initialStartDate,
    this.initialEndDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  State<_CustomDateTimeRangeDialog> createState() =>
      _CustomDateTimeRangeDialogState();
}

class _CustomDateTimeRangeDialogState
    extends State<_CustomDateTimeRangeDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = widget.initialStartDate ?? today;
    _endDate = widget.initialEndDate ?? today;
    _startTime =
        widget.initialStartTime ?? const TimeOfDay(hour: 0, minute: 0);
    _endTime =
        widget.initialEndTime ?? const TimeOfDay(hour: 23, minute: 59);
  }

  bool get _isEndBeforeStart {
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      return false;
    }
    final start = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    final end = DateTime(
      _endDate!.year, _endDate!.month, _endDate!.day,
      _endTime!.hour, _endTime!.minute, 59, 999,
    );
    return end.isBefore(start);
  }

  bool get _canApply =>
      _startDate != null &&
      _endDate != null &&
      _startTime != null &&
      _endTime != null &&
      !_isEndBeforeStart;

  Future<void> _pickDate(bool isStart) async {
    final initial =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 0, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 23, minute: 59));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _fieldTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 18, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.mutedForeground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Custom Date & Time Range',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.mutedForeground,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionLabel('START'),
                const SizedBox(height: 10),
                _fieldTile(
                  label: 'DATE',
                  value: _formatDate(_startDate),
                  onTap: () => _pickDate(true),
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                _fieldTile(
                  label: 'TIME',
                  value: _formatTime(_startTime),
                  onTap: () => _pickTime(true),
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 20),

                _sectionLabel('END'),
                const SizedBox(height: 10),
                _fieldTile(
                  label: 'DATE',
                  value: _formatDate(_endDate),
                  onTap: () => _pickDate(false),
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                _fieldTile(
                  label: 'TIME',
                  value: _formatTime(_endTime),
                  onTap: () => _pickTime(false),
                  icon: Icons.schedule_rounded,
                ),

                if (_isEndBeforeStart) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'End must be after start',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mutedForeground,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _canApply
                          ? () => Navigator.of(context).pop(CustomRangeResult(
                                startDate: _startDate!,
                                endDate: _endDate!,
                                startTime: _startTime!,
                                endTime: _endTime!,
                              ))
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply Filter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
