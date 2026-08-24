import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

class _DesignEditorPageState
    extends State<DesignEditorPage> {
  final ImagePicker picker = ImagePicker();

  Uint8List? selectedImage;
  List<StitchPoint> stitches = [];

  double width = 50;
  double height = 50;
  double density = 3;

  Future<void> pickImage() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        selectedImage = bytes;
        stitches = [];
      });

      if (!mounted) return;

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

  void convertToStitches() {
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

    final result =
        StitchEngine.imageToStitches(
      selectedImage!,
      maxSize: 300,
      density: density,
      widthMm: width,
      heightMm: height,
    );

    setState(() {
      stitches = result;
    });

    if (stitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هیچ Stitch ـێک لە وێنەکە نەدۆزرایەوە.',
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
  }

  void createDst() {
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

    final bytes = DstExporter.createDst(
      stitches,
      name: 'KURDDESIGN',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'DST ئامادەیە — ${bytes.length} bytes',
        ),
      ),
    );
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
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
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
                        fontWeight:
                            FontWeight.bold,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: SizedBox(
                height: 280,
                child: Center(
                  child: stitches.isEmpty
                      ? const Text(
                          'Stitch Preview\n'
                          'وێنەکە بکە بە Stitch',
                          textAlign:
                              TextAlign.center,
                        )
                      : CustomPaint(
                          size: const Size(
                            double.infinity,
                            250,
                          ),
                          painter:
                              StitchPainter(
                            stitches,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: convertToStitches,
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'گۆڕینی وێنە بۆ Stitch',
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: createDst,
              icon: const Icon(
                Icons.download,
              ),
              label: const Text(
                'دروستکردنی DST',
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
                    fontWeight:
                        FontWeight.bold,
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
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (stitches.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    var minX = stitches.first.x;
    var maxX = stitches.first.x;
    var minY = stitches.first.y;
    var maxY = stitches.first.y;

    for (final point in stitches) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    final designWidth =
        (maxX - minX).toDouble();

    final designHeight =
        (maxY - minY).toDouble();

    final scaleX = designWidth == 0
        ? 1.0
        : (size.width - 20) /
            designWidth;

    final scaleY = designHeight == 0
        ? 1.0
        : (size.height - 20) /
            designHeight;

    final scale =
        scaleX < scaleY
            ? scaleX
            : scaleY;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final designCenterX =
        (minX + maxX) / 2;

    final designCenterY =
        (minY + maxY) / 2;

    final path = Path();

    final firstX =
        centerX +
        (stitches.first.x -
                designCenterX) *
            scale;

    final firstY =
        centerY +
        (stitches.first.y -
                designCenterY) *
            scale;

    path.moveTo(
      firstX,
      firstY,
    );

    for (
      var i = 1;
      i < stitches.length;
      i++
    ) {
      final x =
          centerX +
          (stitches[i].x -
                  designCenterX) *
              scale;

      final y =
          centerY +
          (stitches[i].y -
                  designCenterY) *
              scale;

      path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant StitchPainter oldDelegate,
  ) {
    return oldDelegate.stitches !=
        stitches;
  }
}
