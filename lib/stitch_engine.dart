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
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    // Keep the original aspect ratio while resizing.
    final resized = img.copyResize(
      image,
      width: image.width >= image.height
          ? maxSize
          : null,
      height: image.height > image.width
          ? maxSize
          : null,
    );

    final stitches = <StitchPoint>[];

    // Higher density = smaller distance between stitches.
    final step = (9.0 - density)
        .clamp(1.0, 8.0)
        .round();

    final scaleX = widthMm / resized.width;
    final scaleY = heightMm / resized.height;

    for (var y = 0; y < resized.height; y += step) {
      for (var x = 0; x < resized.width; x += step) {
        final pixel = resized.getPixel(x, y);

        final brightness =
            (pixel.r + pixel.g + pixel.b) / 3.0;

        if (brightness < threshold) {
          stitches.add(
            StitchPoint(
              (x * scaleX * 10).round(),
              (y * scaleY * 10).round(),
            ),
          );
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

    final result = <StitchPoint>[points.first];

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
