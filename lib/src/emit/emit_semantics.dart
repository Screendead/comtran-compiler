/// The `--emit-semantics` dump (`docs/design/emit-stages.md`): the
/// semantic layer of every job, as a labeled reconstruction.
///
/// Eight sections per job. STORAGE prints the M3-14 fixture columns —
/// octal LOC, `oct` or `bss`, the word value or the reservation count,
/// and the symbol — whose values the 1962 object listing attests
/// (J 90.05, PDF pp. 199–200); DICTIONARY, RECORDS, ITEMS, and the
/// resolver's four — RESOLUTIONS, CORRESPONDING, KEYS, DELETED — have
/// no attested form at all. Every section prints its header line even
/// with no row under it: a debugger must read "none" apart from "not
/// dumped".
library;

import '../ast/data_ast.dart';
import '../ast/procedure_ast.dart';
import '../data/data_map.dart';
import '../data/dictionary.dart';
import '../data/pictorial.dart';
import '../driver/driver.dart';
import '../lexer/front_end.dart';
import '../lexer/token.dart';
import 'common.dart';

/// Renders the semantic layer of every job on [deck], in deck order.
///
/// A job whose semantic pass an earlier stop kept from running prints
/// [stageNotReached] as its whole section; a pass that stopped mid-run
/// ends its section with [stageStopped], the sections above it holding
/// only what the phase built before the stop (D10.2).
String emitSemantics(DeckCompilation deck) {
  final out = StringBuffer()..writeln(reconstructionLabel);
  for (final (int index, JobCompilation job) in deck.jobs.indexed) {
    if (index > 0) {
      out.writeln();
    }
    out.writeln(jobHeader(index + 1));
    final SemanticResult? semantics = job.semantics;
    if (semantics == null) {
      out.writeln(stageNotReached);
      continue;
    }
    _storage(out, semantics);
    out.writeln();
    _dictionary(out, semantics, job.frontEnd);
    out.writeln();
    _records(out, semantics);
    out.writeln();
    _items(out, semantics);
    out.writeln();
    _resolutions(out, semantics, job.frontEnd);
    out.writeln();
    _corresponding(out, semantics, job.frontEnd);
    out.writeln();
    _keys(out, semantics, job.frontEnd);
    out.writeln();
    _deleted(out, semantics, job.frontEnd);
    if (semantics.stopped) {
      out.writeln(stageStopped);
    }
  }
  return out.toString();
}

/// The M3-14 fixture rows: one `oct` row per initialized word, one
/// `bss` row per maximal uninitialized run. LOCs are cumulative word
/// offsets across the areas in program order, and a run never crosses
/// an area boundary — each area opens a row of its own, carrying its
/// name as the symbol.
void _storage(StringBuffer out, SemanticResult semantics) {
  out.writeln('* STORAGE');
  var loc = 0;
  for (final AreaInfo area in semantics.areas) {
    String symbol = area.name;
    var i = 0;
    while (i < area.words.length) {
      final int? word = area.words[i];
      if (word != null) {
        out.writeln(
          _row(loc + i, 'oct', word.toRadixString(8).padLeft(12, '0'), symbol),
        );
        i++;
      } else {
        var run = 0;
        while (i + run < area.words.length && area.words[i + run] == null) {
          run++;
        }
        out.writeln(_row(loc + i, 'bss', '$run', symbol));
        i += run;
      }
      symbol = '';
    }
    loc += area.extentWords;
  }
}

String _row(int loc, String kind, String value, String symbol) => <String>[
  loc.toRadixString(8).padLeft(5, '0'),
  kind,
  value,
  if (symbol.isNotEmpty) symbol,
].join('\t');

void _dictionary(
  StringBuffer out,
  SemanticResult semantics,
  FrontEndResult frontEnd,
) {
  out.writeln('* DICTIONARY');
  for (final DictionaryEntry entry in semantics.dictionary.entries) {
    final DataItem? item = entry.item;
    final int? card = entry.sentence?.scan.cards.first.cardNumber;
    final String? statement = card == null
        ? null
        : frontEnd.statementNumberByCard[card];
    out.writeln(
      <String>[
        entry.name,
        'kind=${entry.kind.name}',
        'encounter=${entry.encounter}',
        if (item != null) 'item=${_qualifiedName(item)}',
        if (statement != null) 'statement=$statement',
        if (entry.section != null) 'section=${entry.section}',
      ].join('\t'),
    );
  }
}

void _records(StringBuffer out, SemanticResult semantics) {
  out.writeln('* RECORDS');
  for (final RecordInfo record in semantics.records) {
    out.writeln(
      <String>[
        record.name,
        'located=${_yesNo(record.located)}',
        'variable=${_yesNo(record.variable)}',
        'forced-transmit=${_yesNo(record.forcedTransmit)}',
        if (record.inputFiles.isNotEmpty)
          'input=${record.inputFiles.join(',')}',
        if (record.outputFiles.isNotEmpty)
          'output=${record.outputFiles.join(',')}',
      ].join('\t'),
    );
  }
}

/// Every item's semantic record, program order. `word` and `byte` are
/// the offsets inside the item's own space root (J 90.02.05
/// granularity), not the absolute LOCs of the storage section above.
void _items(StringBuffer out, SemanticResult semantics) {
  out.writeln('* ITEMS');
  for (final MapEntry<DataItem, ItemSemantics> entry
      in semantics.semantics.entries) {
    final DataItem item = entry.key;
    final ItemSemantics sem = entry.value;
    final Token? pictorial = item.pictorial;
    final Pictorial? shape = sem.shape;
    final DataItem? root = sem.spaceRoot;
    final flags = <String>[
      if (sem.doublePrecision) 'double',
      if (sem.variableLength) 'variable',
      if (sem.dropped) 'dropped',
      if (sem.constantSuppressed) 'constant-suppressed',
    ];
    out.writeln(
      <String>[
        _qualifiedName(item),
        'class=${sem.fieldClass.name}',
        'word=${sem.word}',
        'byte=${sem.byte}',
        'chars=${sem.storageChars}',
        'qty=${sem.quantity}',
        'stride=${sem.strideChars}',
        'extent=${sem.extentChars}',
        'digits=${sem.digits}',
        'frac=${sem.fractionDigits}',
        'just=${sem.justification.name}',
        if (pictorial != null) 'pic=${pictorial.text}',
        if (shape != null && shape.sign != SignConvention.none)
          'sign=${shape.sign.name}',
        if (root != null) 'root=${_qualifiedName(root)}',
        if (flags.isNotEmpty) 'flags=${flags.join(',')}',
      ].join('\t'),
    );
  }
}

/// Every resolved data reference (M3-17), map order: where the
/// reference stands, the name as punched, and the item it binds to.
void _resolutions(
  StringBuffer out,
  SemanticResult semantics,
  FrontEndResult frontEnd,
) {
  out.writeln('* RESOLUTIONS');
  for (final MapEntry<NameReference, DataItem> entry
      in semantics.dataResolutions.entries) {
    final NameReference reference = entry.key;
    out.writeln(
      <String>[
        _number(frontEnd, reference.anchor.card.cardNumber),
        '${reference.text} -> ${_qualifiedName(entry.value)}',
      ].join('\t'),
    );
  }
}

/// The matched pairs of every MOVE or ADD CORRESPONDING clause (D4.12),
/// source first: a header row per clause, then one indented row per
/// pair. A clause whose search matched nothing prints its header row
/// alone.
void _corresponding(
  StringBuffer out,
  SemanticResult semantics,
  FrontEndResult frontEnd,
) {
  out.writeln('* CORRESPONDING');
  for (final MapEntry<Clause, List<(DataItem, DataItem)>> entry
      in semantics.correspondingPairs.entries) {
    out.writeln(_clauseNumber(frontEnd, entry.key));
    for (final (DataItem source, DataItem target) in entry.value) {
      out.writeln('  ${_qualifiedName(source)} -> ${_qualifiedName(target)}');
    }
  }
}

/// The condition references that resolve to an Environment COND card —
/// the console-key test (J 02.06.17). They resolve to no data item, so
/// the RESOLUTIONS section above holds none of them.
void _keys(
  StringBuffer out,
  SemanticResult semantics,
  FrontEndResult frontEnd,
) {
  out.writeln('* KEYS');
  for (final NameReference reference in semantics.keysConditions) {
    out.writeln(
      <String>[
        _number(frontEnd, reference.anchor.card.cardNumber),
        reference.text,
      ].join('\t'),
    );
  }
}

/// The sentences msg 177 deleted from the text (M3-20). Each keeps its
/// statement number, which is all the deletion leaves to print.
void _deleted(
  StringBuffer out,
  SemanticResult semantics,
  FrontEndResult frontEnd,
) {
  out.writeln('* DELETED');
  for (final Sentence sentence in semantics.capacityDeletedSentences) {
    out.writeln(_number(frontEnd, sentence.scan.cards.first.cardNumber));
  }
}

/// The clause's `n,cc` number: its statement number with the clause
/// digits in place of `00`, the substitution the listing makes for a
/// clause-confined diagnostic (M2-6). A clause the parser never
/// numbered keeps `n,00`.
String _clauseNumber(FrontEndResult frontEnd, Clause clause) {
  final String statement = _number(frontEnd, clause.anchor.card.cardNumber);
  if (clause.clause == 0 || !statement.endsWith(',00')) {
    return statement;
  }
  final String digits = clause.clause.toString().padLeft(2, '0');
  return statement.substring(0, statement.length - 2) + digits;
}

/// The card's statement number, or `9999,99` when the front end
/// numbered no card of its unit — a stopped scan (J 02.02.01; D9.5).
String _number(FrontEndResult frontEnd, int card) =>
    frontEnd.statementNumberByCard[card] ?? '9999,99';

String _yesNo(bool value) => value ? 'yes' : 'no';

/// The reference that names [item] in full, general to specific —
/// qualification is blank-separated (D2.5), and a punched name can
/// itself hold periods. An entry with no name of its own, a discarded
/// REDEF name included (D3.4), ends the chain with `-`: the GN name
/// that replaces it is stage 3's.
String _qualifiedName(DataItem item) {
  final List<String> names = <String>[
    for (final DataItem each in ancestorsOf(item))
      if (each.entry.name.isNotEmpty && !each.nameDiscarded) each.entry.name,
  ].reversed.toList();
  if (item.entry.name.isEmpty || item.nameDiscarded) {
    names.add('-');
  }
  return names.join(' ');
}
