/// Pictorial measurement (M3 stage 1, design note M3-5).
///
/// From a pictorial run the mapper needs: the storage character count
/// (each format character one position; `V`, `S`, and `F` reserve
/// nothing — F p. 80; J 02.05.05), the digit count, the scale, and
/// the sign convention. A single trailing zone letter A–R is an
/// overpunched digit — the punch-level form of the chart's `9̅` (M2-3
/// amendment; design note M3-5).
library;

/// The sign conventions a pictorial can state: the external-decimal
/// overpunch pair (J 90.02.15) and the edited reserved positions
/// (J 90.02.17's seven-valued set, J 02.05.05 note 2).
enum SignConvention {
  /// No sign specification.
  none,

  /// A minus overpunch over the rightmost digit (zone letters J–R).
  overpunchMinus,

  /// A plus overpunch over the rightmost digit (zone letters A–I).
  overpunchPlus,

  /// A `+` position before the first digit.
  plusLeading,

  /// A `+` position after the last digit.
  plusTrailing,

  /// A `-` position before the first digit.
  minusLeading,

  /// A `-` position after the last digit.
  minusTrailing,
}

/// One expanded format-character kind.
enum _Kind {
  alpha, // A or X
  nine,
  eight,
  star,
  v,
  s,
  period,
  comma,
  dollar,
  plus,
  minus,
  f,
  overpunch, // the trailing zone letter
}

/// A measured pictorial.
final class Pictorial {
  Pictorial._(List<(_Kind, int)> elements) : _elements = elements;

  final List<(_Kind, int)> _elements;

  /// Whether a `(0)` count was replaced by one (msg 60).
  bool zeroCountRepaired = false;

  /// Whether a count had no closing right parenthesis (msg 133); the
  /// digits through the end of the run were read as the count.
  bool missingRightParen = false;

  /// Whether a repetition count over [maxCount] was clamped to it
  /// (msg 34).
  bool countClamped = false;

  /// The largest repetition count kept as punched. A blocksize holds
  /// at most 9999 words, 59994 characters (J 02.06.04), so no field
  /// a machine can read reaches this bound; a larger count is a
  /// keying error (M3-16 amendment).
  static const int maxCount = 99999;

  int _count(_Kind kind) => _elements
      .where(((_Kind, int) e) => e.$1 == kind)
      .fold(0, (int sum, (_Kind, int) e) => sum + e.$2);

  /// A and X positions (J 02.05.04: synonymous).
  late final int alphamericCount = _count(_Kind.alpha);

  /// Digit positions reserving storage: `9`, `8`, `*`, and the
  /// overpunched digit.
  late final int digitCount =
      _count(_Kind.nine) +
      _count(_Kind.eight) +
      _count(_Kind.star) +
      _count(_Kind.overpunch);

  /// `S` positions — digits represented but never stored (F p. 80).
  late final int sCount = _count(_Kind.s);

  /// Digits the field represents: stored positions plus `S` fillers.
  /// More than 10 makes the field double precision (J 02.05.06).
  int get valueDigits => digitCount + sCount;

  /// Storage positions: one per format character except `V`, `S`, and
  /// `F` (F p. 80; the overpunch shares its digit's position).
  late final int storageChars = _elements.fold(
    0,
    (int sum, (_Kind, int) e) => switch (e.$1) {
      _Kind.v || _Kind.s || _Kind.f => sum,
      _ => sum + e.$2,
    },
  );

  /// Whether an edit character appears: `8 * . , $ + -` characterize
  /// an edited field (J 02.05.05). An overpunched 8 is one of them:
  /// the chart admits it in the Edited Field row only, the External
  /// Decimal row taking an overpunched 9 alone (images/page-031.png).
  late final bool hasEditCharacters =
      _overpunchDigit == 8 ||
      _elements.any(
        ((_Kind, int) e) => switch (e.$1) {
          _Kind.eight ||
          _Kind.star ||
          _Kind.period ||
          _Kind.comma ||
          _Kind.dollar ||
          _Kind.plus ||
          _Kind.minus => true,
          _ => false,
        },
      );

  /// The `F` count: 1 is single precision, 2 (`FF`) double
  /// (J 02.05.05).
  late final int fCount = _count(_Kind.f);

  /// Edit characters outside the scientific repertoire — `8 * , $`
  /// (the chart admits `9 (n) F . V + -` for scientific decimal,
  /// J 02.05.05).
  late final bool hasNonScientificEdit = _elements.any(
    ((_Kind, int) e) => switch (e.$1) {
      _Kind.eight || _Kind.star || _Kind.comma || _Kind.dollar => true,
      _ => false,
    },
  );

  /// Whether a `V` appears.
  late final bool hasV = _elements.any(((_Kind, int) e) => e.$1 == _Kind.v);

  /// Fraction positions: digit and `S` positions after the `V`, or,
  /// with no `V`, minus the trailing `S` run (`999SSS` scales by a
  /// thousand — F p. 80). Digits after an `F` are the exponent, never
  /// fraction (the scientific form is fraction, `F`, exponent —
  /// J 02.04.02).
  late final int fractionDigits = _fractionDigits();

  int _fractionDigits() {
    final mantissa = <(_Kind, int)>[];
    for (final (_Kind, int) e in _elements) {
      if (e.$1 == _Kind.f) {
        break;
      }
      mantissa.add(e);
    }
    var seenV = false;
    var fraction = 0;
    for (final (_Kind kind, int count) in mantissa) {
      if (kind == _Kind.v || kind == _Kind.period) {
        seenV = true;
        continue;
      }
      if (!seenV) {
        continue;
      }
      if (kind == _Kind.nine ||
          kind == _Kind.eight ||
          kind == _Kind.star ||
          kind == _Kind.s ||
          kind == _Kind.overpunch) {
        fraction += count;
      }
    }
    if (seenV) {
      return fraction;
    }
    var trailing = 0;
    for (final (_Kind kind, int count) in mantissa.reversed) {
      if (kind == _Kind.s) {
        trailing += count;
        continue;
      }
      if (kind == _Kind.plus || kind == _Kind.minus) {
        continue; // A sign after the digits does not end the run.
      }
      break;
    }
    return -trailing;
  }

  SignConvention? _overpunchSign;

  /// The digit the trailing zone letter punches: A–I and J–R carry 1–9.
  int? _overpunchDigit;

  /// The pictorial's sign convention. An overpunch wins; otherwise the
  /// first free-standing sign, leading when it precedes every digit
  /// position.
  late final SignConvention sign = _sign();

  SignConvention _sign() {
    if (_overpunchSign != null) {
      return _overpunchSign!;
    }
    var digitSeen = false;
    for (final (_Kind kind, _) in _elements) {
      switch (kind) {
        case _Kind.nine || _Kind.eight || _Kind.star || _Kind.s:
          digitSeen = true;
        case _Kind.plus:
          return digitSeen
              ? SignConvention.plusTrailing
              : SignConvention.plusLeading;
        case _Kind.minus:
          return digitSeen
              ? SignConvention.minusTrailing
              : SignConvention.minusLeading;
        case _Kind.alpha ||
            _Kind.v ||
            _Kind.period ||
            _Kind.comma ||
            _Kind.dollar ||
            _Kind.f ||
            _Kind.overpunch:
          break;
      }
    }
    return SignConvention.none;
  }

  /// Parses [text] as a pictorial. Returns `null` when the text is not
  /// format-shaped — the caller then reads it as a name
  /// (J 02.05.06). [allowUnclosedCount] additionally accepts a
  /// trailing `(digits` with no right parenthesis, the msg 133 form.
  static Pictorial? tryParse(String text, {bool allowUnclosedCount = false}) {
    final elements = <(_Kind, int)>[];
    var zeroRepaired = false;
    var clamped = false;
    var unclosed = false;
    var i = 0;
    while (i < text.length) {
      final String c = text[i];
      final _Kind? kind = switch (c) {
        'A' || 'X' => _Kind.alpha,
        '9' => _Kind.nine,
        '8' => _Kind.eight,
        '*' => _Kind.star,
        'V' => _Kind.v,
        'S' => _Kind.s,
        '.' => _Kind.period,
        ',' => _Kind.comma,
        r'$' => _Kind.dollar,
        '+' => _Kind.plus,
        '-' => _Kind.minus,
        'F' => _Kind.f,
        _ => null,
      };
      if (kind == null) {
        // A trailing zone letter after all-numeric format characters is
        // an overpunched digit (M3-5); anywhere else the run is a name.
        final int code = c.codeUnitAt(0);
        final bool minus = code >= 0x4A && code <= 0x52; // J–R
        final bool plus = code >= 0x41 && code <= 0x49; // A–I
        if ((minus || plus) &&
            i == text.length - 1 &&
            elements.isNotEmpty &&
            !elements.any(
              ((_Kind, int) e) => e.$1 == _Kind.alpha || e.$1 == _Kind.f,
            )) {
          elements.add((_Kind.overpunch, 1));
          return Pictorial._(elements)
            ..zeroCountRepaired = zeroRepaired
            ..countClamped = clamped
            .._overpunchDigit = minus ? code - 0x49 : code - 0x40
            .._overpunchSign = minus
                ? SignConvention.overpunchMinus
                : SignConvention.overpunchPlus;
        }
        return null;
      }
      i++;
      if (i < text.length && text[i] == '(') {
        int j = i + 1;
        while (j < text.length &&
            text.codeUnitAt(j) >= 0x30 &&
            text.codeUnitAt(j) <= 0x39) {
          j++;
        }
        final String digits = text.substring(i + 1, j);
        final bool closed = j < text.length && text[j] == ')';
        if (!closed) {
          if (!allowUnclosedCount || j != text.length) {
            return null;
          }
          unclosed = true;
        }
        // int.parse throws over 2^63; the description field is wide
        // enough to punch a count past that.
        final int? parsed = digits.isEmpty ? 1 : int.tryParse(digits);
        int count = parsed ?? maxCount;
        if (parsed == null || count > maxCount) {
          count = maxCount; // msg 34: the clamped format is used.
          clamped = true;
        }
        if (count == 0) {
          count = 1; // msg 60: a zero count is replaced by one.
          zeroRepaired = true;
        }
        elements.add((kind, count));
        i = closed ? j + 1 : j;
      } else {
        elements.add((kind, 1));
      }
    }
    if (elements.isEmpty) {
      return null;
    }
    return Pictorial._(elements)
      ..zeroCountRepaired = zeroRepaired
      ..countClamped = clamped
      ..missingRightParen = unclosed;
  }
}
