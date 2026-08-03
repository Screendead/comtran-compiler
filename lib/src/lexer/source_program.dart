/// The structure of a source deck: control cards, division headers, and the
/// cards of each division group.
///
/// Implements the deck-level rules of definition §1.9 and §2.2: division
/// headers `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` with the asterisk in the
/// name margin (F p. 27; F p. 37, rule 1; F p. 65); every entry following a
/// header belongs to that division until the next header; the `$CMPLE`
/// control card (J 02.01.01) and its 1961 field-test counterpart `*COMPILE`
/// (attested by the compiled sample deck, J 90.05 listing); the `*FINISH`
/// card, punched from column 7, which delimits the source statements
/// (J 02.01.02).
library;

import '../cards/card_image.dart';
import 'diagnostic.dart';
import 'messages.dart';
import 'source_card.dart';

/// The three divisions of a program (F p. 13; definition §2.1).
enum Division {
  /// `*DATA` — the data description.
  data,

  /// `*ENVIRONMENT` — the environment description.
  environment,

  /// `*PROCEDURE` — the procedure description.
  procedure,
}

/// One consecutive group of cards under a division header. A division may
/// appear as several groups; each group starts with its own header card
/// (F p. 65: `*DATA` "must precede the first entry of each consecutive
/// group of data description cards").
final class DivisionGroup {
  DivisionGroup._(this.division, this.header, this.cards);

  /// Which division the group belongs to.
  final Division division;

  /// The header card (`*DATA`, `*ENVIRONMENT`, or `*PROCEDURE`).
  final SourceCard header;

  /// The content cards of the group, in deck order. Wholly blank cards are
  /// not included (their treatment is undefined in both manuals; definition
  /// §1.9.4 — skipping them is a recorded M1 design decision).
  final List<SourceCard> cards;
}

/// A source deck split into control cards and division groups.
final class SourceProgram {
  SourceProgram._({
    required this.cards,
    required this.compileCard,
    required this.finishCard,
    required this.groups,
    required this.problems,
  });

  /// Splits [deck] into its structure.
  factory SourceProgram.fromDeck(List<CardImage> deck) {
    final cards = <SourceCard>[
      for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1),
    ];
    SourceCard? compileCard;
    SourceCard? finishCard;
    final groups = <DivisionGroup>[];
    final problems = <Diagnostic>[];
    List<SourceCard>? currentGroup;

    for (final SourceCard card in cards) {
      if (finishCard != null) {
        problems.add(Diagnostic(msgCardAfterFinish, card));
        continue;
      }
      if (card.isBlank) {
        continue;
      }
      final Division? headerOf = _headerDivision(card);
      if (headerOf != null) {
        currentGroup = <SourceCard>[];
        groups.add(DivisionGroup._(headerOf, card, currentGroup));
        continue;
      }
      if (_isFinishCard(card)) {
        finishCard = card;
        continue;
      }
      if (currentGroup == null) {
        if (_isCompileCard(card)) {
          if (compileCard == null) {
            compileCard = card;
          } else {
            problems.add(Diagnostic(msgDuplicateCompileCard, card));
          }
          continue;
        }
        // Omission of a division header is a catastrophic compile error
        // (J 05.06.01); the message is ours (decision D2.3).
        problems.add(Diagnostic(msgTextBeforeHeader, card));
        continue;
      }
      currentGroup.add(card);
    }

    return SourceProgram._(
      cards: cards,
      compileCard: compileCard,
      finishCard: finishCard,
      groups: List.unmodifiable(groups),
      problems: List.unmodifiable(problems),
    );
  }

  /// Every card of the deck, decoded, in deck order.
  final List<SourceCard> cards;

  /// The `$CMPLE` (J 02.01.01) or `*COMPILE` (J 90.05 deck) control card,
  /// when present.
  final SourceCard? compileCard;

  /// The `*FINISH` card, when present (J 02.01.02).
  final SourceCard? finishCard;

  /// The division groups in deck order.
  final List<DivisionGroup> groups;

  /// Structural diagnostics found during the split.
  final List<Diagnostic> problems;

  /// The content cards of every group of [division], in deck order.
  List<SourceCard> cardsOf(Division division) => [
    for (final DivisionGroup group in groups)
      if (group.division == division) ...group.cards,
  ];

  /// A division header has its asterisk in the name margin (columns 7–12)
  /// and nothing else in the body. F puts the asterisk in column 7
  /// (F p. 65); the compiled sample deck punches `*PROCEDURE` from column 8
  /// (J 90.05 listing, PDF p. 195), so the whole name margin is accepted —
  /// a recorded M1 design decision.
  static Division? _headerDivision(SourceCard card) {
    final String body = card.body.trimRight();
    final String trimmed = body.trimLeft();
    final int asteriskColumn = 7 + (body.length - trimmed.length);
    if (asteriskColumn > 12) {
      return null;
    }
    return switch (trimmed) {
      '*DATA' => Division.data,
      '*ENVIRONMENT' => Division.environment,
      '*PROCEDURE' => Division.procedure,
      _ => null,
    };
  }

  /// `$CMPLE` occupies columns 1–6 (J 02.01.01); `*COMPILE` is punched from
  /// column 7 on the compiled sample deck's control card.
  static bool _isCompileCard(SourceCard card) =>
      card.serial == r'$CMPLE' || card.body.startsWith('*COMPILE');

  /// `*FINISH` is punched from column 7 (J 02.01.02).
  static bool _isFinishCard(SourceCard card) =>
      card.body.startsWith('*FINISH') && card.body.substring(7).trim().isEmpty;
}
