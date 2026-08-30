/// Our CT Loader (D0.3; M4-16; LD-3): reads one job's deck — the
/// symbolic control cards, `*CTEXT`, the text section, `*CTEND`
/// ([J 03.01.02]) — resolves every control group ([J 90.03.04]),
/// places the program at a chosen origin, and returns the entry point
/// the end-of-text entry names (D2.1).
///
/// The loader makes one pass. The 1962 loader's second pass over its
/// 2TEXT file served subroutine and control-break references the
/// compiler never punches ([J 90.01.04]), so no 2TEXT form is read.
/// System and file references resolve through the caller's table: the
/// dispatch addresses are the machine assembly's (M4-17), and the file
/// blocks are IOCS's (M5).
library;

import '../cards/card_image.dart';
import '../cards/text_codec.dart';
import '../codegen/text_model.dart';
import '../emulator/machine_state.dart';
import '../emulator/word.dart';
import 'object_deck.dart';

/// A deck the loader cannot load, named for the report.
final class LoadError implements Exception {
  LoadError(this.message, {this.card});

  final String message;

  /// The one-based card the error is at, or `null` for the deck as a
  /// whole.
  final int? card;

  @override
  String toString() => card == null
      ? 'load error: $message'
      : 'load error at card $card: $message';
}

/// A system reference ([J 90.03.05]): the 15-bit code's type in its
/// high four bits — `0000` a system reference, `0001` a file reference
/// — and the number in the low eleven.
final class SystemReference {
  const SystemReference({required this.file, required this.number});

  /// Whether the reference names a file rather than a system routine.
  final bool file;

  /// The system reference number, or the file number.
  final int number;

  /// The 15-bit code as the text carries it.
  int get code => (file ? 0x800 : 0) | number;
}

/// Maps a system reference to the 15-bit address it stands for.
typedef SystemReferenceResolver = int Function(SystemReference reference);

/// One `*FILE` card and its `*SPEC` card as the loader read them
/// ([J 03.02.02]; [J 03.02.05]).
final class LoaderFile {
  LoaderFile({
    required this.deckName,
    required this.number,
    required this.name,
    required this.type,
    required this.mode,
    required this.density,
    required this.unit1,
    required this.unit2,
  });

  /// Columns 1 to 6, which with [number] identify the file on a
  /// `*SPEC` card ([J 03.02.05]).
  final String deckName;
  final int number;
  final String name;

  /// `I`, `T` or `P` ([J 90.08.01]).
  final String type;

  /// `D` or `B`.
  final String mode;

  /// `H` or `L`.
  final String density;
  final String unit1;
  final String unit2;

  /// The `*SPEC` fields, or `null` until a `*SPEC` card names the file.
  int? blocksize;
  String? open;
  String? close;
}

/// A loaded program: its words by address, and the entry point.
final class LoadedProgram {
  const LoadedProgram({
    required this.deckName,
    required this.origin,
    required this.entry,
    required this.words,
    required this.files,
    required this.cardsRead,
  });

  final String deckName;

  /// The address of relative location zero.
  final int origin;

  /// The absolute entry point (D2.1).
  final int entry;

  /// Every word the text placed, by absolute address. Reservations
  /// place nothing.
  final Map<int, int> words;

  /// The files in `*FILE` card order.
  final List<LoaderFile> files;

  /// The cards consumed, `*CTEND` included; a second deck starts at
  /// the next card.
  final int cardsRead;
}

/// Loads the deck at the head of [cards] with relative location zero at
/// [origin], resolving system and file references through [resolve].
///
/// Throws [LoadError] for a deck the loader cannot load: a card out of
/// format or out of sequence, a checksum that fails, a section other
/// than text (D7.10), a control card the compiler never punches, a
/// group the compiler never emits, or a deck.name with an imbedded
/// blank, which "will prevent execution of the object program"
/// ([J 90.01.05] B.5; D7.11).
LoadedProgram loadDeck(
  List<CardImage> cards, {
  required SystemReferenceResolver resolve,
  int origin = 0,
}) => _Loader(cards, origin, resolve).load();

final class _Loader {
  _Loader(this._cards, this._origin, this._resolve);

  final List<CardImage> _cards;
  final int _origin;
  final SystemReferenceResolver _resolve;
  final List<LoaderFile> _files = [];
  final Map<int, int> _words = {};
  int _index = 0;
  String _deckName = '';

  /// The one-based number of the card in hand, for the report.
  int get _card => _index + 1;

  LoadedProgram load() {
    _symbolicCards();
    final int entry = _textSection();
    final String? last = _glyphLine();
    if (last == null || _cardType(last) != '*CTEND') {
      throw LoadError('*CTEND does not follow the text', card: _card);
    }
    _index++;
    return LoadedProgram(
      deckName: _deckName,
      origin: _origin,
      entry: entry,
      words: _words,
      files: _files,
      cardsRead: _index,
    );
  }

  /// The symbolic control cards through `*CTEXT` ([J 03.01.01]).
  void _symbolicCards() {
    while (true) {
      final String? line = _glyphLine();
      if (line == null) {
        throw LoadError('no *CTEXT card before the binary deck', card: _card);
      }
      final String deckName = _field(line, 1, 6);
      switch (_cardType(line)) {
        case '*FILE':
          _files.add(
            LoaderFile(
              deckName: deckName,
              number: _number(line),
              name: _field(line, 55, 72),
              type: _field(line, 28, 28),
              mode: _field(line, 31, 31),
              density: _field(line, 30, 30),
              unit1: _field(line, 18, 21),
              unit2: _field(line, 22, 25),
            ),
          );
        case '*SPEC':
          // A *SPEC card without a *FILE card of the same deck.name and
          // file number is ignored (J 03.02.05).
          final int number = _number(line);
          for (final LoaderFile file in _files) {
            if (file.number == number && file.deckName == deckName) {
              file
                ..blocksize = int.tryParse(_field(line, 17, 20))
                ..open = _field(line, 25, 25)
                ..close = _field(line, 27, 27);
            }
          }
        case '*CTEXT':
          if (deckName.contains(' ')) {
            throw LoadError(
              'deck.name "$deckName" has an imbedded blank (J 90.01.05)',
              card: _card,
            );
          }
          _deckName = deckName;
          _index++;
          return;
        case final String type:
          throw LoadError('unsupported control card $type', card: _card);
      }
      _index++;
    }
  }

  /// The text cards, in section sequence from zero, to the end-of-text
  /// entry; returns the entry point.
  int _textSection() {
    int location = _origin;
    var sequence = 0;
    while (true) {
      if (_index >= _cards.length) {
        throw LoadError('the text ends without an end-of-text entry');
      }
      final List<int> words = _textCard(sequence);
      final List<int> groups = unpackControlGroups(words.sublist(2, 5));
      final int count = wordCountOf(words[0]) - 3;
      for (var i = 0; i < count; i++) {
        final int group = groups[i];
        final int word = words[5 + i];
        if (group == 0) {
          throw LoadError('end of card before its $count words', card: _card);
        }
        if (group == ControlGroup.endOfText) {
          if (i + 1 != count) {
            throw LoadError('words follow the end-of-text entry', card: _card);
          }
          _index++;
          return _relative(Word36.address(word));
        }
        if (group == ControlGroup.locationCounter) {
          location = _locationControl(word, location);
        } else if (group & 0x10 != 0) {
          _place(location, _relocated(word, group));
          location++;
        } else {
          throw LoadError(
            'control group ${controlColumn(group)} is not one the '
            'compiler punches',
            card: _card,
          );
        }
      }
      if (groups[count] != 0) {
        throw LoadError('no end-of-card group after word $count', card: _card);
      }
      _index++;
      sequence++;
    }
  }

  /// The words of the text card in hand, its header and checksum
  /// verified ([J 90.03.01]).
  List<int> _textCard(int sequence) {
    if (_glyphLine() != null) {
      throw LoadError('a symbolic card inside the text', card: _card);
    }
    final List<int> words = cardWords(_cards[_index]);
    final int header = words[0];
    if (!isRelativeCardHeader(header)) {
      throw LoadError('not a relative binary card', card: _card);
    }
    if (deckTypeOf(header) != textDeckType) {
      throw LoadError(
        'deck type ${deckTypeOf(header).toRadixString(2).padLeft(3, '0')} '
        'is not text (D7.10)',
        card: _card,
      );
    }
    final int count = wordCountOf(header);
    if (count < 4 || count > 3 + textCardWords) {
      throw LoadError('word count $count', card: _card);
    }
    if (sequenceOf(header) != sequence) {
      throw LoadError(
        'sequence ${sequenceOf(header)} where $sequence is due',
        card: _card,
      );
    }
    if (!skipsChecksum(header) &&
        words[1] != logicalSum([header, ...words.sublist(2, 2 + count)])) {
      throw LoadError('checksum fails', card: _card);
    }
    return words;
  }

  /// A location counter control entry ([J 90.03.04]): `PZE` an absolute
  /// origin, `MON` a relative origin, `PTW` a reservation.
  int _locationControl(int word, int location) {
    final int address = Word36.address(word);
    return switch (Word36.prefix(word)) {
      0 => address,
      5 => _relative(address),
      2 => location + address,
      3 => throw LoadError(
        'a variable-length reservation (PTH), which the compiler never '
        'punches',
        card: _card,
      ),
      final int prefix => throw LoadError(
        'location counter control prefix $prefix',
        card: _card,
      ),
    };
  }

  /// A standard word `1 AB CD` with its decrement and address relocated
  /// by their classes ([J 90.03.04]).
  int _relocated(int word, int group) {
    final int decrement = _field15(Word36.decrement(word), (group >> 2) & 3);
    final int address = _field15(Word36.address(word), group & 3);
    const int fields = (Word36.fieldMask15 << 18) | Word36.fieldMask15;
    return (word & ~fields) | (decrement << 18) | address;
  }

  int _field15(int field, int relocation) => switch (relocation) {
    0 => field,
    1 => _relative(field),
    2 => _system(field),
    _ => throw LoadError(
      'a complex expression, which the compiler never punches',
      card: _card,
    ),
  };

  int _relative(int field) => _fits(field + _origin);

  int _system(int code) {
    final SystemReference reference = switch (code >> 11) {
      0 => SystemReference(file: false, number: code & 0x7FF),
      1 => SystemReference(file: true, number: code & 0x7FF),
      _ => throw LoadError(
        'system reference type '
        '${(code >> 11).toRadixString(2).padLeft(4, '0')}',
        card: _card,
      ),
    };
    return _fits(_resolve(reference));
  }

  int _fits(int address) {
    if (address < 0 || address >= MachineState.memoryWords) {
      throw LoadError('address $address is outside core', card: _card);
    }
    return address;
  }

  void _place(int location, int word) {
    _words[_fits(location)] = word;
  }

  /// The card in hand as text, or `null` when it is not a glyph card.
  String? _glyphLine() {
    if (_index >= _cards.length) {
      return null;
    }
    final String line = deckToMirror([_cards[_index]]).trimRight();
    return line.startsWith('!') ? null : line;
  }

  /// Columns 7 up to the first blank: `*FILE`, `*CTEXT`, ....
  static String _cardType(String line) {
    final String tail = _field(line, 7, 15);
    final int blank = tail.indexOf(' ');
    return blank < 0 ? tail : tail.substring(0, blank);
  }

  static int _number(String line) => int.tryParse(_field(line, 14, 15)) ?? 0;

  /// Columns [from] to [to] of [line], trailing blanks trimmed.
  static String _field(String line, int from, int to) =>
      line.padRight(to).substring(from - 1, to).trimRight();
}
