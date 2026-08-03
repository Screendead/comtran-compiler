/// The job splitter — the driver's card-level stand-in for the CT
/// monitor (decision D11.1).
///
/// A deck holds one or more jobs, each `$CMPLE … *FINISH` (J 02.01.01,
/// J 02.01.02; D9.14). The splitter cuts the deck into per-job card
/// slices above the compiler, which compiles one job and knows nothing
/// about the stream. It consumes each *FINISH card — the 1962 listing
/// echoes the compile card and no *FINISH (J 90.05 listing) — and it
/// silently skips the two attested monitor cards between jobs: the
/// end-of-file card (J 05.03.01) and the optional $ID accounting card
/// (J 05.03.02). Every other boundary rule is a recorded design
/// decision; the manuals separate jobs with a tape end-of-file mark,
/// never with a card scan (D11.1).
library;

import '../cards/card_image.dart';
import '../lexer/source_card.dart';
import '../lexer/source_program.dart';

/// One job's slice of the deck (D11.1).
final class JobSlice {
  JobSlice._(this.cards, {required this.terminated, required this.ignoredTail});

  /// The job's cards in deck order: its compile card, its division
  /// groups, and any leading junk (the front end diagnoses that with
  /// message 902). The *FINISH card is consumed and absent.
  final List<CardImage> cards;

  /// Whether a *FINISH card closed the job. The last slice of a deck
  /// reports `false` when the deck ended mid-job — the driver records
  /// message 132 (D11.3). An earlier slice reports `false` when a
  /// compile card closed it (D11.1 rule e).
  final bool terminated;

  /// Cards after the last *FINISH with no job following — the
  /// single-job tail. The driver records message 903 for each (D11.1
  /// rule d). Empty on every slice but the last.
  final List<CardImage> ignoredTail;
}

/// Splits [deck] into its job slices (D11.1).
List<JobSlice> splitJobs(List<CardImage> deck) {
  final jobs = <JobSlice>[];
  List<CardImage>? current;
  var seenHeader = false;
  // Non-monitor cards read after a *FINISH: the next job's leading
  // cards, or the ignored tail when no job follows (D11.1 rule d).
  final pending = <CardImage>[];

  void close({required bool terminated}) {
    jobs.add(
      JobSlice._(
        List.unmodifiable(current!),
        terminated: terminated,
        ignoredTail: const [],
      ),
    );
    current = null;
    seenHeader = false;
  }

  for (var i = 0; i < deck.length; i++) {
    final CardImage image = deck[i];
    final card = SourceCard(image, i + 1);
    if (current == null) {
      // The monitor zone: before the first job, and after a *FINISH.
      if (image.isBlank || isEndOfFileCard(image) || isAccountingCard(card)) {
        // The attested separators are skipped silently (D11.1 rule c);
        // blank cards follow the M1 blank-card rule.
        continue;
      }
      if (isFinishCard(card)) {
        // A *FINISH closes a job even here: pending junk becomes that
        // job's only content (and draws 902 from the front end).
        current = List.of(pending);
        pending.clear();
        close(terminated: true);
        continue;
      }
      final bool opens =
          jobs.isEmpty ||
          !jobs.last.terminated ||
          SourceProgram.isCompileCard(card) ||
          SourceProgram.headerDivision(card) != null;
      if (opens) {
        // The next job starts here; junk read since the last *FINISH
        // joins its leading cards (D11.1 rule d).
        current = [...pending, image];
        pending.clear();
        seenHeader = SourceProgram.headerDivision(card) != null;
      } else {
        // After a terminated job, junk waits for a job to join; with
        // none following it becomes the ignored tail.
        pending.add(image);
      }
      continue;
    }
    // A job is open.
    if (isFinishCard(card)) {
      close(terminated: true);
      continue;
    }
    if (SourceProgram.isCompileCard(card) && seenHeader) {
      // A compile card after a division header starts the next job
      // (D11.1 rule a; the D10.4 amendment). Before any header it
      // stays in the slice, where the front end ignores it with
      // message 904.
      close(terminated: false);
      current = [image];
      continue;
    }
    if (SourceProgram.headerDivision(card) != null) {
      seenHeader = true;
    }
    current!.add(image);
  }

  if (current != null) {
    // The deck ended mid-job; the driver records message 132 (D11.3).
    close(terminated: false);
  }
  if (pending.isNotEmpty) {
    // The single-job tail (D11.1 rule d): pending only accumulates
    // after a terminated job, so a last slice exists and is terminated.
    final JobSlice last = jobs.removeLast();
    jobs.add(
      JobSlice._(
        last.cards,
        terminated: last.terminated,
        ignoredTail: List.unmodifiable(pending),
      ),
    );
  }
  return jobs;
}

/// Whether [card] is a `*FINISH` card: punched from column 7 with
/// nothing else in the body (J 02.01.02); an unreadable punched column
/// must not pass as the required blank.
bool isFinishCard(SourceCard card) =>
    card.body.startsWith('*FINISH') &&
    card.body.substring(7).trim().isEmpty &&
    card.unreadableColumns(7, 72).isEmpty;

/// Whether [image] is the attested end-of-file card: columns 1 and 2
/// punched in rows 8 and 7, columns 3 and 4 punched in rows 12, 7, 4,
/// and 1, and nothing else (J 05.03.01, scan-checked against
/// images/page-099.png, 2026-08-03). J calls the card "an integral
/// part of every job deck"; the splitter skips it silently (D11.1
/// rule c).
bool isEndOfFileCard(CardImage image) {
  // Row r of 1–9 is bit 9-r; row 12 is bit 11 (CardImage).
  const int rows87 = (1 << 2) | (1 << 1);
  const int rows12741 = (1 << 11) | (1 << 2) | (1 << 5) | (1 << 8);
  if (image.punchesAt(1) != rows87 ||
      image.punchesAt(2) != rows87 ||
      image.punchesAt(3) != rows12741 ||
      image.punchesAt(4) != rows12741) {
    return false;
  }
  for (var column = 5; column <= CardImage.columnCount; column++) {
    if (image.punchesAt(column) != 0) {
      return false;
    }
  }
  return true;
}

/// Whether [card] is the optional `$ID` accounting card — operation in
/// column 1, per the monitor card format (J 04.02.02; J 05.03.02). The
/// splitter skips it silently in the monitor zone (D11.1 rule c).
bool isAccountingCard(SourceCard card) =>
    card.serial.trimRight() == r'$ID' && card.unreadableColumns(1, 6).isEmpty;
