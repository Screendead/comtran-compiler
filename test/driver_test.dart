/// The job loop (D11.2; D11.3): per-job compilation state, message 132
/// at end of input, tail 903s, and the whole-deck exit severity.
library;

import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

List<CardImage> _deck(List<String> lines) =>
    mirrorToDeck('${lines.join('\n')}\n');

const ListingOptions _options = ListingOptions(date: '08/03/26', time: '1.00');

void main() {
  group('compileDeck (D11.2)', () {
    test('compiles each job independently and restarts the numbering', () {
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE JOBA',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
          r'$CMPLE JOBB',
          '      *PROCEDURE',
          "            DISPLAY 'HI'.",
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(deck.jobs, hasLength(2));
      expect(deck.maxSeverity, 0);
      final JobCompilation second = deck.jobs[1];
      expect(second.diagnostics, isEmpty);
      expect(second.frontEnd.statementCount, 2);
      // The numbering restarts at 1,00 per job (D11.2): card 3 is the
      // second job's first sentence.
      expect(second.frontEnd.statementNumberByCard[3], '1,00');
      // Each job's listing starts at page 1.
      for (final JobCompilation job in deck.jobs) {
        expect(
          writeListing(job.frontEnd, _options, diagnostics: job.diagnostics),
          contains('PAGE   1'),
        );
      }
    });

    test('a severity-5 job never starves the next job (J 90.04.02)', () {
      // A Data Description constant over 120 characters draws 148,00
      // at severity 5 (D7.9).
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE BAD',
          '      *DATA',
          dataCard(level: '2', description: "'${'A' * 33}", continued: true),
          dataCard(description: 'B' * 34, continued: true),
          dataCard(description: 'C' * 34, continued: true),
          dataCard(description: "${'D' * 25}'"),
          '      *FINISH',
          r'$CMPLE GOOD',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(deck.jobs, hasLength(2));
      expect(deck.jobs[0].sink.stopped, isTrue);
      expect(deck.jobs[0].sink.maxSeverity, 5);
      expect(deck.jobs[0].parse, isNull);
      expect(deck.jobs[1].sink.maxSeverity, 0);
      expect(deck.jobs[1].frontEnd.statementNumberByCard[3], '1,00');
      expect(deck.maxSeverity, 5);
    });

    test('a job closed by a compile card is accepted silently', () {
      // The recorded leniency (D11.1 rule e); --pedantic warns later.
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE JOBA',
          '      *PROCEDURE',
          '            STOP RUN.',
          r'$CMPLE JOBB',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(deck.jobs, hasLength(2));
      expect(deck.jobs[0].diagnostics, isEmpty);
      expect(deck.jobs[1].diagnostics, isEmpty);
      expect(deck.maxSeverity, 0);
    });

    test('a job closed by a compile card draws 929 under --pedantic '
        '(D11.1 rule e)', () {
      final lines = [
        r'$CMPLE JOBA',
        '      *PROCEDURE',
        '            STOP RUN.',
        r'$CMPLE JOBB',
        '      *PROCEDURE',
        '            STOP RUN.',
        '      *FINISH',
      ];
      final DeckCompilation plain = compileDeck(_deck(lines));
      expect(plain.jobs[0].diagnostics, isEmpty);
      final DeckCompilation pedantic = compileDeck(
        _deck(lines),
        pedantic: true,
      );
      expect(
        pedantic.jobs[0].diagnostics.single.message,
        msgJobClosedByCompileCard,
      );
      expect(pedantic.jobs[0].diagnostics.single.card, isNull);
      // The second job is unaffected either way (D11.4).
      expect(pedantic.jobs[1].diagnostics, isEmpty);
      expect(pedantic.jobs[0].sink.maxSeverity, 1);
      // Job splitting itself is unchanged (D11.4).
      expect(
        pedantic.jobs[0].frontEnd.statementCount,
        plain.jobs[0].frontEnd.statementCount,
      );
      expect(pedantic.jobs, hasLength(plain.jobs.length));
    });

    test('junk between jobs draws 902 in the next job', () {
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE JOBA',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
          'JUNK CARD',
          r'$CMPLE JOBB',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(deck.jobs[0].diagnostics, isEmpty);
      expect(deck.jobs[1].diagnostics.single.message, msgTextBeforeHeader);
    });

    test('a three-job deck compiles in deck order; the worst severity '
        'spans the deck', () {
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE JOBA',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
          r'$CMPLE JOBB',
          'STRAY CARD',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
          r'$CMPLE JOBC',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(deck.jobs, hasLength(3));
      expect(
        [
          for (final JobCompilation job in deck.jobs)
            job.parse?.compileCard?.deckName,
        ],
        ['JOBA', 'JOBB', 'JOBC'],
      );
      // The stray card draws 902 in job B only; the worst severity of
      // the whole deck is 3, below the exit gate (D11.2).
      expect(deck.jobs[0].sink.maxSeverity, 0);
      expect(deck.jobs[1].sink.maxSeverity, 3);
      expect(deck.jobs[2].sink.maxSeverity, 0);
      expect(deck.maxSeverity, 3);
    });

    test('the single-job tail draws 903 at 9999,99 (D11.1 rule d)', () {
      final DeckCompilation deck = compileDeck(
        _deck([
          r'$CMPLE JOBA',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
          'LATE CARD',
        ]),
      );
      final JobCompilation job = deck.jobs.single;
      expect(job.diagnostics.single.message, msgCardAfterFinish);
      expect(job.sink.maxSeverity, 3);
      final String listing = writeListing(
        job.frontEnd,
        _options,
        diagnostics: job.diagnostics,
      );
      expect(listing, contains('9999,99    3    CARD FOLLOWS THE *FINISH'));
      // The tail card is ignored: it is not echoed as source.
      expect(listing, isNot(contains('LATE CARD')));
    });
  });

  group('message 132 at end of input (D11.3)', () {
    test('a deck ending mid-job draws 132 at severity 5', () {
      final DeckCompilation deck = compileDeck(
        _deck([r'$CMPLE JOBA', '      *PROCEDURE', '            STOP RUN.']),
      );
      final JobCompilation job = deck.jobs.single;
      expect(job.sink.stopped, isTrue);
      expect(job.sink.maxSeverity, 5);
      final Diagnostic last = job.diagnostics.last;
      expect(last.message, msgEndOfFileWithoutFinish);
      expect(last.card, isNull);
      // The job is compiled as read: the parse ran before the stop.
      expect(job.parse, isNotNull);
      final String listing = writeListing(
        job.frontEnd,
        _options,
        diagnostics: job.diagnostics,
      );
      expect(
        listing,
        contains('9999,99    5    END OF FILE ON JOB TAPE WITHOUT *FINISH'),
      );
      expect(listing, isNot(contains('SEVERITY LIMIT')));
    });

    test('the raw 90.05 artifact draws exactly one diagnostic: 132', () {
      final DeckCompilation deck = compileDeck(loadPayrollDeck());
      final JobCompilation job = deck.jobs.single;
      expect(job.diagnostics.single.message, msgEndOfFileWithoutFinish);
      expect(deck.maxSeverity, 5);
    });

    test('the 90.05 job deck compiles with zero diagnostics', () {
      final DeckCompilation deck = compileDeck(loadJobDeck());
      final JobCompilation job = deck.jobs.single;
      expect(job.diagnostics, isEmpty);
      expect(deck.maxSeverity, 0);
      expect(job.frontEnd.statementCount, 229);
    });

    test('under --pedantic the 90.05 job deck draws exactly the D4.11 '
        'notes (D11.4)', () {
      final DeckCompilation deck = compileDeck(loadJobDeck(), pedantic: true);
      final JobCompilation job = deck.jobs.single;
      // Statements 205,00 (two blanked edited targets) and 220,00 (one):
      // the sample's own doubtful figurative moves, noted per D4.11.
      expect(job.diagnostics.map((Diagnostic d) => d.message.number), [
        '943,00',
        '943,00',
        '943,00',
      ]);
      expect(job.diagnostics.map((Diagnostic d) => d.card?.cardNumber), [
        245,
        245,
        276,
      ]);
      expect(deck.maxSeverity, 1);
      expect(job.frontEnd.statementCount, 229);
    });

    test('comtranc exits 1 on the unterminated artifact', () {
      final ProcessResult run = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'comtran:comtranc',
        payrollDeckPath,
        '--date=10/18/61',
        '--time=2.45',
      ]);
      expect(run.exitCode, 1, reason: '${run.stderr}');
      expect(
        run.stdout,
        contains('END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.'),
      );
    });

    test('--explain prints diagnostics to stderr without changing stdout', () {
      final ProcessResult plain = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'comtran:comtranc',
        payrollDeckPath,
        '--date=10/18/61',
        '--time=2.45',
      ]);
      final ProcessResult explained =
          Process.runSync(Platform.resolvedExecutable, [
            'run',
            'comtran:comtranc',
            payrollDeckPath,
            '--date=10/18/61',
            '--time=2.45',
            '--explain',
          ]);
      expect(explained.exitCode, plain.exitCode);
      expect(explained.stdout, plain.stdout);
      expect(plain.stderr, isEmpty);
      expect(
        explained.stderr,
        contains('END OF FILE ON JOB TAPE WITHOUT *FINISH CARD.'),
      );
    });
  });
}
