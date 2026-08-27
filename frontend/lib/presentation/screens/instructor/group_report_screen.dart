// ignore_for_file: experimental_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/badge.dart';

class GroupReportScreen extends StatefulWidget {
  final String groupId;
  const GroupReportScreen({super.key, required this.groupId});

  @override
  State<GroupReportScreen> createState() => _GroupReportScreenState();
}

class _GroupReportScreenState extends State<GroupReportScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _groupName = '';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (!groupDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Group not found.';
        });
        return;
      }
      _groupName = groupDoc.data()?['name'] ?? 'Group';

      final studentsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('groupId', isEqualTo: widget.groupId)
          .where('role', isEqualTo: 'student')
          .where('isArchived', isEqualTo: false)
          .get();

      final assignmentsSnap = await FirebaseFirestore.instance
          .collection('assignments')
          .where('groupId', isEqualTo: widget.groupId)
          .get();

      _students = studentsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      
      // Sort assignments by createdAt descending (so newest assignments are on the right/left)
      _assignments = assignmentsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _assignments.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return aDate.compareTo(bDate); // Oldest first (left to right)
      });

      final studentIds = _students.map((s) => s['id'] as String).toList();
      List<Map<String, dynamic>> allSubmissions = [];

      if (studentIds.isNotEmpty) {
        for (var i = 0; i < studentIds.length; i += 30) {
          final chunk = studentIds.sublist(i, min(i + 30, studentIds.length));
          final snap = await FirebaseFirestore.instance
              .collection('submissions')
              .where('studentId', whereIn: chunk)
              .get();
          allSubmissions.addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
        }
      }
      _submissions = allSubmissions;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading report data: $e';
      });
    }
  }

  Map<String, dynamic>? _getSubmission(String assignmentId, String studentId) {
    try {
      return _submissions.firstWhere(
        (s) => s['assignmentId'] == assignmentId && s['studentId'] == studentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Report Card')),
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error, fontSize: 16))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$_groupName — Report Card',
          style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _students.isEmpty
            ? const Center(child: Text('No students in this group.', style: TextStyle(color: AppColors.mutedForeground)))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Legend Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 15, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('Correct', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel, size: 15, color: AppColors.error),
                                  SizedBox(width: 4),
                                  Text('Incorrect', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty, size: 15, color: AppColors.warning),
                                  SizedBox(width: 4),
                                  Text('Pending', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.remove, size: 15, color: AppColors.mutedForeground),
                                  SizedBox(width: 4),
                                  Text('Missing', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),


                        
                        // Table container
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        columnSpacing: 24,
                                        horizontalMargin: 16,
                                        headingRowColor: WidgetStateProperty.all(AppColors.primary.withAlpha(13)),
                                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13),
                                        dataTextStyle: const TextStyle(color: AppColors.text, fontSize: 13),
                                        columns: [
                                          const DataColumn(label: Text('Student')),
                                          const DataColumn(label: Text('Sub Rate')),
                                          const DataColumn(label: Text('Correct')),
                                          const DataColumn(label: Text('Incorrect')),
                                          const DataColumn(label: Text('Pending')),
                                          ..._assignments.asMap().entries.map((entry) {
                                            final idx = entry.key + 1;
                                            final a = entry.value;
                                            final title = a['title'] as String? ?? 'Assignment';
                                            return DataColumn(
                                              label: Tooltip(
                                                message: 'View $title',
                                                child: InkWell(
                                                  onTap: () => context.push('/assignment/${a['id']}'),
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                    child: Text(
                                                      'Assignment $idx',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                        rows: _students.map((student) {
                                          final studentId = student['id'] as String;
                                          final studentLevelId = student['levelId'] as String?;

                                          // Filter assignments assigned to this student's level
                                          final studentAssignments = _assignments.where((a) {
                                            final aLevelId = a['levelId'] as String?;
                                            return aLevelId == null || aLevelId.isEmpty || aLevelId == studentLevelId;
                                          }).toList();

                                          int correct = 0;
                                          int incorrect = 0;
                                          int pending = 0;
                                          int submitted = 0;

                                          for (final a in studentAssignments) {
                                            final sub = _getSubmission(a['id'], studentId);
                                            if (sub != null) {
                                              submitted++;
                                              final status = sub['status'] as String? ?? 'pending';
                                              if (status == 'correct') {
                                                correct++;
                                              } else if (status == 'incorrect') {
                                                incorrect++;
                                              } else {
                                                pending++;
                                              }
                                            }
                                          }

                                          final subRate = studentAssignments.isNotEmpty
                                              ? (submitted / studentAssignments.length) * 100
                                              : 0.0;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(student['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('@${student['username'] ?? ''}', style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                BadgeWidget(
                                                  label: '${subRate.toStringAsFixed(0)}%',
                                                  variant: subRate >= 80
                                                      ? BadgeVariant.success
                                                      : (subRate >= 50 ? BadgeVariant.warning : BadgeVariant.error),
                                                ),
                                              ),
                                              DataCell(Text('$correct', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                                              DataCell(Text('$incorrect', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                                              DataCell(Text('$pending', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold))),
                                              ..._assignments.map((a) {
                                                final isAssignedToLevel = a['levelId'] == null ||
                                                    a['levelId'].isEmpty ||
                                                    a['levelId'] == studentLevelId;

                                                if (!isAssignedToLevel) {
                                                  return const DataCell(Center(child: Icon(Icons.remove, size: 16, color: AppColors.mutedForeground)));
                                                }

                                                final sub = _getSubmission(a['id'], studentId);
                                                if (sub == null) {
                                                  return const DataCell(Center(child: Icon(Icons.remove, size: 16, color: AppColors.mutedForeground)));
                                                }

                                                final status = sub['status'] as String? ?? 'pending';
                                                if (status == 'correct') {
                                                  return const DataCell(Center(child: Icon(Icons.check_circle, size: 16, color: AppColors.success)));
                                                } else if (status == 'incorrect') {
                                                  return const DataCell(Center(child: Icon(Icons.cancel, size: 16, color: AppColors.error)));
                                                } else {
                                                  return const DataCell(Center(child: Icon(Icons.hourglass_empty, size: 16, color: AppColors.warning)));
                                                }
                                              }),
                                            ],
                                          );
                                        }).toList(),
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
                  ),
                ),
              ),
      ),
    );
  }
}
