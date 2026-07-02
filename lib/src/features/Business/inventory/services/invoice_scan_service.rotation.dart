part of 'invoice_scan_service.dart';

/// Image rotation and EXIF-orientation helpers for [InvoiceScanService].
extension _InvoiceScanRotation on InvoiceScanService {
  /// Rotates [bytes] by [cwDegrees] clockwise and saves as a temp file.
  Future<String> _rotatedTempPath(Uint8List bytes, int cwDegrees) async {
    // Detect PNG vs JPEG by magic bytes so ML Kit reads the right format.
    final isPng = bytes.length >= 4 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47;
    final ext = isPng ? 'png' : 'jpg';

    if (cwDegrees == 0) {
      final tempPath =
          '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(tempPath).writeAsBytes(bytes);
      return tempPath;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      int outW;
      int outH;

      switch (cwDegrees) {
        case 90:
          outW = src.height;
          outH = src.width;
          canvas.translate(src.height.toDouble(), 0);
          canvas.rotate(math.pi / 2);
        case 180:
          outW = src.width;
          outH = src.height;
          canvas.translate(src.width.toDouble(), src.height.toDouble());
          canvas.rotate(math.pi);
        case 270:
          outW = src.height;
          outH = src.width;
          canvas.translate(0, src.width.toDouble());
          canvas.rotate(3 * math.pi / 2);
        default:
          final tempPath =
              '${Directory.systemTemp.path}/invoice_orig_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await File(tempPath).writeAsBytes(bytes);
          return tempPath;
      }

      canvas.drawImage(src, ui.Offset.zero, ui.Paint());
      final picture = recorder.endRecording();
      final rotated = await picture.toImage(outW, outH);
      final data = await rotated.toByteData(format: ui.ImageByteFormat.png);

      final tempPath =
          '${Directory.systemTemp.path}/invoice_rot${cwDegrees}_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(data!.buffer.asUint8List());
      return tempPath;
    } catch (_) {
      final tempPath =
          '${Directory.systemTemp.path}/invoice_err_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(tempPath).writeAsBytes(bytes);
      return tempPath;
    }
  }

  /// Returns how many degrees clockwise to rotate the raw pixel data so that
  /// text is upright, based on the EXIF orientation tag.
  int _requiredCwRotation(Uint8List bytes) {
    final exif = _jpegExifOrientation(bytes);
    if (exif > 0) {
      const map = {
        1: 0,
        2: 0,
        3: 180,
        4: 180,
        5: 90,
        6: 90,
        7: 270,
        8: 270,
      };
      return map[exif] ?? 0;
    }

    final (rawW, rawH) = _jpegRawDimensions(bytes);
    if (rawW > 0 && rawH > 0 && rawW > rawH) return 90;
    return 0;
  }

  int _jpegExifOrientation(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return 0;

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];

      if (marker == 0xE1 && offset + 10 <= bytes.length) {
        final d = offset + 4;
        if (bytes[d] == 0x45 &&
            bytes[d + 1] == 0x78 &&
            bytes[d + 2] == 0x69 &&
            bytes[d + 3] == 0x66 &&
            bytes[d + 4] == 0x00 &&
            bytes[d + 5] == 0x00) {
          return _tiffOrientation(bytes, d + 6);
        }
      }

      if (marker == 0xDA) break;
      if (segLen < 2) break;
      offset += 2 + segLen;
    }

    return 0;
  }

  int _tiffOrientation(Uint8List bytes, int tiffStart) {
    if (tiffStart + 8 > bytes.length) return 0;

    final isLE = bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49;

    int u16(int pos) {
      if (pos + 2 > bytes.length) return 0;
      return isLE
          ? bytes[pos] | (bytes[pos + 1] << 8)
          : (bytes[pos] << 8) | bytes[pos + 1];
    }

    int u32(int pos) {
      if (pos + 4 > bytes.length) return 0;
      return isLE
          ? bytes[pos] |
              (bytes[pos + 1] << 8) |
              (bytes[pos + 2] << 16) |
              (bytes[pos + 3] << 24)
          : (bytes[pos] << 24) |
              (bytes[pos + 1] << 16) |
              (bytes[pos + 2] << 8) |
              bytes[pos + 3];
    }

    final ifd0 = tiffStart + u32(tiffStart + 4);
    if (ifd0 + 2 > bytes.length) return 0;

    final count = u16(ifd0);
    for (int i = 0; i < count; i++) {
      final e = ifd0 + 2 + i * 12;
      if (e + 12 > bytes.length) break;
      if (u16(e) == 0x0112) {
        return u16(e + 8);
      }
    }

    return 0;
  }

  (int, int) _jpegRawDimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return (0, 0);
    }

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];

      if (marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC) {
        final sofBase = offset + 4;
        if (sofBase + 4 < bytes.length) {
          final h = (bytes[sofBase + 1] << 8) | bytes[sofBase + 2];
          final w = (bytes[sofBase + 3] << 8) | bytes[sofBase + 4];
          return (w, h);
        }
        break;
      }

      if (marker == 0xDA) break;
      if (segLen < 2) break;
      offset += 2 + segLen;
    }

    return (0, 0);
  }
}
