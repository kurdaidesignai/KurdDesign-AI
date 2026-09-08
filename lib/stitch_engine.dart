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

    if (resized.width < 2 || resized.height < 2) {
      return [];
    }

    final scaleX = widthMm / resized.width;
    final scaleY = heightMm / resized.height;

    // Density:
    // 1 = fewer stitches
    // 8 = more stitches
    final rowStep =
        (10.0 - density).clamp(2.0, 9.0).round();

    final stitches = <StitchPoint>[];

    // Convert the image to grayscale.
    final gray = List.generate(
      resized.height,
      (_) => List<double>.filled(
        resized.width,
        255.0,
      ),
    );

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);

        gray[y][x] =
            pixel.r * 0.299 +
            pixel.g * 0.587 +
            pixel.b * 0.114;
      }
    }

    // Find dark areas.
    final dark = List.generate(
      resized.height,
      (_) => List<bool>.filled(
        resized.width,
        false,
      ),
    );

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        dark[y][x] = gray[y][x] < threshold;
      }
    }

    // Create horizontal running stitches.
    for (var y = 0;
        y < resized.height;
        y += rowStep) {
      final segments = <List<int>>[];

      var start = -1;
      var end = -1;

      for (var x = 0;
          x < resized.width;
          x += rowStep) {
        if (dark[y][x]) {
          if (start == -1) {
            start = x;
          }

          end = x;
        } else {
          if (start != -1) {
            segments.add([start, end]);

            start = -1;
            end = -1;
          }
        }
      }

      if (start != -1) {
        segments.add([start, end]);
      }

      // Ignore extremely small areas.
      final usefulSegments = segments.where((segment) {
        final segmentWidth =
            segment[1] - segment[0];

        return segmentWidth >= rowStep;
      }).toList();

      if (usefulSegments.isEmpty) {
        continue;
      }

      final rowIndex = y ~/ rowStep;

      if (rowIndex.isEven) {
        for (final segment in usefulSegments) {
          _addSegment(
            stitches,
            startX: segment[0],
            endX: segment[1],
            y: y,
            step: rowStep,
            scaleX: scaleX,
            scaleY: scaleY,
            forward: true,
          );
        }
      } else {
        for (final segment in usefulSegments.reversed) {
          _addSegment(
            stitches,
            startX: segment[0],
            endX: segment[1],
            y: y,
            step: rowStep,
            scaleX: scaleX,
            scaleY: scaleY,
            forward: false,
          );
        }
      }
    }

    return _removeDuplicatePoints(stitches);
  }

  static void _addSegment(
    List<StitchPoint> stitches, {
    required int startX,
    required int endX,
    required int y,
    required int step,
    required double scaleX,
    required double scaleY,
    required bool forward,
  }) {
    if (startX > endX) {
      return;
    }

    if (forward) {
      for (var x = startX;
          x <= endX;
          x += step) {
        stitches.add(
          StitchPoint(
            (x * scaleX * 10).round(),
            (y * scaleY * 10).round(),
          ),
        );
      }

      if ((endX - startX) % step != 0) {
        stitches.add(
          StitchPoint(
            (endX * scaleX * 10).round(),
            (y * scaleY * 10).round(),
          ),
        );
      }
    } else {
      for (var x = endX;
          x >= startX;
          x -= step) {
        stitches.add(
          StitchPoint(
            (x * scaleX * 10).round(),
            (y * scaleY * 10).round(),
          ),
        );
      }

      if ((endX - startX) % step != 0) {
        stitches.add(
          StitchPoint(
            (startX * scaleX * 10).round(),
            (y * scaleY * 10).round(),
          ),
        );
      }
    }
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
