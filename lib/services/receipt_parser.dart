import 'dart:math' as math;

class ParsedReceipt {
  final int? total;
  final DateTime? date;
  final String? merchant;
  const ParsedReceipt({this.total, this.date, this.merchant});
}

class ReceiptParser {
  // Tu khoa tong tien thuc te can chi tra (hoa don)
  static final _totalKw = RegExp(
    r'(tong\s*(cong|tien|thanh\s*toan)?|thanh\s*toan|phai\s*tra|can\s*tra|grand\s*total|amount\s*due|total\s*due|net\s*amount|total)',
  );

  // Tu khoa tien khach dua (TUYET DOI khong lay lam tong chi tieu)
  static final _paidKw = RegExp(
    r'(khach\s*(dua|tra)|tien\s*khach|tien\s*mat\s*khach|cash\s*tendered|tendered|paid)',
  );

  // Tu khoa tien thua / thoi lai
  static final _changeKw = RegExp(
    r'(tien\s*(thua|thoi|tra\s*lai)|tra\s*lai|change|refund)',
  );

  // Tu khoa tam tinh / thue / giam gia can bo qua
  static final _skipKw = RegExp(
    r'(tam\s*tinh|subtotal|tien\s*hang|giam\s*gia|discount|voucher|chiet\s*khau|vat|thue|tax)',
  );

  // 150.000 | 150,000 | 1.250.000,00 | 150000
  static final _money = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\b\d{4,}\b');

  static final _dmy = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b');
  static final _ymd = RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b');

  static const Map<String, String> _canonicalBrands = {
    'circle k': 'Circle K',
    'highlands': 'Highlands Coffee',
    'winmart': 'WinMart',
    'phuc long': 'Phúc Long',
    'the coffee house': 'The Coffee House',
    'gs25': 'GS25',
    'family mart': 'FamilyMart',
    'familymart': 'FamilyMart',
    'bach hoa xanh': 'Bách Hóa Xanh',
    'co.opmart': 'Co.opmart',
    'coopmart': 'Co.opmart',
    'lotte': 'Lotte Mart',
    'nha sach': 'Nhà Sách',
    'phuong nam': 'Nhà Sách Phương Nam',
    'fahasa': 'Fahasa',
    'katinat': 'Katinat',
    'starbucks': 'Starbucks',
    '7-eleven': '7-Eleven',
    'seven eleven': '7-Eleven',
    'ministop': 'Ministop',
    'tocotoco': 'ToCoToCo',
    'mixue': 'Mixue',
  };

  static ParsedReceipt parse(String rawText) {
    final rawLines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final lines = _alignColumns(rawLines);
    return ParsedReceipt(
      total: _extractTotal(lines),
      date: _extractDate(lines),
      merchant: _extractMerchant(lines),
    );
  }

  /// Xu ly truong hop OCR tach labels va amounts ra thanh 2 khoi rieng biet
  static List<String> _alignColumns(List<String> lines) {
    final result = <String>[];
    var i = 0;
    while (i < lines.length) {
      final l = lines[i];
      final normL = _normalize(l);
      final isKeywordOnly = (_totalKw.hasMatch(normL) ||
              _paidKw.hasMatch(normL) ||
              _changeKw.hasMatch(normL)) &&
          _amounts(l).isEmpty;

      if (isKeywordOnly) {
        final labelGroup = <String>[l];
        var j = i + 1;
        while (j < lines.length) {
          final nextNorm = _normalize(lines[j]);
          final isNextKw = (_totalKw.hasMatch(nextNorm) ||
                  _paidKw.hasMatch(nextNorm) ||
                  _changeKw.hasMatch(nextNorm)) &&
              _amounts(lines[j]).isEmpty;
          if (isNextKw) {
            labelGroup.add(lines[j]);
            j++;
          } else {
            break;
          }
        }

        final amountGroup = <String>[];
        while (j < lines.length) {
          final nextAmounts = _amounts(lines[j]);
          final nextNorm = _normalize(lines[j]);
          final hasKw = _totalKw.hasMatch(nextNorm) ||
              _paidKw.hasMatch(nextNorm) ||
              _changeKw.hasMatch(nextNorm);
          if (nextAmounts.isNotEmpty && !hasKw) {
            amountGroup.add(lines[j]);
            j++;
            if (amountGroup.length == labelGroup.length) break;
          } else {
            break;
          }
        }

        if (labelGroup.length > 1 && labelGroup.length == amountGroup.length) {
          for (var k = 0; k < labelGroup.length; k++) {
            result.add('${labelGroup[k]}   ${amountGroup[k]}');
          }
          i = j;
          continue;
        }
      }

      result.add(l);
      i++;
    }
    return result;
  }

  static int? _extractTotal(List<String> lines) {
    final norm = lines.map(_normalize).toList();

    int? paidAmount;
    int? changeAmount;
    final explicitTotals = <int>[];
    final otherAmounts = <int>[];

    for (var i = 0; i < norm.length; i++) {
      final l = norm[i];
      final lineAmounts = _amounts(l);

      // Kiem tra dong Tien khach dua
      if (_paidKw.hasMatch(l)) {
        var a = lineAmounts;
        if (a.isEmpty && i + 1 < norm.length) a = _amounts(norm[i + 1]);
        if (a.isNotEmpty) paidAmount ??= a.last;
        continue;
      }

      // Kiem tra dong Tien thua / Tra lai
      if (_changeKw.hasMatch(l)) {
        var a = lineAmounts;
        if (a.isEmpty && i + 1 < norm.length) a = _amounts(norm[i + 1]);
        if (a.isNotEmpty) changeAmount ??= a.last;
        continue;
      }

      // Kiem tra dong Tong tien thuc te
      if (_totalKw.hasMatch(l) && !_skipKw.hasMatch(l)) {
        var a = lineAmounts;
        if (a.isEmpty &&
            i + 1 < norm.length &&
            !_paidKw.hasMatch(norm[i + 1]) &&
            !_changeKw.hasMatch(norm[i + 1]) &&
            !_skipKw.hasMatch(norm[i + 1])) {
          a = _amounts(norm[i + 1]);
        }
        explicitTotals.addAll(a);
        continue;
      }

      // Cac dong khac khong phai giam gia, thue, tam tinh
      if (!_skipKw.hasMatch(l)) {
        otherAmounts.addAll(lineAmounts);
      }
    }

    // 1. Phuong trinh hoa don: Khach dua - Tien thua = Tong chi tieu thuc te
    if (paidAmount != null && changeAmount != null && paidAmount > changeAmount) {
      final diff = paidAmount - changeAmount;
      if (diff >= 1000) return diff;
    }

    // 2. Co so tien tu dong Tong tien/Thanh toan ro rang
    if (explicitTotals.isNotEmpty) {
      final paid = paidAmount;
      if (paid != null) {
        final underPaid = explicitTotals.where((v) => v <= paid).toList();
        if (underPaid.isNotEmpty) return underPaid.last;
      }
      return explicitTotals.last;
    }

    // 3. Kiem tra quan he so hoc C = A + B giua tat ca cac so (C = Khach dua, A = Bill, B = Tien thua)
    final allNums = {...explicitTotals, ...otherAmounts}.toList()..sort();
    for (var idxC = allNums.length - 1; idxC >= 0; idxC--) {
      final c = allNums[idxC];
      for (var idxA = 0; idxA < idxC; idxA++) {
        final a = allNums[idxA];
        final b = c - a;
        if (b > 0 && allNums.contains(b)) {
          if (explicitTotals.contains(a)) return a;
          if (explicitTotals.contains(b)) return b;
          final maxAB = math.max(a, b);
          if (paidAmount == c || paidAmount == null) {
            return maxAB;
          }
        }
      }
    }

    // 4. Neu chi co Khach dua ma khong co Tien thua va khong co dong Tong:
    // Tim so lon nhat trong cac dong khac nho hon Khach dua
    final paid = paidAmount;
    if (paid != null) {
      final smaller = otherAmounts.where((v) => v < paid).toList();
      if (smaller.isNotEmpty) {
        smaller.sort();
        return smaller.last;
      }
    }

    // 5. Fallback: Loc bo ca Khach dua va Tien thua khoi danh sach
    final pool = otherAmounts
        .where((v) => v != paidAmount && v != changeAmount)
        .toList();
    if (pool.isNotEmpty) {
      pool.sort();
      return pool.last;
    }

    return paidAmount;
  }

  static List<int> _amounts(String line) {
    final out = <int>[];
    for (final m in _money.allMatches(line)) {
      var s = m.group(0)!;
      // Bo qua neu la so dien thoai (bat dau bang 0 va co 9-11 chu so)
      if (RegExp(r'^0\d{8,10}$').hasMatch(s)) continue;
      // Bo phan thap phan (1-2 chu so sau dau cuoi), vd 150.000,00
      s = s.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');
      final rawNum = s.replaceAll(RegExp(r'[.,]'), '');
      final v = int.tryParse(rawNum);
      if (v == null) continue;
      // Loai bo nam (2020-2035) neu nam canh dau gach / hoac -
      if (v >= 2020 && v <= 2035 && RegExp(r'[/\-.]').hasMatch(line)) continue;
      // So tien VND hop le tu 1.000d den 100 trieu d
      if (v >= 1000 && v <= 100000000) out.add(v);
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
    return dt.month == m ? dt : null;
  }

  static String? _extractMerchant(List<String> lines) {
    // 1. Kiem tra thuong hieu noi tieng da duoc chuan hoa
    for (final l in lines.take(10)) {
      final n = _normalize(l);
      for (final entry in _canonicalBrands.entries) {
        if (n.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // 2. Lay dong dau tien hop le (khong phai hoa don, dia chi, sdt, mon an)
    final top = lines.take(8).toList();
    for (final l in top) {
      final n = _normalize(l);
      final letters = RegExp(r'[a-z]').allMatches(n).length;
      if (l.length < 3 || letters < l.length * 0.4) continue;
      if (RegExp(r'(hoa don|phieu|receipt|invoice|dia chi|address|tel|sdt|hotline|mst|ban so|thu ngan|order)')
          .hasMatch(n)) {
        continue;
      }
      if (RegExp(r'(ca phe|tra |sua da|combo|don gia|sl:)').hasMatch(n)) {
        continue;
      }
      return l;
    }
    return null;
  }

  // lowercase + bo dau tieng Viet
  static String _normalize(String s) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
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
