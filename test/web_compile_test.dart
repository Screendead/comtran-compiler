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
      expect(result.diagnostics, isEmpty);
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
        'diagnostics',
        'maxSeverity',
        'marks',
      ]);
    });
  });

  group('the statement marks that join the stages (W3)', () {
    late WebCompilation result;
    const stages = ['cards', 'scan', 'parse', 'semantics', 'listing', 'code'];

    setUpAll(() => result = compileText(_sample()));

    String text(String stage) => result.toJson()[stage]! as String;

    /// The marked lines of [stage] whose mark falls under statement
    /// [statement], as `mark|line`.
    List<String> under(String stage, String statement) {
      final List<String> lines = text(stage).split('\n');
      return [
        for (final (int i, String? mark) in result.marks[stage]!.indexed)
          if (mark != null && mark.startsWith('$statement,'))
            '$mark|${lines[i]}',
      ];
    }

    test('every stage carries one mark per line', () {
      for (final stage in stages) {
        expect(
          result.marks[stage],
          hasLength(text(stage).split('\n').length - 1),
          reason: stage,
        );
      }
    });

    test('every mark names a statement the scan numbered', () {
      final Set<String> scanned = {
        for (final String? mark in result.marks['scan']!)
          if (mark != null) mark.split(',').first,
      };
      expect(scanned, hasLength(229));
      for (final stage in stages) {
        for (final String? mark in result.marks[stage]!) {
          if (mark == null) {
            continue;
          }
          expect(mark, matches(RegExp(r'^\d+:\d+,\d\d$')), reason: stage);
          expect(scanned, contains(mark.split(',').first), reason: stage);
        }
      }
    });

    test('statement 188 marks its own lines in every stage', () {
      expect(under('cards', '1:188'), [
        '1:188,00|      START.          OPEN ALL FILES,',
        '1:188,00|            MOVE ZEROS TO INTERNAL.TOTALS, GRAND.TOTALS,',
        '1:188,00|            GET MASTER, AT END DO END.OF.MASTERS.',
      ]);
      expect(under('scan', '1:188'), hasLength(1));
      final String indent = ' ' * 38;
      expect(under('listing', '1:188'), [
        '1:188,00|${' ' * 17}188,00   71466 START.          OPEN ALL FILES,',
        '1:188,00|${indent}MOVE ZEROS TO INTERNAL.TOTALS, GRAND.TOTALS,',
        '1:188,00|${indent}GET MASTER, AT END DO END.OF.MASTERS.',
      ]);
      expect(
        under('parse', '1:188').map((String s) => s.split('|').first).toSet(),
        {'1:188,00', '1:188,01', '1:188,02', '1:188,03', '1:188,04'},
      );
      final List<String> code = under('code', '1:188');
      expect(code, hasLength(19));
      // The OPEN ALL FILES call is the program's first word, at the
      // entry point GN)000 the listing prints for statement 188.
      expect(
        code.first,
        '1:188,01|00165\tGN)000 START\tTSX\tSYS)175,4\t'
        '007400400257\t10010',
      );
      // The AT END DO, clause 188,04, writes the out-of-line call.
      expect(code.last, startsWith('1:188,04|00207\t\tTRA\tEND.OF.MASTERS+1'));
    });

    test('a refusal carries no marks', () {
      expect(compileText('').marks, isEmpty);
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

    test('a card carries the mirror text it came from', () {
      final String card1 = _sample().split('\n').first;
      expect(punchCard(card1)!.line, card1);
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

  test("a diagnostic reaches the site in the listing's own words", () {
    final WebCompilation result = compileText(
      ['      *DATA', dataCard(name: 'A', level: '99'), ''].join('\n'),
    );
    final WebDiagnostic first = result.diagnostics.first;
    expect(first.number, matches(RegExp(r'^\d+,\d\d$')));
    expect(first.severity, inInclusiveRange(1, 5));
    // The listing prints the same text for the same diagnostic, so the
    // site never states a message of its own.
    expect(result.listing, contains(first.text.split('\n').first));
  });

  test('a program the compiler rejects still returns its stages', () {
    // A severity-5 stop is a result, not a refusal: the reader gets the
    // listing with the diagnostic block, and the stages that ran (D10.2).
    final WebCompilation result = compileText(
      ['      *DATA', dataCard(name: 'A', level: '99'), ''].join('\n'),
    );
    expect(result.error, isNull);
    expect(result.diagnostics, isNotEmpty);
    expect(result.listing, contains('ERRORS WERE DETECTED'));
  });

  test("a diagnostic row carries its statement's mark", () {
    final WebCompilation result = compileText(
      ['      *DATA', dataCard(name: 'A', level: '99'), ''].join('\n'),
    );
    final List<String> lines = result.listing.split('\n');
    final String number = result.diagnostics.first.number;
    final int row = lines.indexWhere(
      (String line) => line.startsWith(number.padLeft(7)),
    );
    expect(row, isNonNegative);
    expect(result.marks['listing']![row], '1:$number');
  });

  test('a second job marks its statements with its own job number', () {
    final String job = [
      '      *DATA',
      dataCard(name: 'A', level: '1'),
    ].join('\n');
    final WebCompilation result = compileText(
      [job, '      *FINISH', job, ''].join('\n'),
    );
    // The division headers and the *FINISH card belong to no statement.
    expect(result.marks['cards'], [null, '1:1,00', null, null, '2:1,00']);
  });
}
