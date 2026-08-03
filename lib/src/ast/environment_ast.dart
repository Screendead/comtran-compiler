/// The Environment Description AST (M2).
///
/// One node per card type (J 02.06.02–17). M2 records each card's parsed
/// option structure; cross-card resolution (a SPECIF naming its FILE
/// card, POOL buffer arithmetic, GROUP name classification) is M3's
/// (design note M2-3, `docs/design/m2-parser.md`).
library;

import '../lexer/environment_lexer.dart';
import '../lexer/token.dart';

/// One parsed environment card (specification group).
sealed class EnvironmentCard {
  EnvironmentCard(this.spec);

  /// The M1 scan specification: cards, name, type, raw option tokens.
  final EnvironmentSpec spec;
}

/// The FILE card's usage designation (J 02.06.03).
enum FileDirection {
  /// `INPUT`.
  input,

  /// `OUTPUT`.
  output,

  /// `CHECKPOINT` — "it may have no other usage" (J 02.06.03).
  checkpoint,
}

/// One record named on a FILE card, with the options that follow it:
/// "the options must be listed after the record name to which they
/// apply" (J 02.06.04).
final class FileRecordClause {
  /// Creates the clause for the record named by [name].
  FileRecordClause(this.name);

  /// The record name token.
  final Token name;

  /// `BLOCK CONTROL` (input; J 02.06.04).
  bool blockControl = false;

  /// The data name after `FIND LENGTH IN`, or `null` (J 02.06.04).
  Token? findLengthIn;

  /// The data name after `PLACE LENGTH IN`, or `null` (J 02.06.04).
  Token? placeLengthIn;

  /// `PRIMARY` (output only; J 02.06.04).
  bool primary = false;

  /// `NO CONTROL WORD` (output only; J 02.06.04).
  bool noControlWord = false;
}

/// A `FILE` card (J 02.06.02–07).
final class FileCard extends EnvironmentCard {
  /// Creates the card; option fields start at their defaults.
  FileCard(super.spec, this.direction);

  /// INPUT, OUTPUT, or CHECKPOINT.
  final FileDirection direction;

  /// `BINARY`; the default is BCD (J 02.06.04).
  bool binary = false;

  /// `CARD`; the default is TAPE. CARD forces [begin] (J 02.06.04).
  bool card = false;

  /// The word count after `BLOCKSIZE`, or `null` when absent or not a
  /// number (mandatory; msg 91,00 when no integer follows).
  int? blocksize;

  /// The statement name after `ON ERROR` (input; msg 92,00), or `null`.
  Token? onError;

  /// The statement name after `FOR LABEL` (msg 93,00), or `null`.
  Token? forLabel;

  /// `HOLD` or `SPANS` — "the compiler does not differentiate"
  /// (J 02.06.04).
  bool holdOrSpans = false;

  /// `BEGIN` — records start a new block (J 02.06.04).
  bool begin = false;

  /// The records, each with its per-record options, source order.
  final List<FileRecordClause> records = [];
}

/// A `SPECIF` card (J 02.06.07–12). The file name is the first option;
/// the name field is unused.
final class SpecifCard extends EnvironmentCard {
  /// Creates the card; option fields start at their defaults.
  SpecifCard(super.spec);

  /// The file name the card modifies (J 02.06.08), or `null` when
  /// missing (msg 153,00).
  Token? fileName;

  /// The unit literal after `UNIT1`, verbatim without quotes.
  String? unit1;

  /// The unit literal after `UNIT2`, verbatim without quotes; `*` is
  /// legal for UNIT2 only (J 02.06.10).
  String? unit2;

  /// `HIGH` or `LOW` density; `null` means the HIGH default
  /// (J 02.06.11).
  String? density;

  /// `DEFER` (J 02.06.11).
  bool defer = false;

  /// `OPENW` — no rewind before open (J 02.06.11).
  bool openW = false;

  /// `OPENF` (J 02.06.11).
  bool openF = false;

  /// `CLOSER` or `CLOSEW`; `null` means rewind and unload (J 02.06.11).
  String? closeMode;

  /// The number after `ACTIVITY`, 1–99 (J 02.06.11), or `null`.
  int? activity;

  /// `CHECKC` or `CHECKF`; the token `CHKS` reads as CHECKC (D7.2).
  String? checkpoint;

  /// `MULTI` (J 02.06.11).
  bool multi = false;

  /// `SEQ` (J 02.06.12).
  bool seq = false;

  /// `CKSUMS` (J 02.06.12).
  bool cksums = false;

  /// `LABELS` or `LABELN`; `null` means unlabeled (J 02.06.12).
  String? labels;

  /// The literal after `SERIAL`, at most 5 characters (J 02.06.12).
  String? serial;

  /// The literal after `REEL`, at most 4 numeric characters
  /// (J 02.06.12).
  String? reel;

  /// The number after `RETAIN`, at most 3 digits (J 02.06.12).
  String? retain;
}

/// A `POOL` card (J 02.06.13). The pool name is in the name field.
final class PoolCard extends EnvironmentCard {
  /// Creates the card; option fields start at their defaults.
  PoolCard(super.spec);

  /// The file names pooled, source order.
  final List<Token> fileNames = [];

  /// The number after `BUFFERCOUNT` (msg 163,00 when no integer), or
  /// `null`.
  int? bufferCount;

  /// The number after `BLOCKSIZE` (msg 162,00 when no integer), or
  /// `null`.
  int? blocksize;
}

/// A `GROUP` card (J 02.06.13–14). A leading pool name and the file
/// names are stored as one name list; telling pool from file needs the
/// symbol table and is M3's.
final class GroupCard extends EnvironmentCard {
  /// Creates the card; option fields start at their defaults.
  GroupCard(super.spec);

  /// The names on the card, source order. When a pool name is present
  /// it is the first item (J 02.06.14).
  final List<Token> names = [];

  /// The number after `OPENCOUNT` (msg 165,00 when no integer), or
  /// `null`.
  int? openCount;

  /// The number after `BUFFERCOUNT` (msg 163,00 when no integer), or
  /// `null`.
  int? bufferCount;
}

/// A `CONTRL` card (J 02.06.15–16). The load name is in the name field,
/// at most 6 characters and unique (msg 207,00).
final class ContrlCard extends EnvironmentCard {
  /// Creates the card for the area [first] (a section, sentence, or
  /// record name), optionally extended `TO` [to] — the area excludes
  /// [to] itself (J 02.06.16).
  ContrlCard(super.spec, this.first, this.to);

  /// The section, sentence, or record name opening the area.
  final Token first;

  /// The sentence name after `TO`, or `null` in the one-name forms.
  final Token? to;
}

/// An `OPTION` card (J 02.06.16–17): two independent, separately
/// scopeable slots.
final class OptionCard extends EnvironmentCard {
  /// Creates the card; option fields start at their defaults.
  OptionCard(super.spec);

  /// `COLLATE COM` — the Commercial collating sequence (J 02.06.16).
  bool collateCom = false;

  /// The section name scoping COLLATE, after `IN`, or `null` for the
  /// whole program.
  Token? collateIn;

  /// `SPACE` or `TIME` after `CONSERVE`; `null` means the TIME default
  /// (J 02.06.17).
  String? conserve;

  /// The section name scoping CONSERVE, after `IN`, or `null`.
  Token? conserveIn;
}

/// A `COND` card (J 02.06.17): console-key condition names.
final class CondCard extends EnvironmentCard {
  /// Creates the card with its normalized key [setting].
  CondCard(super.spec, this.setting);

  /// The key setting: exactly 12 octal digits after normalization —
  /// under-length settings are left-padded with zeros silently (D9.16),
  /// over-length keeps the rightmost 12 (msg 6,00), a non-octal setting
  /// becomes `'1'` wholesale (msg 7,00).
  final String setting;
}
