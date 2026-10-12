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

      expect(parsed.merchant, equals('Highlands Coffee'));
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
      Khach dua:            100.000
      Tien thua:             42.000
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant, equals('WinMart'));
      expect(parsed.total, equals(58000));
      expect(parsed.date, equals(DateTime(2026, 5, 18)));
    });

    test('replicates Screenshot 2: normalizes Circle K brand and excludes cash tendered (50k)', () {
      const sample = '''
      CIRCLE K VIETNAM
      12/10/2026 10:15
      Ca phe sua da Circle K
      Tong cong: 45.000
      Khach dua: 50.000
      Tien tra lai: 5.000
      ''';

      final parsed = ReceiptParser.parse(sample);

      // Thuong hieu phai duoc chuan hoa la Circle K thay vi ca dong ca phe
      expect(parsed.merchant, equals('Circle K'));
      // Tong chi tieu phai la 45.000 chu KHONG PHAI so lon nhat khach dua 50.000
      expect(parsed.total, equals(45000));
      expect(parsed.date, equals(DateTime(2026, 10, 12)));
    });

    test('replicates Screenshot 3: Highlands Coffee bill total 111.240 vs Khach dua 200.000', () {
      const sample = '''
      HIGHLANDS COFFEE
      Ngay: 12/10/2026
      Tam tinh: 103.000
      VAT (8%): 8.240
      Tong thanh toan: 111.240
      Khach dua: 200.000
      Tien thua: 88.760
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant, equals('Highlands Coffee'));
      // Tong hoa don phai la 111.240, khong duoc lay so lon nhat 200.000
      expect(parsed.total, equals(111240));
    });

    test('handles multi-column layout where labels and amounts are separated', () {
      const sample = '''
      Highlands Coffee
      12/10/2026
      Tong thanh toan
      Khach dua
      Tien thua
      111.240
      200.000
      88.760
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant, equals('Highlands Coffee'));
      expect(parsed.total, equals(111240));
    });

    test('handles cash receipt with only customer paid and change (total = paid - change)', () {
      const sample = '''
      Tiem Banh Mi 365
      10/05/2026
      Khach dua: 100.000
      Tien thoi: 70.000
      ''';

      final parsed = ReceiptParser.parse(sample);

      expect(parsed.merchant, equals('Tiem Banh Mi 365'));
      expect(parsed.total, equals(30000));
    });
  });
}
