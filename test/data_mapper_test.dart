/// The M3 stage-1 data mapper: classification (M3-4, M3-5), the
/// storage allocator (M3-6), initial images (M3-7), the environment
/// binder (M3-11), and their diagnostics (M3-13).
library;

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

SemanticResult _map(
  List<String> data, {
  List<String> environment = const [],
  bool pedantic = false,
}) {
  final lines = [
    '      *DATA',
    ...data,
    if (environment.isNotEmpty) '      *ENVIRONMENT',
    ...environment,
  ];
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  final ParseResult parse = runParser(runFrontEnd(deck));
  return runSemantics(parse, pedantic: pedantic);
}

List<String> _ids(SemanticResult result) => [
  for (final Diagnostic d in result.semanticDiagnostics) d.message.number,
];

ItemSemantics _sem(SemanticResult result, String name) => result
    .semantics
    .entries
    .firstWhere(
      (MapEntry<DataItem, ItemSemantics> e) => e.key.entry.name == name,
    )
    .value;

int _octal(String word) => int.parse(word, radix: 8);

void main() {
  group('the six-way classifier (M3-4)', () {
    test('classifies each chart type from mode and pictorial', () {
      final SemanticResult result = _map([
        dataCard(name: 'ALPHA', level: '1', description: 'A(3)'),
        dataCard(name: 'EXT', level: '1', mode: 'E', description: '99V9'),
        dataCard(name: 'INT', level: '1', mode: 'I', description: '999'),
        dataCard(name: 'EDIT', level: '1', description: r'$8889.99'),
        dataCard(name: 'FLOAT', level: '1', mode: 'I', description: 'F'),
        dataCard(name: 'SCI', level: '1', mode: 'E', description: '+99V9F+99'),
      ]);
      expect(_ids(result), isEmpty);
      expect(_sem(result, 'ALPHA').fieldClass, FieldClass.alphameric);
      expect(_sem(result, 'EXT').fieldClass, FieldClass.externalDecimal);
      expect(_sem(result, 'INT').fieldClass, FieldClass.internalDecimal);
      expect(_sem(result, 'EDIT').fieldClass, FieldClass.edited);
      expect(_sem(result, 'FLOAT').fieldClass, FieldClass.floatingPoint);
      expect(_sem(result, 'SCI').fieldClass, FieldClass.scientificDecimal);
    });

    test('digits with a blank mode are external decimal (J 90.05: HOURS)', () {
      final SemanticResult result = _map([
        dataCard(name: 'HOURS', level: '1', description: '99V9'),
      ]);
      expect(_sem(result, 'HOURS').fieldClass, FieldClass.externalDecimal);
      expect(_sem(result, 'HOURS').storageChars, 3);
    });

    test('BLANK WHEN ZERO alone makes the field edited (D3.2)', () {
      final SemanticResult result = _map([
        dataCard(name: 'B', level: '1', description: '999 BLANK WHEN ZERO'),
      ]);
      expect(_sem(result, 'B').fieldClass, FieldClass.edited);
    });

    test('a group is alphameric with the sum of its subfields (D3.3)', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'C1', level: '2', description: 'AA'),
        dataCard(name: 'C2', level: '2', mode: 'I', description: '99'),
      ]);
      final ItemSemantics group = _sem(result, 'G');
      expect(group.fieldClass, FieldClass.group);
      // C2 packs into the least multiple of 6 bits: 8 bits round to 2
      // characters (J 02.05.04).
      expect(_sem(result, 'C2').storageChars, 2);
      expect(group.charLength, 4);
    });

    test('edit characters under mode I draw 32,00 and the pictorial '
        'format is used', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: '88.99'),
      ]);
      expect(_ids(result), ['32,00']);
      expect(result.semanticDiagnostics.single.severity, 1);
      expect(_sem(result, 'X').fieldClass, FieldClass.edited);
    });

    test('FF under mode E draws 32,00 and reads as floating double', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: '9FF'),
      ]);
      expect(_ids(result), ['32,00']);
      final ItemSemantics sem = _sem(result, 'X');
      expect(sem.fieldClass, FieldClass.floatingPoint);
      expect(sem.doublePrecision, isTrue);
      expect(sem.storageChars, 12);
    });

    test('A mixed with edit characters draws 33,00 and the field is '
        'alphameric', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A9.9'),
      ]);
      expect(_ids(result), ['33,00']);
      final ItemSemantics sem = _sem(result, 'X');
      expect(sem.fieldClass, FieldClass.alphameric);
      expect(sem.storageChars, 4);
    });

    test('a mixed A and 9 pictorial downgrades silently (J 90.01.03)', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A99'),
      ]);
      expect(_ids(result), isEmpty);
      expect(_sem(result, 'X').fieldClass, FieldClass.alphameric);
    });

    test('--pedantic notes the mixed-pictorial downgrade with 933,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A99'),
      ], pedantic: true);
      expect(_ids(result), ['933,00']);
      expect(_sem(result, 'X').fieldClass, FieldClass.alphameric);
    });

    test('a scientific fraction over 16 digits draws 35,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: 'V9(17)F99'),
      ]);
      expect(_ids(result), ['35,00']);
      expect(_sem(result, 'X').fractionDigits, 16);
    });

    test('more than 10 digits is double precision (J 02.05.06)', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'D',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '9(11)',
        ),
        dataCard(name: 'P', level: '1'),
        dataCard(name: 'Q', level: '2', mode: 'I', description: '9(11)'),
      ]);
      final ItemSemantics register = _sem(result, 'D');
      expect(register.doublePrecision, isTrue);
      expect(register.storageChars, 12);
      // Packed double precision takes the least multiple of 6 bits:
      // 38 bits round to 7 characters (J 02.05.04).
      expect(_sem(result, 'Q').storageChars, 7);
    });

    test('an overpunch under mode I draws 32,00 and reads external', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: '99R'),
      ]);
      expect(_ids(result), ['32,00']);
      expect(_sem(result, 'X').fieldClass, FieldClass.externalDecimal);
    });

    test('a signed pictorial measures the overpunch (M3-5)', () {
      final SemanticResult result = _map([
        dataCard(name: 'S', level: '1', mode: 'E', description: '99R'),
      ]);
      final ItemSemantics sem = _sem(result, 'S');
      expect(sem.fieldClass, FieldClass.externalDecimal);
      expect(sem.sign, SignConvention.overpunchMinus);
      expect(sem.storageChars, 3);
    });

    test('a count with no right parenthesis draws 133,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: '9(4'),
      ]);
      expect(_ids(result), ['133,00']);
      final ItemSemantics sem = _sem(result, 'X');
      expect(sem.fieldClass, FieldClass.externalDecimal);
      expect(sem.storageChars, 4);
    });

    test('a zero repetition count draws 60,00 and one is used', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A(0)'),
      ]);
      expect(_ids(result), ['60,00']);
      expect(_sem(result, 'X').storageChars, 1);
    });

    test('an entry with no length draws 42,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'E', level: '2'),
      ]);
      expect(_ids(result), contains('42,00'));
    });

    test('a record given length only by a REDEF draws 42,00 '
        '(J 02.05.01)', () {
      final SemanticResult result = _map([
        dataCard(name: 'REC1', level: '1', type: 'RECORD'),
        dataCard(type: 'REDEF', description: 'REC1'),
        dataCard(name: 'AREA', level: '1', description: 'A(40)'),
      ]);
      // REC1 is nonformat and AREA is format-described, so the D9.11
      // position advisory accompanies the length diagnosis.
      expect(_ids(result), ['42,00', '104,00']);
      expect(_sem(result, 'AREA').storageChars, 40);
    });

    test('sub-organization under a formatted field draws 36,00 and '
        'reserves no storage', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A(6)'),
        dataCard(name: 'Y', level: '2', description: 'AA'),
      ]);
      expect(_ids(result), ['36,00']);
      expect(result.semanticDiagnostics.single.severity, 3);
      expect(_sem(result, 'Y').dropped, isTrue);
      expect(result.areas.single.extentWords, 1);
    });

    test('a COND entry with a Quantity draws 38,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'CV', level: '1', description: 'A'),
        dataCard(
          name: 'S',
          level: '2',
          type: 'COND',
          quantity: '5',
          description: "'X'",
        ),
      ]);
      expect(_ids(result), ['38,00']);
    });

    test('a LABEL entry with a Quantity draws 103,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'L',
          level: '1',
          type: 'LABEL',
          quantity: '5',
          description: 'A(6)',
        ),
      ]);
      expect(_ids(result), ['103,00']);
      expect(result.areas, isEmpty);
    });
  });

  group('the storage allocator (M3-6)', () {
    test('right justification of an external field ends at a word '
        'boundary (J 02.05.04)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'A1', level: '2', description: 'AA'),
        dataCard(name: 'RJ', level: '2', justify: 'R', description: '9999'),
        dataCard(name: 'B1', level: '2', description: 'A'),
      ]);
      final ItemSemantics field = _sem(result, 'RJ');
      expect(field.word, 1);
      expect(field.byte, 2);
      expect(_sem(result, 'B1').word, 2);
    });

    test('an internal right-justified field takes one whole word '
        'regardless of digit count (J 02.05.04)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'A1', level: '2', description: 'AA'),
        dataCard(
          name: 'W',
          level: '2',
          mode: 'I',
          justify: 'R',
          description: '9(5)',
        ),
      ]);
      final ItemSemantics word = _sem(result, 'W');
      expect(word.word, 1);
      expect(word.byte, 0);
      expect(word.storageChars, 6);
    });

    test('a repeated right-justified field right-aligns every '
        'occurrence (J 02.05.04)', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(
          name: 'R',
          level: '2',
          mode: 'E',
          justify: 'R',
          quantity: '3',
          description: '999',
        ),
        dataCard(name: 'Z', level: '2', description: 'A'),
      ]);
      expect(_ids(result), isEmpty);
      final ItemSemantics field = _sem(result, 'R');
      expect(field.startChar, 3);
      // The element extent is the reserved word, so each occurrence
      // right-aligns in its own word.
      expect(field.strideChars, 6);
      expect(field.extentChars, 15);
      expect(_sem(result, 'Z').startChar, 18);
    });

    test('a packed floating field lands on a word boundary '
        '(J 02.05.05)', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'P', level: '2', description: '999'),
        dataCard(name: 'FL', level: '2', mode: 'I', description: "F '1'"),
      ]);
      expect(_ids(result), isEmpty);
      expect(_sem(result, 'FL').startChar, 6);
      expect(result.areas.single.words, [isNull, _octal('201400000000')]);
    });

    test('a nested LABEL tree reserves no record storage '
        '(J 02.05.03)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'A1', level: '2', description: 'A(6)'),
        dataCard(name: 'L', level: '2', type: 'LABEL', description: 'A(12)'),
        dataCard(name: 'B1', level: '2', description: 'A(6)'),
      ]);
      expect(_ids(result), isEmpty);
      expect(_sem(result, 'L').spaceRoot, isNull);
      expect(_sem(result, 'B1').startChar, 6);
      expect(result.areas.single.extentWords, 2);
    });

    test('a group whose only child is a COPY draws 42,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'C', level: '2', type: 'COPY', description: 'X'),
      ]);
      expect(_ids(result), ['42,00']);
    });

    test('right justification on a group draws 39,00 and is ignored', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1', justify: 'R'),
        dataCard(name: 'C', level: '2', description: 'AA'),
      ]);
      expect(_ids(result), ['39,00']);
      expect(_sem(result, 'G').justification, Justification.left);
    });

    test('--pedantic notes an ineffective R with 935,00', () {
      final List<String> data = [
        dataCard(name: 'K', level: '1'),
        dataCard(name: 'X', level: '2', justify: 'R', description: "'AB'"),
      ];
      final SemanticResult plain = _map(data);
      expect(_ids(plain), isEmpty);
      final SemanticResult result = _map(data, pedantic: true);
      expect(_ids(result), ['935,00']);
      // The site stays inert in both modes (D11.4).
      expect(_sem(result, 'X').justification, Justification.packed);
      expect(_sem(plain, 'X').justification, Justification.packed);
    });

    test('quantity repeats the whole structure by its extent (M3-6)', () {
      final SemanticResult result = _map([
        dataCard(name: 'T', level: '1'),
        dataCard(name: 'E', level: '2', quantity: '12'),
        dataCard(
          name: 'RATE',
          level: '3',
          mode: 'I',
          justify: 'R',
          description: '99V999',
        ),
        dataCard(name: 'INSPREM', level: '3', description: '9V99'),
        dataCard(name: 'RETPREM', level: '3', description: '9V99'),
      ]);
      final ItemSemantics element = _sem(result, 'E');
      expect(element.strideChars, 12);
      expect(element.extentChars, 144);
      expect(result.areas.single.extentWords, 24);
    });

    test('a REDEF overlays the target and restores the counter '
        '(D3.4)', () {
      final SemanticResult result = _map([
        dataCard(name: 'T', level: '1', description: 'A(12)'),
        dataCard(type: 'REDEF', description: 'T'),
        dataCard(name: 'U', level: '1'),
        dataCard(name: 'U1', level: '2', description: 'A(6)'),
        dataCard(name: 'U2', level: '2', description: 'A(6)'),
        dataCard(name: 'W', level: '1', description: 'AA'),
      ]);
      expect(_ids(result), isEmpty);
      final ItemSemantics overlay = _sem(result, 'U2');
      expect(overlay.word, 1);
      // U redefines T, so W's area follows T's two words.
      expect([for (final AreaInfo a in result.areas) a.name], ['T', 'W']);
    });

    test('a redefinition longer than its target grows the area '
        '(J 02.05.02)', () {
      final SemanticResult result = _map([
        dataCard(name: 'A', level: '1'),
        dataCard(name: 'B', level: '2', description: 'A(3)'),
        dataCard(type: 'REDEF', description: 'A'),
        dataCard(name: 'C', level: '1'),
        dataCard(name: 'D', level: '2', description: 'A(6)'),
        dataCard(name: 'E', level: '2', type: 'RCDMRK', description: 'A'),
      ]);
      expect(_ids(result), isEmpty);
      final AreaInfo area = result.areas.single;
      expect(area.extentWords, 2);
      expect(area.words, [isNull, _octal('720000000000')]);
    });

    test('a REDEF to a later definition draws 40,00', () {
      final SemanticResult result = _map([
        dataCard(type: 'REDEF', description: 'LATER'),
        dataCard(name: 'X', level: '1', description: 'AA'),
        dataCard(name: 'LATER', level: '1', description: 'AA'),
      ]);
      expect(_ids(result), ['40,00']);
    });

    test('a REDEF naming nothing draws 41,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'AA'),
        dataCard(type: 'REDEF', description: 'NOWHERE'),
        dataCard(name: 'Y', level: '1', description: 'AA'),
      ]);
      expect(_ids(result), ['41,00']);
    });

    test('a REDEF to a COND entry draws 45,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'CV', level: '2', description: 'A'),
        dataCard(name: 'SGL', level: '3', type: 'COND', description: "'S'"),
        dataCard(type: 'REDEF', description: 'SGL'),
        dataCard(name: 'Y', level: '2', description: 'A'),
      ]);
      expect(_ids(result), ['45,00']);
    });

    test('a REDEF naming a file draws 46,00', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'X', level: '1', description: 'AA'),
          dataCard(type: 'REDEF', description: 'F1'),
          dataCard(name: 'Y', level: '1', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,X,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), contains('46,00'));
    });

    test('a redefinition at a different level draws 81,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'T', level: '1', description: 'A(6)'),
        dataCard(type: 'REDEF', description: 'T'),
        dataCard(name: 'U', level: '2', justify: 'L', description: 'A(6)'),
      ]);
      expect(_ids(result), ['81,00']);
    });

    test('a redefinition with different justification draws 80,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'X', level: '2', description: 'A(6)'),
        dataCard(type: 'REDEF', description: 'X'),
        dataCard(name: 'Y', level: '2', justify: 'L', description: 'A(6)'),
      ]);
      expect(_ids(result), ['80,00']);
    });

    test('a REDEF between nonformat and format levels draws 104,00 '
        '(D9.11)', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: 'A(6)'),
        dataCard(name: 'G', level: '1'),
        dataCard(type: 'REDEF', description: 'X'),
        dataCard(name: 'F', level: '2', description: 'AA'),
      ]);
      expect(_ids(result), contains('104,00'));
    });

    test('quantity nesting past three levels draws 930,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'A', level: '1', quantity: '2'),
        dataCard(name: 'B', level: '2', quantity: '2'),
        dataCard(name: 'C', level: '3', quantity: '2'),
        dataCard(name: 'D', level: '4', quantity: '2', description: 'AA'),
      ]);
      expect(_ids(result), ['930,00']);
      expect(result.semanticDiagnostics.single.severity, 2);
      expect(_sem(result, 'D').quantity, 1);
      // The repair lands before the D3.3 length pass, so the group
      // length agrees with the storage allocated.
      expect(_sem(result, 'C').charLength, 2);
      expect(result.areas.single.extentWords, 3);
    });

    test('--pedantic notes a Quantity on an unnamed entry with '
        '934,00', () {
      final List<String> data = [
        dataCard(name: 'G', level: '1'),
        dataCard(level: '2', quantity: '5', description: 'AA'),
      ];
      expect(_ids(_map(data)), isEmpty);
      final SemanticResult result = _map(data, pedantic: true);
      expect(_ids(result), ['934,00']);
    });

    test('QUANTITY IN with a blank Quantity draws 44,00 and one is '
        'assumed', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'CNT',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
        dataCard(name: 'G', level: '1'),
        dataCard(name: 'V', level: '2', description: 'A(6) QUANTITY IN CNT'),
      ]);
      expect(_ids(result), ['44,00']);
      final ItemSemantics variable = _sem(result, 'V');
      expect(variable.quantity, 1);
      expect(variable.variableLength, isTrue);
    });

    test('QUANTITY IN on a group draws 47,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'CNT',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
        dataCard(
          name: 'G',
          level: '1',
          quantity: '5',
          description: 'QUANTITY IN CNT',
        ),
        dataCard(name: 'C', level: '2', description: 'AA'),
      ]);
      expect(_ids(result), ['47,00']);
    });

    test('QUANTITY IN naming an alphameric field draws 102,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'CNT', level: '1', description: 'AA'),
        dataCard(name: 'G', level: '1'),
        dataCard(
          name: 'V',
          level: '2',
          quantity: '5',
          description: 'A(6) QUANTITY IN CNT',
        ),
      ]);
      expect(_ids(result), ['102,00']);
    });

    test('a count field after its variable field draws 105,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(
          name: 'V',
          level: '2',
          quantity: '5',
          description: 'A(6) QUANTITY IN CNT',
        ),
        dataCard(
          name: 'CNT',
          level: '2',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
      ]);
      expect(_ids(result), ['105,00']);
    });
  });

  group('initial images (M3-7)', () {
    test('an internal constant stores its binary value (J 90.05: '
        "TABLE's rate words)", () {
      final SemanticResult result = _map([
        dataCard(name: 'T', level: '1'),
        dataCard(
          level: '2',
          mode: 'I',
          justify: 'R',
          description: "9(5) '00999'",
        ),
        dataCard(level: '2', description: "'080060'"),
      ]);
      expect(_ids(result), isEmpty);
      expect(result.areas.single.words, [
        _octal('000000001747'),
        _octal('001000000600'),
      ]);
    });

    test('a record blank-fills its partial final word (J 90.05.04)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'F', level: '2', description: "A '1'"),
        dataCard(name: 'G', level: '2', description: 'AA'),
      ]);
      expect(result.areas.single.words, [_octal('010000606060')]);
    });

    test('the blank shorthand fills a longer pictorial (J 90.05.04)', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: "A(3) ' '"),
      ]);
      expect(_ids(result), isEmpty);
      expect(result.areas.single.words, [_octal('606060000000')]);
    });

    test('RCDMRK inserts the record mark constant (J 02.05.03)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'M', level: '2', type: 'RCDMRK', description: 'A'),
      ]);
      expect(result.areas.single.words, [_octal('726060606060')]);
    });

    test('a wholly uninitialized word has no image (M3-7)', () {
      final SemanticResult result = _map([
        dataCard(name: 'R', level: '1', type: 'RECORD'),
        dataCard(name: 'A1', level: '2', description: "A '1'"),
        dataCard(name: 'B1', level: '2', description: 'A(11)'),
        dataCard(name: 'C1', level: '2', description: "A(6) 'X'"),
      ]);
      final AreaInfo area = result.areas.single;
      expect(area.words[0], isNotNull);
      expect(area.words[1], isNull);
      expect(area.words[2], isNotNull);
    });

    test('an over-long alphabetic constant draws 59,00 and is '
        'truncated', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: "A(2) 'ABC'"),
      ]);
      expect(_ids(result), ['59,00']);
      expect(result.areas.single.words, [_octal('212200000000')]);
    });

    test('an external constant of the wrong length draws 51,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: "999 '12'"),
      ]);
      expect(_ids(result), ['51,00']);
      expect(result.areas.single.words, [isNull]);
    });

    test('an over-long internal constant draws 51,00 and is '
        'left-truncated (J 02.05.07)', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'X',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: "9(2) '123'",
        ),
      ]);
      expect(_ids(result), ['51,00']);
      expect(result.areas.single.words, [_octal('000000000027')]);
    });

    test('a signed internal constant sets the sign bit (J 02.05.04)', () {
      final SemanticResult minus = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: "9(3) '-123'"),
      ]);
      expect(_ids(minus), isEmpty);
      expect(minus.areas.single.words, [_octal('417300000000')]);
      final SemanticResult trailing = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: "9(3) '123-'"),
      ]);
      expect(_ids(trailing), isEmpty);
      expect(trailing.areas.single.words, [_octal('417300000000')]);
      final SemanticResult imbedded = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: "9(3) '1-3'"),
      ]);
      expect(_ids(imbedded), ['67,00']);
    });

    test('a double-precision register constant splits across two '
        'words (M3-7 reconstruction)', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'D',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: "9(13) '1234567890123'",
        ),
      ]);
      expect(_ids(result), isEmpty);
      expect(result.areas.single.words, [
        _octal('000000000043'),
        _octal('356176602313'),
      ]);
    });

    test('a register field over 21 digits draws 35,00 and 21 are '
        'kept (M3-16)', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'BIG',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: "9(24) '123456789012345678901234'",
        ),
      ]);
      expect(_ids(result), ['35,00', '51,00']);
      expect(result.areas.single.words, [
        _octal('143031611121'),
        _octal('316555527762'),
      ]);
    });

    test('a double-precision floating constant stores the low word '
        '(M3-7 reconstruction)', () {
      final SemanticResult result = _map([
        dataCard(name: 'D', level: '1', mode: 'I', description: "FF '1'"),
      ]);
      expect(_ids(result), isEmpty);
      expect(result.areas.single.words, [
        _octal('201400000000'),
        _octal('146000000000'),
      ]);
    });

    test('a repeated entry reports its constant condition once', () {
      final SemanticResult result = _map([
        dataCard(name: 'G', level: '1'),
        dataCard(
          name: 'A1',
          level: '2',
          quantity: '3',
          description: "A(2) 'ABCDE'",
        ),
      ]);
      expect(_ids(result), ['59,00']);
    });

    test('an imbedded blank in a numeric constant draws 67,00; a '
        'leading blank reads as zero ([J 02.05.05] note 3)', () {
      final SemanticResult imbedded = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: "999 '1 3'"),
      ]);
      expect(_ids(imbedded), ['67,00']);
      final SemanticResult leading = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: "999 ' 13'"),
      ]);
      expect(_ids(leading), isEmpty);
    });

    test('an external constant matching its overpunch stores the zone '
        'letter (J 02.05.07)', () {
      final SemanticResult result = _map([
        dataCard(name: 'S', level: '1', mode: 'E', description: "99R '12L'"),
      ]);
      expect(_ids(result), isEmpty);
      expect(result.areas.single.words, [_octal('010243000000')]);
    });

    test('an external constant without the pictorial sign draws '
        '58,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'S', level: '1', mode: 'E', description: "99R '123'"),
      ]);
      expect(_ids(result), ['58,00']);
    });

    test('a non-numeric character in a numeric constant draws 67,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'X',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: "99 '1X'",
        ),
      ]);
      expect(_ids(result), ['67,00']);
    });

    test('a constant on an edited field draws 57,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', description: "88.99 '12.34'"),
      ]);
      expect(_ids(result), ['57,00']);
    });

    test('an illegal scientific constant character draws 54,00', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'E', description: "9F9 'A9'"),
      ]);
      expect(_ids(result), ['54,00']);
    });

    test('a floating constant too large draws 55,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'X',
          level: '1',
          mode: 'I',
          description: "F '9999999999999999999999999999999",
          continued: true,
        ),
        dataCard(description: "99999999'"),
      ]);
      expect(_ids(result), ['55,00']);
    });

    test('a floating constant too small draws 56,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'X',
          level: '1',
          mode: 'I',
          description: "F '.0000000000000000000000000000000",
          continued: true,
        ),
        dataCard(description: "0000000001'"),
      ]);
      expect(_ids(result), ['56,00']);
    });

    test('a floating constant stores the 7090 form', () {
      final SemanticResult result = _map([
        dataCard(name: 'X', level: '1', mode: 'I', description: "F '1'"),
      ]);
      // +1.0: characteristic 201 octal, fraction 400000000 octal.
      expect(result.areas.single.words, [_octal('201400000000')]);
    });

    test('a constant inside a redefinition draws 43,00 and is not '
        'stored (D3.6)', () {
      final SemanticResult result = _map([
        dataCard(name: 'T', level: '1', description: "A(6) 'ORIGIN'"),
        dataCard(type: 'REDEF', description: 'T'),
        dataCard(name: 'U', level: '1'),
        dataCard(name: 'U1', level: '2', description: "A(6) 'ABCDEF'"),
      ]);
      expect(_ids(result), ['43,00']);
      // The original definition's constant stands (D3.6: entries
      // preceding the REDEF are exempt).
      expect(result.areas.single.words, [_octal('465131273145')]);
    });

    test('a constant after a variable length field draws 43,00', () {
      final SemanticResult result = _map([
        dataCard(
          name: 'CNT',
          level: '1',
          mode: 'I',
          justify: 'R',
          description: '99',
        ),
        dataCard(name: 'G', level: '1'),
        dataCard(
          name: 'V',
          level: '2',
          quantity: '2',
          description: 'A(6) QUANTITY IN CNT',
        ),
        dataCard(name: 'C', level: '2', description: "A '1'"),
      ]);
      expect(_ids(result), ['43,00']);
    });

    test('a constant in a located input record draws 43,00 '
        '(J 02.05.06)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'F', level: '2', description: "A(6) 'ABCDEF'"),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['43,00']);
      expect(result.areas, isEmpty);
    });
  });

  group('the environment binder (M3-11)', () {
    test('classifies records located or transmitted (J 02.07.05)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'RIN', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(6)'),
          dataCard(name: 'ROUT', level: '1', type: 'RECORD'),
          dataCard(name: 'B1', level: '2', description: 'A(6)'),
          dataCard(name: 'PLAIN', level: '1', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,RIN,BLOCKSIZE 5',
          ),
          environmentCard(
            name: 'FOUT',
            type: 'FILE',
            options: 'OUTPUT,BCD,TAPE,ROUT,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
      final RecordInfo rin = result.records[0];
      expect(rin.located, isTrue);
      final RecordInfo rout = result.records[1];
      expect(rout.located, isFalse);
      // The located record takes no area (M3-11).
      expect(
        [for (final AreaInfo a in result.areas) a.name],
        ['ROUT', 'PLAIN'],
      );
    });

    test('an input record containing an array is transmitted '
        '(J 90.01.01)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'RIN', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', quantity: '3', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,RIN,BLOCKSIZE 5',
          ),
        ],
      );
      expect(result.records.single.located, isFalse);
      expect(result.areas.single.name, 'RIN');
    });

    test('a variable record is marked and sized at its maximum '
        '(J 02.07.03)', () {
      final SemanticResult result = _map(
        [
          dataCard(
            name: 'CNT',
            level: '1',
            mode: 'I',
            justify: 'R',
            description: '99',
          ),
          dataCard(name: 'RV', level: '1', type: 'RECORD'),
          dataCard(
            name: 'V',
            level: '2',
            quantity: '5',
            description: 'A(6) QUANTITY IN CNT',
          ),
        ],
        environment: [
          environmentCard(
            name: 'FOUT',
            type: 'FILE',
            options: 'OUTPUT,BCD,TAPE,RV,BLOCKSIZE 6',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
      final RecordInfo record = result.records.single;
      expect(record.variable, isTrue);
      expect(result.areas.last.extentWords, 5);
    });

    test('a REDEF sharing an input record area draws 932,00 and '
        'transmits', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'RIN', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(6)'),
          dataCard(type: 'REDEF', description: 'RIN'),
          dataCard(name: 'OTHER', level: '1', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,RIN,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['932,00']);
      final RecordInfo record = result.records.single;
      expect(record.located, isFalse);
      expect(record.forcedTransmit, isTrue);
      expect(result.areas.single.name, 'RIN');
    });

    test('records of different files REDEFined together stay located '
        '(J 90.01.01)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'RIN', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(6)'),
          dataCard(type: 'REDEF', description: 'RIN'),
          dataCard(name: 'RTWO', level: '1', type: 'RECORD'),
          dataCard(name: 'B1', level: '2', description: 'A(6)'),
        ],
        environment: [
          environmentCard(
            name: 'FIN',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,RIN,BLOCKSIZE 5',
          ),
          environmentCard(
            name: 'FTWO',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,RTWO,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
      expect(result.records[0].located, isTrue);
      expect(result.records[1].located, isTrue);
      expect(result.areas, isEmpty);
    });

    test('a FILE card naming no record draws 13,00', () {
      final SemanticResult result = _map(
        [dataCard(name: 'X', level: '1', description: 'AA')],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['13,00']);
    });

    test('a FILE-card record name with no data entry draws 15,00', () {
      final SemanticResult result = _map(
        [dataCard(name: 'X', level: '1', description: 'AA')],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,NOPE,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['15,00']);
    });

    test('a FILE-card record name that is not a RECORD draws 16,00', () {
      final SemanticResult result = _map(
        [dataCard(name: 'X', level: '1', description: 'AA')],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,X,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['16,00']);
    });

    test('a record on two input FILE cards draws 11,00', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5',
          ),
          environmentCard(
            name: 'F2',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['11,00']);
    });

    test('a SPECIF naming no FILE card draws 21,00', () {
      final SemanticResult result = _map(
        [dataCard(name: 'X', level: '1', description: 'AA')],
        environment: [
          environmentCard(type: 'SPECIF', options: "NOFILE,UNIT1 'A1'"),
        ],
      );
      expect(_ids(result), ['21,00']);
    });

    test('a record longer than its BLOCKSIZE without SPANS draws '
        '5,00', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(30)'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'OUTPUT,BCD,TAPE,R1,BLOCKSIZE 3',
          ),
        ],
      );
      expect(_ids(result), ['5,00']);
      expect(result.semanticDiagnostics.single.severity, 4);
    });

    test('SPANS lifts the record-fit check (J 02.06.04)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(30)'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'OUTPUT,BCD,TAPE,R1,BLOCKSIZE 3,SPANS',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
    });

    test('SPANS on an input file transmits the record (J 02.07.05)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'A(30)'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 3,SPANS',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
      expect(result.records.single.located, isFalse);
      expect(result.areas.single.name, 'R1');
    });

    test('an input card file under 24 words draws 209,00 and 24 is '
        'used', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,CARD,R1,BLOCKSIZE 10',
          ),
        ],
      );
      expect(_ids(result), ['209,00']);
      expect(result.semanticDiagnostics.single.severity, 1);
    });

    test('a BLOCKSIZE over 9999 draws 931,00 and the card is '
        'rejected (D7.1)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 10000',
          ),
        ],
      );
      expect(_ids(result), ['931,00']);
      expect(result.semanticDiagnostics.single.severity, 4);
      expect(result.records.single.inputFiles, isEmpty);
    });

    test('a BLOCKSIZE of 9999 is honored without diagnostic (D7.1)', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(name: 'A1', level: '2', description: 'AA'),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'INPUT,BCD,TAPE,R1,BLOCKSIZE 9999',
          ),
        ],
      );
      expect(_ids(result), isEmpty);
    });

    test('an internal-mode record on a BCD output file draws 20,00', () {
      final SemanticResult result = _map(
        [
          dataCard(name: 'R1', level: '1', type: 'RECORD'),
          dataCard(
            name: 'A1',
            level: '2',
            mode: 'I',
            justify: 'R',
            description: '99',
          ),
        ],
        environment: [
          environmentCard(
            name: 'F1',
            type: 'FILE',
            options: 'OUTPUT,BCD,TAPE,R1,BLOCKSIZE 5',
          ),
        ],
      );
      expect(_ids(result), ['20,00']);
    });
  });

  group('the driver wiring (M3-2)', () {
    test('runs the semantic phase per job and skips it after a stop '
        '(D10.2)', () {
      final List<String> lines = [
        r'$CMPLE GOOD',
        '      *DATA',
        dataCard(name: 'X', level: '1', description: 'AA'),
        '      *FINISH',
        r'$CMPLE BAD',
        '      *DATA',
        dataCard(
          name: 'B',
          level: '1',
          description: "'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
          continued: true,
        ),
        dataCard(
          description: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
          continued: true,
        ),
        dataCard(
          description: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
          continued: true,
        ),
        dataCard(description: "AAAAAAAAAAAAAAAAAAAAAAA'"),
        '      *FINISH',
        r'$CMPLE WIDE',
        '      *PROCEDURE',
        for (var i = 1; i <= 36; i++) ...[
          '      ${'S$i.'.padRight(12)}BEGIN SECTION.',
          '            END S$i.',
        ],
        '      *FINISH',
      ];
      final DeckCompilation deck = compileDeck(
        mirrorToDeck('${lines.join('\n')}\n'),
      );
      expect(deck.jobs[0].semantics, isNotNull);
      // The second job's over-long constant stops the front end at
      // severity 5 (msg 148); the semantic phase never runs.
      expect(deck.jobs[1].parse, isNull);
      expect(deck.jobs[1].semantics, isNull);
      // The third job's 36th section stops the parser (msg 149); the
      // partial parse survives and the semantic phase is skipped.
      expect(deck.jobs[2].parse, isNotNull);
      expect(deck.jobs[2].parse!.stopped, isTrue);
      expect(deck.jobs[2].semantics, isNull);
    });

    test('--pedantic adds diagnostics and changes no image (D11.4)', () {
      final List<String> data = [
        dataCard(name: 'X', level: '1', description: 'A99'),
        dataCard(name: 'Y', level: '1', description: "A(3) 'AB'"),
      ];
      final SemanticResult plain = _map(data);
      final SemanticResult pedantic = _map(data, pedantic: true);
      expect(_ids(plain), isEmpty);
      expect(_ids(pedantic), ['933,00']);
      expect(
        [for (final AreaInfo area in pedantic.areas) area.words],
        [for (final AreaInfo area in plain.areas) area.words],
      );
    });
  });
}
