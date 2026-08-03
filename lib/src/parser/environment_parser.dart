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
import '../lexer/reserved_words.dart';
import '../lexer/token.dart';
import 'parser_messages.dart';

/// The program-wide FILE-card tally: "A maximum of 63 files may be
/// described" (J 90.01.04). The driver passes one tally through every
/// environment group of a job; each FILE card past the 63rd draws
/// msg 193 (D10.8).
final class FileCardTally {
  /// FILE cards seen so far.
  int count = 0;
}

/// Parses one environment group's [scan] into cards, appending to
/// [diagnostics]. [fileTally] carries the program-wide FILE-card count
/// across groups; without one the count covers this group only.
List<EnvironmentCard> parseEnvironmentGroup(
  EnvironmentScan scan,
  List<Diagnostic> diagnostics, {
  FileCardTally? fileTally,
}) {
  final FileCardTally tally = fileTally ?? FileCardTally();
  final cards = <EnvironmentCard>[];
  final contrlNames = <String>{};
  for (final EnvironmentSpec spec in scan.specs) {
    if (spec.name.isNotEmpty && _isBarredName(spec.name)) {
      // A list-1/list-2 key word declared as an Environment name:
      // msg 178, the name is kept, parsing continues (D1.5; D10.8).
      diagnostics.add(Diagnostic(msgKeyWordAsDataName, spec.cards.first));
    }
    switch (spec.typeText) {
      case 'FILE':
        tally.count++;
        if (tally.count > 63) {
          // "A maximum of 63 files may be described" (J 90.01.04).
          diagnostics.add(Diagnostic(msgTooManyFiles, spec.cards.first));
        }
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
  var sawBlocksize = false;
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
        sawBlocksize = true;
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
        if (current == null || direction == FileDirection.output) {
          // Input-only: the Output Files form has no BLOCK CONTROL and
          // its meaning is input-specific (J 02.06.03; J 02.06.05).
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
        // comma, D8.5 — accepted silently either way). A record name
        // is a declared use, so a key word here draws 178 (D10.8).
        if (_isBarredName(token.text)) {
          diagnostics.add(
            Diagnostic(msgKeyWordAsDataName, token.card, column: token.column),
          );
        }
        current = FileRecordClause(token);
        card.records.add(current);
        i++;
    }
  }
  if (card.blocksize == null && !sawBlocksize) {
    // BLOCKSIZE is mandatory: "This specification must be made"
    // (J 02.06.04). The keyword-without-integer case drew msg 91 above;
    // total absence draws the card-format message (D10.8; the minimum-24
    // and maximum-9999 range checks are the M3 data mapper's, D7.1).
    diagnostics.add(Diagnostic(msgFileCardFormatError, spec.cards.first));
  }
  return card;
}

/// Whether [name] is a J list-1 or list-2 key word, barred as a Data
/// name (J 02.03.02-03).
bool _isBarredName(String name) {
  final KeyWordClass? keyWordClass = keyWordClassOf(name);
  return keyWordClass == KeyWordClass.alwaysKey ||
      keyWordClass == KeyWordClass.notDataOrProcedureName;
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
    diagnostics.add(Diagnostic(msgSpecifFileNameNotFirst, spec.cards.first));
    if (tokens.isNotEmpty) {
      i = 1;
    }
  }
  final card = SpecifCard(spec)..fileName = fileName;

  // HIGH/LOW is positional: file density before LABELS/LABELN, label
  // density after (J 02.06.12).
  var labelsSeen = false;
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
            Diagnostic(msgUnitNeedsLiteral, token.card, column: token.column),
          );
        } else if (literal.text.length > 6) {
          diagnostics.add(
            Diagnostic(
              msgKeyWordLiteralTooLong,
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
              Diagnostic(msgUnitNeedsLiteral, token.card, column: token.column),
            );
          } else if (literal.text.length > 6) {
            diagnostics.add(
              Diagnostic(
                msgKeyWordLiteralTooLong,
                token.card,
                column: token.column,
              ),
            );
          } else {
            card.unit2 = literal.text;
          }
        }
      case 'HIGH':
        if (labelsSeen) {
          card.labelDensity = 'HIGH';
        } else {
          card.density = 'HIGH';
        }
        i++;
      case 'LOW':
        if (labelsSeen) {
          card.labelDensity = 'LOW';
        } else {
          card.density = 'LOW';
        }
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
        if (value == null) {
          diagnostics.add(
            Diagnostic(
              msgActivityNeedsInteger,
              token.card,
              column: token.column,
            ),
          );
        } else if (value < 1 || value > 99) {
          // An integer followed, but outside 1-99 (J 02.06.11); no
          // dedicated message covers the range fault (D10.1).
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
        labelsSeen = true;
        i++;
      case 'LABELN':
        card.labels = 'LABELN';
        labelsSeen = true;
        i++;
      case 'SERIAL':
        final (int next, Token? literal) = _take(
          tokens,
          i + 1,
          TokenKind.alphamericLiteral,
        );
        i = next;
        if (literal == null) {
          diagnostics.add(
            Diagnostic(msgSerialNeedsLiteral, token.card, column: token.column),
          );
        } else if (literal.text.length > 5) {
          diagnostics.add(
            Diagnostic(
              msgKeyWordLiteralTooLong,
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
        if (literal == null) {
          diagnostics.add(
            Diagnostic(msgReelNeedsLiteral, token.card, column: token.column),
          );
        } else if (literal.text.length > 4) {
          diagnostics.add(
            Diagnostic(
              msgKeyWordLiteralTooLong,
              token.card,
              column: token.column,
            ),
          );
        } else if (!_allDigits(literal.text)) {
          // A literal followed, but not "4 or less numeric characters"
          // (J 02.06.12); no dedicated message covers the fault (D10.1).
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
        if (number == null) {
          diagnostics.add(
            Diagnostic(msgRetainNeedsInteger, token.card, column: token.column),
          );
        } else if (number.text.length > 3) {
          // A number followed, but not "3 or less numeric characters"
          // (J 02.06.12); 160,00 names alphabetic literals only, so no
          // dedicated message covers the fault (D10.1).
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
/// non-octal setting becomes `1` wholesale (msg 7) — a blank is not an
/// octal digit, so an imbedded blank fails this check (D9.16 has no
/// blank-stripping step); an over-length setting keeps its rightmost
/// 12 digits (msg 6); an under-length setting is left-padded with
/// zeros, silently — the D9.16 design decision covering the case
/// neither manual's messages address.
String _normalizeCondKeys(
  String raw,
  EnvironmentSpec spec,
  List<Diagnostic> diagnostics,
) {
  final bool allOctal = raw
      .split('')
      .every((String c) => '01234567'.contains(c));
  if (!allOctal) {
    diagnostics.add(Diagnostic(msgCondKeysNotOctal, spec.cards.first));
    return '000000000001';
  }
  if (raw.length > 12) {
    diagnostics.add(Diagnostic(msgCondKeysTooLong, spec.cards.first));
    return raw.substring(raw.length - 12);
  }
  return raw.padLeft(12, '0');
}
