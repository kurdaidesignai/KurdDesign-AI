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

    final resized = img.copyResize(
      source,
      width: source.width >= source.height
          ? maxSize
          : null,
      height: source.height > source.width
          ? maxSize
          : null,
    );

    final stitches = <StitchPoint>[];

    final scaleX = widthMm / resized.width;
    final scaleY = heightMm / resized.height;

    // 1 = wider stitches
    // 8 = closer stitches
    final step = (9.0 - density)
        .clamp(1.0, 8.0)
        .round();

    // Convert image to grayscale.
    final gray = List.generate(
      resized.height,
      (_) => List<double>.filled(
        resized.width,
        255,
      ),
    );

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final p = resized.getPixel(x, y);

        gray[y][x] =
            p.r * 0.299 +
            p.g * 0.587 +
            p.b * 0.114;
      }
    }

    // Create embroidery rows.
    //
    // Instead of drawing only the outline,
    // we scan the complete dark area.
    for (var y = 0; y < resized.height; y += step) {
      final rowPoints = <int>[];

      for (var x = 0; x < resized.width; x += step) {
        if (gray[y][x] < threshold) {
          rowPoints.add(x);
        }
      }

      if (rowPoints.isEmpty) {
        continue;
      }

      // Group nearby dark pixels into segments.
      final segments = <List<int>>[];
      var current = <int>[];

      for (var i = 0; i < rowPoints.length; i++) {
        final x = rowPoints[i];

        if (current.isEmpty) {
          current.add(x);
          continue;
        }

        if (x - current.last <= step * 2) {
          current.add(x);
        } else {
          segments.add(current);
          current = <int>[x];
        }
      }

      if (current.isNotEmpty) {
        segments.add(current);
      }

      // Create running stitches through each segment.
      for (final segment in segments) {
        if (segment.isEmpty) continue;

        final startX = segment.first;
        final endX = segment.last;

        if (startX == endX) {
          stitches.add(
            StitchPoint(
              (startX * scaleX * 10).round(),
              (y * scaleY * 10).round(),
            ),
          );
          continue;
        }

        // Alternate direction on every row.
        if ((y ~/ step).isEven) {
          for (
            var x = startX;
            x <= endX;
            x += step
          ) {
            stitches.add(
              StitchPoint(
                (x * scaleX * 10).round(),
                (y * scaleY * 10).round(),
              ),
            );
          }
        } else {
          for (
            var x = endX;
            x >= startX;
            x -= step
          ) {
            stitches.add(
              StitchPoint(
                (x * scaleX * 10).round(),
                (y * scaleY * 10).round(),
              ),
            );
          }
        }
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
