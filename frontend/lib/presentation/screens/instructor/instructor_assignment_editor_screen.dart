// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:frontend/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../utils/editor_paste_listener.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/group_model.dart';
import '../../../theme/app_theme.dart';
import '../../../logic/controllers/instructor_assignment_controller.dart';
import '../../../logic/controllers/instructor_group_controller.dart';
import '../../../logic/controllers/auth_controller.dart';
import '../../../di/service_locator.dart';
import '../../widgets/quill_image_widget.dart';

class _ImageEmbedBuilder extends quill.EmbedBuilder {
  final quill.QuillController controller;
  _ImageEmbedBuilder({required this.controller});

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final src = embedContext.node.value.data as String;
    final styleAttr = embedContext.node.style.attributes['style']?.value as String?;

    // Get current width percentage
    double currentVal = 100.0;
    if (styleAttr != null) {
      final match = RegExp(r'width:\s*([0-9.]+)%').firstMatch(styleAttr);
      if (match != null) {
        currentVal = double.tryParse(match.group(1) ?? '') ?? 100.0;
      }
    }
    // Ensure currentVal is clamped between 10.0 and 100.0
    currentVal = currentVal.clamp(10.0, 100.0);

    // Get current alignment
    String currentAlign = 'left';
    if (styleAttr != null) {
      final match = RegExp(r'alignment:\s*(left|center|right)').firstMatch(styleAttr);
      if (match != null) {
        currentAlign = match.group(1) ?? 'left';
      }
    }

    Widget buildAlignButton(String value, IconData icon) {
      final isActive = currentAlign == value;
      return IconButton(
        icon: Icon(
          icon,
          size: 16,
          color: isActive ? AppColors.primary : AppColors.mutedForeground,
        ),
        onPressed: () {
          final offset = embedContext.node.documentOffset;
          controller.formatText(
            offset,
            1,
            quill.Attribute.fromKeyValue('style', 'width: ${currentVal.round()}%; alignment: $value;'),
          );
        },
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
        tooltip: 'Align ${value[0].toUpperCase()}${value.substring(1)}',
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      opaque: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuillImageWidget(
                imageUrl: src,
                styleAttr: styleAttr,
                maxHeight: 300,
                borderRadius: 8.0,
                alignment: Alignment.centerLeft,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 14, color: AppColors.mutedForeground),
                    const SizedBox(width: 4),
                    const Text('Image', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    const SizedBox(width: 8),
                    const Text(
                      'Resize:',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.0,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.border,
                                    thumbColor: AppColors.primary,
                                  ),
                                  child: Slider(
                                    value: currentVal,
                                    min: 10.0,
                                    max: 100.0,
                                    divisions: 18, // steps of 5% from 10% to 100%
                                    label: '${currentVal.round()}%',
                                    onChanged: (val) {
                                      setState(() {
                                        currentVal = val;
                                      });
                                      final offset = embedContext.node.documentOffset;
                                      controller.formatText(
                                        offset,
                                        1,
                                        quill.Attribute.fromKeyValue('style', 'width: ${val.round()}%; alignment: $currentAlign;'),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${currentVal.round()}%',
                                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildAlignButton('left', Icons.format_align_left_outlined),
                        buildAlignButton('center', Icons.format_align_center_outlined),
                        buildAlignButton('right', Icons.format_align_right_outlined),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      onPressed: () {
                        final offset = embedContext.node.documentOffset;
                        controller.document.delete(offset, 1);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorAssignmentEditorScreen extends StatefulWidget {
  final AssignmentModel? initialAssignment;

  const InstructorAssignmentEditorScreen({super.key, this.initialAssignment});

  @override
  State<InstructorAssignmentEditorScreen> createState() =>
      _InstructorAssignmentEditorScreenState();
}

class _InstructorAssignmentEditorScreenState extends State<InstructorAssignmentEditorScreen> {
  final InstructorAssignmentController _controller = getIt<InstructorAssignmentController>();
  final InstructorGroupController _groupController = getIt<InstructorGroupController>();
  final AuthController _authController = getIt<AuthController>();

  List<String> _assignedLevelIds = [];

  late TextEditingController _titleCtrl;
  late quill.QuillController _quillCtrl;
  StreamSubscription<quill.DocChange>? _docChangeSub;
  bool _processingImage = false;
  dynamic _pasteListener;
  bool _isUploadingFile = false;

  DateTime? _selectedDeadline;
  AssignmentType _selectedType = AssignmentType.text;
  List<TextEditingController> _choiceCtrls = [TextEditingController(), TextEditingController()];

  GroupModel? _selectedGroup;
  String? _selectedLevel;
  String? _preselectedGroupId;

  String? _selectedFontFamily;
  String? _selectedFontSize;
  final FocusNode _editorFocusNode = FocusNode();

  static final _quillToolbarConfig = quill.QuillSimpleToolbarConfig(
    multiRowsDisplay: false,
    showBoldButton: true,
    showItalicButton: true,
    showUnderLineButton: true,
    showHeaderStyle: true,
    showListBullets: true,
    showListNumbers: true,
    showDividers: false,
    showFontFamily: false,
    showFontSize: false,
    showBackgroundColorButton: false,
    showColorButton: false,
    showClearFormat: false,
    showAlignmentButtons: true,
    showJustifyAlignment: false,
    showIndent: false,
    showLink: false,
    showDirection: false,
    showSearchButton: false,
    showSubscript: false,
    showSuperscript: false,
    showCodeBlock: false,
    showInlineCode: false,
    showQuote: false,
    showStrikeThrough: false,
    showSmallButton: false,
  );

  static final _imageUrlRegex = RegExp(
    r'^https?://\S+\.(?:jpg|jpeg|png|gif|webp|svg)(\?[^\s]*)?\s*$',
    caseSensitive: false,
  );

  bool get _isEditMode =>
      widget.initialAssignment != null && widget.initialAssignment!.type == 'custom';

  @override
  void initState() {
    super.initState();
    _authController.getCurrentAssignedLevels().then((ids) {
      if (mounted) setState(() => _assignedLevelIds = ids);
    });

    final a = widget.initialAssignment;
    _titleCtrl = TextEditingController(text: a?.title ?? '');

    final clipCfg = quill.QuillControllerConfig(
      clipboardConfig: quill.QuillClipboardConfig(
        onImagePaste: (bytes) async =>
            'data:image/png;base64,${base64Encode(bytes)}',
      ),
    );

    if (a != null && (a.textContent?.isNotEmpty ?? false)) {
      try {
        _quillCtrl = quill.QuillController(
          document: quill.Document.fromJson(jsonDecode(a.textContent!) as List),
          selection: const TextSelection.collapsed(offset: 0),
          config: clipCfg,
        );
      } catch (_) {
        final doc = quill.Document();
        doc.insert(0, a.textContent!);
        _quillCtrl = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
          config: clipCfg,
        );
      }
    } else {
      _quillCtrl = quill.QuillController.basic(config: clipCfg);
    }

    if (_isEditMode && a != null) {
      _selectedDeadline = a.deadline;
      _selectedType = a.assignmentType;
      if (a.choices != null && a.choices!.isNotEmpty) {
        _choiceCtrls = a.choices!.map((c) => TextEditingController(text: c)).toList();
      }
      _preselectedGroupId = a.groupId;
      _selectedLevel = a.levelId;
    }

    _docChangeSub = _quillCtrl.document.changes.listen(_onDocumentChange);
    _pasteListener = addImagePasteListener(_quillCtrl);
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    removeImagePasteListener(_pasteListener);
    _docChangeSub?.cancel();
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    for (final c in _choiceCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDocumentChange(quill.DocChange change) {
    if (_processingImage || change.source != quill.ChangeSource.local) return;
    int offset = 0;
    for (final op in change.change.operations) {
      if (op.isRetain) {
        offset += op.length!;
      } else if (op.isInsert && op.data is String) {
        final raw = op.data as String;
        final url = raw.trim();
        if (_imageUrlRegex.hasMatch(url)) {
          _processingImage = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _quillCtrl.document.delete(offset, raw.length);
            _quillCtrl.document.insert(offset, '\n');
            _quillCtrl.document.insert(offset + 1, quill.BlockEmbed.image(url));
            _quillCtrl.document.insert(offset + 2, '\n');
            _processingImage = false;
          });
          return;
        }
        offset += raw.length;
      }
    }
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingFile = true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'materials/images/${timestamp}_${file.name}';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(bytes);
      final downloadUrl = await ref.getDownloadURL();

      final index = _quillCtrl.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      _quillCtrl.document.insert(safeIndex, '\n');
      _quillCtrl.document.insert(safeIndex + 1, quill.BlockEmbed.image(downloadUrl));
      _quillCtrl.document.insert(safeIndex + 2, '\n');
      _quillCtrl.updateSelection(
        TextSelection.collapsed(offset: safeIndex + 3),
        quill.ChangeSource.local,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline != null && _selectedDeadline!.isAfter(DateTime.now())
          ? _selectedDeadline!
          : DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDeadline != null
            ? TimeOfDay(hour: _selectedDeadline!.hour, minute: _selectedDeadline!.minute)
            : const TimeOfDay(hour: 23, minute: 59),
        initialEntryMode: TimePickerEntryMode.inputOnly,
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (title.isEmpty) {
      _showError(l10n.titleRequired);
      return;
    }
    if (_selectedDeadline == null) {
      _showError(l10n.selectDeadline);
      return;
    }

    GroupModel? groupToSave = _selectedGroup;
    if (groupToSave == null && _preselectedGroupId != null) {
      try {
        groupToSave = _groupController.myGroups.firstWhere((g) => g.id == _preselectedGroupId);
      } catch (_) {}
    }

    if (groupToSave == null) {
      _showError(l10n.chooseGroupHint);
      return;
    }
    if (_selectedLevel == null) {
      _showError(l10n.selectLevelHint);
      return;
    }

    List<String> choices = [];
    if (_selectedType == AssignmentType.multipleChoice) {
      choices = _choiceCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (choices.length < 2) {
        _showError(l10n.atLeast2Options);
        return;
      }
    }

    final deltaJson = jsonEncode(_quillCtrl.document.toDelta().toJson());
    final a = widget.initialAssignment;

    try {
      if (_isEditMode && a != null) {
        await _controller.updateContent(
          a.id, title, deltaJson, _selectedType, choices,
          groupId: groupToSave.id,
          groupName: groupToSave.name,
          levelId: _selectedLevel,
        );
        if (_selectedDeadline != a.deadline) {
          await _controller.updateDeadline(a.id, _selectedDeadline!);
        }
      } else {
        await _controller.addAssignment(
          title,
          deadline: _selectedDeadline,
          textContent: deltaJson,
          assignmentType: _selectedType,
          choices: choices,
          groupId: groupToSave.id,
          groupName: groupToSave.name,
          levelId: _selectedLevel,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    GroupModel? resolvedGroup = _selectedGroup;
    if (resolvedGroup == null && _preselectedGroupId != null) {
      try {
        resolvedGroup = _groupController.myGroups.firstWhere((g) => g.id == _preselectedGroupId);
      } catch (_) {}
    }

    final groups = _groupController.myGroups;
    final levels = (resolvedGroup?.activeLevels.toList() ?? <String>[])
        .where((l) => _assignedLevelIds.contains(l))
        .toList();
    if (_selectedLevel != null && !levels.contains(_selectedLevel)) {
      levels.add(_selectedLevel!);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? l10n.editContent : l10n.createAssignment,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isUploadingFile ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                _isEditMode ? l10n.saveChanges : l10n.createButton,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Formatting toolbar
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            // Font family dropdown
                            SizedBox(
                              width: 100,
                              child: DropdownButton<String>(
                                value: _selectedFontFamily,
                                hint: const Text('Font', style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppColors.text),
                                items: const [
                                  DropdownMenuItem(value: 'IBM Plex Sans Arabic', child: Text('IBM Plex', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Lato', child: Text('Lato', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Merriweather', child: Text('Merriweather', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Playfair Display', child: Text('Playfair', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Courier Prime', child: Text('Courier', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (font) {
                                  setState(() => _selectedFontFamily = font);
                                  if (font != null) {
                                    _quillCtrl.formatSelection(
                                      quill.Attribute.fromKeyValue(quill.Attribute.font.key, font),
                                    );
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) _editorFocusNode.requestFocus();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(height: 20, child: VerticalDivider(width: 1, color: AppColors.border)),
                            const SizedBox(width: 8),
                            // Font size dropdown
                            SizedBox(
                              width: 70,
                              child: DropdownButton<String>(
                                value: _selectedFontSize,
                                hint: const Text('Size', style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppColors.text),
                                items: ['12', '14', '16', '18', '20', '24', '28', '32', '36']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (size) {
                                  setState(() => _selectedFontSize = size);
                                  if (size != null) {
                                    _quillCtrl.formatSelection(
                                      quill.Attribute.fromKeyValue(quill.Attribute.size.key, size),
                                    );
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) _editorFocusNode.requestFocus();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      quill.QuillSimpleToolbar(
                        controller: _quillCtrl,
                        config: _quillToolbarConfig,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Attach toolbar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: kIsWeb ? 900 : double.infinity),
                  child: _isUploadingFile
                      ? const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading...', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.image_outlined, size: 16, color: AppColors.primary),
                                label: const Text('Upload Image', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: _uploadImage,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // Scrollable area for document and settings
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Title input
                          TextField(
                            controller: _titleCtrl,
                            maxLines: 2,
                            minLines: 1,
                            style: TextStyle(
                              fontSize: kIsWeb ? 24 : 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Assignment title...',
                              hintStyle: TextStyle(
                                fontSize: kIsWeb ? 24 : 20,
                                fontWeight: FontWeight.w300,
                                color: AppColors.mutedForeground.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Divider(color: AppColors.border, height: 28),
                          // White doc card
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(kIsWeb ? 12 : 8),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(kIsWeb ? 32 : 20),
                                child: IntrinsicHeight(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(minHeight: 300),
                                    child: quill.QuillEditor.basic(
                                      focusNode: _editorFocusNode,
                                      controller: _quillCtrl,
                                      config: quill.QuillEditorConfig(
                                        scrollable: false,
                                        expands: false,
                                        embedBuilders: [
                                          _ImageEmbedBuilder(controller: _quillCtrl),
                                        ],
                                        placeholder: l10n.hintAssignmentInstructions,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Settings Card
                          Text(
                            'Assignment Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Assignment Type Toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedType = AssignmentType.text),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _selectedType == AssignmentType.text ? AppColors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: _selectedType == AssignmentType.text
                                                  ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              l10n.textAnswerType,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedType == AssignmentType.text ? AppColors.primary : AppColors.mutedForeground,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedType = AssignmentType.multipleChoice),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _selectedType == AssignmentType.multipleChoice ? AppColors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: _selectedType == AssignmentType.multipleChoice
                                                  ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              l10n.multipleChoiceType,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _selectedType == AssignmentType.multipleChoice ? AppColors.primary : AppColors.mutedForeground,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedType == AssignmentType.multipleChoice) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Multiple Choice Options (2 to 4)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(_choiceCtrls.length, (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _choiceCtrls[i],
                                            decoration: InputDecoration(
                                              hintText: l10n.hintOptionN((i + 1).toString()),
                                              isDense: true,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.2)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
                                            ),
                                          ),
                                        ),
                                        if (_choiceCtrls.length > 2)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                            onPressed: () => setState(() => _choiceCtrls.removeAt(i)),
                                          ),
                                      ],
                                    ),
                                  )),
                                  if (_choiceCtrls.length < 4)
                                    TextButton.icon(
                                      onPressed: () => setState(() => _choiceCtrls.add(TextEditingController())),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(l10n.addOptionButton),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                                    ),
                                ],
                                const SizedBox(height: 16),

                                // Group Picker
                                Text(
                                  'Assign to Group',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<GroupModel>(
                                      value: resolvedGroup,
                                      hint: Text(l10n.chooseGroupHint, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedForeground),
                                      items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
                                      onChanged: (val) => setState(() {
                                        _selectedGroup = val;
                                        _selectedLevel = null;
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Level Picker
                                Text(
                                  'Level within Group',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                Opacity(
                                  opacity: resolvedGroup == null ? 0.4 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedLevel,
                                        hint: Text(l10n.selectLevelHint, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedForeground),
                                        items: levels.map((l) => DropdownMenuItem(
                                          value: l,
                                          child: Text(l10n.levelLabel(l.replaceAll('l', '')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        )).toList(),
                                        onChanged: resolvedGroup == null ? null : (val) => setState(() => _selectedLevel = val),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Deadline Picker
                                Text(
                                  'Deadline',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickDeadline,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _selectedDeadline != null ? AppColors.primary : AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _selectedDeadline != null ? AppColors.primary : AppColors.mutedForeground),
                                        const SizedBox(width: 10),
                                        Text(
                                          _selectedDeadline != null
                                              ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}  ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'
                                              : l10n.selectDeadline,
                                          style: TextStyle(fontSize: 13, color: _selectedDeadline != null ? AppColors.text : AppColors.mutedForeground),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
