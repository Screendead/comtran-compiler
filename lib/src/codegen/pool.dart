/// The constant pool (M4-4 as amended): four sub-pools, filled
/// independently and concatenated in one fixed order at layout time.
///
/// The pool is not in first-need order as a whole — the first generated
/// statement references entries of three different sub-pools — so a
/// generator must emit a reference as a sub-pool and a key, and resolve
/// every `CP)+NN` after generation ends. Two constants collapse into one
/// entry exactly when they land in the same sub-pool and their keys are
/// equal: an `OCT` entry keys on its 36-bit word value, a `PZE` entry on
/// its printed symbolic operand, never the assembled bits (the sample
/// holds four all-zero `PZE` words that stay four entries).
library;

import 'dart:collection';

import 'text_model.dart';

/// The printed capacity of the constant pool ([J 90.01.05] item k):
/// the 501st entry draws msg 172 (D9.7).
const int constantPoolCapacity = 500;

/// The four sub-pools, in their frozen concatenation order (M4-4).
enum SubPool {
  /// The values written in the PROCEDURE source, plus the subscript
  /// strides: source order, after the seeds 0 and 1.
  literals,

  /// Masks, statement stamps, verb text, fills, scale and round
  /// constants: first-need order, keyed on the 36-bit word.
  machineWords,

  /// `PZE symbol±offset`, no decrement: first-need order, keyed on the
  /// printed operand.
  subscriptBases,

  /// `PZE symbol,,byte`: first-need order, keyed on the printed operand.
  descriptors,
}

/// One pool reference: a sub-pool and a key, resolved to an index by
/// [ConstantPool.layout] after generation ends.
final class PoolHandle {
  PoolHandle._(this.subPool, this.key);

  final SubPool subPool;

  /// The 36-bit word of an `OCT` entry, or the printed operand of a
  /// `PZE` entry.
  final Object key;
}

/// The pool under construction. Registration is idempotent: the first
/// call creates the entry, every call returns its handle.
final class ConstantPool {
  /// The seeded head: indices 0 and 1 hold the integers 0 and 1 ahead
  /// of every source literal (the notes, section 6.2 item 37 — pinned
  /// at the diff). The callback runs once per entry created, the seeds
  /// included: the msg 942 and 172 counters check on increment (D9.7).
  ConstantPool({this._onEntry}) {
    _literals[0] = (-1, 0);
    _literals[1] = (-1, 1);
    _onEntry?.call();
    _onEntry?.call();
  }

  final void Function()? _onEntry;

  /// Written literals, keyed on the word value; the position of the
  /// earliest source appearance orders them. The seeds sort ahead of
  /// every card and the strides behind, so a written 0 or 1 merges
  /// into its seed and a written stride value absorbs the stride.
  final Map<int, (int, int)> _literals = HashMap<int, (int, int)>();

  final LinkedHashSet<int> _machineWords = LinkedHashSet<int>();

  /// The two `PZE` sub-pools: each operand's assembled word and control
  /// group, captured at registration — a data address is fixed before
  /// generation starts, so the word never depends on the pass.
  final LinkedHashMap<String, (int, int)> _bases =
      LinkedHashMap<String, (int, int)>();
  final LinkedHashMap<String, (int, int)> _descriptors =
      LinkedHashMap<String, (int, int)>();

  /// A value the source writes at [card], [column].
  PoolHandle literal(int bits, {required int card, required int column}) {
    final at = (card, column);
    _literals.update(
      bits,
      ((int, int) first) => first.compareTo(at) <= 0 ? first : at,
      ifAbsent: () => _created(at),
    );
    return PoolHandle._(SubPool.literals, bits);
  }

  T _created<T>(T entry) {
    _onEntry?.call();
    return entry;
  }

  /// A seed's handle. The entries exist from construction; this only
  /// names one for a machinery reference (the zero build, the truth
  /// function's true value, the DO FOR unit bounds).
  PoolHandle seed(int value) {
    assert(value == 0 || value == 1, 'only 0 and 1 are seeded');
    return PoolHandle._(SubPool.literals, value);
  }

  /// A subscript stride, in words. Strides sit at the tail of the
  /// literal sub-pool, after every written literal — the attested
  /// `CP)+13`, first emitted three words ahead of the literal `CP)+8`
  /// yet laid out last.
  PoolHandle stride(int words) {
    final (int, int) at = (1 << 40, words);
    _literals.update(
      words,
      ((int, int) first) => first.compareTo(at) <= 0 ? first : at,
      ifAbsent: () => _created(at),
    );
    return PoolHandle._(SubPool.literals, words);
  }

  PoolHandle machineWord(int bits) {
    if (_machineWords.add(bits)) {
      _onEntry?.call();
    }
    return PoolHandle._(SubPool.machineWords, bits);
  }

  PoolHandle base(String operand, {required int word, required int control}) {
    _register(_bases, operand, word, control);
    return PoolHandle._(SubPool.subscriptBases, operand);
  }

  PoolHandle descriptor(
    String operand, {
    required int word,
    required int control,
  }) {
    _register(_descriptors, operand, word, control);
    return PoolHandle._(SubPool.descriptors, operand);
  }

  void _register(
    LinkedHashMap<String, (int, int)> subPool,
    String operand,
    int word,
    int control,
  ) {
    assert(
      subPool[operand] == null || subPool[operand] == (word, control),
      'one operand, two words: $operand',
    );
    subPool.putIfAbsent(operand, () => _created((word, control)));
  }

  /// Concatenates the four sub-pools and assigns every entry its index.
  PoolLayout layout() {
    final rows = <PoolRow>[
      for (final MapEntry<int, (int, int)> e
          in _literals.entries.toList()..sort(_literalOrder))
        (
          subPool: SubPool.literals,
          key: e.key,
          word: e.key,
          control: ControlGroup.constantWord,
        ),
      for (final int bits in _machineWords)
        (
          subPool: SubPool.machineWords,
          key: bits,
          word: bits,
          control: ControlGroup.constantWord,
        ),
      for (final MapEntry<String, (int, int)> e in _bases.entries)
        (
          subPool: SubPool.subscriptBases,
          key: e.key,
          word: e.value.$1,
          control: e.value.$2,
        ),
      for (final MapEntry<String, (int, int)> e in _descriptors.entries)
        (
          subPool: SubPool.descriptors,
          key: e.key,
          word: e.value.$1,
          control: e.value.$2,
        ),
    ];
    return PoolLayout._(rows, <(SubPool, Object), int>{
      for (var i = 0; i < rows.length; i++) (rows[i].subPool, rows[i].key): i,
    });
  }

  /// Seeds first, written literals by source position, strides last —
  /// the three position-marker zones.
  static int _literalOrder(
    MapEntry<int, (int, int)> a,
    MapEntry<int, (int, int)> b,
  ) => a.value.compareTo(b.value);
}

extension on (int, int) {
  int compareTo((int, int) other) {
    final int cards = $1.compareTo(other.$1);
    return cards != 0 ? cards : $2.compareTo(other.$2);
  }
}

/// One laid-out entry: an `OCT` entry's key is its word, a `PZE`
/// entry's key is its printed operand.
typedef PoolRow = ({SubPool subPool, Object key, int word, int control});

/// The laid-out pool: every handle's `CP)+NN` index.
final class PoolLayout {
  PoolLayout._(this.rows, this._indices);

  /// The entries in layout order; `CP)+NN` is the list index.
  final List<PoolRow> rows;

  final Map<(SubPool, Object), int> _indices;

  int get length => rows.length;

  /// The index `CP)+NN` prints for [handle].
  int indexOf(PoolHandle handle) => _indices[(handle.subPool, handle.key)]!;
}
