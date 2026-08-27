import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../screens/secure_pdf_viewer_screen.dart';
import 'quill_image_widget.dart';

class _PdfPlaceholderEmbedBuilder extends quill.EmbedBuilder {
  final List<Map<String, String>> attachments;
  final void Function(String path, String name)? onOpenViewer;

  _PdfPlaceholderEmbedBuilder({this.attachments = const [], this.onOpenViewer});

  String? _getStoragePath(String filename) {
    try {
      return attachments.firstWhere((a) => a['name'] == filename)['path'];
    } catch (_) {
      return null;
    }
  }

  @override
  String get key => 'pdf_placeholder';

  @override
  bool get expanded => true;

  Widget _buildPageThumb() {
    return Container(
      width: 80,
      height: 110,
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
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mutedForeground.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'view only',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: List.generate(3, (_) => _buildPageThumb())),
              ),
              if (_getStoragePath(filename) != null) ...[
                const Divider(height: 1, color: AppColors.border),
                InkWell(
                  onTap: () => onOpenViewer?.call(_getStoragePath(filename)!, filename),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

class CustomImageEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'image';

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data as String;
    final styleAttr = embedContext.node.style.attributes['style']?.value as String?;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: QuillImageWidget(
            imageUrl: imageUrl,
            styleAttr: styleAttr,
            borderRadius: 12.0,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class VibePremiumRenderer extends StatefulWidget {
  final String content;
  final List<Map<String, String>> attachments;

  const VibePremiumRenderer({
    super.key,
    required this.content,
    this.attachments = const [],
  });

  @override
  State<VibePremiumRenderer> createState() => _VibePremiumRendererState();
}

class _VibePremiumRendererState extends State<VibePremiumRenderer> {
  quill.QuillController? _quillController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(VibePremiumRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _initController();
    }
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

  void _initController() {
    if (_isQuillDelta(widget.content)) {
      try {
        final decoded = jsonDecode(widget.content);
        final rawOps = (decoded is Map && decoded.containsKey('ops')) ? decoded['ops'] : decoded;
        final ops = _sanitizeOps(rawOps as List);
        final doc = quill.Document.fromJson(ops);
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } catch (_) {
        _quillController = null;
      }
    } else {
      _quillController = null;
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  bool _isQuillDelta(String s) {
    if (s.isEmpty) return false;
    final trimmed = s.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic> && decoded.containsKey('ops')) return true;
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return (decoded.first as Map).containsKey('insert');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  bool _isPdfLink(String s) {
    final lower = s.trim().toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.contains('/pdf') ||
        (lower.startsWith('http') && lower.contains('pdf'));
  }

  bool _isImageUrl(String s) {
    final lower = s.trim().toLowerCase();
    return (lower.startsWith('http://') || lower.startsWith('https://')) &&
        (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp') || lower.endsWith('.gif'));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.trim().isEmpty) {
      return _buildEmptyState(context);
    }

    if (_isQuillDelta(widget.content) && _quillController != null) {
      return _buildDeltaContent(context);
    }

    if (_isPdfLink(widget.content)) {
      return _buildPdfCard(context);
    }

    if (_isImageUrl(widget.content)) {
      return _buildImageCard();
    }

    return _buildPlainText();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.mutedForeground.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.noContentProvided,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.mutedForeground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.pdfDocumentLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.content.trim().split('/').last,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context)!.viewLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        widget.content.trim(),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.mutedForeground),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.imageNotLoaded, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeltaContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: quill.QuillEditor.basic(
        controller: _quillController!,
        config: quill.QuillEditorConfig(
          scrollable: false,
          expands: false,
          embedBuilders: [
            CustomImageEmbedBuilder(),
            _PdfPlaceholderEmbedBuilder(
              attachments: widget.attachments,
              onOpenViewer: (path, name) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SecurePdfViewerScreen(
                      storagePath: path,
                      title: name,
                    ),
                  ),
                );
              },
            ),
          ],
          customStyleBuilder: (attribute) {
            if (attribute.key == quill.Attribute.font.key && attribute.value != null) {
              try {
                return GoogleFonts.getFont(attribute.value as String);
              } catch (_) {
                return TextStyle(fontFamily: attribute.value as String);
              }
            }
            return const TextStyle();
          },
        ),
      ),
    );
  }

  Widget _buildPlainText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.content.trim(),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.text,
          height: 1.65,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
