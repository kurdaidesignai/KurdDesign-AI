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
        brightness: Brightness.light,
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
  Uint8List? previewImage;

  List<StitchPoint> stitches = [];

  double width = 50;
  double height = 50;
  double density = 3;
  double threshold = 180;

  bool isPreparingImage = false;
  bool isConverting = false;
  bool isExporting = false;

  String? imageError;

  Future<Uint8List> prepareImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return bytes;
      }

      final normalized = img.bakeOrientation(decoded);

      final png = img.encodePng(normalized);

      return Uint8List.fromList(png);
    } catch (_) {
      return bytes;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (file == null) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        showMessage(
          'وێنەکە بەتاڵە یان ناتوانرێت بخوێندرێتەوە.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        isPreparingImage = true;
        selectedImage = bytes;
        previewImage = null;
        imageError = null;
        stitches = [];
      });

      final Uint8List prepared = await prepareImage(bytes);

      if (!mounted) return;

      setState(() {
        previewImage = prepared;
        isPreparingImage = false;
      });

      showMessage('وێنەکە بە سەرکەوتوویی هێنرا.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isPreparingImage = false;
        imageError = 'نەتوانرا وێنەکە پیشان بدرێت.';
      });

      showMessage('هەڵە لە هێنانی وێنە: $e');
    }
  }

  Future<void> convertToStitches() async {
    final Uint8List? bytes =
        previewImage ?? selectedImage;

    if (bytes == null) {
      showMessage(
        'سەرەتا PNG یان JPG هەڵبژێرە.',
      );
      return;
    }

    if (isConverting) return;

    setState(() {
      isConverting = true;
    });

    try {
      final List<StitchPoint> result =
          StitchEngine.imageToStitches(
        bytes,
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
        showMessage(
          'هیچ Stitch ـێک نەدۆزرایەوە. Threshold بگۆڕە.',
        );
        return;
      }

      showMessage(
        '${result.length} Stitch دروست کرا.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConverting = false;
      });

      showMessage(
        'هەڵە لە گۆڕینی وێنە: $e',
      );
    }
  }

  Future<void> createDst() async {
    if (stitches.isEmpty) {
      showMessage(
        'سەرەتا وێنەکە بکە بە Stitch.',
      );
      return;
    }

    if (isExporting) return;

    setState(() {
      isExporting = true;
    });

    try {
      final Uint8List bytes =
          DstExporter.createDst(
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

      showMessage(
        'هەڵە لە دروستکردنی DST: $e',
      );
    }
  }

  void clearDesign() {
    setState(() {
      selectedImage = null;
      previewImage = null;
      imageError = null;
      stitches = [];
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget buildImagePreview() {
    if (isPreparingImage) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (imageError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            imageError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    final Uint8List? bytes =
        previewImage ?? selectedImage;

    if (bytes == null) {
      return const Center(
        child: Text(
          'سەرەتا وێنەیەک هەڵبژێرە',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'نەتوانرا وێنەکە پیشان بدرێت.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSliderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'قەبارە و ڕێکخستنەکان',
              style: TextStyle(
                fontSize: 19,
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

            const SizedBox(height: 5),

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

            const SizedBox(height: 5),

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
    );
  }

  Widget buildStitchPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Stitch Preview',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'پێشبینینی نەخشەی دوورین',
              textAlign: TextAlign.center,
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
                    BorderRadius.circular(12),
              ),
              child: stitches.isEmpty
                  ? const Center(
                      child: Text(
                        'وێنەکە بکە بە Stitch',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : CustomPaint(
                      painter:
                          StitchPainter(stitches),
                      child:
                          const SizedBox.expand(),
                    ),
            ),

            if (stitches.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${stitches.length} Stitch',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'KurdDesign-AI',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 10),

            const Icon(
              Icons.design_services,
              size: 70,
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

            const SizedBox(height: 8),

            const Text(
              'PNG / JPG  →  Stitch  →  DST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 25),

            FilledButton.icon(
              onPressed:
                  isPreparingImage
                      ? null
                      : pickImage,
              icon: const Icon(
                Icons.photo_library,
              ),
              label: const Text(
                'هێنانی وێنەی PNG / JPG',
              ),
            ),

            const SizedBox(height: 20),

            if (selectedImage != null)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Design Preview',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'وێنەی ڕەنگاڵە و نووسینی نەخشەکە',
                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Container(
                        height: 320,
                        width: double.infinity,
                        clipBehavior:
                            Clip.antiAlias,
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border: Border.all(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        child:
                            buildImagePreview(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            buildSliderCard(),

            const SizedBox(height: 20),

            buildStitchPreview(),

            const SizedBox(height: 20),

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
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed:
                  isExporting
                      ? null
                      : createDst,

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

            const SizedBox(height: 30),
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
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (stitches.isEmpty) return;

    double minX =
        stitches.first.x.toDouble();

    double maxX =
        stitches.first.x.toDouble();

    double minY =
        stitches.first.y.toDouble();

    double maxY =
        stitches.first.y.toDouble();

    for (final StitchPoint stitch
        in stitches) {
      final double x =
          stitch.x.toDouble();

      final double y =
          stitch.y.toDouble();

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final double designWidth =
        maxX - minX;

    final double designHeight =
        maxY - minY;

    if (designWidth <= 0 ||
        designHeight <= 0) {
      return;
    }

    const double padding = 25;

    final double availableWidth =
        size.width - padding * 2;

    final double availableHeight =
        size.height - padding * 2;

    final double scaleX =
        availableWidth / designWidth;

    final double scaleY =
        availableHeight / designHeight;

    final double scale =
        scaleX < scaleY
            ? scaleX
            : scaleY;

    final double centerX =
        size.width / 2;

    final double centerY =
        size.height / 2;

    final double designCenterX =
        (minX + maxX) / 2;

    final double designCenterY =
        (minY + maxY) / 2;

    final Paint stitchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const double stitchLength = 3;

    const int skip = 2;

    for (
      int i = 0;
      i < stitches.length;
      i += skip
    ) {
      final StitchPoint stitch =
          stitches[i];

      final double x =
          centerX +
          (stitch.x - designCenterX) *
              scale;

      final double y =
          centerY +
          (stitch.y - designCenterY) *
              scale;

      final double direction =
          ((i ~/ skip) % 2 == 0)
              ? 1.0
              : -1.0;

      canvas.drawLine(
        Offset(
          x - stitchLength,
          y - stitchLength * direction,
        ),
        Offset(
          x + stitchLength,
          y + stitchLength * direction,
        ),
        stitchPaint,
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
