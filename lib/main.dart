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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  const HomePage._();

  void exportDst(BuildContext context) {
    final stitches = <StitchPoint>[
      const StitchPoint(0, 0),
      const StitchPoint(20, 0),
      const StitchPoint(20, 20),
      const StitchPoint(0, 20),
      const StitchPoint(0, 0),
    ];

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
        content: Text('فایلی DST دروست کرا و دابەزی.'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              'KurdDesign-AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'دیزاینی جل و بەرگی کوردی بە AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 35),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text('دیزاینی نوێ بە AI'),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.design_services),
              label: const Text('دروستکردنی نەخشەی گلدان'),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: () => exportDst(context),
              icon: const Icon(Icons.download),
              label: const Text('Export بۆ DST'),
            ),
          ],
        ),
      ),
    );
  }
}
