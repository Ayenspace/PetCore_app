import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() async {
  for (final size in [32, 192, 512]) {
    final pixels = _renderIcon(size);
    final png = _encodePng(size, size, pixels);
    if (size == 32) {
      await File('web/favicon.png').writeAsBytes(png);
      print('Written web/favicon.png');
    }
    await File('web/icons/Icon-$size.png').writeAsBytes(png);
    await File('web/icons/Icon-maskable-$size.png').writeAsBytes(png);
    print('Written web/icons/Icon-$size.png');
  }
}

Uint8List _renderIcon(int size) {
  final pixels = Uint8List(size * size * 4);
  final s = size.toDouble();

  void setPixel(int x, int y, int r, int g, int b, int a) {
    if (x < 0 || x >= size || y < 0 || y >= size) return;
    final i = (y * size + x) * 4;
    final srcA = a / 255.0;
    final dstA = pixels[i + 3] / 255.0;
    final outA = srcA + dstA * (1 - srcA);
    if (outA == 0) return;
    pixels[i] = ((r * srcA + pixels[i] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 1] = ((g * srcA + pixels[i + 1] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 2] = ((b * srcA + pixels[i + 2] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 3] = (outA * 255).round();
  }

  void fillCircle(double cx, double cy, double r, int red, int g, int b, int a) {
    for (var y = (cy - r - 1).floor(); y <= (cy + r + 1).ceil(); y++) {
      for (var x = (cx - r - 1).floor(); x <= (cx + r + 1).ceil(); x++) {
        final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        if (dist <= r) setPixel(x, y, red, g, b, a);
        else if (dist <= r + 1) setPixel(x, y, red, g, b, (a * (r + 1 - dist)).round().clamp(0, a));
      }
    }
  }

  void fillEllipse(double cx, double cy, double rx, double ry, int r, int g, int b, int a) {
    for (var y = (cy - ry - 1).floor(); y <= (cy + ry + 1).ceil(); y++) {
      for (var x = (cx - rx - 1).floor(); x <= (cx + rx + 1).ceil(); x++) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist <= 1.0) setPixel(x, y, r, g, b, a);
        else if (dist <= 1.0 + 1.0 / rx) setPixel(x, y, r, g, b, (a * (1.0 + 1.0 / rx - dist) * rx).round().clamp(0, a));
      }
    }
  }

  // Purple background
  fillCircle(s / 2, s / 2, s / 2 - 1, 106, 27, 154, 255);
  // Main paw pad
  fillEllipse(s * 0.5, s * 0.63, s * 0.18, s * 0.14, 255, 255, 255, 230);
  // 4 toe pads
  for (final t in [
    [s * 0.28, s * 0.36, s * 0.09],
    [s * 0.42, s * 0.27, s * 0.085],
    [s * 0.58, s * 0.27, s * 0.085],
    [s * 0.72, s * 0.36, s * 0.09],
  ]) {
    fillCircle(t[0], t[1], t[2], 255, 255, 255, 230);
  }

  return pixels;
}

Uint8List _encodePng(int width, int height, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.addByte(rgba[i]);
      raw.addByte(rgba[i + 1]);
      raw.addByte(rgba[i + 2]);
      raw.addByte(rgba[i + 3]);
    }
  }
  final compressed = zlib.encode(raw.toBytes());

  Uint8List chunk(String type, List<int> data) {
    final tb = type.codeUnits;
    final crcVal = _crc32([...tb, ...data]);
    final b = BytesBuilder();
    b.add(_u32(data.length));
    b.add(tb);
    b.add(data);
    b.add(_u32(crcVal));
    return b.toBytes();
  }

  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  out.add(chunk('IHDR', [..._u32(width), ..._u32(height), 8, 6, 0, 0, 0]));
  out.add(chunk('IDAT', compressed));
  out.add(chunk('IEND', []));
  return out.toBytes();
}

List<int> _u32(int v) => [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (var i = 0; i < 8; i++) crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
  }
  return crc ^ 0xFFFFFFFF;
}
