import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/expense_db.dart';
import '../providers/expense_provider.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../utils/format.dart';

/// Dung cho 2 truong hop: xac nhan ket qua OCR (parsed + image) hoac sua giao dich cu (existing).
class ReviewScreen extends StatefulWidget {
  final ParsedReceipt? parsed;
  final String? rawText;
  final File? image;
  final Expense? existing;

  const ReviewScreen({super.key, this.parsed, this.rawText, this.image, this.existing});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _total;
  late DateTime _date;
  late ExpenseCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.parsed;
    _merchant = TextEditingController(text: e?.merchant ?? p?.merchant ?? '');
    _total = TextEditingController(
        text: (e?.total ?? p?.total)?.toString() ?? '');
    _date = e?.date ?? p?.date ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final p = context.read<ExpenseProvider>();
    final total = int.parse(_total.text);
    final merchant = _merchant.text.trim();

    if (widget.existing != null) {
      await p.update(widget.existing!.copyWith(
          merchant: merchant, total: total, category: _category, date: _date));
    } else {
      final path =
          widget.image != null ? await OcrService.cacheImage(widget.image!) : null;
      await p.add(Expense(
          merchant: merchant,
          total: total,
          category: _category,
          date: _date,
          imagePath: path));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = widget.image?.path ?? widget.existing?.imagePath;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Xác nhận hóa đơn' : 'Sửa giao dịch'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (imgPath != null && File(imgPath).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(imgPath), height: 180, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _merchant,
                  decoration: const InputDecoration(
                      labelText: 'Cửa hàng', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tên cửa hàng' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _total,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Tổng tiền (VND)',
                      suffixText: 'đ',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nhập số tiền hợp lệ',
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Ngày', border: OutlineInputBorder()),
                    child: Row(children: [
                      Expanded(child: Text(fmtDate(_date))),
                      const Icon(Icons.calendar_today, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in ExpenseCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ]),
                if (widget.rawText != null) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Văn bản OCR gốc'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(widget.rawText!),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Lưu'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
