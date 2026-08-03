/// The structure of one job's source deck: the control card, division
/// headers, and the cards of each division group.
///
/// Implements the deck-level rules of definition §1.9 and §2.2: division
/// headers `*DATA`, `*ENVIRONMENT`, `*PROCEDURE` with the asterisk in the
/// name margin (F p. 27; F p. 37, rule 1; F p. 65); every entry following a
/// header belongs to that division until the next header; and the `$CMPLE`
/// control card (J 02.01.01) with its 1961 field-test counterpart
/// `*COMPILE` (attested by the compiled sample deck, J 90.05 listing). The
/// `*FINISH` card never reaches this class: the job splitter above the
/// compiler consumes it (D9.14; D11.1).
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
    required this.groups,
    required this.problems,
  });

  /// Splits [deck] into its structure.
  factory SourceProgram.fromDeck(List<CardImage> deck) {
    final cards = <SourceCard>[
      for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1),
    ];
    SourceCard? compileCard;
    final groups = <DivisionGroup>[];
    final problems = <Diagnostic>[];
    List<SourceCard>? currentGroup;

    for (final card in cards) {
      if (card.isBlank) {
        continue;
      }
      final Division? headerOf = headerDivision(card);
      if (headerOf != null) {
        currentGroup = <SourceCard>[];
        groups.add(DivisionGroup._(headerOf, card, currentGroup));
        continue;
      }
      if (isCompileCard(card)) {
        // Recognized at any deck position, so a mid-deck compile card
        // is never lexed as source text (D10.4). The job splitter cuts
        // a new job at a compile card after a division header (D11.1),
        // so the duplicate seen here sits before any header of its own
        // job and is ignored with message 904 (M1-2).
        if (compileCard == null && currentGroup == null) {
          compileCard = card;
        } else {
          problems.add(Diagnostic(msgDuplicateCompileCard, card));
        }
        continue;
      }
      if (currentGroup == null) {
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
      groups: List.unmodifiable(groups),
      problems: List.unmodifiable(problems),
    );
  }

  /// Every card of the deck, decoded, in deck order.
  final List<SourceCard> cards;

  /// The `$CMPLE` (J 02.01.01) or `*COMPILE` (J 90.05 deck) control card,
  /// when present.
  final SourceCard? compileCard;

  /// The division groups in deck order.
  final List<DivisionGroup> groups;

  /// Structural diagnostics found during the split.
  final List<Diagnostic> problems;

  /// The content cards of every group of [division], in deck order.
  List<SourceCard> cardsOf(Division division) => [
    for (final DivisionGroup group in groups)
      if (group.division == division) ...group.cards,
  ];

  /// A division header has its asterisk in column 7 — "the asterisk always
  /// appears in the left-most name column" (F p. 27; F p. 65) — and nothing
  /// else in the body (M1-1). `body` renders an unreadable punched column
  /// as a blank, so the extra check keeps a card with a machine special or
  /// no-readout punch in the body from passing as a header.
  /// All three headers of the compiled sample sit in
  /// column 7 (scan-checked against pages 192 and 195, 2026-08-03).
  /// Public because the job splitter shares the classification (D11.1).
  static Division? headerDivision(SourceCard card) {
    if (card.glyphAt(7) != '*' || card.unreadableColumns(7, 72).isNotEmpty) {
      return null;
    }
    return switch (card.body.trimRight()) {
      '*DATA' => Division.data,
      '*ENVIRONMENT' => Division.environment,
      '*PROCEDURE' => Division.procedure,
      _ => null,
    };
  }

  /// `$CMPLE` occupies columns 1–6 (J 02.01.01); `*COMPILE` is punched from
  /// column 7 on the compiled sample deck's control card. The word and the
  /// column after it must read genuinely — an unreadable punched column
  /// renders as a blank and must not pass as one.
  /// Public because the job splitter shares the classification (D11.1).
  static bool isCompileCard(SourceCard card) =>
      card.serial == r'$CMPLE' ||
      (card.body.startsWith('*COMPILE') &&
          card.unreadableColumns(7, 15).isEmpty);
}
