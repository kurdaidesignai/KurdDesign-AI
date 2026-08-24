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
      return [];
    }

    final resized = img.copyResize(
      image,
      width: image.width > maxSize
          ? maxSize
          : image.width,
    );

    final stitches = <StitchPoint>[];

    final step = (8.0 - density)
        .clamp(1.0, 7.0)
        .round();

    final scaleX =
        widthMm / resized.width;

    final scaleY =
        heightMm / resized.height;

    for (
      var y = 0;
      y < resized.height;
      y += step
    ) {
      for (
        var x = 0;
        x < resized.width;
        x += step
      ) {
        final pixel =
            resized.getPixel(x, y);

        final brightness =
            (pixel.r +
                    pixel.g +
                    pixel.b) /
                3;

        if (brightness < 160) {
          final stitchX =
              ((x - resized.width / 2) *
                      scaleX)
                  .round();

          final stitchY =
              ((y - resized.height / 2) *
                      scaleY)
                  .round();

          stitches.add(
            StitchPoint(
              stitchX,
              stitchY,
            ),
          );
        }
      }
    }

    return stitches;
  }
}
