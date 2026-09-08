import 'dart:typed_data';

import 'package:flutter/material.dart';
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
      ),
      home: const DesignEditorPage(),
    );
  }
}

class DesignEditorPage extends StatefulWidget {
  const DesignEditorPage({super.key});

  @override
  State<DesignEditorPage> createState() =>
      _DesignEditorPageState();
}

class _DesignEditorPageState extends State<DesignEditorPage> {
  final ImagePicker picker = ImagePicker();

  Uint8List? selectedImage;
  List<StitchPoint> stitches = [];

  double width = 50;
  double height = 50;
  double density = 3;
  double threshold = 180;

  bool isConverting = false;
  bool isExporting = false;

  Future<void> pickImage() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = bytes;
        stitches = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'وێنەکە بە سەرکەوتوویی هێنرا.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هەڵە لە هێنانی وێنە: $e',
          ),
        ),
      );
    }
  }

  Future<void> convertToStitches() async {
    if (selectedImage == null) {
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
      final result = StitchEngine.imageToStitches(
        selectedImage!,
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

      if (stitches.isEmpty) {
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
            '${stitches.length} Stitch دروست کرا.',
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
      final bytes = DstExporter.createDst(
        stitches,
        name: 'KURDDESIGN',
      );

      final file = XFile.fromData(
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
          files: [file],
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
      stitches = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KurdDesign-AI'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.design_services,
              size: 70,
            ),

            const SizedBox(height: 12),

            const Text(
              'KurdDesign-AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'PNG/JPG → Stitch → DST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            FilledButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'هێنانی وێنەی PNG / JPG',
              ),
            ),

            const SizedBox(height: 20),

            if (selectedImage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.memory(
                    selectedImage!,
                    height: 230,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قەبارەی نەخشە',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

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

                    const SizedBox(height: 10),

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

            const SizedBox(height: 20),

            // Stitch Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: stitches.isEmpty
                      ? const Center(
                          child: Text(
                            'Stitch Preview\n'
                            'وێنەکە بکە بە Stitch',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : CustomPaint(
                          painter: StitchPainter(stitches),
                          child: const SizedBox.expand(),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: isConverting
                  ? null
                  : convertToStitches,
              icon: isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                isConverting
                    ? 'لە کاردایە...'
                    : 'گۆڕینی وێنە بۆ Stitch',
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: isExporting
                  ? null
                  : createDst,
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                isExporting
                    ? 'ئامادە دەکرێت...'
                    : 'دروستکردن و ناردنی DST',
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

            const SizedBox(height: 20),

            if (stitches.isNotEmpty)
              Center(
                child: Text(
                  '${stitches.length} Stitch',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

  StitchPainter(this.stitches);

  @override
  void paint(Canvas canvas, Size size) {
    if (stitches.isEmpty) return;

    // Find the design boundaries.
    var minX = stitches.first.x.toDouble();
    var maxX = stitches.first.x.toDouble();
    var minY = stitches.first.y.toDouble();
    var maxY = stitches.first.y.toDouble();

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

    const padding = 25.0;

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

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final designCenterX =
        (minX + maxX) / 2;

    final designCenterY =
        (minY + maxY) / 2;

    // Embroidery stitch paint.
    final stitchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Stitch center point.
    final pointPaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw each stitch as a short mark.
    // We intentionally do NOT connect every stitch
    // with one long continuous line.
    for (var i = 0; i < stitches.length; i++) {
      final stitch = stitches[i];

      final x = centerX +
          (stitch.x - designCenterX) * scale;

      final y = centerY +
          (stitch.y - designCenterY) * scale;

      // Keep stitch marks visible.
      final stitchLength =
          (3.0 * scale).clamp(2.0, 5.0);

      // Alternate stitch direction.
      final direction =
          i.isEven ? 1.0 : -1.0;

      final start = Offset(
        x - stitchLength,
        y - stitchLength * direction,
      );

      final end = Offset(
        x + stitchLength,
        y + stitchLength * direction,
      );

      // Individual embroidery stitch.
      canvas.drawLine(
        start,
        end,
        stitchPaint,
      );

      // Small center point.
      canvas.drawCircle(
        Offset(x, y),
        0.8,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant StitchPainter oldDelegate,
  ) {
    return oldDelegate.stitches != stitches;
  }
}
