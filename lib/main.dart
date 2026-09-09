import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'dst_export.dart';
import 'stitch_engine.dart';

void main() {
  runApp(const KurdDesignAI());
}

class KurdDesignAI extends StatelessWidget {
  const KurdDesignAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KurdDesign-AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F7FA),
      ),
      home: const DesignEditorPage(),
    );
  }
}

class DesignEditorPage extends StatefulWidget {
  const DesignEditorPage({super.key});

  @override
  State<DesignEditorPage> createState() => _DesignEditorPageState();
}

class _DesignEditorPageState extends State<DesignEditorPage> {
  final ImagePicker picker = ImagePicker();

  Uint8List? selectedImage;
  Uint8List? previewImage;

  List<StitchPoint> stitches = [];

  double width = 50;
  double height = 50;
  double density = 3;
  double threshold = 180;

  bool isConverting = false;
  bool isExporting = false;
  bool isPreparingImage = false;

  String? previewError;

  Future<Uint8List> _prepareImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return bytes;
      }

      final normalized = img.bakeOrientation(decoded);
      final pngBytes = img.encodePng(normalized);

      return Uint8List.fromList(pngBytes);
    } catch (_) {
      return bytes;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'وێنەکە بەتاڵە یان ناتوانرێت بخوێندرێتەوە.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        isPreparingImage = true;
        selectedImage = bytes;
        previewImage = null;
        previewError = null;
        stitches = [];
      });

      final Uint8List prepared = await _prepareImage(bytes);

      if (!mounted) return;

      setState(() {
        previewImage = prepared;
        isPreparingImage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isPreparingImage = false;
        previewError = 'نەتوانرا وێنەکە ئامادە بکرێت.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هەڵە لە هێنانی وێنە: $e'),
        ),
      );
    }
  }

  Future<void> convertToStitches() async {
    final Uint8List? imageBytes = previewImage ?? selectedImage;

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سەرەتا PNG یان JPG هەڵبژێرە.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isConverting = true;
    });

    try {
      final List<StitchPoint> result =
          StitchEngine.imageToStitches(
        imageBytes,
        maxSize: 400,
        density: density,
        widthMm: width,
        heightMm: height,
        threshold: threshold.round(),
      );

      if (!mounted) return;

      setState(() {
        stitches = result;
        isConverting = false;
      });

      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'هیچ Stitch ـێک نەدۆزرایەوە. Threshold زیاد بکە.',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.length} Stitch دروست کرا.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConverting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هەڵە لە گۆڕینی وێنە: $e',
          ),
        ),
      );
    }
  }

  Future<void> createDst() async {
    if (stitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سەرەتا وێنەکە بکە بە Stitch.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      final Uint8List bytes = DstExporter.createDst(
        stitches,
        name: 'KURDDESIGN',
      );

      final XFile file = XFile.fromData(
        bytes,
        name: 'KURDDESIGN.dst',
        mimeType: 'application/octet-stream',
      );

      if (!mounted) return;

      setState(() {
        isExporting = false;
      });

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[file],
          subject: 'KurdDesign-AI DST',
          text: 'KurdDesign-AI embroidery design',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isExporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هەڵە لە دروستکردنی DST: $e',
          ),
        ),
      );
    }
  }

  void clearDesign() {
    setState(() {
      selectedImage = null;
      previewImage = null;
      previewError = null;
      stitches = [];
    });
  }

  Widget _buildDesignPreview() {
    if (isPreparingImage) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final Uint8List? imageBytes =
        previewImage ?? selectedImage;

    if (imageBytes == null) {
      return const Center(
        child: Text(
          'سەرەتا وێنەیەک هەڵبژێرە',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (previewError != null) {
      return Center(
        child: Text(
          previewError!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Image.memory(
          imageBytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const Center(
              child: Text(
                'نەتوانرا وێنەکە پیشان بدرێت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KurdDesign-AI',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDE7F6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.design_services,
              size: 64,
            ),

            const SizedBox(height: 10),

            const Text(
              'KurdDesign-AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'PNG/JPG → Stitch → DST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
                  isPreparingImage ? null : pickImage,
              icon: const Icon(
                Icons.photo_library,
              ),
              label: const Text(
                'هێنانی وێنەی PNG / JPG',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (selectedImage != null)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _sectionTitle(
                        'Design Preview',
                        'وێنەی ڕەنگاڵە و نووسینی نەخشەکە',
                      ),

                      const SizedBox(height: 12),

                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: _buildDesignPreview(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 18),

            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قەبارە و ڕێکخستن',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'پانی: ${width.round()} mm',
                    ),

                    Slider(
                      value: width,
                      min: 10,
                      max: 200,
                      divisions: 38,
                      onChanged: (value) {
                        setState(() {
                          width = value;
                        });
                      },
                    ),

                    Text(
                      'بەرزی: ${height.round()} mm',
                    ),

                    Slider(
                      value: height,
                      min: 10,
                      max: 200,
                      divisions: 38,
                      onChanged: (value) {
                        setState(() {
                          height = value;
                        });
                      },
                    ),

                    Text(
                      'Stitch Density: '
                      '${density.toStringAsFixed(1)}',
                    ),

                    Slider(
                      value: density,
                      min: 1,
                      max: 8,
                      divisions: 14,
                      onChanged: (value) {
                        setState(() {
                          density = value;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Image Threshold: '
                      '${threshold.round()}',
                    ),

                    Slider(
                      value: threshold,
                      min: 50,
                      max: 240,
                      divisions: 38,
                      onChanged: (value) {
                        setState(() {
                          threshold = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _sectionTitle(
                      'Stitch Preview',
                      'پێشبینینی نەخشەی دوورین',
                    ),

                    const SizedBox(height: 12),

                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: stitches.isEmpty
                          ? const Center(
                              child: Text(
                                'وێنەکە بکە بە Stitch',
                                textAlign:
                                    TextAlign.center,
                              ),
                            )
                          : CustomPaint(
                              painter: StitchPainter(
                                stitches,
                                imageBytes:
                                    previewImage ??
                                    selectedImage,
                              ),
                              child:
                                  const SizedBox.expand(),
                            ),
                    ),

                    if (stitches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${stitches.length} Stitch',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed:
                  isConverting
                      ? null
                      : convertToStitches,
              icon: isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                    ),
              label: Text(
                isConverting
                    ? 'لە کاردایە...'
                    : 'گۆڕینی وێنە بۆ Stitch',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed:
                  isExporting ? null : createDst,
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.download,
                    ),
              label: Text(
                isExporting
                    ? 'ئامادە دەکرێت...'
                    : 'دروستکردن و ناردنی DST',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: clearDesign,
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'پاککردنەوە',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StitchPainter extends CustomPainter {
  final List<StitchPoint> stitches;
  final Uint8List? imageBytes;

  StitchPainter(
    this.stitches, {
    this.imageBytes,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (stitches.isEmpty) {
      return;
    }

    double minX = stitches.first.x.toDouble();
    double maxX = stitches.first.x.toDouble();
    double minY = stitches.first.y.toDouble();
    double maxY = stitches.first.y.toDouble();

    for (final stitch in stitches) {
      final x = stitch.x.toDouble();
      final y = stitch.y.toDouble();

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final designWidth = maxX - minX;
    final designHeight = maxY - minY;

    if (designWidth <= 0 || designHeight <= 0) {
      return;
    }

    const padding = 28.0;

    final availableWidth =
        size.width - padding * 2;

    final availableHeight =
        size.height - padding * 2;

    final scaleX =
        availableWidth / designWidth;

    final scaleY =
        availableHeight / designHeight;

    final scale =
        scaleX < scaleY ? scaleX : scaleY;

    if (scale.isInfinite || scale.isNaN) {
      return;
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final designCenterX =
        (minX + maxX) / 2;

    final designCenterY =
        (minY + maxY) / 2;

    img.Image? sourceImage;

    if (imageBytes != null) {
      try {
        sourceImage =
            img.decodeImage(imageBytes!);
      } catch (_) {
        sourceImage = null;
      }
    }

    int previewStep;

    if (stitches.length > 20000) {
      previewStep = 10;
    } else if (stitches.length > 12000) {
      previewStep = 8;
    } else if (stitches.length > 8000) {
      previewStep = 6;
    } else if (stitches.length > 4000) {
      previewStep = 4;
    } else if (stitches.length > 2000) {
      previewStep = 3;
    } else {
      previewStep = 2;
    }

    for (
      int i = 0;
      i < stitches.length;
      i += previewStep
    ) {
      final stitch = stitches[i];

      final x =
          centerX +
          (stitch.x - designCenterX) * scale;

      final y =
          centerY +
          (stitch.y - designCenterY) * scale;

      if (x < -20 ||
          x > size.width + 20 ||
          y < -20 ||
          y > size.height + 20) {
        continue;
      }

      Color stitchColor =
          const Color(0xFF5E35B1);

      if (sourceImage != null) {
        final normalizedX =
            (stitch.x - minX) / designWidth;

        final normalizedY =
            (stitch.y - minY) / designHeight;

        final imageX =
            (normalizedX *
                    (sourceImage.width - 1))
                .round()
                .clamp(
                  0,
                  sourceImage.width - 1,
                );

        final imageY =
            (normalizedY *
                    (sourceImage.height - 1))
                .round()
                .clamp(
                  0,
                  sourceImage.height - 1,
                );

        final pixel =
            sourceImage.getPixel(
          imageX,
          imageY,
        );

        stitchColor = Color.fromARGB(
          255,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
      }

      final paint = Paint()
        ..color = stitchColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round;

      final pointPaint = Paint()
        ..color = stitchColor
        ..style = PaintingStyle.fill;

      final direction =
          ((i ~/ previewStep) % 2 == 0)
              ? 1.0
              : -1.0;

      double stitchLength = 2.7;

      if (scale > 3) {
        stitchLength = 3.2;
      }

      canvas.drawLine(
        Offset(
          x - stitchLength,
          y - stitchLength * direction,
        ),
        Offset(
          x + stitchLength,
          y + stitchLength * direction,
        ),
        paint,
      );

      canvas.drawCircle(
        Offset(x, y),
        0.65,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant StitchPainter oldDelegate,
  ) {
    return oldDelegate.stitches != stitches ||
        oldDelegate.imageBytes != imageBytes;
  }
}
