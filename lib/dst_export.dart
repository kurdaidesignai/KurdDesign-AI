        final previous = stitches[i - 1];
        data.addAll(
          _encodeStitch(
            current.x - previous.x,
            current.y - previous.y,
          ),
        );
      }
    }

    data.addAll([0x00, 0x00, 0xF3]);

    return Uint8List.fromList([
      ...header,
      ...data,
    ]);
  }

  static List<int> _createHeader(String name) {
    final title = name.padRight(16).substring(0, 16);

    final headerText = [
      'LA:$title',
      'ST:0000000',
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

    for (var i = 0; i < textBytes.length && i < 511; i++) {
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
    var x = dx.clamp(-121, 121);
    var y = dy.clamp(-121, 121);

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
}final textBytes = headerText.codeUnits;
