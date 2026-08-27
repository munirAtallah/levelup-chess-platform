/// Presentation Tier — Screen
/// Path: lib/presentation/screens/details/student_assignment_detail_screen.dart
///
/// ✅ Decoupled view for students taking an assignment
/// ✅ Renders text fields vs MCQ radios dynamically
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/assignment_model.dart';
import '../../widgets/vibe_premium_renderer.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/repositories/submission_repository.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<StudentAssignmentDetailScreen> createState() => _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState extends State<StudentAssignmentDetailScreen> {
  final SubmissionRepository _submissionRepo = getIt<SubmissionRepository>();
  final TextEditingController _textCtrl = TextEditingController();
  SubmissionModel? _submission;
  String _textAnswer = '';
  String? _selectedChoice;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    final sub = await _submissionRepo.getSubmissionForAssignment(widget.assignment.id, uid);
    if (mounted) {
      setState(() {
        _submission = sub;
        if (sub != null) {
          _textAnswer = sub.answer;
          _textCtrl.text = _textAnswer;
          _selectedChoice = sub.selectedChoice;
        }
        _isLoading = false;
      });
    }
  }

  bool get _isLocked => widget.assignment.isOverdue || (_submission != null && _submission!.status != GradeStatus.pending);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: Text(
          widget.assignment.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.assignment.isOverdue)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.deadlinePassedLocked,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Assignment details & instructions
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.assignment.type.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentDark, letterSpacing: 1),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.dueDeadlineLabel(widget.assignment.deadlineText),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.instructionsLabel,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          VibePremiumRenderer(
                            content: widget.assignment.textContent ?? 'No instructions provided.',
                          ),
                        ],
                      ),
                    ),

                    // Submission area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.yourAnswer,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (widget.assignment.assignmentType == AssignmentType.text)
                      _buildTextSubmission()
                    else
                      _buildMCQSubmission(),
                      
                    if (_submission != null && _submission!.status != GradeStatus.pending) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _submission!.status == GradeStatus.correct ? Colors.green.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _submission!.status == GradeStatus.correct ? Colors.green : AppColors.error),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_submission!.status == GradeStatus.correct ? Icons.check_circle : Icons.cancel, color: _submission!.status == GradeStatus.correct ? Colors.green : AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _submission!.status == GradeStatus.correct ? AppLocalizations.of(context)!.gradedCorrect : AppLocalizations.of(context)!.gradedIncorrect,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _submission!.status == GradeStatus.correct ? Colors.green : AppColors.error),
                                  ),
                                ],
                              ),
                              if (_submission!.feedback != null && _submission!.feedback!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _submission!.feedback!,
                                  style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Submit Button — only shown when actively working
            if (_submission == null || _isEditing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 0),
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.mutedForeground,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : Text(_submission != null ? AppLocalizations.of(context)!.updateAssignment : AppLocalizations.of(context)!.submitAssignment, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              )
            else if (_submission != null && !_isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.submittedLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSubmission() {
    if (_submission != null && !_isEditing && !_isLocked) {
      // Show read-only version
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                _textAnswer.isNotEmpty ? _textAnswer : AppLocalizations.of(context)!.noAnswerProvided,
                style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(AppLocalizations.of(context)!.editAnswer, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (_isLocked) {
      // Locked read-only
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Text(
          _textAnswer.isNotEmpty ? _textAnswer : 'No answer provided.',
          style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground, height: 1.5),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFc4b8da), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _textCtrl,
        onChanged: (val) => setState(() => _textAnswer = val),
        enabled: !_isLocked,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: _isLocked ? AppLocalizations.of(context)!.submissionLocked : AppLocalizations.of(context)!.typeAnswerHint,
          hintStyle: const TextStyle(color: AppColors.mutedForeground),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5),
      ),
    );
  }

  Widget _buildMCQSubmission() {
    final choices = widget.assignment.choices ?? [];
    // MCQ is interactive only when actively answering
    final bool isInteractive = !_isLocked && (_submission == null || _isEditing);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Choices — dimmed when not interactive
          Opacity(
            opacity: isInteractive ? 1.0 : 0.6,
            child: Column(
              children: choices.asMap().entries.map((entry) {
                final isSelected = _selectedChoice == entry.value;
                return GestureDetector(
                  onTap: isInteractive ? () => setState(() => _selectedChoice = entry.value) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isInteractive ? AppColors.primary.withValues(alpha: 0.05) : AppColors.background)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.mutedForeground.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                            ? const Icon(Icons.check, size: 14, color: AppColors.white)
                            : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryDark : AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // "Change Answer" — OUTSIDE Opacity, fully visible and tappable
          if (_submission != null && !_isEditing && !_isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: Text(AppLocalizations.of(context)!.changeAnswer, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    if (_isLocked || _isSaving) return false;
    if (widget.assignment.assignmentType == AssignmentType.text) {
      return _textAnswer.trim().isNotEmpty;
    } else {
      return _selectedChoice != null;
    }
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    final textAnswerToSave = widget.assignment.assignmentType == AssignmentType.multipleChoice
        ? (_selectedChoice ?? '')
        : _textAnswer;

    try {
      if (_submission == null) {
        await _submissionRepo.addSubmission(
          assignmentId: widget.assignment.id,
          studentId: uid,
          textContent: textAnswerToSave,
          selectedChoice: _selectedChoice,
        );
      } else {
        await _submissionRepo.updateSubmission(
          submissionId: _submission!.id,
          textContent: textAnswerToSave,
          selectedChoice: _selectedChoice,
        );
      }
      
      await _loadSubmission();
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.assignmentSaved), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('StudentAssignmentDetailScreen._submit error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving submission: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
