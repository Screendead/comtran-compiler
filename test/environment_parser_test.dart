import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

List<SourceCard> _cards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

String _card({
  String name = '',
  String type = '',
  String options = '',
  bool continued = false,
}) {
  final line =
      '${' ' * 6}${name.padRight(16)}${' ' * 2}${type.padRight(6)}'
      '${options.padRight(41)}${continued ? 'X' : ' '}';
  return line.trimRight();
}

void main() {
  group('the 90.05 environment division', () {
    test('parses with zero added diagnostics and matches the deck', () {
      final FrontEndResult result = runFrontEnd(
        decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
      );
      final EnvironmentGroupScan envGroup = result.groupScans
          .whereType<EnvironmentGroupScan>()
          .single;
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        envGroup.scan,
        diagnostics,
      );
      expect(diagnostics, isEmpty);
      // 7 FILE + 7 SPECIF, per the mirror (tests/90.05-payroll.deck:181-195).
      expect(cards, hasLength(14));
      expect(cards.whereType<FileCard>(), hasLength(7));
      expect(cards.whereType<SpecifCard>(), hasLength(7));

      // Line 181: INPUTMASTER FILE INPUT,BINARY,TAPE,MASTER,BLOCKSIZE 300
      final FileCard inputMaster = cards.whereType<FileCard>().firstWhere(
        (FileCard c) => c.spec.name == 'INPUTMASTER',
      );
      expect(inputMaster.direction, FileDirection.input);
      expect(inputMaster.binary, isTrue);
      expect(inputMaster.card, isFalse);
      expect(inputMaster.blocksize, 300);
      expect(
        [for (final FileRecordClause r in inputMaster.records) r.name.text],
        ['MASTER'],
      );

      // Line 189-190: PAYFILE FILE OUTPUT,BCD,TAPE,PAYRECORD,
      //                       DEPARTMENT.TOTAL,BLOCKSIZE 20
      final FileCard payfile = cards.whereType<FileCard>().firstWhere(
        (FileCard c) => c.spec.name == 'PAYFILE',
      );
      expect(payfile.direction, FileDirection.output);
      expect(payfile.binary, isFalse);
      expect(payfile.blocksize, 20);
      expect(
        [for (final FileRecordClause r in payfile.records) r.name.text],
        ['PAYRECORD', 'DEPARTMENT.TOTAL'],
      );

      // Line 182: SPECIFINPUTMASTER, UNIT1 'D1',OPENW,CLOSER
      final SpecifCard specif = cards.whereType<SpecifCard>().firstWhere(
        (SpecifCard c) => c.fileName?.text == 'INPUTMASTER',
      );
      expect(specif.unit1, 'D1');
      expect(specif.unit2, isNull);
      expect(specif.openW, isTrue);
      expect(specif.closeMode, 'CLOSER');
      expect(specif.density, isNull);

      // Line 186: SPECIFDETAILFILE,UNIT1 'C2',OPENW,CLOSER,LOW
      final SpecifCard detailSpecif = cards.whereType<SpecifCard>().firstWhere(
        (SpecifCard c) => c.fileName?.text == 'DETAILFILE',
      );
      expect(detailSpecif.unit1, 'C2');
      expect(detailSpecif.density, 'LOW');
    });
  });

  group('FILE card errors', () {
    test('no direction word draws 89,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'F', type: 'FILE', options: 'MASTER,BLOCKSIZE 10'),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgFileCardFormatError);
      expect(cards.single, isA<FileCard>());
    });

    test('BLOCKSIZE with no following integer draws 91,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'F', type: 'FILE', options: 'INPUT,MASTER,BLOCKSIZE'),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgBlocksizeNeedsInteger);
    });

    test('ON ERROR with no following name draws 92,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'F',
            type: 'FILE',
            options: 'INPUT,MASTER,BLOCKSIZE 10,ON ERROR',
          ),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgOnErrorNeedsName);
    });

    test('PRIMARY on an INPUT file draws 96,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'F',
            type: 'FILE',
            options: 'INPUT,MASTER,BLOCKSIZE 10,PRIMARY',
          ),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgIllegalWordInFileCard);
    });

    test('a FILE card without BLOCKSIZE draws 89,00 (J 02.06.04)', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(name: 'F', type: 'FILE', options: 'INPUT,MASTER')]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgFileCardFormatError);
    });

    test('a CHECKPOINT file needs no BLOCKSIZE', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(name: 'F', type: 'FILE', options: 'CHECKPOINT')]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics, isEmpty);
    });

    test('BLOCK CONTROL on an OUTPUT file draws 96,00 (J 02.06.03)', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'F',
            type: 'FILE',
            options: 'OUTPUT,BLOCKSIZE 10,REC1,BLOCK CONTROL',
          ),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgIllegalWordInFileCard);
    });

    test('BLOCK CONTROL on an INPUT record stays clean', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'F',
            type: 'FILE',
            options: 'INPUT,BLOCKSIZE 10,REC1,BLOCK CONTROL',
          ),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics, isEmpty);
    });

    test('a key word as a FILE or record name draws 178,00 (D10.8)', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'ZERO', type: 'FILE', options: 'INPUT,BLOCKSIZE 10,MOVE'),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.map((Diagnostic d) => d.message), [
        msgKeyWordAsDataName,
        msgKeyWordAsDataName,
      ]);
      final card = cards.single as FileCard;
      expect(card.records.single.name.text, 'MOVE');
    });

    test('the 64th FILE card draws 193,00 across groups (D10.8)', () {
      final tally = FileCardTally();
      final diagnostics = <Diagnostic>[];
      for (var group = 0; group < 2; group++) {
        final EnvironmentScan scan = scanEnvironment(
          _cards([
            for (var i = 0; i < 32; i++)
              _card(
                name: 'F$group$i',
                type: 'FILE',
                options: 'INPUT,R$group$i,BLOCKSIZE 10',
              ),
          ]),
        );
        parseEnvironmentGroup(scan, diagnostics, fileTally: tally);
      }
      expect(tally.count, 64);
      expect(diagnostics.single.message, msgTooManyFiles);
    });

    test('PATTERN draws 905,00 and nothing else (D9.12)', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(
            name: 'F',
            type: 'FILE',
            options: 'INPUT,MASTER,PATTERN,BLOCKSIZE 10',
          ),
        ]),
      );
      expect(scan.diagnostics, isEmpty);
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.map((Diagnostic d) => d.message), [
        msgPatternNotImplemented,
      ]);
    });
  });

  group('SPECIF operand errors (D10.1)', () {
    List<Diagnostic> diagnose(String options) {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'SPECIF', options: options)]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      return diagnostics;
    }

    test('a literal first item draws 154,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'SPECIF', options: "'D1',DEFER")]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgSpecifFileNameNotFirst);
      expect((cards.single as SpecifCard).fileName, isNull);
    });

    test('UNIT1 with no following literal draws 155,00', () {
      expect(
        diagnose('MASTER,UNIT1,DEFER').single.message,
        msgUnitNeedsLiteral,
      );
    });

    test('UNIT2 with no following literal draws 155,00', () {
      expect(diagnose('MASTER,UNIT2 A1').single.message, msgUnitNeedsLiteral);
    });

    test('SERIAL with no following literal draws 156,00', () {
      expect(diagnose('MASTER,SERIAL').single.message, msgSerialNeedsLiteral);
    });

    test('REEL with no following literal draws 157,00', () {
      expect(diagnose('MASTER,REEL 12').single.message, msgReelNeedsLiteral);
    });

    test('RETAIN with no following integer draws 158,00', () {
      expect(
        diagnose("MASTER,RETAIN 'AB'").single.message,
        msgRetainNeedsInteger,
      );
    });

    test('ACTIVITY with no following integer draws 159,00', () {
      expect(
        diagnose('MASTER,ACTIVITY HIGH').single.message,
        msgActivityNeedsInteger,
      );
    });

    test('an over-length SERIAL literal draws 160,00 and is dropped', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'SPECIF', options: "MASTER,SERIAL 'ABC123'")]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgKeyWordLiteralTooLong);
      expect((cards.single as SpecifCard).serial, isNull);
    });

    test('an over-length REEL literal draws 160,00', () {
      expect(
        diagnose("MASTER,REEL '12345'").single.message,
        msgKeyWordLiteralTooLong,
      );
    });

    test('an over-length UNIT1 literal draws 160,00', () {
      expect(
        diagnose("MASTER,UNIT1 'A(1)234'").single.message,
        msgKeyWordLiteralTooLong,
      );
    });

    test('an out-of-range ACTIVITY integer draws the 153,00 fallback', () {
      expect(
        diagnose('MASTER,ACTIVITY 100').single.message,
        msgSpecifCardFormatError,
      );
    });

    test('a non-numeric REEL literal draws the 153,00 fallback', () {
      expect(
        diagnose("MASTER,REEL '12A'").single.message,
        msgSpecifCardFormatError,
      );
    });

    test('an over-length RETAIN number draws the 153,00 fallback', () {
      expect(
        diagnose('MASTER,RETAIN 1234').single.message,
        msgSpecifCardFormatError,
      );
    });
  });

  group('SPECIF label density (J 02.06.12)', () {
    SpecifCard parse(String options) {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'SPECIF', options: options)]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics, isEmpty);
      return cards.single as SpecifCard;
    }

    test('HIGH/LOW after LABELS is the label density', () {
      final SpecifCard card = parse('F1,LOW,LABELS,HIGH');
      expect(card.density, 'LOW');
      expect(card.labels, 'LABELS');
      expect(card.labelDensity, 'HIGH');
    });

    test('HIGH/LOW after LABELN is the label density', () {
      final SpecifCard card = parse('F1,LABELN,LOW');
      expect(card.density, isNull);
      expect(card.labels, 'LABELN');
      expect(card.labelDensity, 'LOW');
    });

    test('HIGH/LOW without LABELS/LABELN is the file density', () {
      final SpecifCard card = parse('F1,HIGH');
      expect(card.density, 'HIGH');
      expect(card.labelDensity, isNull);
    });
  });

  group('other card errors', () {
    test('SPECIF with an unknown word draws 153,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'SPECIF', options: 'MASTER,FROBOZZ')]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgSpecifCardFormatError);
    });

    test('POOL BLOCKSIZE with no following integer draws 162,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'POOLA', type: 'POOL', options: 'FILEA,BLOCKSIZE'),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgPoolBlocksizeNeedsInteger);
      expect((cards.single as PoolCard).fileNames, hasLength(1));
    });

    test('GROUP OPENCOUNT with no following integer draws 165,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'GROUP', options: 'FILEA,OPENCOUNT')]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgOpencountNeedsInteger);
      expect((cards.single as GroupCard).names, hasLength(1));
    });

    test(
      'a CONTRL name over 6 characters draws 207,00; well-formed card also gets 90,00',
      () {
        final EnvironmentScan scan = scanEnvironment(
          _cards([
            _card(name: 'TOOLONGNAME', type: 'CONTRL', options: 'SECTIONA'),
          ]),
        );
        final diagnostics = <Diagnostic>[];
        parseEnvironmentGroup(scan, diagnostics);
        expect(diagnostics.map((Diagnostic d) => d.message), [
          msgContrlNameInvalid,
          msgEnvironmentTypeNotProcessed,
        ]);
      },
    );

    test('a duplicate CONTRL name draws 207,00 on the repeat only', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'AREA1', type: 'CONTRL', options: 'SECTA'),
          _card(name: 'AREA1', type: 'CONTRL', options: 'SECTB'),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      final Iterable<Diagnostic> nameErrors = diagnostics.where(
        (Diagnostic d) => d.message == msgContrlNameInvalid,
      );
      expect(nameErrors, hasLength(1));
      expect(nameErrors.single.card, scan.specs[1].cards.first);
      // Both cards still get 90,00 (D7.8).
      expect(
        diagnostics.where(
          (Diagnostic d) => d.message == msgEnvironmentTypeNotProcessed,
        ),
        hasLength(2),
      );
    });

    test('OPTION with unrecognized content draws 3,00', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(type: 'OPTION', options: 'FROBOZZ')]),
      );
      final diagnostics = <Diagnostic>[];
      parseEnvironmentGroup(scan, diagnostics);
      expect(diagnostics.single.message, msgOptionCardFormatError);
    });
  });

  group('COND key setting normalization (D9.16)', () {
    test("KEYS '77' pads silently to 12 octal digits", () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(name: 'COND1', type: 'COND', options: "KEYS '77'")]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics, isEmpty);
      expect((cards.single as CondCard).setting, '000000000077');
    });

    test('a 13-digit KEYS setting draws 6,00 and keeps the rightmost 12', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'COND1', type: 'COND', options: "KEYS '0123456701234'"),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgCondKeysTooLong);
      expect((cards.single as CondCard).setting, '123456701234');
    });

    test('a KEYS setting with an imbedded blank draws 7,00 (D9.16)', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([_card(name: 'COND1', type: 'COND', options: "KEYS '77 001'")]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgCondKeysNotOctal);
      expect((cards.single as CondCard).setting, '000000000001');
    });

    test('a KEYS setting with an 8 draws 7,00 and becomes key setting 1', () {
      final EnvironmentScan scan = scanEnvironment(
        _cards([
          _card(name: 'COND1', type: 'COND', options: "KEYS '780000000000'"),
        ]),
      );
      final diagnostics = <Diagnostic>[];
      final List<EnvironmentCard> cards = parseEnvironmentGroup(
        scan,
        diagnostics,
      );
      expect(diagnostics.single.message, msgCondKeysNotOctal);
      expect((cards.single as CondCard).setting, '000000000001');
    });
  });

  group('diagnostic conformance', () {
    test(
      'every issued message id has a severity row (Diagnostic.severity)',
      () {
        final EnvironmentScan scan = scanEnvironment(
          _cards([
            // 89 (bad direction).
            _card(name: 'F1', type: 'FILE', options: 'MASTER'),
            // 91, 92, 93, 905, 96 (PRIMARY on an input file) — split across a
            // continuation card; the options field is 41 columns wide.
            _card(
              name: 'F2',
              type: 'FILE',
              options: 'INPUT,MASTER,BLOCKSIZE,ON ERROR,',
              continued: true,
            ),
            _card(options: 'FOR LABEL,PATTERN,PRIMARY'),
            // 94, 95 — likewise split.
            _card(
              name: 'F3',
              type: 'FILE',
              options: 'OUTPUT,REC1,FIND LENGTH IN,',
              continued: true,
            ),
            _card(options: 'PLACE LENGTH IN'),
            // 153.
            _card(type: 'SPECIF', options: 'MASTER,FROBOZZ'),
            // 154, 155, 156 — split across a continuation card.
            _card(
              type: 'SPECIF',
              options: "'X',UNIT1,SERIAL,",
              continued: true,
            ),
            // 157, 158, 159, 160.
            _card(options: "REEL,RETAIN,ACTIVITY,UNIT2 'ABC1234'"),
            // 161 (no file names at all).
            _card(name: 'POOLA', type: 'POOL', options: 'BUFFERCOUNT 5'),
            // 163.
            _card(name: 'POOLB', type: 'POOL', options: 'FILEA,BUFFERCOUNT'),
            // 164 (no names at all).
            _card(type: 'GROUP', options: 'OPENCOUNT 5'),
            // 176 (malformed shape) plus 90.
            _card(name: 'BAD1', type: 'CONTRL'),
            // 207 (over-length) plus 90.
            _card(name: 'TOOLONGNAME', type: 'CONTRL', options: 'SECTIONA'),
            // 3.
            _card(type: 'OPTION', options: 'FROBOZZ'),
            // 4 (missing KEYS).
            _card(name: 'COND1', type: 'COND', options: 'FOO'),
            // 6.
            _card(name: 'COND2', type: 'COND', options: "KEYS '0123456701234'"),
            // 7.
            _card(name: 'COND3', type: 'COND', options: "KEYS '780000000000'"),
          ]),
        );
        final diagnostics = <Diagnostic>[];
        parseEnvironmentGroup(scan, diagnostics);

        // A representative spread of the message ids this parser issues.
        expect(
          diagnostics.map((Diagnostic d) => d.message.number),
          containsAll(<String>[
            '89,00', '91,00', '92,00', '93,00', '96,00', '905,00', //
            '94,00', '95,00', //
            '153,00', //
            '154,00', '155,00', '156,00', '157,00', '158,00', '159,00', //
            '160,00', //
            '161,00', '163,00', //
            '164,00', //
            '176,00', '207,00', '90,00', //
            '3,00', //
            '4,00', '6,00', '7,00', //
          ]),
        );

        for (final d in diagnostics) {
          expect(() => d.severity, returnsNormally);
          expect(d.severity, messageSeverities[d.message.number]);
        }
      },
    );
  });
}
