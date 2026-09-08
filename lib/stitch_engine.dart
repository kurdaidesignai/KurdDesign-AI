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

    // Resize the image while keeping its aspect ratio.
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

    if (resized.width < 2 || resized.height < 2) {
      return stitches;
    }

    final scaleX = widthMm / resized.width;
    final scaleY = heightMm / resized.height;

    // Density controls the distance between embroidery rows.
    //
    // 1 = wider spacing
    // 8 = closer spacing
    final rowStep =
        (10.0 - density).clamp(2.0, 9.0).round();

    // Convert image to grayscale.
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

    // Slightly clean the image.
    //
    // A pixel is considered dark only when it is
    // clearly below the selected threshold.
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

    // Scan the design row by row.
    //
    // Instead of creating a stitch for every dark pixel,
    // create evenly spaced running stitches.
    for (var y = 0;
        y < resized.height;
        y += rowStep) {
      final segments = <List<int>>[];

      var segmentStart = -1;
      var lastDarkX = -1;

      for (var x = 0;
          x < resized.width;
          x += rowStep) {
        if (dark[y][x]) {
          if (segmentStart == -1) {
            segmentStart = x;
          }

          lastDarkX = x;
        } else {
          if (segmentStart != -1) {
            segments.add([
              segmentStart,
              lastDarkX,
            ]);

            segmentStart = -1;
            lastDarkX = -1;
          }
        }
      }

      if (segmentStart != -1) {
        segments.add([
          segmentStart,
          lastDarkX,
        ]);
      }

      // Ignore extremely small segments.
      final usefulSegments = segments.where((segment) {
        final segmentWidth =
            segment[1] - segment[0];

        return segmentWidth >= rowStep;
      }).toList();

      if (usefulSegments.isEmpty) {
        continue;
      }

      final rowIndex = y ~/ rowStep;

      // Alternate direction to create a clean
      // embroidery running-stitch pattern.
      if (rowIndex.isEven) {
        for (final segment in usefulSegments) {
          _addSegmentStitches(
            stitches,
            segment[0],
            segment[1],
            y,
            rowStep,
            scaleX,
            scaleY,
            forward: true,
          );
        }
      } else {
        for (final segment in usefulSegments.reversed) {
          _addSegmentStitches(
            stitches,
            segment[0],
            segment[1],
            y,
            rowStep,
            scaleX,
            scaleY,
            forward: false,
          );
        }
      }
    }

    return _removeDuplicatePoints(stitches);
  }

  static void _addSegmentStitches(
    List<StitchPoint> stitches,
    int startX,
    int endX,
    int y,
    int step,
    double scaleX,
    double scaleY, {
    required bool forward,
  }) {
    if (startX > endX) return;

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

      // Make sure the end of the segment is included.
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

      // Make sure the beginning of the segment is included.
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
