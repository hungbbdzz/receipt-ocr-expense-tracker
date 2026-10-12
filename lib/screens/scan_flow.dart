import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import 'review_screen.dart';

/// Chon nguon anh -> crop (khung chon bien hoa don) -> OCR -> man hinh review.
class ScanFlow {
  static Future<void> start(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Chụp ảnh hóa đơn'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Chọn từ thư viện'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt viền hóa đơn',
          toolbarColor: const Color(0xFF0284C7),
          toolbarWidgetColor: Colors.white,
          statusBarLight: false,
          activeControlsWidgetColor: const Color(0xFF0284C7),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Cắt viền hóa đơn',
        ),
      ],
    );
    if (cropped == null || !context.mounted) return;

    final file = File(cropped.path);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ocr = OcrService();
    try {
      final r = await ocr.scan(file);
      if (!context.mounted) return;
      Navigator.pop(context); // dong dialog loading
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReviewScreen(parsed: r.parsed, rawText: r.raw, image: file),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OCR thất bại: $e')));
    } finally {
      ocr.dispose();
    }
  }
}
