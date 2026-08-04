/// The data mapper (M3 stage 1): the six-way field classifier (M3-4),
/// pictorial measurement (M3-5), and the storage allocator (M3-6).
///
/// The allocator replays the 1962 storage assignment counter over the
/// entries in source order ([J 02.05.04]; D3.4's save/restore rule for
/// REDEF). Offsets are relative to each top-level item's space; M4
/// binds spaces to object addresses (M3-6).
library;

import '../ast/data_ast.dart';
import '../lexer/data_lexer.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'pictorial.dart';

/// One open hierarchy level during the allocation walk.
final class _Frame {
  _Frame(this.item, this.spaceRoot, this.startChar) : endChar = startChar;

  final DataItem item;
  final DataItem? spaceRoot;
  final int startChar;

  /// The furthest character reached in [spaceRoot]'s space.
  int endChar;

  /// Set for a nested LABEL frame: the cursor to restore on close —
  /// the label area is the IOCS's, not the program's (J 02.05.03).
  (DataItem?, int)? labelResume;
}

/// An active redefinition: the head item allocating over the target,
/// and the cursor to restore on level termination (J 02.05.02; D3.4).
final class _Redef {
  _Redef(this.head, this.savedRoot, this.savedChar);

  final DataItem head;
  final DataItem? savedRoot;
  final int savedChar;
}

/// Classifies and allocates one job's data division.
final class DataMapper {
  DataMapper(this.diagnostics, this.environmentNames, {this.pedantic = false});

  final List<Diagnostic> diagnostics;

  /// The Environment specification names, for msg 46's stage-1 case (a
  /// REDEF or QUANTITY IN naming a file).
  final Set<String> environmentNames;

  final bool pedantic;

  /// Every item's semantic record, identity-keyed.
  final Map<DataItem, ItemSemantics> semantics = Map.identity();

  /// All items, source order across the job's data groups.
  final List<DataItem> items = [];

  /// Redefinition links, (redefined target, redefinition head) — the
  /// binder's REDEF-sharing evidence (J 02.07.05).
  final List<(DataItem, DataItem)> redefLinks = [];

  /// The roots owning storage spaces, source order; a root absent here
  /// is an overlay head or a LABEL tree.
  final List<DataItem> spaceRoots = [];

  /// Per-root storage extent in characters, filled as roots close.
  final Map<DataItem, int> rootExtent = Map.identity();

  final Map<DataItem, int> _index = Map.identity();
  final Map<String, List<DataItem>> _byName = {};
  int _minLevel = 100;

  /// The items declared under [name], source order.
  List<DataItem> itemsNamed(String name) => _byName[name] ?? const [];

  /// Classifies every item and allocates storage.
  void map(List<List<DataItem>> groups) {
    groups.forEach(items.addAll);
    for (final (int i, DataItem item) in items.indexed) {
      _index[item] = i;
      final int? level = item.entry.level;
      if (level != null && level < _minLevel) {
        _minLevel = level;
      }
      if (item.entry.name.isNotEmpty && !item.nameDiscarded) {
        _byName.putIfAbsent(item.entry.name, () => []).add(item);
      }
    }
    items.forEach(_classify);
    for (final DataItem item in items.reversed) {
      // Children follow their parent in card order, so the reverse
      // walk sums each group's subfields after they are known (D3.3).
      final ItemSemantics sem = semantics[item]!;
      if (sem.fieldClass == FieldClass.group) {
        var sum = 0;
        for (final DataItem child in _storageChildren(item)) {
          final ItemSemantics childSem = semantics[child]!;
          sum += childSem.charLength * childSem.quantity;
        }
        sem.charLength = sum;
      }
    }
    items.forEach(_positionAdvisory);
    _allocate();
  }

  // ── Classification (M3-4, M3-5) ──────────────────────────────────

  void _classify(DataItem item) {
    final sem = ItemSemantics(item);
    semantics[item] = sem;
    final DataEntry entry = item.entry;

    if (item.parent != null) {
      final ItemSemantics parent = semantics[item.parent]!;
      final int i = _index[item]!;
      final bool redefinitionHead =
          i > 0 && items[i - 1].typeCode == DataTypeCode.redef;
      if (parent.dropped) {
        sem.dropped = true;
      } else if (_isFormattedLeafEntry(item.parent!) &&
          item.typeCode != DataTypeCode.cond &&
          item.typeCode != DataTypeCode.redef &&
          !redefinitionHead) {
        // Only a COND may appear below a formatted field (J 02.05.06).
        // A REDEF marker is a directive, not sub-organization — the
        // parser attaches it under whatever entry precedes it — and
        // the entry after one is the redefinition's head, not a
        // subfield. The diagnosed subordinate reserves no storage.
        diagnostics.reportAt(
          msgFormatLevelSubOrganization,
          entry.cards.first,
          operands: [item.parent!.entry.name],
        );
        sem.dropped = true;
      }
    }

    switch (item.typeCode) {
      case DataTypeCode.cond:
        sem.fieldClass = FieldClass.condition;
        if (entry.quantityText.isNotEmpty) {
          // A condition names a value, never storage (F pp. 71-72).
          diagnostics.reportAt(
            msgCondCannotHaveQuantity,
            entry.cards.first,
            column: 31,
          );
        }
        return;
      case DataTypeCode.redef:
        sem.fieldClass = FieldClass.redefinition;
        return;
      case DataTypeCode.copy:
        // Refused at M2 with msg 110 (D9.8); no storage.
        sem.dropped = true;
        return;
      case DataTypeCode.label:
        if (entry.quantityText.isNotEmpty) {
          diagnostics.reportAt(
            msgLabelCannotHaveQuantity,
            entry.cards.first,
            column: 31,
          );
        }
      case DataTypeCode.rcdmrk:
      case DataTypeCode.record:
      case DataTypeCode.none:
      case null:
        break;
    }

    final Pictorial? shape = _shapeOf(item);
    sem.shape = shape;
    final List<DataItem> storageChildren = _storageChildren(item);
    final internalMode = entry.modeText == 'I';

    if (shape != null) {
      // The pictorial wins even over subordinates: they are the msg 36
      // case above and reserve no storage.
      _classifyFormatted(sem, shape, internalMode);
    } else if (item.constant != null) {
      // A literal-only entry: an alphameric constant of the literal's
      // length (J 02.05.06; the attested TABLE form, M3-7).
      sem
        ..fieldClass = FieldClass.alphameric
        ..storageChars = item.constant!.text.length;
    } else if (storageChildren.isNotEmpty) {
      sem.fieldClass = FieldClass.group;
    } else if (item.typeCode == DataTypeCode.rcdmrk) {
      // The compiler supplies the single-A pictorial (J 02.05.03).
      sem
        ..fieldClass = FieldClass.alphameric
        ..shape = Pictorial.tryParse('A')
        ..storageChars = 1;
    } else {
      // No pictorial, no constant, no subfields — including a record
      // whose only content is a REDEF, which gives it no length
      // (J 02.05.01).
      diagnostics.reportAt(
        msgDataItemWithoutLength,
        entry.cards.first,
        operands: [entry.name],
      );
    }

    _effectiveQuantity(sem);
    _checkQuantityDepth(item, sem);
    _effectiveJustification(sem);
    if (sem.fieldClass == FieldClass.internalDecimal) {
      if (sem.justification == Justification.right && sem.digits > 21) {
        // The register form's two words hold at most 21 digits
        // (10^21 - 1 < 2^70); the clamped format is used.
        diagnostics.reportAt(
          msgNumericLengthExceededInField,
          entry.cards.first,
          column: item.pictorial?.column,
          operands: [entry.name],
        );
        sem.digits = 21;
      }
      sem.storageChars = _internalChars(sem);
    }
    if (sem.fieldClass != FieldClass.group) {
      sem.charLength = sem.storageChars;
    }

    if (pedantic &&
        entry.quantityText.isNotEmpty &&
        entry.name.isEmpty &&
        !item.nameDiscarded &&
        !_hasNamedDescendant(item)) {
      // "quantity numbers should not be assigned to data items not
      // having names, unless these items include named items at a
      // lower level" (F p. 77; J 02.05.04; Open Question 18).
      diagnostics.reportAt(
        msgQuantityOnUnnamedEntry,
        entry.cards.first,
        column: 31,
      );
    }
  }

  void _classifyFormatted(ItemSemantics sem, Pictorial shape, bool internal) {
    final DataEntry entry = sem.item.entry;
    void conflict(Message message) {
      // The 'NAME.1' slot always takes a name; the catalog prints
      // formats unquoted beside the name (msgs 25, 84).
      diagnostics.reportAt(
        message,
        entry.cards.first,
        column: sem.item.pictorial?.column,
        operands: [entry.name],
      );
    }

    sem
      ..digits = shape.valueDigits
      ..fractionDigits = shape.fractionDigits
      ..sign = shape.sign
      ..storageChars = shape.storageChars;
    if (shape.zeroCountRepaired) {
      diagnostics.reportAt(
        msgZeroCountInPictorial,
        entry.cards.first,
        column: sem.item.pictorial?.column,
      );
    }

    if (shape.alphamericCount > 0) {
      sem.fieldClass = FieldClass.alphameric;
      if (shape.hasEditCharacters ||
          shape.sCount > 0 ||
          shape.hasV ||
          shape.fCount > 0 ||
          sem.item.blankWhenZero) {
        conflict(msgIllegalFormatCombination);
      } else if (shape.digitCount > 0 && pedantic) {
        // The attested silent downgrade of a mixed A/9 pictorial
        // (J 90.01.03); --pedantic notes it (M3-13).
        diagnostics.reportAt(
          msgMixedPictorialDowngraded,
          entry.cards.first,
          column: sem.item.pictorial?.column,
        );
      }
      return;
    }
    if (shape.fCount > 0) {
      if (internal) {
        final bool double = shape.fCount >= 2;
        sem
          ..fieldClass = FieldClass.floatingPoint
          ..doublePrecision = double
          ..storageChars = double ? 12 : 6;
        return;
      }
      if (shape.fCount >= 2) {
        // FF under mode E: a conflict the chart does not define; the
        // pictorial's format is used (M3-4).
        conflict(msgModeDescriptionConflict);
        sem
          ..fieldClass = FieldClass.floatingPoint
          ..doublePrecision = true
          ..storageChars = 12;
        return;
      }
      if (shape.hasNonScientificEdit) {
        conflict(msgIllegalFormatCombination);
        sem.fieldClass = FieldClass.alphameric;
        return;
      }
      sem.fieldClass = FieldClass.scientificDecimal;
      if (shape.fractionDigits > 16) {
        // "The maximum fractional portion of a scientific decimal
        // field is 16 digits" ([J 02.05.05] note 4).
        conflict(msgNumericLengthExceededInField);
        sem.fractionDigits = 16;
      }
      return;
    }
    if (shape.hasEditCharacters || sem.item.blankWhenZero) {
      if (internal) {
        conflict(msgModeDescriptionConflict);
      }
      sem
        ..fieldClass = FieldClass.edited
        ..doublePrecision = shape.valueDigits > 10;
      return;
    }
    if (shape.digitCount > 0 || shape.sCount > 0) {
      if (internal &&
          (shape.sign == SignConvention.overpunchMinus ||
              shape.sign == SignConvention.overpunchPlus)) {
        // An overpunch states a BCD sign form; under mode I the chart
        // defines no meaning, so the external reading is used (M3-4).
        conflict(msgModeDescriptionConflict);
        sem.fieldClass = FieldClass.externalDecimal;
      } else {
        sem.fieldClass = internal
            ? FieldClass.internalDecimal
            : FieldClass.externalDecimal;
      }
      sem.doublePrecision = shape.valueDigits > 10;
      return;
    }
    // Only V or S-free counts: nothing reserves storage; the item
    // falls to the zero-length diagnosis at allocation.
    sem.fieldClass = FieldClass.externalDecimal;
  }

  Pictorial? _shapeOf(DataItem item) {
    final Token? token = item.pictorial;
    if (token != null) {
      return Pictorial.tryParse(token.text);
    }
    // The msg 133 form: a would-be pictorial whose count has no right
    // parenthesis reads as a name at M2; the mapper reclaims it.
    final Token? stray = item.targetName;
    if (stray != null) {
      final Pictorial? shape = Pictorial.tryParse(
        stray.text,
        allowUnclosedCount: true,
      );
      if (shape != null && shape.missingRightParen) {
        diagnostics.report(msgNoRightParenthesis, stray);
        return shape;
      }
    }
    return null;
  }

  bool _isFormattedLeafEntry(DataItem item) {
    if (item.typeCode == DataTypeCode.cond ||
        item.typeCode == DataTypeCode.redef ||
        item.typeCode == DataTypeCode.copy) {
      return false;
    }
    return item.pictorial != null || item.constant != null;
  }

  List<DataItem> _storageChildren(DataItem item) => [
    for (final DataItem child in item.children)
      // COPY is tested by type code because a parent classifies before
      // its children carry a semantic record.
      if (child.typeCode != DataTypeCode.cond &&
          child.typeCode != DataTypeCode.redef &&
          child.typeCode != DataTypeCode.copy &&
          !(semantics[child]?.dropped ?? false))
        child,
  ];

  void _effectiveQuantity(ItemSemantics sem) {
    final DataEntry entry = sem.item.entry;
    if (sem.item.typeCode == DataTypeCode.record) {
      return; // Quantity at record level is an M2 coding conflict.
    }
    final int? quantity = entry.quantity;
    if (quantity != null && quantity >= 1 && quantity <= 32767) {
      sem.quantity = quantity;
    }
    if (sem.item.quantityInName != null) {
      sem.variableLength = true;
      if (entry.quantityText.isEmpty) {
        // Storage is reserved for the maximum; with none stated, one
        // (J 02.05.07).
        diagnostics.reportAt(
          msgQuantityAssumedOne,
          entry.cards.first,
          column: 31,
        );
      }
    }
  }

  void _effectiveJustification(ItemSemantics sem) {
    final DataEntry entry = sem.item.entry;
    final bool topLevel = sem.item.parent == null || entry.level == _minLevel;
    final Justification fallback = topLevel
        ? Justification.left
        : Justification.packed;
    switch (entry.justifyText) {
      case 'L':
        sem.justification = Justification.left;
      case 'R':
        if (sem.shape != null && sem.fieldClass != FieldClass.group) {
          sem.justification = Justification.right;
        } else if (sem.fieldClass == FieldClass.group) {
          // R is effective only with an explicitly described format
          // (J 02.05.04; D3.5).
          diagnostics.reportAt(
            msgGroupCannotJustifyRight,
            entry.cards.first,
            column: 37,
          );
          sem.justification = fallback;
        } else {
          if (pedantic) {
            diagnostics.reportAt(
              msgIneffectiveRightJustification,
              entry.cards.first,
              column: 37,
            );
          }
          sem.justification = fallback;
        }
      default:
        sem.justification = fallback;
    }
  }

  int _internalChars(ItemSemantics sem) {
    if (sem.justification == Justification.right) {
      // The register form: the field appears by itself in a full word,
      // two if double precision (J 02.05.04).
      return sem.doublePrecision ? 12 : 6;
    }
    if (sem.digits == 0) {
      return 0;
    }
    // "The least multiple of 6 bits sufficient to contain the number
    // and its sign" (J 02.05.04).
    final int bits =
        (BigInt.from(10).pow(sem.digits) - BigInt.one).bitLength + 1;
    return (bits + 5) ~/ 6;
  }

  bool _hasNamedDescendant(DataItem item) => item.children.any(
    (DataItem child) =>
        (child.entry.name.isNotEmpty && !child.nameDiscarded) ||
        _hasNamedDescendant(child),
  );

  void _positionAdvisory(DataItem item) {
    if (item.typeCode != DataTypeCode.redef &&
        item.typeCode != DataTypeCode.label) {
      return;
    }
    final int i = _index[item]!;
    if (i == 0 || i + 1 >= items.length) {
      return;
    }
    final ItemSemantics prev = semantics[items[i - 1]]!;
    final ItemSemantics next = semantics[items[i + 1]]!;
    if (prev.fieldClass == FieldClass.group &&
        next.fieldClass != FieldClass.group &&
        next.shape != null) {
      // The message states its own criterion (D9.11: criterion
      // attested, severity ours).
      diagnostics.reportAt(msgRedefBetweenLevels, item.entry.cards.first);
    }
  }

  // ── Allocation (M3-6) ────────────────────────────────────────────

  DataItem? _cursorRoot;
  int _cursorChar = 0;
  final List<_Frame> _frames = [];
  _Redef? _redef;
  DataItem? _pendingRedefTarget;
  final Set<DataItem> _variableSeen = Set.identity();

  void _allocate() {
    for (final DataItem item in items) {
      final ItemSemantics sem = semantics[item]!;
      while (_frames.isNotEmpty && !identical(_frames.last.item, item.parent)) {
        _closeFrame(_frames.removeLast());
      }
      if (_redef != null && !_isUnder(item, _redef!.head)) {
        // Level termination restores the counter; another REDEF
        // terminates without restoring (J 02.05.02).
        final _Redef redef = _redef!;
        _redef = null;
        if (item.typeCode != DataTypeCode.redef) {
          _cursorRoot = redef.savedRoot;
          _cursorChar = redef.savedChar;
        }
      }
      if (sem.fieldClass == FieldClass.condition) {
        continue;
      }
      if (sem.fieldClass == FieldClass.redefinition) {
        _startRedef(item);
        continue;
      }
      if (sem.dropped) {
        if (item.children.isNotEmpty) {
          _frames.add(_Frame(item, null, 0));
        }
        continue;
      }
      final DataItem? target = _pendingRedefTarget;
      _pendingRedefTarget = null;
      if (target != null) {
        _beginOverlay(item, target);
      } else if (item.parent == null && _redef == null) {
        if (item.typeCode == DataTypeCode.label) {
          _cursorRoot = null;
          _cursorChar = 0;
        } else {
          _cursorRoot = item;
          _cursorChar = 0;
          spaceRoots.add(item);
        }
        _variableSeen.remove(_spaceKey(item));
      }
      _allocateItem(item, sem);
    }
    while (_frames.isNotEmpty) {
      _closeFrame(_frames.removeLast());
    }
  }

  DataItem _spaceKey(DataItem item) => _cursorRoot ?? item;

  bool _isUnder(DataItem item, DataItem head) {
    for (DataItem? p = item; p != null; p = p.parent) {
      if (identical(p, head)) {
        return true;
      }
    }
    return false;
  }

  void _startRedef(DataItem marker) {
    final Token? name = marker.targetName;
    if (name == null) {
      return; // Already an M2 coding conflict.
    }
    final List<DataItem> candidates = _byName[name.text] ?? const [];
    final int here = _index[marker]!;
    DataItem? target;
    var following = false;
    for (final candidate in candidates) {
      if (_index[candidate]! < here) {
        target = candidate;
      } else {
        following = true;
      }
    }
    if (target == null) {
      if (following) {
        // Assignment proceeds over an already-allocated area
        // (J 02.05.02).
        diagnostics.report(
          msgRedefBeforeDefinition,
          name,
          operands: [name.text],
        );
      } else if (environmentNames.contains(name.text)) {
        diagnostics.report(
          msgRedefTargetNotDataName,
          name,
          operands: [name.text],
        );
      } else {
        diagnostics.report(msgRedefTargetUndefined, name);
      }
      return;
    }
    final ItemSemantics targetSem = semantics[target]!;
    if (targetSem.fieldClass == FieldClass.condition) {
      diagnostics.report(msgRedefTargetIsCond, name, operands: [name.text]);
      return;
    }
    if (targetSem.spaceRoot == null) {
      return; // The target reserved no storage; nothing to overlay.
    }
    // A chained REDEF terminates the previous one without a restore
    // (J 02.05.02).
    _redef = null;
    _pendingRedefTarget = target;
  }

  void _beginOverlay(DataItem head, DataItem target) {
    final ItemSemantics targetSem = semantics[target]!;
    final ItemSemantics headSem = semantics[head]!;
    final int? headLevel = head.entry.level;
    final int? targetLevel = target.entry.level;
    if (headLevel != null && targetLevel != null && headLevel != targetLevel) {
      // "The first item appearing thereafter must have the same level
      // number as the item referenced" (J 02.05.02).
      diagnostics.reportAt(msgRedefLevelConflict, head.entry.cards.first);
    }
    if (headSem.justification != targetSem.justification) {
      diagnostics.reportAt(
        msgRedefJustificationConflict,
        head.entry.cards.first,
        column: 37,
      );
    }
    _redef = _Redef(head, _cursorRoot, _cursorChar);
    _cursorRoot = targetSem.spaceRoot;
    _cursorChar = targetSem.startChar;
    redefLinks.add((target, head));
  }

  void _allocateItem(DataItem item, ItemSemantics sem) {
    (DataItem?, int)? labelResume;
    if (item.typeCode == DataTypeCode.label && item.parent != null) {
      labelResume = (_cursorRoot, _cursorChar);
      _cursorRoot = null;
      _cursorChar = 0;
    }

    _resolveQuantityIn(item, sem);

    if (sem.fieldClass == FieldClass.group) {
      if (sem.justification == Justification.left) {
        _cursorChar = _roundUpWord(_cursorChar);
      }
      sem
        ..spaceRoot = _cursorRoot
        ..startChar = _cursorChar;
      _frames.add(
        _Frame(item, _cursorRoot, _cursorChar)..labelResume = labelResume,
      );
      return;
    }

    final int chars = sem.storageChars;
    if (chars == 0) {
      if (sem.shape != null) {
        // A pictorial of only V or S positions reserves nothing.
        diagnostics.reportAt(
          msgDataItemWithoutLength,
          item.entry.cards.first,
          operands: [item.entry.name],
        );
      }
      if (labelResume != null) {
        _cursorRoot = labelResume.$1;
        _cursorChar = labelResume.$2;
      }
      return;
    }
    var stride = chars;
    switch (sem.justification) {
      case Justification.left:
        _cursorChar = _roundUpWord(_cursorChar);
        sem.startChar = _cursorChar;
        _cursorChar += chars;
      case Justification.right:
        // A new word with the last character in the final byte
        // (J 02.05.04); internal and floating words land on the
        // boundary because their size is a word multiple. The element
        // extent is the reserved words, so every repetition
        // right-aligns in its own word(s) (M3-6).
        final int boundary = _roundUpWord(_cursorChar);
        final int words = (chars + 5) ~/ 6;
        sem.startChar = boundary + words * 6 - chars;
        _cursorChar = boundary + words * 6;
        stride = words * 6;
      case Justification.packed:
        if (sem.fieldClass == FieldClass.floatingPoint) {
          // A floating binary field is a machine word ([J 02.05.05]);
          // it cannot straddle one.
          _cursorChar = _roundUpWord(_cursorChar);
        }
        sem.startChar = _cursorChar;
        _cursorChar += chars;
    }
    sem
      ..spaceRoot = _cursorRoot
      ..strideChars = stride;
    if (sem.quantity > 1) {
      _cursorChar += stride * (sem.quantity - 1);
    }
    sem.extentChars = stride * (sem.quantity - 1) + chars;
    _updateFrames();
    _checkConstantPlacement(item, sem);
    if (sem.variableLength) {
      _variableSeen.add(_spaceKey(item));
    }
    if (item.parent == null && identical(sem.spaceRoot, item)) {
      _recordRootExtent(item, sem.extentChars);
    }
    if (labelResume != null) {
      _cursorRoot = labelResume.$1;
      _cursorChar = labelResume.$2;
    }
  }

  void _checkQuantityDepth(DataItem item, ItemSemantics sem) {
    bool specifies(DataItem i) =>
        i.entry.quantityText.isNotEmpty || i.quantityInName != null;
    if (sem.dropped || !specifies(item)) {
      return;
    }
    var depth = 1;
    for (DataItem? p = item.parent; p != null; p = p.parent) {
      if (specifies(p)) {
        depth++;
      }
    }
    if (depth > 3) {
      // Three levels of nested Quantity specifications (F p. 77;
      // D3.1); the quantity in excess is replaced by one.
      diagnostics.reportAt(
        msgQuantityNestedTooDeep,
        item.entry.cards.first,
        column: 31,
      );
      sem.quantity = 1;
    }
  }

  void _resolveQuantityIn(DataItem item, ItemSemantics sem) {
    final Token? name = item.quantityInName;
    if (name == null) {
      return;
    }
    if (sem.shape == null || item.children.isNotEmpty) {
      // The variable field must carry an explicit format and no
      // subfields ([J 02.05.06]; msg 47).
      diagnostics.report(msgQuantityInOnGroup, name);
      return;
    }
    final List<DataItem> candidates = _byName[name.text] ?? const [];
    if (candidates.isEmpty) {
      if (environmentNames.contains(name.text)) {
        diagnostics.report(
          msgRedefTargetNotDataName,
          name,
          operands: [name.text],
        );
      } else {
        diagnostics.report(msgRedefTargetUndefined, name);
      }
      return;
    }
    final int here = _index[item]!;
    DataItem? preceding;
    for (final candidate in candidates) {
      if (_index[candidate]! < here) {
        preceding = candidate;
      }
    }
    if (preceding == null) {
      // The count cannot follow the variable data it dimensions —
      // msg 105's own text states the rule.
      diagnostics.report(
        msgQuantityItemFollowsVariable,
        name,
        operands: [name.text],
      );
    }
    final ItemSemantics targetSem = semantics[preceding ?? candidates.first]!;
    if (targetSem.fieldClass == FieldClass.condition) {
      diagnostics.report(msgRedefTargetIsCond, name, operands: [name.text]);
      return;
    }
    if (targetSem.fieldClass != FieldClass.internalDecimal &&
        targetSem.fieldClass != FieldClass.externalDecimal) {
      diagnostics.report(msgQuantityInNotNumeric, name, operands: [name.text]);
    }
  }

  void _checkConstantPlacement(DataItem item, ItemSemantics sem) {
    if (item.constant == null) {
      return;
    }
    if (_redef != null) {
      // Constants cannot be part of a redefinition (J 02.05.06 iv;
      // D3.6 as amended 2026-08-04: msg 43 covers the case).
      diagnostics.report(msgConstantPlacementIllegal, item.constant!);
      sem.constantSuppressed = true;
      return;
    }
    if (_variableSeen.contains(_spaceKey(item))) {
      diagnostics.report(msgConstantPlacementIllegal, item.constant!);
      sem.constantSuppressed = true;
    }
  }

  void _updateFrames() {
    for (final _Frame frame in _frames) {
      if (identical(frame.spaceRoot, _cursorRoot) &&
          _cursorChar > frame.endChar) {
        frame.endChar = _cursorChar;
      }
    }
    if (_cursorRoot != null) {
      // An overlay can run past the redefined area — assignment
      // proceeds over it (J 02.05.02) — so the area grows to hold the
      // furthest character reached.
      _recordRootExtent(_cursorRoot!, _cursorChar);
    }
  }

  void _recordRootExtent(DataItem root, int chars) {
    final int known = rootExtent[root] ?? 0;
    if (chars > known) {
      rootExtent[root] = chars;
    }
  }

  void _closeFrame(_Frame frame) {
    if (frame.labelResume != null) {
      _cursorRoot = frame.labelResume!.$1;
      _cursorChar = frame.labelResume!.$2;
    }
    final ItemSemantics sem = semantics[frame.item]!;
    if (sem.dropped) {
      return;
    }
    final int extent = frame.endChar - frame.startChar;
    sem
      ..storageChars = extent
      ..strideChars = extent
      ..extentChars = extent * sem.quantity;
    if (sem.quantity > 1 && identical(_cursorRoot, frame.spaceRoot)) {
      // Whole-structure repetition: the element repeats by its own
      // (word, byte) extent (M3-6; TABLE's twelve 2-word pairs).
      _cursorChar = frame.startChar + extent * sem.quantity;
      _updateFrames();
    }
    if (frame.item.parent == null && identical(sem.spaceRoot, frame.item)) {
      _recordRootExtent(frame.item, sem.extentChars);
    }
  }

  int _roundUpWord(int char) => (char + 5) ~/ 6 * 6;
}
