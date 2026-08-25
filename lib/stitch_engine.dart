import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'dst_export.dart';

class StitchEngine {
  static List<StitchPoint> imageToStitches(
    Uint8List bytes, {
    int maxSize = 300,
    double density = 3.0,
    double widthMm = 50.0,
    double heightMm = 50.0,
  }) {
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    final resized = img.copyResize(
      image,
      width: image.width > maxSize ? maxSize : image.width,
      height: image.height > maxSize ? maxSize : image.height,
    );

    final List<StitchPoint> stitches = [];

    final int step = (8.0 - density).clamp(1.0, 7.0).round();

    final double scaleX = widthMm / resized.width;
    final double scaleY = heightMm / resized.height;

    for (int y = 0; y < resized.height; y += step) {
      for (int x = 0; x < resized.width; x += step) {
        final pixel = resized.getPixel(x, y);

        final double brightness =
            (pixel.r + pixel.g + pixel.b) / 3.0;

        if (brightness < 160) {
          stitches.add(
            StitchPoint(
              (x * scaleX).round(),
              (y * scaleY).round(),
            ),
          );
        }
      }
    }

    return stitches;
  }
}
