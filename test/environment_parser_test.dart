import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The result of [_parse]: the parsed cards, the diagnostics the parse
/// drew, and the scan they came from.
typedef _EnvParse = ({
  List<EnvironmentCard> cards,
  List<Diagnostic> diagnostics,
  EnvironmentScan scan,
});

/// Scans and parses one inline Environment Division fixture, built from
/// [environmentCard] lines.
_EnvParse _parse(
  List<String> lines, {
  bool pedantic = false,
  FileCardTally? fileTally,
}) {
  final EnvironmentScan scan = scanEnvironment(sourceCards(lines));
  final diagnostics = <Diagnostic>[];
  final List<EnvironmentCard> cards = parseEnvironmentGroup(
    scan,
    diagnostics,
    pedantic: pedantic,
    fileTally: fileTally,
  );
  return (cards: cards, diagnostics: diagnostics, scan: scan);
}

void main() {
  group('FILE card errors', () {
    // Each row: the options of one FILE card, and the one message the
    // card draws, or null where it stays clean.
    final Map<String, (String, Message?)> rows = {
      'no direction word draws 89,00': (
        'MASTER,BLOCKSIZE 10',
        msgFileCardFormatError,
      ),
      'BLOCKSIZE with no following integer draws 91,00': (
        'INPUT,MASTER,BLOCKSIZE',
        msgBlocksizeNeedsInteger,
      ),
      'ON ERROR with no following name draws 92,00': (
        'INPUT,MASTER,BLOCKSIZE 10,ON ERROR',
        msgOnErrorNeedsName,
      ),
      'PRIMARY on an INPUT file draws 96,00': (
        'INPUT,MASTER,BLOCKSIZE 10,PRIMARY',
        msgIllegalWordInFileCard,
      ),
      'a FILE card without BLOCKSIZE draws 89,00 (J 02.06.04)': (
        'INPUT,MASTER',
        msgFileCardFormatError,
      ),
      'a CHECKPOINT file needs no BLOCKSIZE': ('CHECKPOINT', null),
      'BLOCK CONTROL on an OUTPUT file draws 96,00 (J 02.06.03)': (
        'OUTPUT,BLOCKSIZE 10,REC1,BLOCK CONTROL',
        msgIllegalWordInFileCard,
      ),
      'BLOCK CONTROL on an INPUT record stays clean': (
        'INPUT,BLOCKSIZE 10,REC1,BLOCK CONTROL',
        null,
      ),
    };
    for (final MapEntry(key: name, value: (options, message)) in rows.entries) {
      test(name, () {
        final _EnvParse result = _parse([
          environmentCard(name: 'F', type: 'FILE', options: options),
        ]);
        expect(result.scan.diagnostics, isEmpty);
        expect(result.cards.single, isA<FileCard>());
        expect(
          [for (final Diagnostic d in result.diagnostics) d.message],
          [?message],
        );
      });
    }

    test('a key word as a FILE or record name draws 178,00 (D10.8)', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'ZERO',
          type: 'FILE',
          options: 'INPUT,BLOCKSIZE 10,MOVE',
        ),
      ]);
      expect(result.diagnostics.map((Diagnostic d) => d.message), [
        msgKeyWordAsDataName,
        msgKeyWordAsDataName,
      ]);
      final card = result.cards.single as FileCard;
      expect(card.records.single.name.text, 'MOVE');
    });

    test('a second input record with no leading comma draws 924 under '
        '--pedantic (D8.5)', () {
      final List<String> lines = [
        environmentCard(
          name: 'F',
          type: 'FILE',
          options: 'INPUT,REC1 REC2,BLOCKSIZE 10',
        ),
      ];
      final _EnvParse plain = _parse(lines);
      expect(plain.scan.diagnostics, isEmpty);
      expect(plain.diagnostics, isEmpty);
      final _EnvParse pedantic = _parse(lines, pedantic: true);
      expect(pedantic.diagnostics.single.message, msgInputFileCommaOmitted);
      // The record list is identical in both modes (D11.4).
      final plainCard = plain.cards.single as FileCard;
      final pedanticCard = pedantic.cards.single as FileCard;
      expect(
        [for (final FileRecordClause r in pedanticCard.records) r.name.text],
        [for (final FileRecordClause r in plainCard.records) r.name.text],
      );
    });

    test('a second input record after a comma stays clean under --pedantic '
        '(D8.5)', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'F',
          type: 'FILE',
          options: 'INPUT,REC1,REC2,BLOCKSIZE 10',
        ),
      ], pedantic: true);
      expect(result.diagnostics, isEmpty);
    });

    test('the 64th FILE card draws 193,00 across groups (D10.8)', () {
      final tally = FileCardTally();
      final diagnostics = <Diagnostic>[];
      for (var group = 0; group < 2; group++) {
        final _EnvParse result = _parse([
          for (var i = 0; i < 32; i++)
            environmentCard(
              name: 'F$group$i',
              type: 'FILE',
              options: 'INPUT,R$group$i,BLOCKSIZE 10',
            ),
        ], fileTally: tally);
        diagnostics.addAll(result.diagnostics);
      }
      expect(tally.count, 64);
      expect(diagnostics.single.message, msgTooManyFiles);
    });

    test('PATTERN draws 905,00 and nothing else (D9.12)', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'F',
          type: 'FILE',
          options: 'INPUT,MASTER,PATTERN,BLOCKSIZE 10',
        ),
      ]);
      expect(result.scan.diagnostics, isEmpty);
      expect(result.diagnostics.map((Diagnostic d) => d.message), [
        msgPatternNotImplemented,
      ]);
    });
  });

  test('each FILE key word sets its option (J 02.06.04-05)', () {
    // HOLD and SPANS: "The compiler does not differentiate" (J 02.06.04).
    // The options field is 41 columns wide (J 02.06.01): each option
    // text must fit inside it, on one card.
    final Map<String, bool Function(FileCard)> options = {
      'INPUT,CARD,MASTER,BLOCKSIZE 10': (FileCard c) => c.card && c.begin,
      'INPUT,MASTER,BLOCKSIZE 10,HOLD': (FileCard c) => c.holdOrSpans,
      'INPUT,MASTER,BLOCKSIZE 10,SPANS': (FileCard c) => c.holdOrSpans,
      'INPUT,MASTER,BLOCKSIZE 10,BEGIN': (FileCard c) => c.begin && !c.card,
      'INPUT,BLOCKSIZE 10,FOR LABEL ERR': (FileCard c) =>
          c.forLabel!.text == 'ERR',
      'OUTPUT,BLOCKSIZE 10,R,FIND LENGTH IN LEN': (FileCard c) =>
          c.records.single.findLengthIn!.text == 'LEN',
      'OUTPUT,BLOCKSIZE 10,R,PLACE LENGTH IN LEN': (FileCard c) =>
          c.records.single.placeLengthIn!.text == 'LEN',
      'OUTPUT,BLOCKSIZE 10,REC1,NO CONTROL WORD': (FileCard c) =>
          c.records.single.noControlWord,
    };
    for (final MapEntry(key: text, value: isSet) in options.entries) {
      final _EnvParse result = _parse([
        environmentCard(name: 'F', type: 'FILE', options: text),
      ]);
      expect(result.diagnostics, isEmpty, reason: text);
      expect(isSet(result.cards.single as FileCard), isTrue, reason: text);
    }
  });

  group('SPECIF operand errors (D10.1)', () {
    test('a literal first item draws 154,00', () {
      final _EnvParse result = _parse([
        environmentCard(type: 'SPECIF', options: "'D1',DEFER"),
      ]);
      expect(result.diagnostics.single.message, msgSpecifFileNameNotFirst);
      expect((result.cards.single as SpecifCard).fileName, isNull);
    });

    // Each row: the options of one SPECIF card, and the one message
    // the card draws.
    final Map<String, (String, Message)> rows = {
      'UNIT1 with no following literal draws 155,00': (
        'MASTER,UNIT1,DEFER',
        msgUnitNeedsLiteral,
      ),
      'UNIT2 with no following literal draws 155,00': (
        'MASTER,UNIT2 A1',
        msgUnitNeedsLiteral,
      ),
      'SERIAL with no following literal draws 156,00': (
        'MASTER,SERIAL',
        msgSerialNeedsLiteral,
      ),
      'REEL with no following literal draws 157,00': (
        'MASTER,REEL 12',
        msgReelNeedsLiteral,
      ),
      'RETAIN with no following integer draws 158,00': (
        "MASTER,RETAIN 'AB'",
        msgRetainNeedsInteger,
      ),
      'ACTIVITY with no following integer draws 159,00': (
        'MASTER,ACTIVITY HIGH',
        msgActivityNeedsInteger,
      ),
      'an over-length REEL literal draws 160,00': (
        "MASTER,REEL '12345'",
        msgKeyWordLiteralTooLong,
      ),
      'an over-length UNIT1 literal draws 160,00': (
        "MASTER,UNIT1 'A(1)234'",
        msgKeyWordLiteralTooLong,
      ),
      'an out-of-range ACTIVITY integer draws the 153,00 fallback': (
        'MASTER,ACTIVITY 100',
        msgSpecifCardFormatError,
      ),
      'a non-numeric REEL literal draws the 153,00 fallback': (
        "MASTER,REEL '12A'",
        msgSpecifCardFormatError,
      ),
      'an over-length RETAIN number draws the 153,00 fallback': (
        'MASTER,RETAIN 1234',
        msgSpecifCardFormatError,
      ),
    };
    for (final MapEntry(key: name, value: (options, message)) in rows.entries) {
      test(name, () {
        final _EnvParse result = _parse([
          environmentCard(type: 'SPECIF', options: options),
        ]);
        expect(result.diagnostics.single.message, message);
      });
    }

    test('an over-length SERIAL literal draws 160,00 and is dropped', () {
      final _EnvParse result = _parse([
        environmentCard(type: 'SPECIF', options: "MASTER,SERIAL 'ABC123'"),
      ]);
      expect(result.diagnostics.single.message, msgKeyWordLiteralTooLong);
      expect((result.cards.single as SpecifCard).serial, isNull);
    });
  });

  test('HIGH/LOW after LABELS or LABELN is the label density '
      '(J 02.06.12)', () {
    for (final (String options, String? density, String? labels, String? label)
        in [
          ('F1,LOW,LABELS,HIGH', 'LOW', 'LABELS', 'HIGH'),
          ('F1,LABELN,LOW', null, 'LABELN', 'LOW'),
          ('F1,HIGH', 'HIGH', null, null),
        ]) {
      final _EnvParse result = _parse([
        environmentCard(type: 'SPECIF', options: options),
      ]);
      expect(result.diagnostics, isEmpty, reason: options);
      final card = result.cards.single as SpecifCard;
      expect(card.density, density, reason: options);
      expect(card.labels, labels, reason: options);
      expect(card.labelDensity, label, reason: options);
    }
  });

  test('each SPECIF key word sets its option (J 02.06.10-12; D7.2)', () {
    // CHKS: Appendix 90.08 mislabels CHECKC as CHKS; the parser accepts
    // the mislabeling with no diagnostic and stores it as CHECKC (D7.2).
    final Map<String, bool Function(SpecifCard)> options = {
      "UNIT2 'D2'": (SpecifCard c) => c.unit2 == 'D2',
      'UNIT2 *': (SpecifCard c) => c.unit2 == '*',
      'DEFER': (SpecifCard c) => c.defer,
      'OPENF': (SpecifCard c) => c.openF,
      'CLOSEW': (SpecifCard c) => c.closeMode == 'CLOSEW',
      'ACTIVITY 50': (SpecifCard c) => c.activity == 50,
      'CHECKC': (SpecifCard c) => c.checkpoint == 'CHECKC',
      'CHECKF': (SpecifCard c) => c.checkpoint == 'CHECKF',
      'CHKS': (SpecifCard c) => c.checkpoint == 'CHECKC',
      'MULTI': (SpecifCard c) => c.multi,
      'SEQ': (SpecifCard c) => c.seq,
      'CKSUMS': (SpecifCard c) => c.cksums,
      "SERIAL '12'": (SpecifCard c) => c.serial == '12',
      "REEL '1234'": (SpecifCard c) => c.reel == '1234',
      'RETAIN 123': (SpecifCard c) => c.retain == '123',
    };
    for (final MapEntry(key: option, value: isSet) in options.entries) {
      final _EnvParse result = _parse([
        environmentCard(type: 'SPECIF', options: 'MASTER,$option'),
      ]);
      expect(result.diagnostics, isEmpty, reason: option);
      expect(isSet(result.cards.single as SpecifCard), isTrue, reason: option);
    }
  });

  group('other card errors', () {
    test('SPECIF with an unknown word draws 153,00', () {
      final _EnvParse result = _parse([
        environmentCard(type: 'SPECIF', options: 'MASTER,FROBOZZ'),
      ]);
      expect(result.diagnostics.single.message, msgSpecifCardFormatError);
    });

    test('POOL BLOCKSIZE with no following integer draws 162,00', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'POOLA',
          type: 'POOL',
          options: 'FILEA,BLOCKSIZE',
        ),
      ]);
      expect(result.diagnostics.single.message, msgPoolBlocksizeNeedsInteger);
      expect((result.cards.single as PoolCard).fileNames, hasLength(1));
    });

    test('GROUP OPENCOUNT with no following integer draws 165,00', () {
      final _EnvParse result = _parse([
        environmentCard(type: 'GROUP', options: 'FILEA,OPENCOUNT'),
      ]);
      expect(result.diagnostics.single.message, msgOpencountNeedsInteger);
      expect((result.cards.single as GroupCard).names, hasLength(1));
    });

    test(
      // ignore: lines_longer_than_80_chars, reason: docs/design/message-checklist.tsv matches this test by literal name (msgs 90, 207); a split string would still concatenate but the checklist test greps raw source text, so the literal must stay on one line.
      'a CONTRL name over 6 characters draws 207,00; well-formed card also gets 90,00',
      () {
        final _EnvParse result = _parse([
          environmentCard(
            name: 'TOOLONGNAME',
            type: 'CONTRL',
            options: 'SECTIONA',
          ),
        ]);
        expect(result.diagnostics.map((Diagnostic d) => d.message), [
          msgContrlNameInvalid,
          msgEnvironmentTypeNotProcessed,
        ]);
      },
    );

    test('a duplicate CONTRL name draws 207,00 on the repeat only', () {
      final _EnvParse result = _parse([
        environmentCard(name: 'AREA1', type: 'CONTRL', options: 'SECTA'),
        environmentCard(name: 'AREA1', type: 'CONTRL', options: 'SECTB'),
      ]);
      final Iterable<Diagnostic> nameErrors = result.diagnostics.where(
        (Diagnostic d) => d.message == msgContrlNameInvalid,
      );
      expect(nameErrors, hasLength(1));
      expect(nameErrors.single.card, result.scan.specs[1].cards.first);
      // Both cards still get 90,00 (D7.8).
      expect(
        result.diagnostics.where(
          (Diagnostic d) => d.message == msgEnvironmentTypeNotProcessed,
        ),
        hasLength(2),
      );
    });

    test('OPTION with unrecognized content draws 3,00', () {
      final _EnvParse result = _parse([
        environmentCard(type: 'OPTION', options: 'FROBOZZ'),
      ]);
      expect(result.diagnostics.single.message, msgOptionCardFormatError);
    });
  });

  group('COND key setting normalization (D9.16)', () {
    test('a short KEYS setting draws 925 under --pedantic (D9.16)', () {
      final List<String> lines = [
        environmentCard(name: 'COND1', type: 'COND', options: "KEYS '77'"),
      ];
      final _EnvParse plain = _parse(lines);
      expect(plain.diagnostics, isEmpty);
      final _EnvParse pedantic = _parse(lines, pedantic: true);
      expect(pedantic.diagnostics.single.message, msgCondKeyUnderLength);
      expect((plain.cards.single as CondCard).setting, '000000000077');
      // The padded value is identical in both modes (D11.4).
      expect(
        (pedantic.cards.single as CondCard).setting,
        (plain.cards.single as CondCard).setting,
      );
    });

    test('a 13-digit KEYS setting draws 6,00 and keeps the rightmost 12', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'COND1',
          type: 'COND',
          options: "KEYS '0123456701234'",
        ),
      ]);
      expect(result.diagnostics.single.message, msgCondKeysTooLong);
      expect((result.cards.single as CondCard).setting, '123456701234');
    });

    test('a KEYS setting with an imbedded blank draws 7,00 (D9.16)', () {
      final _EnvParse result = _parse([
        environmentCard(name: 'COND1', type: 'COND', options: "KEYS '77 001'"),
      ]);
      expect(result.diagnostics.single.message, msgCondKeysNotOctal);
      expect((result.cards.single as CondCard).setting, '000000000001');
    });

    test('a KEYS setting with an 8 draws 7,00 and becomes key setting 1', () {
      final _EnvParse result = _parse([
        environmentCard(
          name: 'COND1',
          type: 'COND',
          options: "KEYS '780000000000'",
        ),
      ]);
      expect(result.diagnostics.single.message, msgCondKeysNotOctal);
      expect((result.cards.single as CondCard).setting, '000000000001');
    });
  });

  group('diagnostic conformance', () {
    test(
      'every issued message id has a severity row (Diagnostic.severity)',
      () {
        final _EnvParse result = _parse([
          // 89 (bad direction).
          environmentCard(name: 'F1', type: 'FILE', options: 'MASTER'),
          // 91, 92, 93, 905, 96 (PRIMARY on an input file) — split across a
          // continuation card; the options field is 41 columns wide.
          environmentCard(
            name: 'F2',
            type: 'FILE',
            options: 'INPUT,MASTER,BLOCKSIZE,ON ERROR,',
            continued: true,
          ),
          environmentCard(options: 'FOR LABEL,PATTERN,PRIMARY'),
          // 94, 95 — likewise split.
          environmentCard(
            name: 'F3',
            type: 'FILE',
            options: 'OUTPUT,REC1,FIND LENGTH IN,',
            continued: true,
          ),
          environmentCard(options: 'PLACE LENGTH IN'),
          // 153.
          environmentCard(type: 'SPECIF', options: 'MASTER,FROBOZZ'),
          // 154, 155, 156 — split across a continuation card.
          environmentCard(
            type: 'SPECIF',
            options: "'X',UNIT1,SERIAL,",
            continued: true,
          ),
          // 157, 158, 159, 160.
          environmentCard(options: "REEL,RETAIN,ACTIVITY,UNIT2 'ABC1234'"),
          // 161 (no file names at all).
          environmentCard(
            name: 'POOLA',
            type: 'POOL',
            options: 'BUFFERCOUNT 5',
          ),
          // 163.
          environmentCard(
            name: 'POOLB',
            type: 'POOL',
            options: 'FILEA,BUFFERCOUNT',
          ),
          // 164 (no names at all).
          environmentCard(type: 'GROUP', options: 'OPENCOUNT 5'),
          // 176 (malformed shape) plus 90.
          environmentCard(name: 'BAD1', type: 'CONTRL'),
          // 207 (over-length) plus 90.
          environmentCard(
            name: 'TOOLONGNAME',
            type: 'CONTRL',
            options: 'SECTIONA',
          ),
          // 3.
          environmentCard(type: 'OPTION', options: 'FROBOZZ'),
          // 4 (missing KEYS).
          environmentCard(name: 'COND1', type: 'COND', options: 'FOO'),
          // 6.
          environmentCard(
            name: 'COND2',
            type: 'COND',
            options: "KEYS '0123456701234'",
          ),
          // 7.
          environmentCard(
            name: 'COND3',
            type: 'COND',
            options: "KEYS '780000000000'",
          ),
        ]);
        final List<Diagnostic> diagnostics = result.diagnostics;

        // The exact spread of message ids this parser issues, in source
        // order, each paired with its card: a duplicated, missing, or
        // misattributed diagnostic fails this. Card 1 (F1) draws
        // 89 twice — once for the missing direction word, once because
        // BLOCKSIZE, unreachable after that, is never seen either. Card 4
        // (F3) likewise draws 89 at the end: its options never mention
        // BLOCKSIZE at all.
        expect(
          diagnostics.map(
            (Diagnostic d) => (d.message.number, d.card!.cardNumber),
          ),
          [
            ('89,00', 1),
            ('89,00', 1),
            ('91,00', 2),
            ('92,00', 2),
            ('93,00', 3),
            ('905,00', 3),
            ('96,00', 3),
            ('95,00', 4),
            ('94,00', 5),
            ('89,00', 4),
            ('153,00', 6),
            ('154,00', 7),
            ('155,00', 7),
            ('156,00', 7),
            ('157,00', 8),
            ('158,00', 8),
            ('159,00', 8),
            ('160,00', 8),
            ('161,00', 9),
            ('163,00', 10),
            ('164,00', 11),
            ('90,00', 12),
            ('176,00', 12),
            ('207,00', 13),
            ('90,00', 13),
            ('3,00', 14),
            ('4,00', 15),
            ('6,00', 16),
            ('7,00', 17),
          ],
        );

        for (final d in diagnostics) {
          expect(() => d.severity, returnsNormally);
          expect(d.severity, messageSeverities[d.message.number]);
        }
      },
    );
  });
}
