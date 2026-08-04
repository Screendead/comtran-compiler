/// Initial images (M3 stage 1, design note M3-7): each transmitted
/// area's initial words — constants in their stored form, the
/// automatic blank fill, and no image for wholly uninitialized words.
///
/// Word images bind to the emulator's 36-bit word model (ED-1) and
/// the D0.6 BCD codes — no parallel representation. Literal values
/// are re-read from the card images, because M1 token text uses
/// display placeholders (M1-9; M3-2).
library;

import '../ast/data_ast.dart';
import '../chars/char_code.dart';
import '../lexer/diagnostic.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'mapper.dart';
import 'pictorial.dart';

const int _bcdPlus = 0x10;
const int _bcdMinus = 0x20;
const int _bcdPeriod = 0x1B;
const int _bcdRecordMark = 0x3A;

/// Re-reads a quoted constant's characters from the card images as
/// BCD codes, replaying the M1 scan's walk (M1-9 directs the re-read;
/// D1.1's join rules; D9.10's zero repair).
List<int> constantBcd(Token constant, List<SourceCard> group) {
  final result = <int>[];
  var blanks = 0;
  for (int i = group.indexOf(constant.card); i < group.length; i++) {
    final SourceCard card = group[i];
    final bool opening = identical(card, constant.card);
    final int from = opening ? constant.column + 1 : 38;
    // Leading unpunched columns of a continuation card never join
    // (D1.1); blanks after the opening quote do.
    bool beforeContent = !opening;
    for (var column = from; column <= 71; column++) {
      if (!card.isPunched(column)) {
        if (!beforeContent) {
          blanks++;
        }
        continue;
      }
      beforeContent = false;
      for (; blanks > 0; blanks--) {
        result.add(bcdBlank);
      }
      final int? bcd = card.bcdAt(column);
      if (bcd == null) {
        result.add(0); // The D9.10 repair; M1 diagnosed the column.
        continue;
      }
      if (card.glyphAt(column) == "'") {
        return result;
      }
      result.add(bcd);
    }
    blanks = 0; // The card's unpunched tail never joins (D1.1).
  }
  return result; // Unclosed: msg 167 was issued at M1.
}

/// Builds the transmitted areas with their initial words.
final class ImageBuilder {
  ImageBuilder(this.diagnostics, this.mapper, this.records);

  final List<Diagnostic> diagnostics;
  final DataMapper mapper;
  final List<RecordInfo> records;

  late List<int> _words;
  late List<bool> _touched;

  List<AreaInfo> build() {
    final Map<DataItem, RecordInfo> recordOf = Map.identity();
    for (final RecordInfo record in records) {
      recordOf[record.item] = record;
    }
    // A located record's fields live in the buffers; a constant there
    // has no storage to occupy (J 02.05.06 ii).
    for (final RecordInfo record in records.where(
      (RecordInfo r) => r.located,
    )) {
      for (final DataItem item in subtreeOf(record.item)) {
        final ItemSemantics sem = mapper.semantics[item]!;
        if (item.constant != null &&
            !sem.constantSuppressed &&
            sem.fieldClass != FieldClass.condition) {
          diagnostics.report(msgConstantPlacementIllegal, item.constant!);
          sem.constantSuppressed = true;
        }
      }
    }

    final areas = <AreaInfo>[];
    for (final DataItem root in mapper.spaceRoots) {
      if (recordOf[root]?.located ?? false) {
        continue;
      }
      final int extentChars = mapper.rootExtent[root] ?? 0;
      if (extentChars == 0) {
        continue;
      }
      final int extentWords = (extentChars + 5) ~/ 6;
      _words = List<int>.filled(extentWords, 0);
      _touched = List<bool>.filled(extentWords, false);
      for (final DataItem item in mapper.items) {
        final ItemSemantics sem = mapper.semantics[item]!;
        if (!identical(sem.spaceRoot, root)) {
          continue;
        }
        _storeItem(item, sem);
      }
      final isRecord = root.typeCode == DataTypeCode.record;
      if (isRecord && extentChars % 6 != 0) {
        // A record's partial final word is blank-filled automatically
        // ([J 90.05.02], [J 90.05.04]).
        for (var char = extentChars; char < extentWords * 6; char++) {
          _setChar(char, bcdBlank);
        }
      }
      areas.add(
        AreaInfo(
          root,
          root.entry.name,
          isRecord: isRecord,
          words: [
            for (var i = 0; i < extentWords; i++)
              _touched[i] ? _words[i] : null,
          ],
        ),
      );
    }
    return areas;
  }

  void _storeItem(DataItem item, ItemSemantics sem) {
    if (item.typeCode == DataTypeCode.rcdmrk) {
      for (var k = 0; k < sem.quantity; k++) {
        _setChar(sem.startChar + k * sem.strideChars, _bcdRecordMark);
      }
      return;
    }
    final Token? constant = item.constant;
    if (constant == null ||
        sem.constantSuppressed ||
        sem.fieldClass == FieldClass.condition ||
        sem.fieldClass == FieldClass.redefinition) {
      return;
    }
    if (sem.fieldClass == FieldClass.group) {
      // A constant beside subfields has no defined placement; neither
      // manual states one, and the sample writes none.
      return;
    }
    if (sem.fieldClass == FieldClass.edited) {
      diagnostics.report(msgConstantOnEditedField, constant);
      sem.constantSuppressed = true;
      return;
    }
    final List<int> bcd = constantBcd(constant, item.entry.cards);
    for (var k = 0; k < sem.quantity; k++) {
      // A conversion condition is the entry's, not the occurrence's:
      // only the first store reports.
      if (!_storeOccurrence(
        item,
        sem,
        bcd,
        sem.startChar + k * sem.strideChars,
        report: k == 0,
      )) {
        sem.constantSuppressed = true;
        return;
      }
    }
  }

  bool _storeOccurrence(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start, {
    required bool report,
  }) {
    switch (sem.fieldClass) {
      case FieldClass.alphameric:
        return _storeAlphameric(item, sem, bcd, start, report: report);
      case FieldClass.externalDecimal:
        return _storeExternal(item, sem, bcd, start);
      case FieldClass.internalDecimal:
        return _storeInternal(item, sem, bcd, start, report: report);
      case FieldClass.scientificDecimal:
        return _storeScientific(item, sem, bcd, start);
      case FieldClass.floatingPoint:
        return _storeFloating(item, sem, bcd, start);
      case FieldClass.group ||
          FieldClass.edited ||
          FieldClass.condition ||
          FieldClass.redefinition:
        return false;
    }
  }

  bool _storeAlphameric(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start, {
    required bool report,
  }) {
    final int chars = sem.storageChars;
    if (report && bcd.length > chars) {
      // Filled from the left, the remainder discarded (J 02.05.06).
      diagnostics.report(msgAlphabeticConstantConflict, item.constant!);
    }
    for (var i = 0; i < chars; i++) {
      _setChar(start + i, i < bcd.length ? bcd[i] : bcdBlank);
    }
    return true;
  }

  bool _storeExternal(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start,
  ) {
    final Pictorial? shape = sem.shape;
    if (bcd.length != sem.storageChars) {
      // "The length specified by the pictorial must be exactly equal
      // to the length of the constant" (J 02.05.07).
      diagnostics.report(
        msgConstantLengthConflict,
        item.constant!,
        operands: [item.entry.name],
      );
      return false;
    }
    SignConvention zone = SignConvention.none;
    var leading = true;
    for (var i = 0; i < bcd.length; i++) {
      final int c = bcd[i];
      if (c <= 0x09) {
        leading = false;
        continue;
      }
      if (c == bcdBlank && leading) {
        continue; // Leading blanks read as zeros ([J 02.05.05] note 3).
      }
      if (i == bcd.length - 1 && c >= 0x21 && c <= 0x29) {
        zone = SignConvention.overpunchMinus;
        continue;
      }
      if (i == bcd.length - 1 && c >= 0x11 && c <= 0x19) {
        zone = SignConvention.overpunchPlus;
        continue;
      }
      diagnostics.report(msgNonNumericInNumericField, item.constant!);
      return false;
    }
    if (zone != (shape?.sign ?? SignConvention.none)) {
      // The constant must utilize the pictorial's sign convention:
      // `999̅` takes `123̅`, never `123` (J 02.05.07).
      diagnostics.report(
        msgExternalConstantInError,
        item.constant!,
        operands: [item.entry.name],
      );
      return false;
    }
    for (var i = 0; i < bcd.length; i++) {
      _setChar(start + i, bcd[i]);
    }
    return true;
  }

  bool _storeInternal(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start, {
    required bool report,
  }) {
    var minus = false;
    var leading = true;
    final digits = <int>[];
    for (var i = 0; i < bcd.length; i++) {
      final int c = bcd[i];
      if (c == _bcdPlus || c == _bcdMinus) {
        // Leading, trailing, or no sign (J 02.05.07).
        if (i != 0 && i != bcd.length - 1) {
          diagnostics.report(msgNonNumericInNumericField, item.constant!);
          return false;
        }
        minus = c == _bcdMinus;
        continue;
      }
      if (c <= 0x09) {
        leading = false;
        digits.add(c);
        continue;
      }
      if (c == bcdBlank && leading) {
        // Leading blanks read as zeros ([J 02.05.05] note 3).
        digits.add(0);
        continue;
      }
      diagnostics.report(msgNonNumericInNumericField, item.constant!);
      return false;
    }
    var kept = digits;
    if (digits.length > sem.digits) {
      // Left-truncated to the pictorial's size, converted, stored,
      // and diagnosed (J 02.05.07).
      if (report) {
        diagnostics.report(
          msgConstantLengthConflict,
          item.constant!,
          operands: [item.entry.name],
        );
      }
      kept = digits.sublist(digits.length - sem.digits);
    }
    BigInt value = BigInt.zero;
    for (final digit in kept) {
      value = value * BigInt.from(10) + BigInt.from(digit);
    }
    final int chars = sem.storageChars;
    if (sem.justification == Justification.right && sem.doublePrecision) {
      // Two words, the sign in each word's sign bit — the 7090
      // double-precision convention; the split is a reconstruction.
      // The classifier caps the register form at 21 digits, so the
      // magnitude fits the two words' 70 bits.
      assert(start % 6 == 0, 'register form off the word boundary');
      assert(value < BigInt.one << 70, 'register value over 70 bits');
      final BigInt low = value & ((BigInt.one << 35) - BigInt.one);
      final BigInt high = value >> 35;
      final int signBit = minus ? 1 << 35 : 0;
      _setWord(start ~/ 6, signBit | high.toInt());
      _setWord(start ~/ 6 + 1, signBit | low.toInt());
      return true;
    }
    // The sign occupies the field's leftmost bit (J 02.05.04); for the
    // register form that bit is the word's sign bit.
    final int bits = chars * 6;
    final BigInt pattern =
        (minus ? BigInt.one << (bits - 1) : BigInt.zero) | value;
    _setBitRange(start * 6, bits, pattern);
    return true;
  }

  bool _storeScientific(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start,
  ) {
    if (bcd.length != sem.storageChars) {
      diagnostics.report(
        msgConstantLengthConflict,
        item.constant!,
        operands: [item.entry.name],
      );
      return false;
    }
    for (final c in bcd) {
      final bool legal =
          c <= 0x09 ||
          c == bcdBlank ||
          c == _bcdPeriod ||
          c == _bcdPlus ||
          c == _bcdMinus;
      if (!legal) {
        diagnostics.report(msgIllegalConstantCharacter, item.constant!);
        return false;
      }
    }
    for (var i = 0; i < bcd.length; i++) {
      _setChar(start + i, bcd[i]);
    }
    return true;
  }

  bool _storeFloating(
    DataItem item,
    ItemSemantics sem,
    List<int> bcd,
    int start,
  ) {
    assert(start % 6 == 0, 'floating field off the word boundary');
    final buffer = StringBuffer();
    for (final c in bcd) {
      if (c <= 0x09) {
        buffer.writeCharCode(0x30 + c);
      } else if (c == _bcdPeriod) {
        buffer.write('.');
      } else if (c == _bcdMinus) {
        buffer.write('-');
      } else if (c == _bcdPlus || c == bcdBlank) {
        // A plus adds nothing; blanks read as zeros.
        if (c == bcdBlank) {
          buffer.write('0');
        }
      } else {
        diagnostics.report(msgIllegalConstantCharacter, item.constant!);
        return false;
      }
    }
    final double? value = double.tryParse(buffer.toString());
    if (value == null) {
      diagnostics.report(msgIllegalConstantCharacter, item.constant!);
      return false;
    }
    if (value == 0) {
      _setWord(start ~/ 6, 0);
      if (sem.doublePrecision) {
        _setWord(start ~/ 6 + 1, 0);
      }
      return true;
    }
    double fraction = value.abs();
    var exponent = 0;
    while (fraction >= 1) {
      fraction /= 2;
      exponent++;
    }
    while (fraction < 0.5) {
      fraction *= 2;
      exponent--;
    }
    final int excess = exponent + 128;
    if (excess > 255) {
      diagnostics.report(msgFloatingOverflow, item.constant!);
      return false;
    }
    if (excess < 0) {
      diagnostics.report(msgFloatingUnderflow, item.constant!);
      return false;
    }
    final int signBit = value < 0 ? 1 << 35 : 0;
    int high = (fraction * (1 << 27)).floor();
    if (high == 1 << 27) {
      high--;
    }
    _setWord(start ~/ 6, signBit | (excess << 27) | high);
    if (sem.doublePrecision) {
      // The low word holds the next 27 fraction bits at exponent
      // minus 27 — a reconstruction; no manual states the layout.
      final int lowExcess = excess >= 27 ? excess - 27 : 0;
      final int low = ((fraction * (1 << 27) - high) * (1 << 27)).floor();
      _setWord(start ~/ 6 + 1, signBit | (lowExcess << 27) | low);
    }
    return true;
  }

  void _setChar(int charPos, int bcd) {
    final int word = charPos ~/ 6;
    final int shift = (5 - charPos % 6) * 6;
    _words[word] = (_words[word] & ~(0x3F << shift)) | (bcd << shift);
    _touched[word] = true;
  }

  void _setWord(int word, int value) {
    _words[word] = value;
    _touched[word] = true;
  }

  void _setBitRange(int firstBit, int bitCount, BigInt pattern) {
    for (var i = 0; i < bitCount; i++) {
      final int bit = firstBit + i;
      final int word = bit ~/ 36;
      final int position = 35 - bit % 36;
      if ((pattern >> (bitCount - 1 - i)) & BigInt.one == BigInt.one) {
        _words[word] |= 1 << position;
      }
      _touched[word] = true;
    }
  }
}
