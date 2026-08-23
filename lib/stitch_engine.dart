import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'dst_export.dart';

class StitchEngine {
  static List<StitchPoint> imageToStitches(
    Uint8List bytes, {
    int maxSize = 300,
  }) {
    final image = img.decodeImage(bytes);

    if (image == null) {
      return [];
    }

    final resized = img.copyResize(
      image,
      width: image.width > maxSize ? maxSize : image.width,
    );

    final stitches = <StitchPoint>[];

    const step = 4;

    for (var y = 0; y < resized.height; y += step) {
      for (var x = 0; x < resized.width; x += step) {
        final pixel = resized.getPixel(x, y);

        final brightness =
            (pixel.r + pixel.g + pixel.b) / 3;

        if (brightness < 160) {
          stitches.add(
            StitchPoint(
              x - resized.width ~/ 2,
              y - resized.height ~/ 2,
            ),
          );
        }
      }
    }

    return stitches;
  }
}
