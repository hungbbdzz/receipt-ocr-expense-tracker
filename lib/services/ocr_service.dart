import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'receipt_parser.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Chay OCR offline roi parse bang regex.
  Future<({String raw, ParsedReceipt parsed})> scan(File image) async {
    final result = await _recognizer.processImage(InputImage.fromFile(image));
    // Ghep theo thu tu block/line de giu dung bo cuc tren-xuong
    final raw = result.blocks
        .expand((b) => b.lines)
        .map((l) => l.text)
        .join('\n');
    return (raw: raw, parsed: ReceiptParser.parse(raw));
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
