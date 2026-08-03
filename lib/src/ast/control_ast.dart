/// The compiler control-card AST (M2).
///
/// The $CMPLE card initiates compilation (J 02.01.01); *COMPILE is the
/// attested 1961 spelling of the same card (D7.12). *FINISH needs no
/// node — `SourceProgram.finishCard` carries it.
library;

import '../lexer/source_card.dart';

/// The parsed compile control card.
final class CompileCard {
  /// Creates the parsed card.
  CompileCard({
    required this.card,
    required this.historicalSpelling,
    required this.deckName,
    required this.options,
    required this.secondaryIdentifier,
  });

  /// The source card.
  final SourceCard card;

  /// Whether the card is the 1961 `*COMPILE` form rather than `$CMPLE`
  /// (D7.12). The *COMPILE layout carries no deck.name field.
  final bool historicalSpelling;

  /// The deck name, columns 8–13 of a $CMPLE card, leading blanks
  /// ignored. Imbedded blanks are accepted silently (D7.11). Empty on a
  /// *COMPILE card.
  final String deckName;

  /// The option words, in order. The option list is comma-separated and
  /// the first blank terminates it (J 02.01.01).
  final List<String> options;

  /// The secondary identifier, columns 55–72, verbatim (J 02.01.02).
  final String secondaryIdentifier;
}
