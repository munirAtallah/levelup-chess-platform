import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class QuillImageWidget extends StatefulWidget {
  final String imageUrl;
  final String? styleAttr;
  final double? maxHeight;
  final double borderRadius;
  final Alignment alignment;

  const QuillImageWidget({
    super.key,
    required this.imageUrl,
    this.styleAttr,
    this.maxHeight,
    this.borderRadius = 8.0,
    this.alignment = Alignment.centerLeft,
  });

  @override
  State<QuillImageWidget> createState() => _QuillImageWidgetState();
}

class _QuillImageWidgetState extends State<QuillImageWidget> {
  Uint8List? _cachedMemoryBytes;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void didUpdateWidget(covariant QuillImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initializeImage();
    }
  }

  void _initializeImage() {
    if (widget.imageUrl.startsWith('data:')) {
      try {
        final base64Str = widget.imageUrl.split(',').last;
        _cachedMemoryBytes = base64Decode(base64Str);
        _imageProvider = MemoryImage(_cachedMemoryBytes!);
      } catch (e) {
        _cachedMemoryBytes = null;
        _imageProvider = null;
      }
    } else if (widget.imageUrl.startsWith('assets/')) {
      _cachedMemoryBytes = null;
      _imageProvider = AssetImage(widget.imageUrl);
    } else {
      _cachedMemoryBytes = null;
      _imageProvider = NetworkImage(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProvider == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 24, color: Colors.grey),
            SizedBox(width: 8),
            Text('Image failed to load', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Parse size and alignment from styleAttr
    double? percentWidth;
    double? pixelWidth;
    Alignment alignment = widget.alignment;

    final style = widget.styleAttr;
    if (style != null && style.isNotEmpty) {
      // Look for percent width, e.g., width: 50%
      final percentMatch = RegExp(r'width:\s*([0-9.]+)%').firstMatch(style);
      if (percentMatch != null) {
        final val = double.tryParse(percentMatch.group(1) ?? '');
        if (val != null) {
          percentWidth = val / 100.0;
        }
      } else {
        // Look for pixel width, e.g., width: 300px or width: 300
        final pixelMatch = RegExp(r'width:\s*([0-9.]+)(px)?').firstMatch(style);
        if (pixelMatch != null) {
          pixelWidth = double.tryParse(pixelMatch.group(1) ?? '');
        }
      }

      // Look for alignment, e.g., alignment: center
      final alignMatch = RegExp(r'alignment:\s*(left|center|right);?').firstMatch(style);
      if (alignMatch != null) {
        final alignVal = alignMatch.group(1);
        if (alignVal == 'left') {
          alignment = Alignment.centerLeft;
        } else if (alignVal == 'center') {
          alignment = Alignment.center;
        } else if (alignVal == 'right') {
          alignment = Alignment.centerRight;
        }
      }
    }

    Widget imageWidget = Image(
      image: _imageProvider!,
      fit: BoxFit.contain,
      alignment: alignment, // Set alignment of the image within the container bounds
      errorBuilder: (context, error, stackTrace) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 24, color: Colors.grey),
            SizedBox(width: 8),
            Text('Error loading image', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      loadingBuilder: widget.imageUrl.startsWith('data:') || widget.imageUrl.startsWith('assets/')
          ? null
          : (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
    );

    if (widget.maxHeight != null) {
      final double scaleFactor = percentWidth ?? 1.0;
      imageWidget = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight! * scaleFactor),
        child: imageWidget,
      );
    }

    imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: imageWidget,
    );

    // Apply width constraints
    if (percentWidth != null) {
      imageWidget = FractionallySizedBox(
        widthFactor: percentWidth,
        child: imageWidget,
      );
    } else if (pixelWidth != null) {
      imageWidget = SizedBox(
        width: pixelWidth,
        child: imageWidget,
      );
    }

    return Align(
      alignment: alignment, // Align the container inside the parent editor/viewer
      child: imageWidget,
    );
  }
}
