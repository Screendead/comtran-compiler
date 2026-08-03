/// The M1 front end: deck structure, per-division scans, and statement
/// numbering.
///
/// Statement numbers are assigned one per Procedure sentence, Data
/// Description entry, or Environment specification group (J 02.02.01,
/// read per the compiled sample: one number per period-terminated
/// sentence, per entry, and per multi-card specification group — J 90.05
/// listing). The counter runs continuously across all three divisions
/// and does not reset; division headers get no number. The form is
/// `n,00`; non-zero clause digits appear only in diagnostics and are an
/// M2 concern (decision D7.13).
library;

import '../cards/card_image.dart';
import 'data_lexer.dart';
import 'diagnostic.dart';
import 'environment_lexer.dart';
import 'messages.dart';
import 'procedure_lexer.dart';
import 'source_card.dart';
import 'source_program.dart';

/// The scan of one division group.
sealed class GroupScan {
  GroupScan._(this.group);

  /// The group the scan covers.
  final DivisionGroup group;
}

/// A scanned `*DATA` group.
final class DataGroupScan extends GroupScan {
  DataGroupScan._(super.group, this.scan) : super._();

  /// The group's entries and diagnostics.
  final DataScan scan;
}

/// A scanned `*ENVIRONMENT` group.
final class EnvironmentGroupScan extends GroupScan {
  EnvironmentGroupScan._(super.group, this.scan) : super._();

  /// The group's specifications and diagnostics.
  final EnvironmentScan scan;
}

/// A scanned `*PROCEDURE` group.
final class ProcedureGroupScan extends GroupScan {
  ProcedureGroupScan._(super.group, this.scan) : super._();

  /// The group's sentences and diagnostics.
  final ProcedureScan scan;
}

/// The complete M1 front-end result for one job's deck.
final class FrontEndResult {
  FrontEndResult._({
    required this.program,
    required this.groupScans,
    required this.diagnostics,
    required this.statementNumberByCard,
    required this.numberedCards,
    required this.statementCount,
    required this.stopped,
  });

  /// The deck structure.
  final SourceProgram program;

  /// One scan per division group, in deck order.
  final List<GroupScan> groupScans;

  /// Every diagnostic: structural ones first, then each group's, in deck
  /// order.
  final List<Diagnostic> diagnostics;

  /// The statement number (`n,00`) of every card that belongs to a
  /// statement unit, keyed by card number. Continuation cards map to
  /// their unit's number; headers and control cards are absent.
  final Map<int, String> statementNumberByCard;

  /// The cards a statement number is printed against — the first card of
  /// each unit (J 90.05 listing: continuation lines print with the
  /// number field blank).
  final Set<int> numberedCards;

  /// How many statements were numbered.
  final int statementCount;

  /// Whether a severity-5 diagnostic stopped the front end at the
  /// point of detection (D9.1): later cards are unscanned and
  /// unnumbered, and the driver runs no parser over the result.
  final bool stopped;

  /// The highest diagnostic severity, or 0 with no diagnostics.
  int get maxSeverity => diagnostics.isEmpty
      ? 0
      : diagnostics
            .map((Diagnostic d) => d.severity)
            .reduce((int a, int b) => a > b ? a : b);
}

/// Runs the M1 front end over [deck].
///
/// Diagnostics go to [sink] when one is given — the compilation's one
/// [DiagnosticSink] (D9.1), shared with the parser by the driver. A
/// severity-5 diagnostic stops the front end at the point of detection:
/// the result carries everything scanned and numbered up to it, with
/// [FrontEndResult.stopped] set. [pedantic] adds non-historical written-
/// language-strictness diagnostics (decision D0.8, D11.4) without
/// changing any scanned value.
FrontEndResult runFrontEnd(
  List<CardImage> deck, {
  DiagnosticSink? sink,
  bool pedantic = false,
}) {
  final program = SourceProgram.fromDeck(deck);
  final groupScans = <GroupScan>[];
  final DiagnosticSink diagnostics = sink ?? DiagnosticSink();
  final statementNumberByCard = <int, String>{};
  final numberedCards = <int>{};
  var statement = 0;
  var stopped = false;

  void number(List<List<SourceCard>> units) {
    for (final unit in units) {
      statement++;
      numberedCards.add(unit.first.cardNumber);
      for (final card in unit) {
        statementNumberByCard[card.cardNumber] = '$statement,00';
      }
    }
  }

  try {
    diagnostics.addAll(program.problems);
    for (final DivisionGroup group in program.groups) {
      switch (group.division) {
        case Division.data:
          final DataScan scan = scanDataDescription(
            group.cards,
            sink: diagnostics,
            pedantic: pedantic,
          );
          groupScans.add(DataGroupScan._(group, scan));
          number([for (final DataEntry e in scan.entries) e.cards]);
        case Division.environment:
          final EnvironmentScan scan = scanEnvironment(
            group.cards,
            diagnostics,
          );
          groupScans.add(EnvironmentGroupScan._(group, scan));
          // Number by card group, not by surviving specification, so a
          // deleted card (144,00) still consumes its statement number —
          // the numbering analogue of decision D9.8.
          number(_cardGroups(group.cards));
        case Division.procedure:
          final ProcedureScan scan = scanProcedure(group.cards, diagnostics);
          groupScans.add(ProcedureGroupScan._(group, scan));
          number([for (final ProcedureSentence s in scan.sentences) s.cards]);
          if (pedantic) {
            // A shallow post-pass over the repair the scan already
            // recorded (decisions D1.3, D9.4a, D11.4): the omission
            // itself is unchanged in both modes.
            for (final ProcedureSentence s in scan.sentences) {
              if (s.label != null && !s.labelHadPeriod) {
                diagnostics.add(
                  Diagnostic(
                    msgProcedureNamePeriodOmitted,
                    s.cards.first,
                    column: s.labelColumn,
                  ),
                );
              }
            }
          }
      }
    }
  } on StopCompilation {
    // Severity 5 stops the front end at the point of detection (D9.1;
    // D10.2). The scans completed so far and every diagnostic recorded
    // — the severity-5 one last — stand.
    stopped = true;
  }

  return FrontEndResult._(
    program: program,
    groupScans: List.unmodifiable(groupScans),
    diagnostics: List.unmodifiable(diagnostics),
    statementNumberByCard: Map.unmodifiable(statementNumberByCard),
    numberedCards: Set.unmodifiable(numberedCards),
    statementCount: statement,
    stopped: stopped,
  );
}

/// Partitions fixed-form division cards into their continuation groups:
/// a unit is complete when column 72 is blank (J 02.03.02, §3.b).
List<List<SourceCard>> _cardGroups(List<SourceCard> cards) {
  final units = <List<SourceCard>>[];
  var i = 0;
  while (i < cards.length) {
    final unit = <SourceCard>[cards[i]];
    while (cards[i].isPunched(72) && i + 1 < cards.length) {
      i++;
      unit.add(cards[i]);
    }
    i++;
    units.add(unit);
  }
  return units;
}
