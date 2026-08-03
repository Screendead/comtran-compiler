/// The Environment Description parser (M2).
///
/// Builds one [EnvironmentCard] per M1 [EnvironmentSpec], dispatched on
/// the specification's type code (J 02.06.02: FILE, SPECIF, POOL, GROUP,
/// CONTRL, OPTION, COND). Each per-type grammar is the option-field
/// syntax of J 02.06.02–17; cross-card and cross-division resolution
/// (a SPECIF naming its FILE card, POOL/GROUP buffer arithmetic, pool
/// vs. file classification on GROUP) is M3's (design note M2-3,
/// `docs/design/m2-parser.md`).
///
/// A malformed slot is diagnosed and, where the manual gives no repair,
/// left at its declared default; the parser never throws on malformed
/// input. Where a keyword's argument slot is attempted (a following
/// token is read), that slot is always consumed once attempted, valid
/// or not — mirroring the CONTRL card's own "build with what you have"
/// recovery — so a malformed argument never re-enters the dispatch loop
/// as something else (e.g. a mistyped record name).
library;

import '../ast/environment_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/environment_lexer.dart';
import '../lexer/token.dart';
import 'parser_messages.dart';

/// Parses one environment group's [scan] into cards, appending to
/// [diagnostics].
List<EnvironmentCard> parseEnvironmentGroup(
  EnvironmentScan scan,
  List<Diagnostic> diagnostics,
) {
  final cards = <EnvironmentCard>[];
  final contrlNames = <String>{};
  for (final EnvironmentSpec spec in scan.specs) {
    switch (spec.typeText) {
      case 'FILE':
        cards.add(_parseFileCard(spec, diagnostics));
      case 'SPECIF':
        cards.add(_parseSpecifCard(spec, diagnostics));
      case 'POOL':
        cards.add(_parsePoolCard(spec, diagnostics));
      case 'GROUP':
        cards.add(_parseGroupCard(spec, diagnostics));
      case 'CONTRL':
        final ContrlCard? card = _parseContrlCard(
          spec,
          diagnostics,
          contrlNames,
        );
        if (card != null) {
          cards.add(card);
        }
      case 'OPTION':
        cards.add(_parseOptionCard(spec, diagnostics));
      case 'COND':
        cards.add(_parseCondCard(spec, diagnostics));
      default:
        // M1 guarantees typeText is one of the seven codes above
        // (`environmentTypeCodes`, `environment_lexer.dart`).
        throw ArgumentError('unknown environment type ${spec.typeText}');
    }
  }
  return cards;
}

// --- Small token-cursor helpers, shared by every card type ---------------

/// Reads a token of [kind] at [i]. Returns the advanced index and the
/// token, or `null` when the slot is empty or of a different kind. A
/// present-but-wrong-kind token is still consumed: once a keyword's
/// argument slot has been attempted, it does not re-enter the dispatch
/// loop as something else.
(int, Token?) _take(List<Token> tokens, int i, TokenKind kind) {
  if (i >= tokens.length) {
    return (i, null);
  }
  final Token token = tokens[i];
  return token.kind == kind ? (i + 1, token) : (i + 1, null);
}

/// Reads a word token at [i] (same consume-regardless rule as [_take]).
(int, Token?) _takeWord(List<Token> tokens, int i) =>
    _take(tokens, i, TokenKind.word);

/// Reads a numeric-literal token at [i] and parses its value.
(int, int?) _takeInt(List<Token> tokens, int i) {
  final (int next, Token? token) = _take(tokens, i, TokenKind.numericLiteral);
  return (next, token == null ? null : int.parse(token.text));
}

/// Advances past [text] at [i] when it is there; otherwise leaves [i]
/// unchanged (an optional decorative continuation word, not an argument
/// slot — e.g. the `LENGTH`/`IN` of `FIND LENGTH IN`).
int _consumeWord(List<Token> tokens, int i, String text) {
  if (i < tokens.length &&
      tokens[i].kind == TokenKind.word &&
      tokens[i].text == text) {
    return i + 1;
  }
  return i;
}

/// Advances past every leading comma separator at [i].
int _skipCommas(List<Token> tokens, int i) {
  var j = i;
  while (j < tokens.length &&
      tokens[j].kind == TokenKind.symbol &&
      tokens[j].text == ',') {
    j++;
  }
  return j;
}

// --- FILE ------------------------------------------------------------------

/// `INPUT`, `OUTPUT`, `CHECKPOINT` (J 02.06.03).
const Map<String, FileDirection> _fileDirections = {
  'INPUT': FileDirection.input,
  'OUTPUT': FileDirection.output,
  'CHECKPOINT': FileDirection.checkpoint,
};

/// Parses a `FILE` card (J 02.06.02–07).
FileCard _parseFileCard(EnvironmentSpec spec, List<Diagnostic> diagnostics) {
  final List<Token> tokens = spec.optionTokens;
  var i = 0;
  FileDirection direction = FileDirection.input;
  if (tokens.isNotEmpty &&
      tokens[0].kind == TokenKind.word &&
      _fileDirections.containsKey(tokens[0].text)) {
    direction = _fileDirections[tokens[0].text]!;
    i = 1;
  } else {
    // "First option word must be INPUT, OUTPUT, or CHECKPOINT"; a
    // best-guess INPUT direction lets the rest of the card still parse.
    diagnostics.add(Diagnostic(msgFileCardFormatError, spec.cards.first));
    if (tokens.isNotEmpty) {
      i = 1;
    }
  }
  final card = FileCard(spec, direction);

  if (direction == FileDirection.checkpoint) {
    // "If a file is designated CHECKPOINT it may have no other usage"
    // (J 02.06.03).
    if (_skipCommas(tokens, i) < tokens.length) {
      diagnostics.add(Diagnostic(msgFileCardFormatError, spec.cards.first));
    }
    return card;
  }

  FileRecordClause? current;
  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.symbol && token.text == ',') {
      i++;
      continue;
    }
    if (token.kind != TokenKind.word) {
      // No FILE-card rule covers a stray literal or numeral here.
      i++;
      continue;
    }
    switch (token.text) {
      case 'BCD':
        card.binary = false;
        i++;
      case 'BINARY':
        card.binary = true;
        i++;
      case 'CARD':
        // CARD forces BEGIN (J 02.06.04).
        card.card = true;
        card.begin = true;
        i++;
      case 'TAPE':
        card.card = false;
        i++;
      case 'BLOCKSIZE':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgBlocksizeNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.blocksize = value;
        }
      case 'ON':
        final int afterKeyword = _consumeWord(tokens, i + 1, 'ERROR');
        final (int next, Token? name) = _takeWord(tokens, afterKeyword);
        i = next;
        if (name == null) {
          diagnostics.add(
            Diagnostic(msgOnErrorNeedsName, token.card, column: token.column),
          );
        } else if (direction == FileDirection.output) {
          // ON ERROR is input-only (J 02.06.03-04).
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.onError = name;
        }
      case 'FOR':
        final int afterKeyword = _consumeWord(tokens, i + 1, 'LABEL');
        final (int next, Token? name) = _takeWord(tokens, afterKeyword);
        i = next;
        if (name == null) {
          diagnostics.add(
            Diagnostic(msgForLabelNeedsName, token.card, column: token.column),
          );
        } else {
          card.forLabel = name;
        }
      case 'HOLD':
      case 'SPANS':
        // "The compiler does not differentiate" (J 02.06.04).
        card.holdOrSpans = true;
        i++;
      case 'BEGIN':
        card.begin = true;
        i++;
      case 'PATTERN':
        // Reserved, rules bound, syntax deferred to M5 (D9.12): never
        // msg 89 or 96 for this word.
        diagnostics.add(
          Diagnostic(
            msgPatternNotImplemented,
            token.card,
            column: token.column,
          ),
        );
        i++;
      case 'BLOCK':
        final int next = _consumeWord(tokens, i + 1, 'CONTROL');
        i = next;
        if (current == null) {
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else {
          current.blockControl = true;
        }
      case 'FIND':
        var j = _consumeWord(tokens, i + 1, 'LENGTH');
        j = _consumeWord(tokens, j, 'IN');
        final (int next, Token? name) = _takeWord(tokens, j);
        i = next;
        if (current == null) {
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else if (name == null) {
          diagnostics.add(
            Diagnostic(
              msgFindLengthNeedsName,
              token.card,
              column: token.column,
            ),
          );
        } else {
          current.findLengthIn = name;
        }
      case 'PLACE':
        var j = _consumeWord(tokens, i + 1, 'LENGTH');
        j = _consumeWord(tokens, j, 'IN');
        final (int next, Token? name) = _takeWord(tokens, j);
        i = next;
        if (current == null) {
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else if (name == null) {
          diagnostics.add(
            Diagnostic(
              msgPlaceLengthNeedsName,
              token.card,
              column: token.column,
            ),
          );
        } else {
          current.placeLengthIn = name;
        }
      case 'PRIMARY':
        if (current == null || direction == FileDirection.input) {
          // Output-only (J 02.06.04).
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else {
          current.primary = true;
        }
        i++;
      case 'NO':
        var j = _consumeWord(tokens, i + 1, 'CONTROL');
        j = _consumeWord(tokens, j, 'WORD');
        i = j;
        if (current == null || direction == FileDirection.input) {
          // Output-only (J 02.06.04).
          diagnostics.add(
            Diagnostic(
              msgIllegalWordInFileCard,
              token.card,
              column: token.column,
            ),
          );
        } else {
          current.noControlWord = true;
        }
      default:
        // Not a recognized keyword: a record name (a record name
        // directly after a previous record's options needs no leading
        // comma, D8.5 — accepted silently either way).
        current = FileRecordClause(token);
        card.records.add(current);
        i++;
    }
  }
  return card;
}

// --- SPECIF ------------------------------------------------------------

/// Parses a `SPECIF` card (J 02.06.07–12). The name field is unused; the
/// file the card modifies is the first option token.
SpecifCard _parseSpecifCard(
  EnvironmentSpec spec,
  List<Diagnostic> diagnostics,
) {
  final List<Token> tokens = spec.optionTokens;
  var i = 0;
  Token? fileName;
  if (tokens.isNotEmpty && tokens[0].kind == TokenKind.word) {
    fileName = tokens[0];
    i = 1;
  } else {
    diagnostics.add(Diagnostic(msgSpecifCardFormatError, spec.cards.first));
    if (tokens.isNotEmpty) {
      i = 1;
    }
  }
  final card = SpecifCard(spec)..fileName = fileName;

  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.symbol && token.text == ',') {
      i++;
      continue;
    }
    if (token.kind != TokenKind.word) {
      i++;
      continue;
    }
    switch (token.text) {
      case 'UNIT1':
        final (int next, Token? literal) = _take(
          tokens,
          i + 1,
          TokenKind.alphamericLiteral,
        );
        i = next;
        if (literal == null) {
          // `*` is legal for UNIT2 only (J 02.06.10).
          diagnostics.add(
            Diagnostic(
              msgSpecifCardFormatError,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.unit1 = literal.text;
        }
      case 'UNIT2':
        if (i + 1 < tokens.length &&
            tokens[i + 1].kind == TokenKind.descriptionItem &&
            tokens[i + 1].text == '*') {
          card.unit2 = '*';
          i += 2;
        } else {
          final (int next, Token? literal) = _take(
            tokens,
            i + 1,
            TokenKind.alphamericLiteral,
          );
          i = next;
          if (literal == null) {
            diagnostics.add(
              Diagnostic(
                msgSpecifCardFormatError,
                token.card,
                column: token.column,
              ),
            );
          } else {
            card.unit2 = literal.text;
          }
        }
      case 'HIGH':
        card.density = 'HIGH';
        i++;
      case 'LOW':
        card.density = 'LOW';
        i++;
      case 'DEFER':
        card.defer = true;
        i++;
      case 'OPENW':
        card.openW = true;
        i++;
      case 'OPENF':
        card.openF = true;
        i++;
      case 'CLOSER':
        card.closeMode = 'CLOSER';
        i++;
      case 'CLOSEW':
        card.closeMode = 'CLOSEW';
        i++;
      case 'ACTIVITY':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null || value < 1 || value > 99) {
          diagnostics.add(
            Diagnostic(
              msgSpecifCardFormatError,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.activity = value;
        }
      case 'CHECKC':
        card.checkpoint = 'CHECKC';
        i++;
      case 'CHECKF':
        card.checkpoint = 'CHECKF';
        i++;
      case 'CHKS':
        // Appendix 90.08's mislabeling of CHECKC (D7.2); silent.
        card.checkpoint = 'CHECKC';
        i++;
      case 'MULTI':
        card.multi = true;
        i++;
      case 'SEQ':
        card.seq = true;
        i++;
      case 'CKSUMS':
        card.cksums = true;
        i++;
      case 'LABELS':
        card.labels = 'LABELS';
        i++;
      case 'LABELN':
        card.labels = 'LABELN';
        i++;
      case 'SERIAL':
        final (int next, Token? literal) = _take(
          tokens,
          i + 1,
          TokenKind.alphamericLiteral,
        );
        i = next;
        if (literal == null || literal.text.length > 5) {
          diagnostics.add(
            Diagnostic(
              msgSpecifCardFormatError,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.serial = literal.text;
        }
      case 'REEL':
        final (int next, Token? literal) = _take(
          tokens,
          i + 1,
          TokenKind.alphamericLiteral,
        );
        i = next;
        if (literal == null ||
            literal.text.length > 4 ||
            !_allDigits(literal.text)) {
          diagnostics.add(
            Diagnostic(
              msgSpecifCardFormatError,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.reel = literal.text;
        }
      case 'RETAIN':
        final (int next, Token? number) = _take(
          tokens,
          i + 1,
          TokenKind.numericLiteral,
        );
        i = next;
        if (number == null || number.text.length > 3) {
          diagnostics.add(
            Diagnostic(
              msgSpecifCardFormatError,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.retain = number.text;
        }
      default:
        diagnostics.add(
          Diagnostic(
            msgSpecifCardFormatError,
            token.card,
            column: token.column,
          ),
        );
        i++;
    }
  }
  return card;
}

/// Whether every character of [text] is a decimal digit, and [text] is
/// non-empty (SPECIF `REEL`, J 02.06.12).
bool _allDigits(String text) =>
    text.isNotEmpty &&
    text.split('').every((String c) => '0123456789'.contains(c));

// --- POOL ------------------------------------------------------------------

/// Parses a `POOL` card (J 02.06.13). The pool name is already
/// `spec.name`.
PoolCard _parsePoolCard(EnvironmentSpec spec, List<Diagnostic> diagnostics) {
  final List<Token> tokens = spec.optionTokens;
  final card = PoolCard(spec);
  var i = 0;
  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.symbol && token.text == ',') {
      i++;
      continue;
    }
    if (token.kind != TokenKind.word) {
      i++;
      continue;
    }
    switch (token.text) {
      case 'BUFFERCOUNT':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgBuffercountNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.bufferCount = value;
        }
      case 'BLOCKSIZE':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgPoolBlocksizeNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.blocksize = value;
        }
      default:
        card.fileNames.add(token);
        i++;
    }
  }
  if (card.fileNames.isEmpty) {
    diagnostics.add(Diagnostic(msgPoolCardFormatError, spec.cards.first));
  }
  return card;
}

// --- GROUP -----------------------------------------------------------------

/// Parses a `GROUP` card (J 02.06.13–14). Splitting a leading pool name
/// from the file names is M3's (design note M2-3).
GroupCard _parseGroupCard(EnvironmentSpec spec, List<Diagnostic> diagnostics) {
  final List<Token> tokens = spec.optionTokens;
  final card = GroupCard(spec);
  var i = 0;
  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.symbol && token.text == ',') {
      i++;
      continue;
    }
    if (token.kind != TokenKind.word) {
      i++;
      continue;
    }
    switch (token.text) {
      case 'OPENCOUNT':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgOpencountNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.openCount = value;
        }
      case 'BUFFERCOUNT':
        final (int next, int? value) = _takeInt(tokens, i + 1);
        i = next;
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgBuffercountNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else {
          card.bufferCount = value;
        }
      default:
        card.names.add(token);
        i++;
    }
  }
  if (card.names.isEmpty) {
    diagnostics.add(Diagnostic(msgGroupCardFormatError, spec.cards.first));
  }
  return card;
}

// --- CONTRL ------------------------------------------------------------

/// Parses a `CONTRL` card (J 02.06.15–16), tracking [seenNames] across
/// the whole environment group for the uniqueness check. Returns `null`
/// when the card names no area at all, after diagnosing (D7.8: CONTRL
/// is still fully parsed and name-checked even though it reaches no
/// object-deck effect).
ContrlCard? _parseContrlCard(
  EnvironmentSpec spec,
  List<Diagnostic> diagnostics,
  Set<String> seenNames,
) {
  final String name = spec.name;
  final bool invalid =
      name.isEmpty || name.length > 6 || seenNames.contains(name);
  if (invalid) {
    diagnostics.add(Diagnostic(msgContrlNameInvalid, spec.cards.first));
  }
  if (name.isNotEmpty) {
    seenNames.add(name);
  }
  // CONTRL has no object-deck effect (D7.8; J 90.01.04) — every CONTRL
  // card draws this in addition to its own format/name checks.
  diagnostics.add(Diagnostic(msgEnvironmentTypeNotProcessed, spec.cards.first));

  final List<Token> tokens = spec.optionTokens;
  Token? first;
  Token? to;
  var malformed = false;
  if (tokens.length == 1 && tokens[0].kind == TokenKind.word) {
    first = tokens[0];
  } else if (tokens.length == 3 &&
      tokens[0].kind == TokenKind.word &&
      tokens[1].kind == TokenKind.word &&
      tokens[1].text == 'TO' &&
      tokens[2].kind == TokenKind.word) {
    first = tokens[0];
    to = tokens[2];
  } else {
    malformed = true;
    if (tokens.isNotEmpty && tokens[0].kind == TokenKind.word) {
      first = tokens[0];
    }
  }
  if (malformed) {
    diagnostics.add(Diagnostic(msgContrlCardFormatError, spec.cards.first));
  }
  if (first == null) {
    return null;
  }
  return ContrlCard(spec, first, to);
}

// --- OPTION ------------------------------------------------------------

/// Parses an `OPTION` card (J 02.06.16–17): two independent slots,
/// COLLATE and CONSERVE, each separately scopeable via `IN`.
OptionCard _parseOptionCard(
  EnvironmentSpec spec,
  List<Diagnostic> diagnostics,
) {
  final List<Token> tokens = spec.optionTokens;
  final card = OptionCard(spec);
  var i = 0;
  while (i < tokens.length) {
    final Token token = tokens[i];
    if (token.kind == TokenKind.symbol && token.text == ',') {
      i++;
      continue;
    }
    if (token.kind != TokenKind.word) {
      diagnostics.add(
        Diagnostic(msgOptionCardFormatError, token.card, column: token.column),
      );
      i++;
      continue;
    }
    switch (token.text) {
      case 'COLLATE':
        final int afterKeyword = _consumeWord(tokens, i + 1, 'COM');
        if (afterKeyword == i + 1) {
          diagnostics.add(
            Diagnostic(
              msgOptionCardFormatError,
              token.card,
              column: token.column,
            ),
          );
          i = afterKeyword;
        } else {
          card.collateCom = true;
          i = _consumeIn(
            tokens,
            afterKeyword,
            (Token name) => card.collateIn = name,
          );
        }
      case 'CONSERVE':
        final int afterKeyword = i + 1;
        if (afterKeyword < tokens.length &&
            tokens[afterKeyword].kind == TokenKind.word &&
            (tokens[afterKeyword].text == 'SPACE' ||
                tokens[afterKeyword].text == 'TIME')) {
          card.conserve = tokens[afterKeyword].text;
          i = _consumeIn(
            tokens,
            afterKeyword + 1,
            (Token name) => card.conserveIn = name,
          );
        } else {
          diagnostics.add(
            Diagnostic(
              msgOptionCardFormatError,
              token.card,
              column: token.column,
            ),
          );
          i = afterKeyword;
        }
      default:
        diagnostics.add(
          Diagnostic(
            msgOptionCardFormatError,
            token.card,
            column: token.column,
          ),
        );
        i++;
    }
  }
  return card;
}

/// Consumes an optional `IN section.name` clause starting at [i] (after
/// any leading commas), calling [setName] when one is present. Returns
/// [i] unchanged when no `IN` clause is there.
int _consumeIn(List<Token> tokens, int i, void Function(Token) setName) {
  final int afterCommas = _skipCommas(tokens, i);
  if (afterCommas < tokens.length &&
      tokens[afterCommas].kind == TokenKind.word &&
      tokens[afterCommas].text == 'IN') {
    final (int next, Token? name) = _takeWord(tokens, afterCommas + 1);
    if (name != null) {
      setName(name);
    }
    return next;
  }
  return i;
}

// --- COND ------------------------------------------------------------------

/// Parses a `COND` card (J 02.06.17): a console-key condition name.
CondCard _parseCondCard(EnvironmentSpec spec, List<Diagnostic> diagnostics) {
  final List<Token> tokens = spec.optionTokens;
  final int i = _skipCommas(tokens, 0);
  final String setting;
  if (i < tokens.length &&
      tokens[i].kind == TokenKind.word &&
      tokens[i].text == 'KEYS' &&
      i + 1 < tokens.length &&
      tokens[i + 1].kind == TokenKind.alphamericLiteral) {
    setting = _normalizeCondKeys(tokens[i + 1].text, spec, diagnostics);
  } else {
    diagnostics.add(Diagnostic(msgCondCardFormatError, spec.cards.first));
    setting = '000000000000';
  }
  return CondCard(spec, setting);
}

/// Normalizes a COND `KEYS` literal to 12 octal digits (D9.16): a
/// non-octal setting becomes `1` wholesale (msg 7); an over-length
/// setting keeps its rightmost 12 digits (msg 6); an under-length
/// setting is left-padded with zeros, silently — the D9.16 design
/// decision covering the case neither manual's messages address.
String _normalizeCondKeys(
  String raw,
  EnvironmentSpec spec,
  List<Diagnostic> diagnostics,
) {
  final String stripped = raw.replaceAll(' ', '');
  final bool allOctal = stripped
      .split('')
      .every((String c) => '01234567'.contains(c));
  if (!allOctal) {
    diagnostics.add(Diagnostic(msgCondKeysNotOctal, spec.cards.first));
    return '000000000001';
  }
  if (stripped.length > 12) {
    diagnostics.add(Diagnostic(msgCondKeysTooLong, spec.cards.first));
    return stripped.substring(stripped.length - 12);
  }
  return stripped.padLeft(12, '0');
}
