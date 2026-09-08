import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'dst_export.dart';

class StitchEngine {
  static List<StitchPoint> imageToStitches(
    Uint8List bytes, {
    int maxSize = 400,
    double density = 3.0,
    double widthMm = 50.0,
    double heightMm = 50.0,
    int threshold = 180,
  }) {
    final source = img.decodeImage(bytes);

    if (source == null) {
      throw Exception('Unable to decode image');
    }

    // Resize while keeping aspect ratio.
    final resized = img.copyResize(
      source,
      width: source.width >= source.height ? maxSize : null,
      height: source.height > source.width ? maxSize : null,
    );

    final stitches = <StitchPoint>[];

    final scaleX = widthMm / resized.width;
    final scaleY = heightMm / resized.height;

    // Density:
    // 1 = farther stitches
    // 8 = closer stitches
    final step = (9.0 - density).clamp(1.0, 8.0).round();

    // Convert image to grayscale.
    final gray = List.generate(
      resized.height,
      (_) => List<double>.filled(resized.width, 0),
    );

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final p = resized.getPixel(x, y);

        gray[y][x] =
            (p.r * 0.299) +
            (p.g * 0.587) +
            (p.b * 0.114);
      }
    }

    // Detect edges.
    final edges = <List<bool>>[];

    for (var y = 0; y < resized.height; y++) {
      final row = List<bool>.filled(resized.width, false);

      for (var x = 0; x < resized.width; x++) {
        if (x == 0 ||
            y == 0 ||
            x >= resized.width - 1 ||
            y >= resized.height - 1) {
          continue;
        }

        final center = gray[y][x];

        final right = gray[y][x + 1];
        final down = gray[y + 1][x];

        final difference =
            ((center - right).abs() +
                (center - down).abs()) /
            2.0;

        row[x] = difference > 25;
      }

      edges.add(row);
    }

    // Convert detected edges into embroidery stitch paths.
    for (var y = 0; y < resized.height; y += step) {
      var pathStarted = false;

      for (var x = 0; x < resized.width; x += step) {
        if (!edges[y][x]) {
          pathStarted = false;
          continue;
        }

        final stitchX =
            (x * scaleX * 10).round();

        final stitchY =
            (y * scaleY * 10).round();

        // Add a small jump/start marker by
        // separating disconnected paths.
        if (!pathStarted && stitches.isNotEmpty) {
          final previous = stitches.last;

          stitches.add(
            StitchPoint(
              previous.x,
              previous.y,
            ),
          );
        }

        stitches.add(
          StitchPoint(
            stitchX,
            stitchY,
          ),
        );

        pathStarted = true;
      }
    }

    return _removeDuplicatePoints(stitches);
  }

  static List<StitchPoint> _removeDuplicatePoints(
    List<StitchPoint> points,
  ) {
    if (points.length < 2) {
      return points;
    }

    final result = <StitchPoint>[
      points.first,
    ];

    for (var i = 1; i < points.length; i++) {
      final previous = result.last;
      final current = points[i];

      if (current.x != previous.x ||
          current.y != previous.y) {
        result.add(current);
      }
    }

    return result;
  }
}
