import 'dart:typed_data';

import 'package:image/image.dart' as img;

class StitchPoint {
  final int x;
  final int y;

  const StitchPoint(this.x, this.y);
}

/// Converts a PNG/JPG image into a simple embroidery stitch path.
///
/// The result is a list of StitchPoint objects that can be:
/// - previewed in the app
/// - exported to Tajima DST
class StitchEngine {
  static List<StitchPoint> imageToStitches(
    Uint8List bytes, {
    int maxSize = 400,
    double density = 3.0,
    double widthMm = 50.0,
    double heightMm = 50.0,
    int threshold = 180,
  }) {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Could not decode the selected image.');
    }

    if (decoded.width <= 0 || decoded.height <= 0) {
      throw Exception('The selected image is empty.');
    }

    // ------------------------------------------------------------
    // 1. Bake EXIF orientation
    // ------------------------------------------------------------
    final oriented = img.bakeOrientation(decoded);

    // ------------------------------------------------------------
    // 2. Resize while keeping the original aspect ratio
    // ------------------------------------------------------------
    final scale = maxSize / oriented.width;

    final resizedWidth = oriented.width > maxSize
        ? maxSize
        : oriented.width;

    final resizedHeight = oriented.width > maxSize
        ? (oriented.height * scale).round()
        : oriented.height;

    final resized = img.copyResize(
      oriented,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.average,
    );

    // ------------------------------------------------------------
    // 3. Convert to grayscale
    // ------------------------------------------------------------
    final gray = img.grayscale(resized);

    // ------------------------------------------------------------
    // 4. Density
    //
    // Higher density = more stitches.
    // Lower density = fewer stitches.
    // ------------------------------------------------------------
    final safeDensity = density.clamp(1.0, 8.0);

    final step = (9.0 - safeDensity).round().clamp(1, 8);

    // ------------------------------------------------------------
    // 5. Create binary embroidery map
    // ------------------------------------------------------------
    final points = <StitchPoint>[];

    final imageWidth = gray.width;
    final imageHeight = gray.height;

    if (imageWidth == 0 || imageHeight == 0) {
      return points;
    }

    // Map image pixels to the requested embroidery size.
    final scaleX = widthMm / imageWidth;
    final scaleY = heightMm / imageHeight;

    // Center the design around the embroidery origin.
    final centerX = (widthMm * 5).round();
    final centerY = (heightMm * 5).round();

    // ------------------------------------------------------------
    // 6. Scan rows using a zig-zag path
    //
    // This creates a more embroidery-friendly movement:
    //
    // left -> right
    // right -> left
    // left -> right
    // ...
    // ------------------------------------------------------------
    for (int y = 0; y < imageHeight; y += step) {
      final rowPoints = <StitchPoint>[];

      for (int x = 0; x < imageWidth; x += step) {
        final pixel = gray.getPixel(x, y);

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final brightness = ((r + g + b) / 3).round();

        // Dark pixels become embroidery stitches.
        if (brightness <= threshold) {
          final px = (x * scaleX * 10).round();
          final py = (y * scaleY * 10).round();

          final stitchX = centerX + px - ((imageWidth * scaleX * 10) / 2).round();
          final stitchY = centerY + py - ((imageHeight * scaleY * 10) / 2).round();

          rowPoints.add(
            StitchPoint(
              stitchX,
              stitchY,
            ),
          );
        }
      }

      // Zig-zag every second row.
      if ((y ~/ step).isOdd) {
        rowPoints.reverse();
      }

      points.addAll(rowPoints);
    }

    // ------------------------------------------------------------
    // 7. Remove duplicate consecutive stitches
    // ------------------------------------------------------------
    final cleaned = <StitchPoint>[];

    StitchPoint? previous;

    for (final point in points) {
      if (previous == null ||
          previous.x != point.x ||
          previous.y != point.y) {
        cleaned.add(point);
        previous = point;
      }
    }

    // ------------------------------------------------------------
    // 8. Limit extremely large stitch counts
    //
    // This protects the iPhone preview from becoming too heavy.
    // It does NOT normally affect normal designs.
    // ------------------------------------------------------------
    const maxStitches = 100000;

    if (cleaned.length > maxStitches) {
      return cleaned.sublist(0, maxStitches);
    }

    return cleaned;
  }

  /// Creates a smaller preview list.
  ///
  /// This is useful when the original design contains many stitches.
  /// The actual stitch list is not modified.
  static List<StitchPoint> createPreview(
    List<StitchPoint> stitches, {
    int maxPoints = 8000,
  }) {
    if (stitches.length <= maxPoints) {
      return List<StitchPoint>.from(stitches);
    }

    final result = <StitchPoint>[];

    final step = (stitches.length / maxPoints).ceil();

    for (int i = 0; i < stitches.length; i += step) {
      result.add(stitches[i]);
    }

    return result;
  }

  /// Calculates the bounding box of the stitch design.
  static Map<String, int> getBounds(
    List<StitchPoint> stitches,
  ) {
    if (stitches.isEmpty) {
      return {
        'minX': 0,
        'minY': 0,
        'maxX': 0,
        'maxY': 0,
        'width': 0,
        'height': 0,
      };
    }

    int minX = stitches.first.x;
    int maxX = stitches.first.x;
    int minY = stitches.first.y;
    int maxY = stitches.first.y;

    for (final stitch in stitches) {
      if (stitch.x < minX) minX = stitch.x;
      if (stitch.x > maxX) maxX = stitch.x;
      if (stitch.y < minY) minY = stitch.y;
      if (stitch.y > maxY) maxY = stitch.y;
    }

    return {
      'minX': minX,
      'minY': minY,
      'maxX': maxX,
      'maxY': maxY,
      'width': maxX - minX,
      'height': maxY - minY,
    };
  }

  /// Moves the whole design so its center is at the requested position.
  static List<StitchPoint> centerDesign(
    List<StitchPoint> stitches, {
    int centerX = 250,
    int centerY = 250,
  }) {
    if (stitches.isEmpty) {
      return [];
    }

    final bounds = getBounds(stitches);

    final currentCenterX =
        ((bounds['minX']! + bounds['maxX']!) / 2).round();

    final currentCenterY =
        ((bounds['minY']! + bounds['maxY']!) / 2).round();

    final offsetX = centerX - currentCenterX;
    final offsetY = centerY - currentCenterY;

    return stitches.map((point) {
      return StitchPoint(
        point.x + offsetX,
        point.y + offsetY,
      );
    }).toList();
  }

  /// Removes stitches that are extremely close to the previous stitch.
  ///
  /// This helps reduce unnecessary movements in the DST file.
  static List<StitchPoint> simplify(
    List<StitchPoint> stitches, {
    int minimumDistance = 1,
  }) {
    if (stitches.isEmpty) {
      return [];
    }

    final result = <StitchPoint>[stitches.first];

    for (int i = 1; i < stitches.length; i++) {
      final previous = result.last;
      final current = stitches[i];

      final dx = current.x - previous.x;
      final dy = current.y - previous.y;

      if ((dx * dx + dy * dy) >=
          minimumDistance * minimumDistance) {
        result.add(current);
      }
    }

    return result;
  }

  /// Converts millimeters to the 0.1 mm unit used by the stitch coordinates.
  static int mmToUnits(double mm) {
    return (mm * 10).round();
  }

  /// Converts 0.1 mm stitch units back to millimeters.
  static double unitsToMm(int units) {
    return units / 10.0;
  }
}
