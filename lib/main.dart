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
  State<DesignEditorPage> createState() => _DesignEditorPageState();
}

class _DesignEditorPageState extends State<DesignEditorPage> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? selectedImage;
  List<StitchPoint> stitches = [];

  double width = 50;
  double height = 50;
  double density = 3;

  Future<void> pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        selectedImage = bytes;
        stitches = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وێنەکە بە سەرکەوتوویی هێنرا.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هەڵەیەک لە هێنانی وێنە ڕوویدا.'),
        ),
      );
    }
  }

  void convertToStitches() {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سەرەتا وێنەی PNG یان JPG هەڵبژێرە.'),
        ),
      );
      return;
    }

    final result = StitchEngine.imageToStitches(
      selectedImage!,
      maxSize: 300,
    );

    setState(() {
      stitches = result;
    });

    if (stitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لە وێنەکەدا Stitch نەدۆزرایەوە.'),
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

  Future<void> exportDst() async {
    if (stitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سەرەتا وێنەکە بکە بە Stitch.'),
        ),
      );
      return;
    }

    try {
      final bytes = DstExporter.createDst(
        stitches,
        name: 'KURDDESIGN',
      );

      final file = XFile.fromData(
        bytes,
        name: 'kurd_design.dst',
        mimeType: 'application/octet-stream',
      );

      await Share.shareXFiles(
        [file],
        text: 'KurdDesign-AI DST Design',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هەڵەیەک لە Export کردنی DST ڕوویدا.'),
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
              style: TextStyle(fontSize: 18),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Container(
                height: 280,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(15),
                child: stitches.isEmpty
                    ? const Text(
                        'Stitch Preview\n'
                        'وێنەکە بکە بە Stitch',
                        textAlign: TextAlign.center,
                      )
                    : CustomPaint(
                        size: const Size(
                          double.infinity,
                          250,
                        ),
                        painter: StitchPainter(stitches),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: convertToStitches,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'گۆڕینی وێنە بۆ Stitch',
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: exportDst,
              icon: const Icon(Icons.download),
              label: const Text(
                'Export بۆ DST',
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: clearDesign,
              icon: const Icon(Icons.delete_outline),
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

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final minX = stitches
        .map((p) => p.x)
        .reduce((a, b) => a < b ? a : b);

    final maxX = stitches
        .map((p) => p.x)
        .reduce((a, b) => a > b ? a : b);

    final minY = stitches
        .map((p) => p.y)
        .reduce((a, b) => a < b ? a : b);

    final maxY = stitches
        .map((p) => p.y)
        .reduce((a, b) => a > b ? a : b);

    final designWidth =
        (maxX - minX).abs().toDouble();

    final designHeight =
        (maxY - minY).abs().toDouble();

    final scaleX = designWidth == 0
        ? 1.0
        : (size.width - 20) / designWidth;

    final scaleY = designHeight == 0
        ? 1.0
        : (size.height - 20) / designHeight;

    final scale =
        scaleX < scaleY ? scaleX : scaleY;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final path = Path();

    final firstX =
        centerX +
        (stitches.first.x -
                (minX + maxX) / 2) *
            scale;

    final firstY =
        centerY +
        (stitches.first.y -
                (minY + maxY) / 2) *
            scale;

    path.moveTo(
      firstX.toDouble(),
      firstY.toDouble(),
    );

    for (var i = 1; i < stitches.length; i++) {
      final x =
          centerX +
          (stitches[i].x -
                  (minX + maxX) / 2) *
              scale;

      final y =
          centerY +
          (stitches[i].y -
                  (minY + maxY) / 2) *
              scale;

      path.lineTo(
        x.toDouble(),
        y.toDouble(),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant StitchPainter oldDelegate,
  ) {
    return oldDelegate.stitches != stitches;
  }
}
