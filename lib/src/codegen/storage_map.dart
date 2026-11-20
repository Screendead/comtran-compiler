/// The `*DATA` storage-map print (M4-7; the values are M3-14's): the
/// counter head, then one `OCT` per initialized word and one `BSS n` per
/// uninitialized run, over the transmitted areas in program order.
///
/// Location Counter 1's head — `USE 1` and `BGN 2,PI)1` — is not here.
/// Both carry the counter-1 origin, which sits after the procedure text,
/// so `counterHead` builds them once the text is placed.
library;

import '../data/data_map.dart';
import '../loader/control_group.dart';
import 'text_model.dart';

/// The transmitted-data region of [semantics], from `USE 0` through the
/// last word of the last area.
List<AssemblyUnit> storageMapUnits(SemanticResult semantics) {
  final units = <AssemblyUnit>[
    AssemblyUnit(
      operation: 'USE',
      operand: '0',
      word: counterWord(CounterOp.relativeOrigin, 0),
      control: ControlGroup.locationCounter,
      form: WordForm.prefix,
    ),
    AssemblyUnit(
      operation: 'BSS',
      operand: '0',
      location: 0,
      labels: const <String>['*DATA'],
      word: counterWord(CounterOp.fixedReservation, 0),
      control: ControlGroup.locationCounter,
      form: WordForm.prefix,
    ),
  ];
  for (final StorageRun run in storageRuns(semantics.areas)) {
    final labels = run.symbol.isEmpty ? const <String>[] : <String>[run.symbol];
    final int? word = run.word;
    units.add(
      word != null
          ? AssemblyUnit(
              operation: 'OCT',
              operand: word.toRadixString(8).padLeft(12, '0'),
              location: run.location,
              labels: labels,
              word: word,
              control: ControlGroup.constantWord,
            )
          : AssemblyUnit(
              operation: 'BSS',
              operand: '${run.words}',
              location: run.location,
              labels: labels,
              word: counterWord(CounterOp.fixedReservation, run.words),
              control: ControlGroup.locationCounter,
              form: WordForm.prefix,
            ),
    );
  }
  return units;
}
