class ParsedReceipt {
  final int? total;
  final DateTime? date;
  final String? merchant;
  const ParsedReceipt({this.total, this.date, this.merchant});
}

class ReceiptParser {
  // Keyword da bo dau + lowercase (OCR hay mat dau tieng Viet)
  static final _totalKw = RegExp(
      r'(tong\s*(tien|cong|thanh\s*toan)?|thanh\s*toan|phai\s*tra|grand\s*total|total|amount)');
  static final _skipKw = RegExp(
      r'(khach\s*dua|tien\s*thua|tra\s*lai|change|cash|tien\s*mat|giam\s*gia|discount|vat|thue|subtotal|tam\s*tinh)');

  // 150.000 | 150,000 | 1.250.000,00 | 150000
  static final _money = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,}');

  static final _dmy = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b');
  static final _ymd = RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b');

  static const _brands = [
    'winmart', 'circle k', 'highlands', 'phuc long', 'the coffee house',
    'gs25', 'family mart', 'familymart', 'bach hoa xanh', 'co.opmart',
    'coopmart', 'lotte', 'nha sach', 'phuong nam', 'fahasa', 'katinat',
  ];

  static ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return ParsedReceipt(
      total: _extractTotal(lines),
      date: _extractDate(lines),
      merchant: _extractMerchant(lines),
    );
  }

  static int? _extractTotal(List<String> lines) {
    final norm = lines.map(_normalize).toList();
    final candidates = <int>[];

    for (var i = 0; i < norm.length; i++) {
      final l = norm[i];
      if (!_totalKw.hasMatch(l) || _skipKw.hasMatch(l)) continue;
      var amounts = _amounts(l);
      // so tien co the nam o dong ke tiep
      if (amounts.isEmpty && i + 1 < norm.length) amounts = _amounts(norm[i + 1]);
      candidates.addAll(amounts);
    }
    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.last;
    }
    // Fallback: so lon nhat tren cac dong khong bi loai
    final all = <int>[];
    for (final l in norm) {
      if (!_skipKw.hasMatch(l)) all.addAll(_amounts(l));
    }
    if (all.isEmpty) return null;
    all.sort();
    return all.last;
  }

  static List<int> _amounts(String line) {
    final out = <int>[];
    for (final m in _money.allMatches(line)) {
      var s = m.group(0)!;
      // bo phan thap phan (1-2 chu so sau dau cuoi), vd 150.000,00
      s = s.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');
      final v = int.tryParse(s.replaceAll(RegExp(r'[.,]'), ''));
      if (v != null && v >= 1000) out.add(v); // loai so luong/SDT ngan
    }
    return out;
  }

  static DateTime? _extractDate(List<String> lines) {
    for (final l in lines) {
      final a = _ymd.firstMatch(l);
      if (a != null) {
        final d = _build(int.parse(a[1]!), int.parse(a[2]!), int.parse(a[3]!));
        if (d != null) return d;
      }
      final b = _dmy.firstMatch(l);
      if (b != null) {
        final d = _build(int.parse(b[3]!), int.parse(b[2]!), int.parse(b[1]!));
        if (d != null) return d;
      }
    }
    return null;
  }

  static DateTime? _build(int y, int m, int d) {
    if (y < 2000 || y > DateTime.now().year + 1) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final dt = DateTime(y, m, d);
    return dt.month == m ? dt : null; // chan 31/02
  }

  static String? _extractMerchant(List<String> lines) {
    final top = lines.take(6).toList();
    for (final l in top) {
      final n = _normalize(l);
      if (_brands.any(n.contains)) return l;
    }
    for (final l in top) {
      final n = _normalize(l);
      final letters = RegExp(r'[a-z]').allMatches(n).length;
      if (l.length < 3 || letters < l.length * 0.5) {
        continue;
      }
      if (RegExp(r'(hoa don|phieu|receipt|invoice|dia chi|address|tel|sdt)')
          .hasMatch(n)) {
        continue;
      }
      return l;
    }
    return null;
  }

  // lowercase + bo dau tieng Viet
  static String _normalize(String s) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final c = String.fromCharCode(r);
      final i = from.indexOf(c);
      buf.write(i >= 0 ? to[i] : c);
    }
    return buf.toString();
  }
}
