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
    final data = <int>[];

    if (stitches.isEmpty) {
      return Uint8List.fromList([
        ..._createHeader(
          name,
          stitchCount: 0,
        ),
        0x00,
        0x00,
        0xF3,
      ]);
    }

    var previousX = 0;
    var previousY = 0;

    for (var i = 0; i < stitches.length; i++) {
      final point = stitches[i];

      var dx = point.x - previousX;
      var dy = point.y - previousY;

      final isFirst = i == 0;

      while (dx.abs() > 121 || dy.abs() > 121) {
        final stepX = dx.clamp(-121, 121);
        final stepY = dy.clamp(-121, 121);

        data.addAll(
          _encodeStitch(
            stepX,
            stepY,
            jump: true,
          ),
        );

        dx -= stepX;
        dy -= stepY;
      }

      data.addAll(
        _encodeStitch(
          dx,
          dy,
          jump: isFirst,
        ),
      );

      previousX = point.x;
      previousY = point.y;
    }

    data.addAll([
      0x00,
      0x00,
      0xF3,
    ]);

    final header = _createHeader(
      name,
      stitchCount: stitches.length,
    );

    return Uint8List.fromList([
      ...header,
      ...data,
    ]);
  }

  static List<int> _createHeader(
    String name, {
    required int stitchCount,
  }) {
    final title = name
        .toUpperCase()
        .padRight(16)
        .substring(0, 16);

    final headerText = [
      'LA:$title',
      'ST:${stitchCount.toString().padLeft(7, '0')}',
      'CO:001',
      '+X:00000',
      '-X:00000',
      '+Y:00000',
      '-Y:00000',
      'AX:+X00000',
      'AY:+Y00000',
      'MX:+X00000',
      'MY:+Y00000',
      'PD:******',
    ].join('\r');

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

  static List<int> _encodeStitch(
    int dx,
    int dy, {
    bool jump = false,
  }) {
    var x = dx;
    var y = dy;

    var b1 = 0;
    var b2 = 0;
    var b3 = 0x03;

    if (x >= 0) {
      if (x >= 81) {
        b1 |= 0x04;
        x -= 81;
      }

      if (x >= 40) {
        b1 |= 0x01;
        x -= 40;
      }

      if (x >= 20) {
        b1 |= 0x08;
        x -= 20;
      }

      if (x >= 10) {
        b1 |= 0x10;
        x -= 10;
      }

      if (x >= 5) {
        b1 |= 0x20;
        x -= 5;
      }

      if (x >= 1) {
        b1 |= 0x40;
        x -= 1;
      }
    } else {
      x = -x;

      if (x >= 81) {
        b1 |= 0x08;
        x -= 81;
      }

      if (x >= 40) {
        b1 |= 0x02;
        x -= 40;
      }

      if (x >= 20) {
        b1 |= 0x10;
        x -= 20;
      }

      if (x >= 10) {
        b1 |= 0x20;
        x -= 10;
      }

      if (x >= 5) {
        b1 |= 0x40;
        x -= 5;
      }

      if (x >= 1) {
        b1 |= 0x80;
        x -= 1;
      }
    }

    if (y >= 0) {
      if (y >= 81) {
        b2 |= 0x04;
        y -= 81;
      }

      if (y >= 40) {
        b2 |= 0x01;
        y -= 40;
      }

      if (y >= 20) {
        b2 |= 0x08;
        y -= 20;
      }

      if (y >= 10) {
        b2 |= 0x10;
        y -= 10;
      }

      if (y >= 5) {
        b2 |= 0x20;
        y -= 5;
      }

      if (y >= 1) {
        b2 |= 0x40;
        y -= 1;
      }
    } else {
      y = -y;

      if (y >= 81) {
        b2 |= 0x08;
        y -= 81;
      }

      if (y >= 40) {
        b2 |= 0x02;
        y -= 40;
      }

      if (y >= 20) {
        b2 |= 0x10;
        y -= 20;
      }

      if (y >= 10) {
        b2 |= 0x20;
        y -= 10;
      }

      if (y >= 5) {
        b2 |= 0x40;
        y -= 5;
      }

      if (y >= 1) {
        b2 |= 0x80;
        y -= 1;
      }
    }

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
