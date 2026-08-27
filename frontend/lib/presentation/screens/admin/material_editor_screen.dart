// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:frontend/l10n/app_localizations.dart';
import '../../../utils/editor_paste_listener.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/models/instructor_material_model.dart';
import '../../../logic/controllers/curriculum_controller.dart';
import '../../../logic/controllers/instructor_material_controller.dart';
import '../../../di/service_locator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../secure_pdf_viewer_screen.dart';
import '../../widgets/quill_image_widget.dart';

// ── Embed builders ────────────────────────────────────────────────────────────

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

class PdfBlockEmbed extends quill.CustomBlockEmbed {
  static const String pdfType = 'pdf_placeholder';
  const PdfBlockEmbed(String filename) : super(pdfType, filename);
}

class _PdfEmbedBuilder extends quill.EmbedBuilder {
  final quill.QuillController controller;
  final List<Map<String, String>> attachments;
  final void Function(String storagePath, String title)? onOpenViewer;

  _PdfEmbedBuilder({
    required this.controller,
    this.attachments = const [],
    this.onOpenViewer,
  });

  String? _getStoragePath(String filename) {
    try {
      return attachments.firstWhere((a) => a['name'] == filename)['path'];
    } catch (_) {
      return null;
    }
  }

  @override
  String get key => PdfBlockEmbed.pdfType;

  @override
  bool get expanded => true;

  Widget _buildPageThumb() {
    return Container(
      width: 90,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          7,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final filename = embedContext.node.value.data as String;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      opaque: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filename,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
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
              const Divider(height: 1, color: AppColors.border),
              // Page thumbnails
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: List.generate(3, (_) => _buildPageThumb()),
                ),
              ),
              // Open viewer (only if storage path available)
              if (_getStoragePath(filename) != null) ...[
                const Divider(height: 1, color: AppColors.border),
                InkWell(
                  onTap: () => onOpenViewer?.call(_getStoragePath(filename)!, filename),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Open full PDF viewer',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MaterialEditorScreen extends StatefulWidget {
  // ── Admin curriculum mode (original) ──
  final String levelId;
  final String weekId;
  final String? itemId;
  final CurriculumItem? item;

  // ── Instructor material mode ──
  final bool isInstructorMaterial;
  final String? instructorMaterialId;
  final InstructorMaterialModel? instructorMaterial;
  final String? groupId;
  final String? materialLevelId;

  const MaterialEditorScreen({
    super.key,
    this.levelId = '',
    this.weekId = '',
    this.itemId,
    this.item,
    // Instructor-material params
    this.isInstructorMaterial = false,
    this.instructorMaterialId,
    this.instructorMaterial,
    this.groupId,
    this.materialLevelId,
  });

  @override
  State<MaterialEditorScreen> createState() => _MaterialEditorScreenState();
}

class _MaterialEditorScreenState extends State<MaterialEditorScreen> {
  // Controllers
  final CurriculumController _curriculumController = getIt<CurriculumController>();
  final InstructorMaterialController _materialController =
      getIt<InstructorMaterialController>();

  late TextEditingController _titleCtrl;
  late quill.QuillController _quillCtrl;
  StreamSubscription<quill.DocChange>? _docChangeSub;
  bool _processingImage = false;
  dynamic _pasteListener;

  List<Map<String, String>> _attachments = [];
  bool _isUploadingFile = false;

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

  // ── Init / dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Pre-fill from whichever source is active.
    final existingTitle = widget.isInstructorMaterial
        ? (widget.instructorMaterial?.title ?? '')
        : (widget.item?.title ?? '');

    final existingContent = widget.isInstructorMaterial
        ? (widget.instructorMaterial?.deltaJson ??
            widget.instructorMaterial?.content)
        : (widget.item?.content ?? widget.item?.deltaJson);

    final existingAttachments = widget.isInstructorMaterial
        ? List<Map<String, String>>.from(
            widget.instructorMaterial?.attachments ?? [])
        : List<Map<String, String>>.from(widget.item?.attachments ?? []);

    _titleCtrl = TextEditingController(text: existingTitle);
    _attachments = existingAttachments;

    final clipCfg = quill.QuillControllerConfig(
      clipboardConfig: quill.QuillClipboardConfig(
        onImagePaste: (bytes) async =>
            'data:image/png;base64,${base64Encode(bytes)}',
      ),
    );

    if (existingContent != null && existingContent.isNotEmpty) {
      try {
        final ops = _sanitizeOps(jsonDecode(existingContent) as List);
        _quillCtrl = quill.QuillController(
          document: quill.Document.fromJson(ops),
          selection: const TextSelection.collapsed(offset: 0),
          config: clipCfg,
        );
      } catch (_) {
        _quillCtrl = quill.QuillController.basic(config: clipCfg);
      }
    } else {
      _quillCtrl = quill.QuillController.basic(config: clipCfg);
    }

    _docChangeSub = _quillCtrl.document.changes.listen(_onDocumentChange);
    _pasteListener = addImagePasteListener(_quillCtrl);
  }

  static List<dynamic> _sanitizeOps(List<dynamic> ops) {
    return ops.map((op) {
      if (op is Map<String, dynamic>) {
        final attrs = op['attributes'];
        if (attrs is Map<String, dynamic> && attrs.containsKey('size')) {
          final size = attrs['size'];
          if (size is String && size.endsWith('pt')) {
            final cleaned = Map<String, dynamic>.from(attrs)
              ..['size'] = size.replaceAll('pt', '');
            return {...op, 'attributes': cleaned};
          }
        }
      }
      return op;
    }).toList();
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    removeImagePasteListener(_pasteListener);
    _docChangeSub?.cancel();
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    super.dispose();
  }

  // ── Document change listener ──────────────────────────────────────────────

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

  // ── File uploads ──────────────────────────────────────────────────────────

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      final base64String = base64Encode(bytes);
      final extension = file.extension?.toLowerCase() ?? 'png';
      final dataUrl = 'data:image/$extension;base64,$base64String';

      final index = _quillCtrl.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      _quillCtrl.document.insert(safeIndex, '\n');
      _quillCtrl.document.insert(safeIndex + 1, quill.BlockEmbed.image(dataUrl));
      _quillCtrl.document.insert(safeIndex + 2, '\n');
      _quillCtrl.updateSelection(
        TextSelection.collapsed(offset: safeIndex + 3),
        quill.ChangeSource.local,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _uploadPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploadingFile = true);

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes.');

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use a different storage path for instructor materials.
      final String storagePath;
      if (widget.isInstructorMaterial) {
        final gId = widget.groupId ?? 'unknown';
        final lId = widget.materialLevelId ?? 'unknown';
        storagePath = 'materials/instructor_pdfs/${gId}_${lId}_$timestamp.pdf';
      } else {
        storagePath =
            'materials/pdfs/${widget.levelId}_${widget.weekId}_$timestamp.pdf';
      }

      await FirebaseStorage.instance.ref().child(storagePath).putData(bytes);

      setState(() {
        _attachments.add({'path': storagePath, 'name': file.name, 'type': 'pdf'});
      });

      final index = _quillCtrl.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      _quillCtrl.document.insert(safeIndex, '\n');
      _quillCtrl.document.insert(safeIndex + 1, PdfBlockEmbed(file.name));
      _quillCtrl.document.insert(safeIndex + 2, '\n');
      _quillCtrl.updateSelection(
        TextSelection.collapsed(offset: safeIndex + 3),
        quill.ChangeSource.local,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _openPdfViewer(String storagePath, String filename) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecurePdfViewerScreen(
          storagePath: storagePath,
          title: filename,
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Collect only PDFs still present in the document.
    final presentFilenames = <String>{};
    for (final op in _quillCtrl.document.toDelta().operations) {
      if (op.isInsert && op.data is Map) {
        final data = op.data as Map;
        if (data.containsKey('pdf_placeholder')) {
          presentFilenames.add(data['pdf_placeholder'] as String);
        }
      }
    }
    final activeAttachments = _attachments
        .where((a) => presentFilenames.contains(a['name']))
        .toList();

    final deltaJson = jsonEncode(_quillCtrl.document.toDelta().toJson());

    try {
      if (widget.isInstructorMaterial) {
        await _saveInstructorMaterial(title, deltaJson, activeAttachments);
      } else {
        await _saveCurriculumMaterial(title, deltaJson, activeAttachments);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveInstructorMaterial(
    String title,
    String deltaJson,
    List<Map<String, String>> attachments,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final groupId = widget.groupId ?? '';
    final levelId = widget.materialLevelId ?? '';

    if (widget.instructorMaterialId != null) {
      // Edit existing
      await _materialController.updateMaterial(
        widget.instructorMaterialId!,
        title,
        deltaJson,
        attachments,
        instructorId: uid,
      );
    } else {
      // Create new
      await _materialController.addMaterial(
        title: title,
        deltaJson: deltaJson,
        attachments: attachments,
        instructorId: uid,
        groupId: groupId,
        levelId: levelId,
      );
    }
  }

  Future<void> _saveCurriculumMaterial(
    String title,
    String deltaJson,
    List<Map<String, String>> attachments,
  ) async {
    if (widget.item != null) {
      await _curriculumController.updateItem(
        widget.levelId,
        widget.weekId,
        widget.itemId!,
        title,
        deltaJson,
        deltaJson: deltaJson,
        attachments: attachments,
      );
    } else {
      await _curriculumController.addMaterial(
        widget.levelId,
        widget.weekId,
        title,
        content: deltaJson,
        deltaJson: deltaJson,
        attachments: attachments,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.isInstructorMaterial
        ? widget.instructorMaterialId != null
        : widget.item != null;

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
          isEdit ? 'Edit Material' : l10n.addMaterialTitle,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isUploadingFile ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                isEdit ? 'Save' : l10n.add,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Formatting toolbar ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            // Font family dropdown
                            SizedBox(
                              width: 100,
                              child: DropdownButton<String>(
                                value: _selectedFontFamily,
                                hint: const Text('Font',
                                    style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text),
                                items: [
                                  DropdownMenuItem(
                                      value: 'IBM Plex Sans Arabic',
                                      child: Text('IBM Plex',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'Roboto',
                                      child: Text('Roboto',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'Lato',
                                      child: Text('Lato',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'Merriweather',
                                      child: Text('Merriweather',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'Playfair Display',
                                      child: Text('Playfair',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'Courier Prime',
                                      child: Text('Courier',
                                          style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (font) {
                                  setState(() => _selectedFontFamily = font);
                                  if (font != null) {
                                    _quillCtrl.formatSelection(
                                      quill.Attribute.fromKeyValue(
                                          quill.Attribute.font.key, font),
                                    );
                                  }
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted)
                                      _editorFocusNode.requestFocus();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(
                                height: 20,
                                child: VerticalDivider(
                                    width: 1, color: AppColors.border)),
                            const SizedBox(width: 8),
                            // Font size dropdown
                            SizedBox(
                              width: 70,
                              child: DropdownButton<String>(
                                value: _selectedFontSize,
                                hint: const Text('Size',
                                    style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text),
                                items: [
                                  '12',
                                  '14',
                                  '16',
                                  '18',
                                  '20',
                                  '24',
                                  '28',
                                  '32',
                                  '36'
                                ]
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style: const TextStyle(
                                                fontSize: 12))))
                                    .toList(),
                                onChanged: (size) {
                                  setState(() => _selectedFontSize = size);
                                  if (size != null) {
                                    _quillCtrl.formatSelection(
                                      quill.Attribute.fromKeyValue(
                                          quill.Attribute.size.key, size),
                                    );
                                  }
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted)
                                      _editorFocusNode.requestFocus();
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
            // ── Attach toolbar ────────────────────────────────────────────
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: kIsWeb ? 900 : double.infinity),
                  child: _isUploadingFile
                      ? const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading...',
                                  style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12)),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.image_outlined,
                                    size: 16, color: AppColors.primary),
                                label: const Text('Image',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onPressed: _uploadImage,
                              ),
                            ),
                            const VerticalDivider(
                                width: 1, color: AppColors.border),
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 16,
                                    color: AppColors.primary),
                                label: const Text('PDF',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onPressed: _uploadPdf,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // ── Scrollable doc area ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: kIsWeb ? 20 : 16),
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
                              hintText: 'Material title...',
                              hintStyle: TextStyle(
                                fontSize: kIsWeb ? 24 : 20,
                                fontWeight: FontWeight.w300,
                                color: AppColors.mutedForeground
                                    .withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Divider(
                              color: AppColors.border, height: 28),
                          // White doc card
                          Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 820),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                      kIsWeb ? 12 : 8),
                                  border:
                                      Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(kIsWeb ? 32 : 20),
                                child: IntrinsicHeight(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        minHeight: 400),
                                    child: quill.QuillEditor.basic(
                                      focusNode: _editorFocusNode,
                                      controller: _quillCtrl,
                                      config: quill.QuillEditorConfig(
                                        scrollable: false,
                                        expands: false,
                                        embedBuilders: [
                                          _ImageEmbedBuilder(
                                              controller: _quillCtrl),
                                          _PdfEmbedBuilder(
                                            controller: _quillCtrl,
                                            attachments: _attachments,
                                            onOpenViewer: _openPdfViewer,
                                          ),
                                        ],
                                        placeholder: isEdit
                                            ? 'Edit material content…'
                                            : 'Write material content here…',
                                        customStyleBuilder: (attribute) {
                                          if (attribute.key ==
                                                  quill.Attribute.font
                                                      .key &&
                                              attribute.value != null) {
                                            try {
                                              return GoogleFonts.getFont(
                                                  attribute.value
                                                      as String);
                                            } catch (_) {
                                              return TextStyle(
                                                  fontFamily: attribute
                                                      .value as String);
                                            }
                                          }
                                          return const TextStyle();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
