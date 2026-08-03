/// Compiler diagnostics in the vocabulary of the J 90.04 message catalog.
library;

import 'dart:collection';

import 'messages.dart';
import 'severities.dart';
import 'source_card.dart';

/// Thrown after a severity-5 diagnostic is issued: compilation stops
/// at the point of detection (D9.1). The phase driver catches it and
/// keeps everything parsed and diagnosed up to that point; nothing
/// inside the parser does (design note M2-13).
final class StopCompilation implements Exception {
  const StopCompilation();
}

/// The one diagnostic sink of a compilation (D9.1; D10.2): the ordered
/// diagnostic list plus the running maximum severity. Recording a
/// severity-5 diagnostic sets [stopped] and throws [StopCompilation],
/// so every phase stops at the point of detection. The driver passes
/// one sink through the front end and the parser; a plain list stays
/// usable where no stop path is wanted (unit tests of one scanner or
/// parser function).
final class DiagnosticSink extends ListBase<Diagnostic> {
  final List<Diagnostic> _diagnostics = [];

  /// The highest severity recorded, or 0 with no diagnostics.
  int get maxSeverity => _maxSeverity;
  int _maxSeverity = 0;

  /// Whether a severity-5 diagnostic stopped the compilation (D9.1).
  bool get stopped => _stopped;
  bool _stopped = false;

  @override
  int get length => _diagnostics.length;

  @override
  set length(int newLength) {
    if (newLength > _diagnostics.length) {
      throw UnsupportedError('a DiagnosticSink cannot grow by length');
    }
    _diagnostics.length = newLength;
  }

  @override
  Diagnostic operator [](int index) => _diagnostics[index];

  @override
  void operator []=(int index, Diagnostic value) {
    _diagnostics[index] = value;
    _record(value);
  }

  @override
  void add(Diagnostic element) {
    _diagnostics.add(element);
    _record(element);
  }

  void _record(Diagnostic diagnostic) {
    final int severity = diagnostic.severity;
    if (severity > _maxSeverity) {
      _maxSeverity = severity;
    }
    if (severity >= 5) {
      _stopped = true;
      throw const StopCompilation();
    }
  }
}

/// One diagnostic, reported against a card (and optionally a column).
///
/// Where the 1962 compiler documents a message for the condition, [message]
/// carries its 90.04 catalog entry; the severity value actually printed by
/// the 1962 compiler per message is unrecoverable (the catalog prints code
/// 0 throughout, J 90.04.01), so severities here are our assignment.
final class Diagnostic {
  Diagnostic(this.message, this.card, {this.column, this.operands = const []});

  /// Creates a diagnostic confined to no single source statement — no
  /// card, printed at statement 9999,99, "used to reference errors
  /// which are not confined to a single source statement"
  /// (J 02.02.01; D11.3).
  Diagnostic.wholeProgram(this.message, {this.operands = const []})
    : card = null,
      column = null;

  /// The 90.04 catalog entry.
  final Message message;

  /// The card the condition was detected on, or `null` for a
  /// whole-program diagnostic (msg 132; D11.3).
  final SourceCard? card;

  /// The 1-based column, when the condition is tied to one.
  final int? column;

  /// Values substituted for the message's `'NAME.1'`-style parameters,
  /// in `NAME.n` index order: `operands[0]` fills `'NAME.1'`,
  /// `operands[1]` fills `'NAME.2'` — not in order of appearance, which
  /// differs for msgs 5,00 and 195,00, whose texts print `'NAME.2'`
  /// first (J 90.04.01).
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
      '${card == null ? '(whole program)' : '(card ${card!.cardNumber}'
                '${column == null ? '' : ', column $column'})'}';
}
