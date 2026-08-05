/// The `--emit-scan` dump: the front end's output, a labeled
/// reconstruction (`docs/design/emit-stages.md`).
///
/// Renders each job's [FrontEndResult] flat, in deck order: the compile
/// card, then each division group with its header card, then one line
/// per scanned unit (data entry, environment specification, procedure
/// sentence) — no tree, one line per unit. A unit's line carries its
/// statement number in the `n,00` form the front end assigns (D7.13),
/// the unit kind, and the text the scanner assembled for it. The front
/// end stops at a severity-5 diagnostic (D9.1) by discarding the whole
/// group it was scanning when the stop hit (`front_end.dart`), so a
/// stopped job's section renders only the groups completed before that
/// group and ends with the shared `stageStopped` line (D10.2).
library;

import '../driver/driver.dart';
import '../lexer/data_lexer.dart';
import '../lexer/environment_lexer.dart';
import '../lexer/front_end.dart';
import '../lexer/procedure_lexer.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import 'common.dart';

/// Renders the `--emit-scan` dump for [deck]: the reconstruction label,
/// then one job section per job.
String emitScan(DeckCompilation deck) {
  final buffer = StringBuffer()..writeln(reconstructionLabel);
  for (var i = 0; i < deck.jobs.length; i++) {
    if (i > 0) {
      buffer.writeln();
    }
    buffer.writeln(jobHeader(i + 1));
    _writeJob(buffer, deck.jobs[i].frontEnd);
  }
  return buffer.toString();
}

void _writeJob(StringBuffer buffer, FrontEndResult frontEnd) {
  final SourceCard? compileCard = frontEnd.program.compileCard;
  if (compileCard != null) {
    buffer.writeln('COMPILE  ${compileCard.textRange(1, 72).trimRight()}');
  }
  for (final GroupScan group in frontEnd.groupScans) {
    buffer.writeln(group.group.header.body.trimRight());
    switch (group) {
      case DataGroupScan(:final scan):
        for (final DataEntry entry in scan.entries) {
          _writeUnit(
            buffer,
            frontEnd,
            entry.cards.first,
            'ENTRY',
            _dataText(entry),
          );
        }
      case EnvironmentGroupScan(:final scan):
        for (final EnvironmentSpec spec in scan.specs) {
          _writeUnit(
            buffer,
            frontEnd,
            spec.cards.first,
            'SPEC',
            _environmentText(spec),
          );
        }
      case ProcedureGroupScan(:final scan):
        for (final ProcedureSentence sentence in scan.sentences) {
          _writeUnit(
            buffer,
            frontEnd,
            sentence.cards.first,
            'SENTENCE',
            _procedureText(sentence),
          );
        }
    }
  }
  if (frontEnd.stopped) {
    buffer.writeln(stageStopped);
  }
}

void _writeUnit(
  StringBuffer buffer,
  FrontEndResult frontEnd,
  SourceCard firstCard,
  String kind,
  String text,
) {
  final String number =
      frontEnd.statementNumberByCard[firstCard.cardNumber] ?? '9999,99';
  buffer.writeln('$number  $kind  $text');
}

/// The name, level, type, quantity, mode, and justification fields (each
/// already scanner-trimmed but for the raw level field), followed by the
/// description tokens.
String _dataText(DataEntry entry) {
  final Iterable<String> fields = <String>[
    entry.name,
    entry.levelText.trim(),
    entry.typeText,
    entry.quantityText,
    entry.modeText,
    entry.justifyText,
  ].where((String f) => f.isNotEmpty);
  final String description = _joinTokens(entry.descriptionTokens);
  return [...fields, if (description.isNotEmpty) description].join(' ');
}

/// The name and type fields, followed by the option tokens.
String _environmentText(EnvironmentSpec spec) {
  final fields = <String>[if (spec.name.isNotEmpty) spec.name, spec.typeText];
  final String options = _joinTokens(spec.optionTokens);
  return [...fields, if (options.isNotEmpty) options].join(' ');
}

/// The margin label, when present, followed by the sentence's tokens.
String _procedureText(ProcedureSentence sentence) {
  final String body = _joinTokens(sentence.tokens);
  if (sentence.label == null) {
    return body;
  }
  return body.isEmpty ? '${sentence.label}.' : '${sentence.label}. $body';
}

/// Joins [tokens] with one space, except before a comma symbol, so a
/// list like `A,B,C` reads as `A, B, C` rather than `A , B , C`.
String _joinTokens(List<Token> tokens) {
  final buffer = StringBuffer();
  for (final token in tokens) {
    final bool comma = token.kind == TokenKind.symbol && token.text == ',';
    if (buffer.isNotEmpty && !comma) {
      buffer.write(' ');
    }
    buffer.write(_renderToken(token));
  }
  return buffer.toString();
}

/// An alphameric literal is re-quoted; every other token kind prints its
/// scanned text as-is.
String _renderToken(Token token) =>
    token.kind == TokenKind.alphamericLiteral ? "'${token.text}'" : token.text;
