import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

FrontEndResult _payroll() => runFrontEnd(loadPayrollDeck());

const ListingOptions _sampleOptions = ListingOptions(
  date: '10/18/61',
  time: '2.45',
  title: 'COMPILATION OF SAMPLE PROBLEM',
);

void main() {
  group('the 90.05 front end', () {
    late FrontEndResult result;

    setUpAll(() => result = _payroll());

    test('numbers exactly 229 statements continuously', () {
      expect(result.diagnostics, isEmpty);
      expect(result.maxSeverity, 0);
      expect(result.statementCount, 229);
      // Division boundaries: data 1-172, environment 173-186,
      // procedure 187-229 (J 90.05 listing, PDF pp. 192-197).
      expect(result.statementNumberByCard[3], '1,00');
      expect(result.statementNumberByCard[180], isNull); // *ENVIRONMENT
      expect(result.statementNumberByCard[181], '173,00');
      expect(result.statementNumberByCard[197], '187,00');
      expect(result.statementNumberByCard[293], '229,00');
    });

    test('a continued entry keeps one number across its cards', () {
      // Statement 3,00 spans two cards (EMPLOYEE.NUM + BER); the number
      // prints on the first card only.
      expect(result.statementNumberByCard[5], '3,00');
      expect(result.statementNumberByCard[6], '3,00');
      expect(result.numberedCards, contains(5));
      expect(result.numberedCards, isNot(contains(6)));
    });

    test('page 197 statements group per the scan, not the transcription', () {
      // The conversion misattributes the numbers of statements 218-221
      // and 228 by one line (printer half-line stagger); the page scan
      // is authoritative. Verified against images/page-197.png.
      final ProcedureGroupScan procedure = result.groupScans
          .whereType<ProcedureGroupScan>()
          .single;
      String firstWords(int statement, int count) {
        final ProcedureSentence s = procedure.scan.sentences[statement - 187];
        return s.tokens.take(count).map((Token t) => t.text).join(' ');
      }

      expect(procedure.scan.sentences[217 - 187].label, 'BOND.ROUTINE');
      expect(firstWords(218, 2), 'ADD M.BND.DED');
      expect(firstWords(219, 2), 'MOVE M.BND.DED');
      expect(firstWords(220, 3), 'IF MASTER BONDENOMINATION');
      expect(firstWords(221, 2), 'MOVE CORRESPONDING');
      expect(firstWords(222, 2), 'FILE BONDORDER');
      expect(firstWords(228, 2), 'MOVE CORRESPONDING');
      expect(procedure.scan.sentences[220 - 187].cards, hasLength(3));
    });
  });

  group('the listing', () {
    test('reproduces the committed golden byte for byte', () {
      final String listing = writeListing(_payroll(), _sampleOptions);
      expect(
        listing,
        File('test/goldens/90.05-payroll.listing').readAsStringSync(),
      );
    });

    test('comtranc prints the golden and exits 0', () {
      final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'comtran:comtranc',
        payrollDeckPath,
        '--date=10/18/61',
        '--time=2.45',
        '--title=COMPILATION OF SAMPLE PROBLEM',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(
        run.stdout,
        File('test/goldens/90.05-payroll.listing').readAsStringSync(),
      );
    });

    test('diagnostics form a block with statement numbers, not ids', () {
      final List<CardImage> deck = mirrorToDeck(
        [
          'STRAY CARD',
          '      *PROCEDURE',
          "            MOVE 'ABC TO X.",
          '      DONE. STOP RUN.',
          '',
        ].join('\n'),
      );
      final FrontEndResult result = runFrontEnd(deck);
      final String listing = writeListing(
        result,
        const ListingOptions(date: '08/03/26', time: '1.00'),
      );
      expect(listing, contains('THE FOLLOWING ERRORS WERE DETECTED'));
      expect(listing, contains('NUMBER   CODE   MESSAGE'));
      // The stray card is not a numbered statement: 9999,99.
      expect(listing, contains('9999,99'));
      // The unclosed literal is in statement 1: its row carries the
      // statement number and the severity, never the message id.
      expect(listing, contains('   1,00    2    ALPHABETIC LITERAL'));
      expect(listing, isNot(contains('168,00')));
      expect(listing, contains('SEVERITY LIMIT WAS NOT REACHED'));
      expect(listing, isNot(contains('NO ERRORS')));
    });

    test('a clean run prints the NO ERRORS line', () {
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck('      *PROCEDURE\n            STOP RUN.\n'),
      );
      final String listing = writeListing(
        result,
        const ListingOptions(date: '08/03/26', time: '1.00'),
      );
      expect(listing, contains('NO ERRORS WERE DETECTED DURING COMPILATION'));
      expect(listing, isNot(contains('SEVERITY LIMIT')));
    });

    test('long output repeats the page head with advancing numbers', () {
      final String listing = writeListing(_payroll(), _sampleOptions);
      final Iterable<String> heads = listing
          .split('\n')
          .where((String line) => line.contains('DATE 10/18/61'));
      expect(heads.length, greaterThanOrEqualTo(6));
      expect(listing, contains('PAGE   1'));
      expect(listing, contains('PAGE   6'));
    });
  });
}
