import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dst_export.dart';

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
  double width = 50;
  double height = 50;
  double density = 3;

  final List<StitchPoint> stitches = [];

  void addSquareDesign() {
    final w = width.round();
    final h = height.round();

    setState(() {
      stitches.clear();

      stitches.addAll([
        const StitchPoint(0, 0),
        StitchPoint(w, 0),
        StitchPoint(w, h),
        StitchPoint(0, h),
        const StitchPoint(0, 0),
      ]);
    });
  }

  void clearDesign() {
    setState(() {
      stitches.clear();
    });
  }

  void exportDst() {
    if (stitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سەرەتا نەخشەیەک دروست بکە.'),
        ),
      );
      return;
    }

    final bytes = DstExporter.createDst(
      stitches,
      name: 'KURDDESIGN',
    );

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'kurd_design.dst')
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فایلی DST بە سەرکەوتوویی دروست کرا.'),
      ),
    );
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
              'Design Editor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'دروستکردنی نەخشەی گلدان و Export بۆ DST',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

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
                      'Stitch Density: ${density.toStringAsFixed(1)}',
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
                height: 250,
                alignment: Alignment.center,
                child: stitches.isEmpty
                    ? const Text(
                        'Preview\nنەخشەکەت لێرە دەردەکەوێت',
                        textAlign: TextAlign.center,
                      )
                    : CustomPaint(
                        size: const Size(250, 250),
                        painter: StitchPainter(stitches),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: addSquareDesign,
              icon: const Icon(Icons.add),
              label: const Text('دروستکردنی نەخشە'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: clearDesign,
              icon: const Icon(Icons.delete_outline),
              label: const Text('پاککردنەوە'),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: exportDst,
              icon: const Icon(Icons.download),
              label: const Text('Export بۆ DST'),
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
      ..strokeWidth = 3;

    final path = Path();

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    path.moveTo(
      centerX + stitches.first.x.toDouble(),
      centerY + stitches.first.y.toDouble(),
    );

    for (var i = 1; i < stitches.length; i++) {
      path.lineTo(
        centerX + stitches[i].x.toDouble(),
        centerY + stitches[i].y.toDouble(),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StitchPainter oldDelegate) {
    return oldDelegate.stitches != stitches;
  }
}
