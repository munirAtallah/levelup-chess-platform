import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:secure_application/secure_application.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'pdf_web_stub.dart'
    if (dart.library.html) 'pdf_web_impl.dart';

/// Secure PDF viewer that supports two sources:
/// - [pdfBytes]: in-memory bytes (from PDF export)
/// - [storagePath]: Firebase Storage path (fetches bytes, renders in-app)
class SecurePdfViewerScreen extends StatefulWidget {
  final Uint8List? pdfBytes;
  final String? storagePath;
  final String title;

  const SecurePdfViewerScreen({
    super.key,
    this.pdfBytes,
    this.storagePath,
    required this.title,
  });

  @override
  State<SecurePdfViewerScreen> createState() => _SecurePdfViewerScreenState();
}

class _SecurePdfViewerScreenState extends State<SecurePdfViewerScreen> {
  Uint8List? _pdfBytesFromStorage;
  bool _loadingUrl = false;
  String? _urlError;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  // Web-only: created once when bytes arrive, stable across rebuilds
  String? _pdfViewId;
  String? _pdfBlobUrl;

  @override
  void initState() {
    super.initState();
    _secureScreen();
    if (widget.storagePath != null) {
      _fetchUrl();
    }
  }

  Future<void> _fetchUrl() async {
    setState(() {
      _loadingUrl = true;
      _urlError = null;
    });
    try {
      final url = await FirebaseStorage.instance
          .ref(widget.storagePath!)
          .getDownloadURL();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pdfBytesFromStorage = response.bodyBytes;
            _loadingUrl = false;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _urlError = e.toString();
          _loadingUrl = false;
        });
      }
    }
  }

  void _initWebPdfView() {
    if (_pdfViewId != null) return; // already initialized
    if (_pdfBytesFromStorage == null) return;

    _pdfViewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';
    final containerId = 'pdf-container-$_pdfViewId';
    _pdfBlobUrl = createBlobUrl(_pdfBytesFromStorage!);

    registerPdfViewFactory(_pdfViewId!, containerId, _pdfBlobUrl!);
  }

  Future<void> _secureScreen() async {
    if (!kIsWeb) {
      await ScreenProtector.preventScreenshotOn();
    }
  }

  @override
  void dispose() {
    if (_pdfBlobUrl != null) {
      revokeBlobUrl(_pdfBlobUrl!);
    }
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _unsecureScreen() async {
    if (!kIsWeb) {
      await ScreenProtector.preventScreenshotOff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureApplication(
      nativeRemoveDelay: 100,
      onNeedUnlock: (secure) => null,
      child: SecureGate(
        blurr: 20,
        opacity: 0.8,
        lockedBuilder: (context, secureNotifier) => Center(
          child: Text(AppLocalizations.of(context)!.secureModeEnabled),
        ),
        child: Builder(builder: (context) {
          SecureApplicationProvider.of(context)?.secure();
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('View only', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            body: _buildBody(),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    // In-memory bytes path (PDF export)
    if (widget.pdfBytes != null) {
      return PdfPreview(
        build: (format) => widget.pdfBytes!,
        allowSharing: false,
        allowPrinting: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        padding: EdgeInsets.zero,
        maxPageWidth: double.infinity,
        initialPageFormat: const PdfPageFormat(
          390,
          844,
          marginTop: 24,
          marginBottom: 24,
          marginLeft: 20,
          marginRight: 20,
        ),
      );
    }

    // Firebase Storage path
    if (_loadingUrl) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_urlError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load PDF', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchUrl,
              child: const Text('Try again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_pdfBytesFromStorage != null) {
      if (kIsWeb) {
        _initWebPdfView();
        if (_pdfViewId != null) {
          return HtmlElementView(viewType: _pdfViewId!);
        }
      } else {
        return SfPdfViewer.memory(
          _pdfBytesFromStorage!,
          controller: _pdfViewerController,
          initialZoomLevel: 1.0,
          maxZoomLevel: 3.0,
          enableDoubleTapZooming: true,
          enableTextSelection: false,
        );
      }
    }

    return const Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48));
  }
}
