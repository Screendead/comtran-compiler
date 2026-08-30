/// The loader symbolic control cards the compiler punches (M4-16; LD-1):
/// a `*FILE` and a `*SPEC` card per file, filled from the Environment
/// FILE and SPECIF cards by the [J 90.08] derivations, and the `*CTEXT`
/// and `*CTEND` cards that bracket the binary deck ([J 03.02.09]).
///
/// Each builder returns the card's columns 1 to 72 as text, trailing
/// blanks trimmed. The deck writer adds the serial in columns 73 to 80.
library;

import '../ast/environment_ast.dart';
import '../codegen/procedure.dart' show UnrecoveredShape;
import '../parser/parser.dart';

/// The FILE cards of [parse] in declaration order, every card of a name
/// after its first dropped. The file number `k` is a card's one-based
/// index here, and the calling sequences address the file as
/// `04000 + k` (the notes, section 2.6).
List<FileCard> numberedFiles(ParseResult parse) {
  final files = <String, FileCard>{};
  for (final FileCard card in fileCards(parse)) {
    files.putIfAbsent(card.spec.name, () => card);
  }
  return files.values.toList();
}

/// Every FILE card of [parse], in source order.
Iterable<FileCard> fileCards(ParseResult parse) => parse.groups
    .whereType<ParsedEnvironmentGroup>()
    .expand((ParsedEnvironmentGroup group) => group.cards)
    .whereType<FileCard>();

/// The `*FILE` and `*SPEC` pair of every numbered file, deck order.
///
/// The first SPECIF card that names a file supplies its options; a file
/// no SPECIF card names takes every default ([J 02.06.07]: SPECIF cards
/// "are not necessary for correct compilation").
List<String> controlCards(ParseResult parse) {
  final String deckName = parse.compileCard?.deckName ?? '';
  final specifs = <String, SpecifCard>{};
  for (final ParsedEnvironmentGroup group
      in parse.groups.whereType<ParsedEnvironmentGroup>()) {
    for (final SpecifCard card in group.cards.whereType<SpecifCard>()) {
      final String? name = card.fileName?.text;
      if (name != null) {
        specifs.putIfAbsent(name, () => card);
      }
    }
  }
  final out = <String>[];
  for (final (int index, FileCard file) in numberedFiles(parse).indexed) {
    final SpecifCard? specif = specifs[file.spec.name];
    out
      ..add(fileControlCard(deckName, index + 1, file, specif))
      ..add(specControlCard(deckName, index + 1, file, specif));
  }
  return out;
}

/// The `*FILE` card of file [number] ([J 90.08.01]; [J 03.02.02]).
///
/// The file name punches at column 55, where the 90.05 print puts it
/// and where [J 03.02.02] puts it; [J 90.08.01]'s "54-72" loses to the
/// artifact (LD-1). A quoted literal punches left-aligned in its field
/// and a number right-aligned, the two alignments the print attests.
String fileControlCard(
  String deckName,
  int number,
  FileCard file,
  SpecifCard? specif,
) {
  if (specif != null && specif.seq) {
    _unruled('a SPECIF SEQ option (no attested *FILE character; J 90.08.01)');
  }
  if (specif != null && specif.cksums) {
    _unruled(
      'a SPECIF CKSUMS option (no attested *FILE character; J 90.08.01)',
    );
  }
  // A checkpoint file has no type character: [J 90.08.01] lists the
  // three I/O usages only, and column 35 marks the file (D7.2; LD-1).
  final String type = switch (file.direction) {
    FileDirection.input => 'I',
    FileDirection.output => file.holdOrSpans ? 'T' : 'P',
    FileDirection.checkpoint => '',
  };
  final String? labels = specif?.labels;
  // Reel control: a label search needs OPENF on a labeled file; the
  // multi-reel mark is for an unlabeled file.
  final String reelControl = switch (specif) {
    SpecifCard(openF: true) when labels != null => 'L',
    SpecifCard(multi: true) when labels == null => 'M',
    _ => '',
  };
  final String labelDensity = switch (specif?.labelDensity) {
    _ when labels == null => '',
    'HIGH' => 'H',
    'LOW' => 'L',
    _ => 'S',
  };
  // Column 35 needs the FILE type and the SPECIF option together (D7.2).
  final String checkpoint = switch (specif?.checkpoint) {
    'CHECKC' when file.direction == FileDirection.checkpoint => 'C',
    'CHECKF' when file.direction == FileDirection.output && labels != null =>
      'F',
    _ => '',
  };
  return (_Card()
        ..put(1, deckName)
        ..put(7, '*FILE')
        ..put(14, _twoDigits(number))
        ..put(17, specif?.defer ?? false ? '' : '*')
        ..put(18, specif?.unit1 ?? '')
        ..put(22, specif?.unit2 ?? '')
        ..put(28, type)
        ..put(29, reelControl)
        ..put(30, specif?.density == 'LOW' ? 'L' : 'H')
        ..put(31, file.binary ? 'B' : 'D')
        ..put(32, labelDensity)
        ..put(35, checkpoint)
        ..put(38, specif?.reel ?? '')
        ..put(44, specif?.serial ?? '')
        ..putRight(53, specif?.retain ?? '')
        ..put(55, file.spec.name))
      .toString();
}

/// The `*SPEC` card of file [number] ([J 90.08.02]; [J 03.02.05]).
///
/// The blocksize is the FILE card's, right-justified in four columns
/// (D7.1); a value past 9999, which msg 931 rejected, leaves the field
/// blank rather than overrun it. Where [J 90.08.02] allows "R or blank"
/// the compiler punches `R`, as the attested CLOSER case shows it did
/// (LD-1).
String specControlCard(
  String deckName,
  int number,
  FileCard file,
  SpecifCard? specif,
) {
  final String close = switch (specif?.closeMode) {
    'CLOSEW' => 'N',
    'CLOSER' => 'R',
    _ => 'U',
  };
  final String blocksize = switch (file.blocksize) {
    final int words when words <= 9999 => '$words',
    _ => '',
  };
  return (_Card()
        ..put(1, deckName)
        ..put(7, '*SPEC')
        ..put(14, _twoDigits(number))
        ..putRight(20, blocksize)
        ..putRight(23, specif?.activity?.toString() ?? '')
        ..put(25, specif?.openW ?? false ? 'N' : 'R')
        ..put(27, close))
      .toString();
}

/// A `*CTEXT` or `*CTEND` card ([J 03.02.09]): [name] at column 7, the
/// date and time at columns 26 to 48 in the form the 90.05 print
/// attests — `DATE 101861 TIME   2.45`, the date's separators dropped
/// and the time right-aligned ending at column 48 — and the compile
/// card's secondary identifier at column 55.
String textBracketCard(
  String name, {
  required String deckName,
  required String secondaryIdentifier,
  required String date,
  required String time,
}) =>
    (_Card()
          ..put(1, deckName)
          ..put(7, name)
          ..put(26, 'DATE')
          ..put(31, date.replaceAll('/', ''))
          ..put(38, 'TIME')
          ..putRight(48, time)
          ..put(55, secondaryIdentifier))
        .toString();

String _twoDigits(int number) => number.toString().padLeft(2, '0');

Never _unruled(String what) => throw UnrecoveredShape(what);

/// Columns 1 to 72 of one card under construction.
final class _Card {
  final List<String> _columns = List<String>.filled(72, ' ');

  /// Writes [text] from [column] rightwards.
  void put(int column, String text) {
    for (var i = 0; i < text.length; i++) {
      _columns[column - 1 + i] = text[i];
    }
  }

  /// Writes [text] so that its last character lands on [column].
  void putRight(int column, String text) => put(column - text.length + 1, text);

  @override
  String toString() => _columns.join().trimRight();
}
