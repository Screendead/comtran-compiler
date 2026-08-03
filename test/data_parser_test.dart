import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

List<SourceCard> _cards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

// Builds a data card from its fields at the documented columns.
String _card({
  String name = '',
  String level = '',
  String type = '',
  String quantity = '',
  String mode = '',
  String justify = '',
  String description = '',
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${level.padLeft(2)}${type.padRight(6)}'
      '${quantity.padLeft(5)}${mode.padRight(1)}${justify.padRight(1)}'
      '${description.padRight(34)}';
  return line.trimRight();
}

// Scans and parses one constructed data division.
(List<DataItem>, List<Diagnostic>) _parse(List<String> lines) {
  final DataScan scan = scanDataDescription(_cards(lines));
  expect(scan.diagnostics, isEmpty, reason: 'scan must be clean');
  final diagnostics = <Diagnostic>[];
  final List<DataItem> items = parseDataGroup(scan, diagnostics);
  return (items, diagnostics);
}

void main() {
  group('the 90.05 data division', () {
    late final List<DataItem> items;

    setUpAll(() {
      final FrontEndResult result = runFrontEnd(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
      final DataGroupScan scan = result.groupScans
          .whereType<DataGroupScan>()
          .single;
      final diagnostics = <Diagnostic>[];
      items = parseDataGroup(scan.scan, diagnostics);
      expect(diagnostics, isEmpty);
    });

    test('parses its 172 entries with zero diagnostics', () {
      expect(items, hasLength(172));
    });

    test('recognizes the seven RECORD roots and the hierarchy', () {
      final Iterable<DataItem> records = items.where(
        (DataItem i) => i.typeCode == DataTypeCode.record,
      );
      expect(records.map((DataItem i) => i.entry.name), [
        'MASTER',
        'DETAIL',
        'CHECK',
        'PAYRECORD',
        'DEPARTMENT.TOTAL',
        'BONDORDER',
        'ERROROUT',
      ]);
      final DataItem master = items.first;
      expect(master.entry.name, 'MASTER');
      expect(master.parent, isNull);
      // MASTER 1 > DAT 2 > EMPLOYEE.NUMBER 3 > DEPARTMENT 4 (F p. 68).
      final DataItem dat = master.children.first;
      expect(dat.entry.name, 'DAT');
      final DataItem employeeNumber = dat.children.first;
      expect(employeeNumber.entry.name, 'EMPLOYEE.NUMBER');
      expect(employeeNumber.children.map((DataItem i) => i.entry.name), [
        'DEPARTMENT',
        'EMPLOYEE',
      ]);
    });

    test('splits pictorials from the description field', () {
      final DataItem name = items.singleWhere(
        (DataItem i) =>
            i.entry.name == 'NAME' &&
            i.parent?.entry.name == 'DAT' &&
            i.parent?.parent?.entry.name == 'MASTER',
      );
      expect(name.pictorial!.text, 'A(15)');
      expect(name.constant, isNull);
      expect(name.extras, isEmpty);
    });

    test('parses the unnamed REDEF entry and its target', () {
      final DataItem redef = items.singleWhere(
        (DataItem i) => i.typeCode == DataTypeCode.redef,
      );
      expect(redef.entry.name, isEmpty);
      expect(redef.entry.level, isNull);
      expect(redef.targetName!.text, 'TABLE');
    });

    test('parses the constants of the condition and control fields', () {
      // Statement 43,00: CNTRLCHARSECLIN 02, description `A '2'`
      // (scan-verified during the deck re-keying).
      final DataItem control = items.singleWhere(
        (DataItem i) => i.entry.name == 'CNTRLCHARSECLIN',
      );
      expect(control.pictorial!.text, 'A');
      expect(control.constant!.text, '2');
    });
  });

  group('type codes', () {
    test('a withdrawn or unknown code draws 907 and a null typeCode', () {
      for (final String code in ['FUNCT', 'PARAM', 'JUNK']) {
        final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
          _card(name: 'F', level: '2', type: code, description: '99'),
        ]);
        expect(items.single.typeCode, isNull, reason: code);
        expect(diagnostics.single.message, msgTypeCodeNotInLanguage);
        expect(diagnostics.single.operands, [code]);
        expect(diagnostics.single.severity, 3);
      }
    });

    test('a RECORD card with a Quantity draws 906', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'R', level: '1', type: 'RECORD', quantity: '5'),
      ]);
      expect(diagnostics.single.message, msgDataCardCodingConflict);
    });

    test('an RCDMRK card accepts an explicit pictorial, as the sample '
        'punches (J 90.05, statement 42,00)', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'M', level: '2', type: 'RCDMRK', description: 'A'),
      ]);
      expect(items.single.typeCode, DataTypeCode.rcdmrk);
      expect(items.single.pictorial!.text, 'A');
      expect(diagnostics, isEmpty);
    });

    test('an RCDMRK card with more than a pictorial draws 906', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'M', level: '2', type: 'RCDMRK', description: "A 'X'"),
      ]);
      expect(diagnostics.single.message, msgDataCardCodingConflict);
    });

    test('a COND entry takes exactly one quoted constant', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'MARRIED', level: '7', type: 'COND', description: "'M'"),
        _card(name: 'SINGLE', level: '7', type: 'COND', description: 'M'),
      ]);
      expect(items.first.constant!.text, 'M');
      expect(diagnostics.single.message, msgDataCardCodingConflict);
      expect(diagnostics.single.card.cardNumber, 2);
    });

    test('a REDEF card with more than the target name draws 906', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(type: 'REDEF', description: 'TABLE EXTRA'),
      ]);
      expect(items.single.targetName!.text, 'TABLE');
      expect(items.single.extras.single.text, 'EXTRA');
      expect(diagnostics.single.message, msgDataCardCodingConflict);
    });

    test('a COPY entry parses its target and draws 110', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'NEW', level: '2', type: 'COPY', description: 'OLD.NAME'),
      ]);
      expect(items.single.typeCode, DataTypeCode.copy);
      expect(items.single.targetName!.text, 'OLD.NAME');
      expect(diagnostics.single.message, msgCopyNotHandled);
    });
  });

  group('the Quantity field', () {
    test('accepts 1 through 32767 (J 02.05.04)', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'T', level: '2', quantity: '32767', description: '99'),
      ]);
      expect(items.single.entry.quantity, 32767);
      expect(diagnostics, isEmpty);
    });

    test('rejects zero, overflow, and non-numbers with 908', () {
      for (final String quantity in ['0', '32768', '1A']) {
        final (_, List<Diagnostic> diagnostics) = _parse([
          _card(name: 'T', level: '2', quantity: quantity, description: '99'),
        ]);
        expect(
          diagnostics.single.message,
          msgQuantityOutOfRange,
          reason: quantity,
        );
      }
    });
  });

  group('the description clauses', () {
    test('QUANTITY IN takes the following name (F pp. 82-83)', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(
          name: 'ITEM',
          level: '3',
          quantity: '50',
          description: '99 QUANTITY IN COUNT',
        ),
      ]);
      expect(items.single.pictorial!.text, '99');
      expect(items.single.quantityInName!.text, 'COUNT');
      expect(diagnostics, isEmpty);
    });

    test('QUANTITY IN without a name draws 906', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'ITEM', level: '3', description: '99 QUANTITY IN'),
      ]);
      expect(diagnostics.single.message, msgDataCardCodingConflict);
    });

    test('BLANK WHEN ZERO is a clause, not a name (J 02.05.07)', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'AMT', level: '3', description: r'$99.99 BLANK WHEN ZERO'),
      ]);
      expect(items.single.pictorial!.text, r'$99.99');
      expect(items.single.blankWhenZero, isTrue);
      expect(items.single.targetName, isNull);
      expect(diagnostics, isEmpty);
    });

    test('a non-format run reads as a name (J 02.05.06)', () {
      final (List<DataItem> items, _) = _parse([
        _card(name: 'W', level: '3', description: 'EMPLOYEE.RATE'),
      ]);
      expect(items.single.pictorial, isNull);
      expect(items.single.targetName!.text, 'EMPLOYEE.RATE');
    });
  });

  group('the level hierarchy', () {
    test('levels need not be consecutive (F p. 68)', () {
      final (List<DataItem> items, List<Diagnostic> diagnostics) = _parse([
        _card(name: 'R', level: '1', type: 'RECORD'),
        _card(name: 'A', level: '5', description: '99'),
        _card(name: 'B', level: '20', description: '99'),
        _card(name: 'C', level: '5', description: '99'),
      ]);
      expect(diagnostics, isEmpty);
      final DataItem r = items[0];
      expect(items[1].parent, same(r));
      expect(items[2].parent, same(items[1]));
      expect(items[3].parent, same(r));
      expect(r.children, [items[1], items[3]]);
    });

    test('a level-less entry attaches at the current position', () {
      final (List<DataItem> items, _) = _parse([
        _card(name: 'R', level: '1', type: 'RECORD'),
        _card(name: 'A', level: '2', description: '99'),
        _card(type: 'REDEF', description: 'A'),
      ]);
      expect(items[2].parent, same(items[1]));
      expect(items[2].children, isEmpty);
    });
  });
}
