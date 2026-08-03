/// The job splitter (D11.1): card-level job boundaries, the monitor
/// zone, and the consumed *FINISH card.
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

List<CardImage> _deck(List<String> lines) =>
    mirrorToDeck('${lines.join('\n')}\n');

/// The attested end-of-file card (J 05.03.01): columns 1 and 2 punched
/// in rows 8 and 7, columns 3 and 4 in rows 12, 7, 4, and 1.
CardImage _endOfFileCard() {
  final List<int> columns = blankColumns();
  columns[0] = (1 << 2) | (1 << 1);
  columns[1] = (1 << 2) | (1 << 1);
  columns[2] = (1 << 11) | (1 << 8) | (1 << 5) | (1 << 2);
  columns[3] = (1 << 11) | (1 << 8) | (1 << 5) | (1 << 2);
  return CardImage.fromColumns(columns);
}

CardImage _accountingCard() {
  final List<int> columns = blankColumns();
  punchGlyphs(columns, 1, r'$ID');
  punchGlyphs(columns, 16, 'JOB1');
  return CardImage.fromColumns(columns);
}

const List<String> _jobA = [
  r'$CMPLE JOBA',
  '      *PROCEDURE',
  '            STOP RUN.',
];

void main() {
  group('splitJobs (D11.1)', () {
    test('one terminated job: the *FINISH card is consumed', () {
      final List<JobSlice> jobs = splitJobs(_deck([..._jobA, '      *FINISH']));
      final JobSlice job = jobs.single;
      expect(job.terminated, isTrue);
      expect(job.cards, hasLength(3));
      expect(job.ignoredTail, isEmpty);
      // No slice card is the *FINISH card.
      for (final CardImage image in job.cards) {
        expect(isFinishCard(SourceCard(image, 1)), isFalse);
      }
    });

    test('an unterminated deck reports one open job', () {
      final List<JobSlice> jobs = splitJobs(_deck(_jobA));
      expect(jobs.single.terminated, isFalse);
      expect(jobs.single.cards, hasLength(3));
    });

    test('splits two jobs at *FINISH then the next compile card', () {
      final List<JobSlice> jobs = splitJobs(
        _deck([
          ..._jobA,
          '      *FINISH',
          r'$CMPLE JOBB',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(jobs, hasLength(2));
      expect(jobs[0].terminated, isTrue);
      expect(jobs[0].cards, hasLength(3));
      expect(jobs[1].terminated, isTrue);
      expect(jobs[1].cards, hasLength(3));
    });

    test('a compile card after a division header starts the next job', () {
      // The D10.4 amendment: no *FINISH closed the first job.
      final List<JobSlice> jobs = splitJobs(
        _deck([..._jobA, r'$CMPLE JOBB', '      *PROCEDURE', '      *FINISH']),
      );
      expect(jobs, hasLength(2));
      expect(jobs[0].terminated, isFalse);
      expect(jobs[0].cards, hasLength(3));
      expect(jobs[1].terminated, isTrue);
    });

    test('a duplicate compile card before any header stays in its job', () {
      // The front end ignores it with message 904 (D10.4).
      final List<JobSlice> jobs = splitJobs(
        _deck([
          r'$CMPLE JOBA',
          r'$CMPLE AGAIN',
          '      *PROCEDURE',
          '            STOP RUN.',
          '      *FINISH',
        ]),
      );
      expect(jobs.single.cards, hasLength(4));
    });

    test('junk between jobs joins the next job as leading cards', () {
      final List<JobSlice> jobs = splitJobs(
        _deck([
          ..._jobA,
          '      *FINISH',
          'JUNK CARD',
          r'$CMPLE JOBB',
          '      *PROCEDURE',
          '      *FINISH',
        ]),
      );
      expect(jobs, hasLength(2));
      expect(jobs[0].ignoredTail, isEmpty);
      expect(jobs[1].cards, hasLength(3));
      expect(SourceCard(jobs[1].cards.first, 1).textRange(1, 9), 'JUNK CARD');
    });

    test('junk after the last *FINISH is the ignored tail', () {
      final List<JobSlice> jobs = splitJobs(
        _deck([..._jobA, '      *FINISH', 'LATE CARD', 'LATER CARD']),
      );
      final JobSlice job = jobs.single;
      expect(job.terminated, isTrue);
      expect(job.cards, hasLength(3));
      expect(job.ignoredTail, hasLength(2));
    });

    test(r'end-of-file and $ID cards are skipped in the monitor zone', () {
      final List<JobSlice> jobs = splitJobs([
        _accountingCard(),
        ..._deck(_jobA),
        ..._deck(['      *FINISH']),
        _endOfFileCard(),
        _accountingCard(),
        ..._deck([r'$CMPLE JOBB', '      *PROCEDURE', '      *FINISH']),
        _endOfFileCard(),
      ]);
      expect(jobs, hasLength(2));
      expect(jobs[0].cards, hasLength(3));
      // Job B's *FINISH is consumed: two cards remain.
      expect(jobs[1].cards, hasLength(2));
      expect(jobs[1].terminated, isTrue);
      expect(jobs[1].ignoredTail, isEmpty);
    });

    test('an end-of-file card inside an open job is not skipped', () {
      final List<JobSlice> jobs = splitJobs([
        ..._deck(_jobA),
        _endOfFileCard(),
        ..._deck(['      *FINISH']),
      ]);
      expect(jobs.single.cards, hasLength(4));
    });

    test('a blank card in the monitor zone is skipped', () {
      final List<JobSlice> jobs = splitJobs([
        CardImage.blank(),
        ..._deck([..._jobA, '      *FINISH']),
      ]);
      expect(jobs.single.cards, hasLength(3));
    });

    test('a corrupt *FINISH is ordinary text, not a boundary', () {
      // An unreadable punched column in the body disqualifies the card
      // (J 02.01.02 requires the blank body).
      final List<int> columns = blankColumns();
      punchGlyphs(columns, 7, '*FINISH');
      columns[39] = punchesFromBcd(0x3A)!; // record mark, column 40
      final List<JobSlice> jobs = splitJobs([
        ..._deck(_jobA),
        CardImage.fromColumns(columns),
      ]);
      expect(jobs.single.terminated, isFalse);
      expect(jobs.single.cards, hasLength(4));
    });

    test('a *FINISH with no open job closes an empty job', () {
      final List<JobSlice> jobs = splitJobs(_deck(['      *FINISH']));
      expect(jobs.single.terminated, isTrue);
      expect(jobs.single.cards, isEmpty);
    });

    test('a division header after *FINISH opens a compile-card-less job', () {
      final List<JobSlice> jobs = splitJobs(
        _deck([
          ..._jobA,
          '      *FINISH',
          '      *PROCEDURE',
          '            STOP RUN.',
        ]),
      );
      expect(jobs, hasLength(2));
      expect(jobs[1].terminated, isFalse);
      expect(jobs[1].cards, hasLength(2));
    });

    test('an empty deck and a monitor-only deck hold no jobs', () {
      expect(splitJobs(const []), isEmpty);
      expect(splitJobs([_endOfFileCard(), _accountingCard()]), isEmpty);
    });

    test('the 90.05 job deck is one terminated 293-card job', () {
      final List<JobSlice> jobs = splitJobs(loadJobDeck());
      expect(jobs.single.terminated, isTrue);
      expect(jobs.single.cards, hasLength(293));
      expect(jobs.single.ignoredTail, isEmpty);
    });

    test('the raw 90.05 artifact is one open job of 293 cards', () {
      // The artifact itself stays 293 cards (D9.14 oracle; D11.3).
      final List<CardImage> deck = loadPayrollDeck();
      expect(deck, hasLength(293));
      final List<JobSlice> jobs = splitJobs(deck);
      expect(jobs.single.terminated, isFalse);
      expect(jobs.single.cards, hasLength(293));
    });
  });

  group('the monitor-card predicates (D11.1 rule c)', () {
    test('the end-of-file card matches its attested punches exactly', () {
      expect(isEndOfFileCard(_endOfFileCard()), isTrue);
      final List<int> extra = _endOfFileCard().toColumnList();
      extra[10] = 1 << 4;
      expect(isEndOfFileCard(CardImage.fromColumns(extra)), isFalse);
      final List<int> wrong = _endOfFileCard().toColumnList();
      wrong[0] = 1 << 2;
      expect(isEndOfFileCard(CardImage.fromColumns(wrong)), isFalse);
      expect(isEndOfFileCard(CardImage.blank()), isFalse);
    });

    test(r'the $ID card needs a readable serial field', () {
      expect(isAccountingCard(SourceCard(_accountingCard(), 1)), isTrue);
      final List<int> corrupt = _accountingCard().toColumnList();
      corrupt[3] = punchesFromBcd(0x3A)!; // record mark, column 4
      expect(
        isAccountingCard(SourceCard(CardImage.fromColumns(corrupt), 1)),
        isFalse,
      );
      final cmple = SourceCard(_deck([r'$CMPLE JOBA']).single, 1);
      expect(isAccountingCard(cmple), isFalse);
    });
  });
}
