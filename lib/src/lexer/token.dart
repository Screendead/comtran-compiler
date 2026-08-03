/// Lexical tokens of the source language.
///
/// Token formation follows definition §1.3 (words and names), §1.7
/// (literals), and §1.8 (operators, punctuation, spacing).
library;

import 'source_card.dart';

/// The kinds of token the scanners emit.
enum TokenKind {
  /// A word: a name or a key word (F p. 15; classification is the parser's
  /// job — the scanner does not decide which).
  word,

  /// A numeric literal: numerals with at most one decimal point (F p. 18).
  numericLiteral,

  /// A floating point literal in the J form `fraction F±exponent` or the
  /// double-precision `FF` form (J 02.04.02).
  floatingLiteral,

  /// An alphameric literal; [Token.text] is the content between the
  /// quotation marks (F p. 19).
  alphamericLiteral,

  /// An operator or punctuation character: `+ - * / ** = ( ) ,`
  /// (definition §1.8.1).
  symbol,

  /// The free text of a NOTE command, kept raw because punctuation and
  /// spacing rules do not apply to it (F p. 59).
  noteText,

  /// An unclassified blank-separated run in a Description field —
  /// pictorial, name, or clause word; classification is semantic and
  /// happens at M3 (F p. 79).
  descriptionItem,
}

/// One token, tied to the card and column it starts at.
final class Token {
  /// Creates a token of [kind] with content [text], starting at 1-based
  /// [column] of [card].
  Token(this.kind, this.text, this.card, this.column);

  /// The kind of token.
  final TokenKind kind;

  /// The token content. For [TokenKind.alphamericLiteral] the enclosing
  /// quotation marks are not included.
  final String text;

  /// The card the token starts on.
  final SourceCard card;

  /// The 1-based column of the token's first character (for an alphameric
  /// literal, of its opening quotation mark).
  final int column;

  @override
  String toString() =>
      '${kind.name}(${text.isEmpty ? '' : text})@'
      '${card.cardNumber}:$column';
}
