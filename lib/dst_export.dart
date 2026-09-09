import 'dart:typed_data';

class StitchPoint {
  final int x;
  final int y;

  const StitchPoint(this.x, this.y);
}

class DstExporter {
  static Uint8List createDst(
    List<StitchPoint> stitches, {
    String name = 'KURDDESIGN',
  }) {
    if (stitches.isEmpty) {
      throw Exception('No stitches to export');
    }

    final data = <int>[];

    var previousX = 0;
    var previousY = 0;

    for (var i = 0; i < stitches.length; i++) {
      final point = stitches[i];

      var dx = point.x - previousX;
      var dy = point.y - previousY;

      previousX = point.x;
      previousY = point.y;

      // First point is a jump/move from origin.
      if (i == 0) {
        data.addAll(
          _encodeMove(
            dx,
            dy,
            jump: true,
          ),
        );
        continue;
      }

      // Tajima DST supports movement up to about 121 units
      // per record. Split larger movements into smaller records.
      while (dx.abs() > 121 || dy.abs() > 121) {
        final stepX = dx.clamp(-121, 121);
        final stepY = dy.clamp(-121, 121);

        data.addAll(
          _encodeMove(
            stepX,
            stepY,
            jump: true,
          ),
        );

        dx -= stepX;
        dy -= stepY;
      }

      data.addAll(
        _encodeMove(
          dx,
          dy,
        ),
      );
    }

    // End of design.
    data.addAll([
      0x00,
      0x00,
      0xF3,
    ]);

    final header = _createHeader(
      name,
      stitches,
    );

    return Uint8List.fromList([
      ...header,
      ...data,
    ]);
  }

  static List<int> _createHeader(
    String name,
    List<StitchPoint> stitches,
  ) {
    var minX = stitches.first.x;
    var maxX = stitches.first.x;
    var minY = stitches.first.y;
    var maxY = stitches.first.y;

    for (final stitch in stitches) {
      if (stitch.x < minX) minX = stitch.x;
      if (stitch.x > maxX) maxX = stitch.x;
      if (stitch.y < minY) minY = stitch.y;
      if (stitch.y > maxY) maxY = stitch.y;
    }

    final plusX = maxX.clamp(0, 99999);
    final minusX = (-minX).clamp(0, 99999);
    final plusY = maxY.clamp(0, 99999);
    final minusY = (-minY).clamp(0, 99999);

    final cleanName = name
        .toUpperCase()
        .replaceAll('\r', '')
        .replaceAll('\n', '');

    final title = cleanName
        .padRight(16)
        .substring(0, 16);

    final headerText = [
      'LA:$title',
      'ST:${stitches.length.toString().padLeft(7, '0')}',
      'CO:001',
      '+X:${plusX.toString().padLeft(5, '0')}',
      '-X:${minusX.toString().padLeft(5, '0')}',
      '+Y:${plusY.toString().padLeft(5, '0')}',
      '-Y:${minusY.toString().padLeft(5, '0')}',
      'AX:+X00000',
      'AY:+Y00000',
      'MX:+X00000',
      'MY:+Y00000',
      'PD:******',
    ].join('\r');

    // Tajima DST header = exactly 512 bytes.
    final bytes = List<int>.filled(
      512,
      0x20,
    );

    final textBytes = headerText.codeUnits;

    for (
      var i = 0;
      i < textBytes.length && i < 511;
      i++
    ) {
      bytes[i] = textBytes[i];
    }

    bytes[511] = 0x1A;

    return bytes;
  }

  static List<int> _encodeMove(
    int dx,
    int dy, {
    bool jump = false,
  }) {
    var x = dx.clamp(-121, 121);
    var y = dy.clamp(-121, 121);

    var b1 = 0;
    var b2 = 0;

    // X encoding.
    if (x > 0) {
      if (x >= 81) {
        b1 |= 0x01;
        x -= 81;
      }

      if (x >= 27) {
        b1 |= 0x02;
        x -= 27;
      }

      if (x >= 9) {
        b1 |= 0x04;
        x -= 9;
      }

      if (x >= 3) {
        b1 |= 0x08;
        x -= 3;
      }

      if (x >= 1) {
        b1 |= 0x10;
        x -= 1;
      }
    } else if (x < 0) {
      x = -x;

      if (x >= 81) {
        b1 |= 0x08;
        x -= 81;
      }

      if (x >= 27) {
        b1 |= 0x04;
        x -= 27;
      }

      if (x >= 9) {
        b1 |= 0x02;
        x -= 9;
      }

      if (x >= 3) {
        b1 |= 0x01;
        x -= 3;
      }

      if (x >= 1) {
        b1 |= 0x80;
        x -= 1;
      }
    }

    // Y encoding.
    if (y > 0) {
      if (y >= 81) {
        b2 |= 0x01;
        y -= 81;
      }

      if (y >= 27) {
        b2 |= 0x02;
        y -= 27;
      }

      if (y >= 9) {
        b2 |= 0x04;
        y -= 9;
      }

      if (y >= 3) {
        b2 |= 0x08;
        y -= 3;
      }

      if (y >= 1) {
        b2 |= 0x10;
        y -= 1;
      }
    } else if (y < 0) {
      y = -y;

      if (y >= 81) {
        b2 |= 0x08;
        y -= 81;
      }

      if (y >= 27) {
        b2 |= 0x04;
        y -= 27;
      }

      if (y >= 9) {
        b2 |= 0x02;
        y -= 9;
      }

      if (y >= 3) {
        b2 |= 0x01;
        y -= 3;
      }

      if (y >= 1) {
        b2 |= 0x80;
        y -= 1;
      }
    }

    // Third byte:
    // 0x03 = normal stitch
    // 0x83 = jump stitch
    var b3 = 0x03;

    if (jump) {
      b3 |= 0x80;
    }

    return [
      b1 & 0xFF,
      b2 & 0xFF,
      b3 & 0xFF,
    ];
  }
}
