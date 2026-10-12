import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'receipt_parser.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Chay OCR offline, gom nhom dong theo toa do khong gian (spatial clustering)
  /// de ghep cac cot nhan (Labels) va so tien (Amounts) nam cung hang ngang.
  Future<({String raw, ParsedReceipt parsed})> scan(File image) async {
    final result = await _recognizer.processImage(InputImage.fromFile(image));
    final raw = _reconstructSpatialText(result);
    return (raw: raw, parsed: ReceiptParser.parse(raw));
  }

  /// Tai tao van ban hoa don theo hang ngang dua tren toa do boundingBox.
  /// Khac phuc triet de loi ML Kit tach cot khien ten nhan va so tien bi chia ra 2 khoi rieng.
  static String _reconstructSpatialText(RecognizedText result) {
    final allLines = result.blocks.expand((b) => b.lines).toList();
    if (allLines.isEmpty) return '';

    // Sap xep ban dau theo truc Y (top)
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Gom cac TextLine nam tren cung 1 dong ngang
    final rows = <List<TextLine>>[];
    for (final line in allLines) {
      final lineMidY = (line.boundingBox.top + line.boundingBox.bottom) / 2;
      final lineHeight =
          line.boundingBox.height > 0 ? line.boundingBox.height : 12.0;

      List<TextLine>? matchedRow;
      for (final row in rows) {
        final rowMidY = row
                .map((l) => (l.boundingBox.top + l.boundingBox.bottom) / 2)
                .reduce((a, b) => a + b) /
            row.length;
        final avgHeight = row
                .map((l) =>
                    l.boundingBox.height > 0 ? l.boundingBox.height : 12.0)
                .reduce((a, b) => a + b) /
            row.length;
        final threshold =
            (lineHeight < avgHeight ? lineHeight : avgHeight) * 0.65;
        if ((lineMidY - rowMidY).abs() <= threshold) {
          matchedRow = row;
          break;
        }
      }

      if (matchedRow != null) {
        matchedRow.add(line);
      } else {
        rows.add([line]);
      }
    }

    // Sap xep cac dong ngang theo thu tu tu tren xuong duoi theo Y trung binh
    rows.sort((r1, r2) {
      final y1 = r1
              .map((l) => (l.boundingBox.top + l.boundingBox.bottom) / 2)
              .reduce((a, b) => a + b) /
          r1.length;
      final y2 = r2
              .map((l) => (l.boundingBox.top + l.boundingBox.bottom) / 2)
              .reduce((a, b) => a + b) /
          r2.length;
      return y1.compareTo(y2);
    });

    // Trong moi dong ngang, sap xep tu trai sang phai (boundingBox.left)
    final buffer = StringBuffer();
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final rowText = row
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .join('   ');
      if (rowText.isNotEmpty) {
        buffer.writeln(rowText);
      }
    }

    return buffer.toString().trim();
  }

  /// Copy anh vao thu muc documents de luu thumbnail ben vung.
  static Future<String> cacheImage(File src) async {
    final dir = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'receipts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = p.join(
        dir.path, '${DateTime.now().millisecondsSinceEpoch}${p.extension(src.path)}');
    await src.copy(dest);
    return dest;
  }

  void dispose() => _recognizer.close();
}
