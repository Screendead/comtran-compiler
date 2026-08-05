/// The dictionary allocator (M3-8): the GN)nnn generated names and the
/// five-octal-digit LOC values the 1962 listing prints, from one model.
///
/// Every unnamed or name-discarded data entry takes the next generated
/// name in source order; GN)000 is reserved for the program entry and
/// prints on the first procedure sentence. The word counter starts at
/// the attested base — octal 71175, the value the sample's print
/// shows — and allocates in source order: one word per data-division
/// entry, named or generated; two per RECORD entry; one for the
/// program entry; one per CALL synonym and per procedure label.
/// Environment entries take none.
///
/// Procedure text also allocates silently: an IF takes a join label,
/// and two labels with an OTHERWISE arm; an AT END phrase takes its
/// exit and resume pair; an unlabelled END sentence takes a generated
/// name and prints it. These generated labels consume words and GN
/// numbers in source order — the sample's GN)058–083 — which is why
/// the printed label words skip (71466, 71471, 71474, …). DO-loop
/// machinery and EQU'd symbols number in a later compiler pass
/// (GN)084 on) and take no source-order word; they are M4's.
///
/// A word's value prints only for a programmer name, on the line where
/// the name completes; a GN-named entry consumes its word without
/// printing it. The whole model is a non-historical reconstruction
/// verified value-by-value against the sample's printed column and the
/// J 90.05 symbolic listing (M3-8 as amended; M3-23).
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/data_lexer.dart';
import '../lexer/procedure_lexer.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import '../listing/listing.dart';
import '../parser/parser.dart';

/// The LOC counter's start: octal 71175 (M3-8, the base the sample's
/// print shows).
const int dictionaryBase = 29309;

/// The allocator's result: the words and names, plus the print
/// annotations the listing consumes.
final class DictionaryAllocation {
  DictionaryAllocation._({
    required this.generatedNames,
    required this.dataWords,
    required this.programEntryWord,
    required this.synonymWords,
    required this.labelWords,
    required this.annotations,
  });

  /// The GN)nnn name of every unnamed or name-discarded data entry,
  /// numbered from 001 in source order (M3-8).
  final Map<DataItem, String> generatedNames;

  /// The first dictionary word of every data entry; a RECORD's two
  /// words start here.
  final Map<DataItem, int> dataWords;

  /// The program entry's word — the word the object listing labels
  /// GN)000 — or `null` when the job has no procedure sentence.
  final int? programEntryWord;

  /// One word per CALL synonym, keyed by the token that defines it.
  final Map<Token, int> synonymWords;

  /// One word per procedure label, keyed by the labelled sentence.
  final Map<Sentence, int> labelWords;

  /// The card-keyed print annotations (M3-8).
  final ListingAnnotations annotations;
}

/// Allocates the dictionary for [parse] (M3-8).
DictionaryAllocation allocateDictionary(ParseResult parse) {
  final generatedNames = <DataItem, String>{};
  final dataWords = <DataItem, int>{};
  final synonymWords = <Token, int>{};
  final labelWords = <Sentence, int>{};
  final locByCard = <int, String>{};
  final nameByCard = <int, (int, String)>{};
  int? programEntryWord;
  int word = dictionaryBase;
  var generated = 0;

  int take(int width) {
    final first = word;
    word += width;
    return first;
  }

  // Two names completing on one line would need two column values; the
  // first keeps the column (unattested corner — the sample never packs
  // two).
  void printLoc(SourceCard card, int value) {
    locByCard.putIfAbsent(card.cardNumber, () => _octal(value));
  }

  void printName(SourceCard card, String name) {
    nameByCard.putIfAbsent(card.cardNumber, () => (_gnColumn, name));
  }

  void allocateItem(DataItem item) {
    final int first = take(item.typeCode == DataTypeCode.record ? 2 : 1);
    dataWords[item] = first;
    final DataEntry entry = item.entry;
    if (entry.name.isEmpty || item.nameDiscarded) {
      generated++;
      final String name = _gnName(generated);
      generatedNames[item] = name;
      printName(entry.cards.first, name);
    } else {
      printLoc(_nameCompletionCard(entry), first);
    }
  }

  for (final ParsedGroup group in parse.groups) {
    switch (group) {
      case ParsedDataGroup(:final List<DataItem> items):
        items.forEach(allocateItem);
      case ParsedEnvironmentGroup():
        break; // Environment entries take no word (M3-8).
      case ParsedProcedureGroup(:final List<Sentence> sentences):
        if (programEntryWord == null && sentences.isNotEmpty) {
          programEntryWord = take(1);
          printName(sentences.first.scan.cards.first, 'GN)000');
        }
        for (final sentence in sentences) {
          final ProcedureSentence scan = sentence.scan;
          if (scan.label != null) {
            final int labelWord = take(1);
            labelWords[sentence] = labelWord;
            printLoc(scan.cards.first, labelWord);
          }
          for (final Clause clause in clauseTree(sentence.clauses)) {
            switch (clause) {
              case CallClause(:final pairs):
                for (final pair in pairs) {
                  final int synonymWord = take(1);
                  synonymWords[pair.newName] = synonymWord;
                  printLoc(pair.newName.card, synonymWord);
                }
              case IfClause(:final List<Clause> otherwiseArm):
                // A branch and its join: two labels with OTHERWISE, the
                // join alone without (GN)058-076, 079-082 attested;
                // J 90.05 symbolic listing).
                generated += otherwiseArm.isEmpty ? 1 : 2;
                take(otherwiseArm.isEmpty ? 1 : 2);
              case GetClause(atEnd: AtEndClause()):
                // The AT END exit and the resume point (GN)058/059
                // pattern, J 90.05 symbolic listing).
                generated += 2;
                take(2);
              case SetClause(onOverflow: Clause()) ||
                  AddClause(onOverflow: Clause()):
                // Unattested: no ON OVERFLOW survives in the sample.
                // The slot mirrors AT END structurally, so it takes
                // the same pair (recorded inference, M3-23).
                generated += 2;
                take(2);
              case EndClause() when scan.label == null:
                // An unlabelled END sentence takes a generated name
                // and prints it: GN)077, GN)078, GN)083 close the
                // sample's unlabelled sections. A labelled END prints
                // its own label's word instead (BOND.END., SEARCH.END.).
                generated++;
                final String name = _gnName(generated);
                take(1);
                printName(scan.cards.first, name);
              default:
                break;
            }
          }
        }
    }
  }
  return DictionaryAllocation._(
    generatedNames: generatedNames,
    dataWords: dataWords,
    programEntryWord: programEntryWord,
    synonymWords: synonymWords,
    labelWords: labelWords,
    annotations: ListingAnnotations(
      locByCard: locByCard,
      nameByCard: nameByCard,
    ),
  );
}

/// The card a continued name completes on: the last of the entry's
/// cards with a punched name field, columns 7–22 (M3-8 — statements
/// 3,00, 21,00, 22,00, 103,00 and 107,00 print their value on the
/// continuation line).
SourceCard _nameCompletionCard(DataEntry entry) {
  for (final SourceCard card in entry.cards.reversed) {
    for (var column = 7; column <= 22; column++) {
      if (card.isPunched(column)) {
        return card;
      }
    }
  }
  return entry.cards.first;
}

/// The print column of a generated name — card column 7, the name
/// field's start.
const int _gnColumn = 7;

String _gnName(int number) => 'GN)${number.toString().padLeft(3, '0')}';

/// Five octal digits. The value is masked to the 7090's 15-bit address
/// width first: a counter past octal 77777 wraps as the hardware
/// address field would (non-historical corner; the sample stays far
/// below it).
String _octal(int value) => (value & 0x7FFF).toRadixString(8).padLeft(5, '0');
