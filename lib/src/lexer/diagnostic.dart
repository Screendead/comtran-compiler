/// Compiler diagnostics in the vocabulary of the J 90.04 message catalog.
library;

import 'messages.dart';
import 'source_card.dart';

/// One diagnostic, reported against a card (and optionally a column).
///
/// Where the 1962 compiler documents a message for the condition, [message]
/// carries its 90.04 catalog entry; the severity value actually printed by
/// the 1962 compiler per message is unrecoverable (the catalog prints code
/// 0 throughout, J 90.04.01), so severities here are our assignment.
final class Diagnostic {
  /// Creates a diagnostic for [message] against [card].
  Diagnostic(this.message, this.card, {this.column, this.operands = const []});

  /// The 90.04 catalog entry.
  final Message message;

  /// The card the condition was detected on.
  final SourceCard card;

  /// The 1-based column, when the condition is tied to one.
  final int? column;

  /// Values substituted for the message's `'NAME.1'`-style parameters, in
  /// order of appearance.
  final List<String> operands;

  /// The message text with [operands] substituted.
  String get text => message.substitute(operands);

  @override
  String toString() =>
      '${message.number ?? '——'} ${message.severity} $text '
      '(card ${card.cardNumber}${column == null ? '' : ', column $column'})';
}
