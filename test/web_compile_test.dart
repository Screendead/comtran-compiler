/// The website's compiler entry point (roadmap W1): the six stage dumps the
/// browser prints, and the refusals it prints instead.
///
/// The stage assertions are the same byte comparisons `emit_test.dart`,
/// `listing_test.dart`, and `codegen_test.dart` make of the command-line
/// compiler. They hold the browser to the identical output, so a listing a
/// reader sees on the site is the listing the goldens carry.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

/// The sample program the site preloads: the mirror of the job deck.
String _sample() =>
    File('test/fixtures/90.05-payroll-job.ct').readAsStringSync();

String _golden(String stage) =>
    File('test/goldens/90.05-payroll.$stage').readAsStringSync();

void main() {
  group('the sample program in the browser', () {
    late WebCompilation result;

    setUpAll(() => result = compileText(_sample()));

    test('every stage reproduces its golden byte for byte', () {
      expect(result.error, isNull);
      expect(result.cards, _sample());
      expect(result.scan, _golden('scan'));
      expect(result.parse, _golden('parse'));
      expect(result.semantics, _golden('semantics'));
      expect(result.listing, _golden('listing'));
      expect(result.code, _golden('code'));
    });

    test('the deck compiles clean', () {
      expect(result.cardCount, 294);
      expect(result.diagnosticCount, 0);
      expect(result.maxSeverity, 0);
    });

    test('the browser payload names every stage after its emit flag', () {
      expect(result.toJson().keys, [
        'error',
        'cards',
        'scan',
        'parse',
        'semantics',
        'code',
        'listing',
        'cardCount',
        'diagnosticCount',
        'maxSeverity',
      ]);
    });
  });

  group('punchText', () {
    test('accepts what a text area produces', () {
      // CRLF, no final newline, a trailing blank, and lower case: four
      // things mirrorToDeck refuses and no typist can see.
      expect(
        punchText('      *data\r\n            stop run.   '),
        '      *DATA\n            STOP RUN.\n',
      );
    });

    test('drops the blank cards a trailing return leaves', () {
      expect(punchText('      *DATA\n\n   \n'), '      *DATA\n');
      expect(punchText('   \n\n'), isEmpty);
    });

    test('keeps a blank card between two punched ones', () {
      expect(
        punchText('      *DATA\n\n      *FINISH\n'),
        '      *DATA\n\n      *FINISH\n',
      );
    });
  });

  group('a deck the site cannot punch', () {
    test('empty text asks for a program', () {
      final WebCompilation result = compileText('   \n');
      expect(result.error, contains('no program to compile'));
      expect(result.listing, isEmpty);
    });

    test('a tab names the card and says what to type instead', () {
      final WebCompilation result = compileText('      *DATA\n\tSTOP RUN.\n');
      expect(result.error, contains('Card 2 contains a tab'));
      expect(result.error, contains('spaces'));
    });

    test('a character outside the source set names its column', () {
      final WebCompilation result = compileText('      *DATA\n      A%B\n');
      expect(result.error, startsWith('Card 2, column 8'));
      expect(result.error, endsWith('Fix that card and compile again.'));
    });

    test('a card wider than eighty columns is refused', () {
      final WebCompilation result = compileText('${'A' * 81}\n');
      expect(result.error, contains('longer than 80 columns'));
    });
  });

  test('a program the compiler rejects still returns its stages', () {
    // A severity-5 stop is a result, not a refusal: the reader gets the
    // listing with the diagnostic block, and the stages that ran (D10.2).
    final WebCompilation result = compileText(
      ['      *DATA', dataCard(name: 'A', level: '99'), ''].join('\n'),
    );
    expect(result.error, isNull);
    expect(result.diagnosticCount, greaterThan(0));
    expect(result.listing, contains('ERRORS WERE DETECTED'));
  });
}
