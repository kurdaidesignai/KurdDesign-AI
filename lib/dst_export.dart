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

    for (var i = 0; i < stitches.length; i++) {
      final point = stitches[i];

      if (i == 0) {
        data.addAll(
          _encodeStitch(point.x, point.y, jump: true),
        );
      } else {
        final previous = stitches[i - 1];

        var dx = point.x - previous.x;
        var dy = point.y - previous.y;

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
          _encodeStitch(dx, dy),
        );
      }
    }

    // End of DST design.
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

    final bytes = List<int>.filled(512, 0x20);

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
      b1 |= 0x01;
    } else {
      b1 |= 0x02;
      x = -x;
    }

    if (y >= 0) {
      b2 |= 0x01;
    } else {
      b2 |= 0x02;
      y = -y;
    }

    b1 |= (x & 0x7F) << 2;
    b2 |= (y & 0x7F) << 2;

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
