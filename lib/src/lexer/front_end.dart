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

  /// The highest diagnostic severity, or 0 with no diagnostics.
  int get maxSeverity => diagnostics.isEmpty
      ? 0
      : diagnostics
            .map((Diagnostic d) => d.severity)
            .reduce((int a, int b) => a > b ? a : b);
}

/// Runs the M1 front end over [deck].
FrontEndResult runFrontEnd(List<CardImage> deck) {
  final SourceProgram program = SourceProgram.fromDeck(deck);
  final groupScans = <GroupScan>[];
  final diagnostics = <Diagnostic>[...program.problems];
  final statementNumberByCard = <int, String>{};
  final numberedCards = <int>{};
  var statement = 0;

  void number(List<List<SourceCard>> units) {
    for (final List<SourceCard> unit in units) {
      statement++;
      numberedCards.add(unit.first.cardNumber);
      for (final SourceCard card in unit) {
        statementNumberByCard[card.cardNumber] = '$statement,00';
      }
    }
  }

  for (final DivisionGroup group in program.groups) {
    switch (group.division) {
      case Division.data:
        final DataScan scan = scanDataDescription(group.cards);
        groupScans.add(DataGroupScan._(group, scan));
        diagnostics.addAll(scan.diagnostics);
        number([for (final DataEntry e in scan.entries) e.cards]);
      case Division.environment:
        final EnvironmentScan scan = scanEnvironment(group.cards);
        groupScans.add(EnvironmentGroupScan._(group, scan));
        diagnostics.addAll(scan.diagnostics);
        // Number by card group, not by surviving specification, so a
        // deleted card (144,00) still consumes its statement number —
        // the numbering analogue of decision D9.8.
        number(_cardGroups(group.cards));
      case Division.procedure:
        final ProcedureScan scan = scanProcedure(group.cards);
        groupScans.add(ProcedureGroupScan._(group, scan));
        diagnostics.addAll(scan.diagnostics);
        number([for (final ProcedureSentence s in scan.sentences) s.cards]);
    }
  }

  return FrontEndResult._(
    program: program,
    groupScans: List.unmodifiable(groupScans),
    diagnostics: List.unmodifiable(diagnostics),
    statementNumberByCard: Map.unmodifiable(statementNumberByCard),
    numberedCards: Set.unmodifiable(numberedCards),
    statementCount: statement,
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
