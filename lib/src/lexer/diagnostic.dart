/// Compiler diagnostics in the vocabulary of the J 90.04 message catalog.
library;

import 'messages.dart';
import 'severities.dart';
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

  /// The clause the condition is confined to, for the `n,cc` statement
  /// number form (J 02.02.01; design note M2-6): 1-based within the
  /// sentence, or `null` for the whole unit (`n,00`). Assigned by the
  /// procedure parser after clause numbering, which is why the field is
  /// not final.
  int? clause;

  /// The message text with [operands] substituted.
  String get text => message.substitute(operands);

  /// The severity value from the D9.2 severity table — the compiler
  /// reads severities from that table only.
  int get severity {
    final int? value = messageSeverities[message.number];
    if (value == null) {
      throw StateError('no severity row for message ${message.number}');
    }
    return value;
  }

  @override
  String toString() =>
      '${message.number} $severity $text '
      '(card ${card.cardNumber}${column == null ? '' : ', column $column'})';
}
