import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_tracker/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('extracts total amount, date, and merchant from a typical Vietnamese receipt', () {
      const sample = '''
      HIGHLANDS COFFEE
      Dia chi: 123 Nguyen Huu Tho, Da Nang
      Ngay: 12/10/2026 14:30
      1. Phin Sua Da (L)     39.000
      2. Tra Sen Vang (M)    45.000
      Tam tinh:              84.000
      VAT (8%):               6.720
      Tong thanh toan:       90.720
      Khach dua:            100.000
      Tien thua:              9.280
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant?.toLowerCase(), contains('highlands'));
      expect(parsed.total, equals(90720));
      expect(parsed.date, equals(DateTime(2026, 10, 12)));
    });

    test('parses WinMart receipt with thousand separators and YYYY-MM-DD date', () {
      const sample = '''
      WINMART+
      Hoa don ban le: #88921
      2026-05-18 09:15
      Sua tuoi TH True Milk: 36.000
      Banh mi sandwich:      22.000
      Tong tien:             58.000 VND
      Tien mat:             100.000
      Tien thua:             42.000
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant?.toLowerCase(), contains('winmart'));
      expect(parsed.total, equals(58000));
      expect(parsed.date, equals(DateTime(2026, 5, 18)));
    });

    test('ignores non-total amounts like cash given and change', () {
      const sample = '''
      Circle K
      10-08-2026
      Thanh toan: 150.000
      Khach dua: 200.000
      Tien thua: 50.000
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant?.toLowerCase(), contains('circle k'));
      expect(parsed.total, equals(150000));
      expect(parsed.date, equals(DateTime(2026, 8, 10)));
    });
  });
}

