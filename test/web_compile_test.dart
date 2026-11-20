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
        'diagnostics',
        'maxSeverity',
      ]);
    });
  });

  test('punchText accepts what a text area produces', () {
    for (final (String typed, String punched) in [
      // CRLF, no final newline, a trailing blank, and lower case: four
      // things mirrorToDeck refuses and no typist can see.
      (
        '      *data\r\n            stop run.   ',
        '      *DATA\n            STOP RUN.\n',
      ),
      ('      *DATA\n\n   \n', '      *DATA\n'),
      ('   \n\n', ''),
      ('      *DATA\n\n      *FINISH\n', '      *DATA\n\n      *FINISH\n'),
    ]) {
      expect(punchText(typed), punched, reason: typed);
    }
  });

  test('a deck the site cannot punch is refused in words a typist can act '
      'on', () {
    for (final (String text, String message) in [
      ('   \n', 'no program to compile'),
      ('      *DATA\n\tSTOP RUN.\n', 'Card 2 contains a tab'),
      ('      *DATA\n\tSTOP RUN.\n', 'spaces'),
      ('      *DATA\n      A%B\n', 'Card 2, column 8'),
      ('      *DATA\n      A%B\n', 'Fix that card and compile again.'),
      ('${'A' * 81}\n', 'longer than 80 columns'),
    ]) {
      final WebCompilation result = compileText(text);
      expect(result.error, contains(message), reason: text);
      expect(result.listing, isEmpty, reason: text);
    }
  });

  group('the deck a reader downloads', () {
    test('is byte for byte the canon file the repository holds', () {
      // The site's download is the deck itself, not a rendering of it, so
      // the bytes must match the committed canon pair of the same program.
      expect(
        canonDeck(_sample()),
        File('test/fixtures/90.05-payroll-job.ctd').readAsBytesSync(),
      );
    });

    test('round-trips back through the compiler', () {
      final List<CardImage> deck = decodeCanon(canonDeck(_sample())!);
      expect(deckToMirror(deck), _sample());
    });

    test('a deck the punch cannot cut has no file', () {
      expect(canonDeck('   \n'), isNull);
      expect(canonDeck('      A%B\n'), isNull);
      expect(canonDeck('\tSTOP RUN.\n'), isNull);
    });
  });

  group('the card view', () {
    test('punches a card 1 the reader can check against the manual', () {
      // Card 1 of the sample: *COMPILE in columns 7 to 14. An asterisk is
      // 11-4-8, so column 7 carries exactly those three holes and no
      // others.
      final WebCard card = punchCard(_sample().split('\n').first)!;
      expect(card.rows, hasLength(12));
      expect(card.glyphs, hasLength(80));
      expect(card.glyphs.substring(6, 14), '*COMPILE');
      expect(card.glyphs.substring(0, 6), '      ');

      const rows = [
        '12',
        '11',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ];
      final punched = <String>[
        for (var i = 0; i < 12; i++)
          if (card.rows[i][6] == '#') rows[i],
      ];
      expect(punched, ['11', '4', '8']);
    });

    test('a blank line is a blank card', () {
      final WebCard card = punchCard('')!;
      expect(card.glyphs.trim(), isEmpty);
      expect(card.rows.every((String row) => !row.contains('#')), isTrue);
    });

    test('a character the punch cannot cut has no card', () {
      expect(punchCard('      A%B'), isNull);
      expect(punchCard('\tSTOP RUN.'), isNull);
    });

    test('lower case is punched as upper case', () {
      expect(punchCard('      stop')!.glyphs.substring(6, 10), 'STOP');
    });
  });

  group('punching a card by hand', () {
    // Row 0 is punch row 12, row 1 is row 11, row 2 is row 0, and rows 3
    // to 11 are the digit rows.
    const row12 = 0;
    const row11 = 1;
    const row4 = 6;
    const row8 = 10;

    test('cutting the three holes of an asterisk types the asterisk', () {
      WebCard card = togglePunch('', row11, 7)!;
      card = togglePunch(card.line, row4, 7)!;
      card = togglePunch(card.line, row8, 7)!;
      expect(card.line, '      *');
      expect(card.glyphs[6], '*');
    });

    test('filling one hole of an asterisk leaves the letter M', () {
      // 11-4-8 is the asterisk and 11-4 is M, so one filled hole is one
      // different character, not a broken card.
      final WebCard card = togglePunch('      *', row8, 7)!;
      expect(card.line, '      M');
      expect(togglePunch(card.line, row8, 7)!.line, '      *');
    });

    test('a hole no character matches puts the card in punch form', () {
      // Row 12 alone is the plus sign. Rows 12 and 11 together are no BCD
      // character at all, so the card leaves the glyph form for the `!`
      // punch form the deck format defines for exactly this case.
      final WebCard plus = togglePunch('', row12, 7)!;
      expect(plus.line, '      +');
      final WebCard both = togglePunch(plus.line, row11, 7)!;
      expect(both.line, '! 7:12-11');
      expect(both.glyphs.trim(), isEmpty);
      expect(togglePunch(both.line, row11, 7)!.line, '      +');
    });

    test('a position off the card is refused', () {
      expect(togglePunch('', row12, 0), isNull);
      expect(togglePunch('', row12, 81), isNull);
      expect(togglePunch('', -1, 7), isNull);
      expect(togglePunch('', 12, 7), isNull);
      expect(togglePunch('      A%B', row12, 7), isNull);
    });
  });

  test('a program the compiler rejects still returns its stages, and its '
      "diagnostics in the listing's own words", () {
    // A severity-5 stop is a result, not a refusal: the reader gets the
    // listing with the diagnostic block, and the stages that ran (D10.2).
    final WebCompilation result = compileText(
      ['      *DATA', dataCard(name: 'A', level: '99'), ''].join('\n'),
    );
    expect(result.error, isNull);
    expect(result.listing, contains('ERRORS WERE DETECTED'));
    final WebDiagnostic first = result.diagnostics.first;
    expect(first.number, matches(RegExp(r'^\d+,\d\d$')));
    expect(first.severity, inInclusiveRange(1, 5));
    // The listing prints the same text for the same diagnostic, so the
    // site never states a message of its own.
    expect(result.listing, contains(first.text.split('\n').first));
  });
}
