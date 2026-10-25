/// The machine assembly (RT-1): the dispatch rule, the step budget, the
/// 1962 sample over its input tapes, one program run end to end, and
/// the `--run` flag that carries it to the command line, outcome by
/// outcome.
library;

import 'dart:io';

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import '../emulator/asm.dart';
import '../support/deck_fixtures.dart';
import 'runtime_support.dart';

const ListingOptions _options = ListingOptions(date: '10/18/61', time: '2.45');

/// An I/O-free program: one `SET` over two internal-decimal fields, then
/// `STOP RUN`.
final List<String> _source = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(
    name: 'TOT',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  SET TOT = NUM + 1.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that halts on `STOP n` and then runs on: the `SET` after
/// the halt stores only if the run resumes in sequence (D2.7).
final List<String> _halt = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  STOP 1234.',
  '            SET NUM = NUM + 1.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that computes with an external-decimal field (M6-9). The
/// literal row under REDEF gives EXT the characters `0425`, so EXT
/// reads 4.25.
final List<String> _external = <String>[
  '      *DATA',
  dataCard(name: 'AREA', level: '1'),
  dataCard(level: '2', description: "'0425'"),
  dataCard(type: 'REDEF', description: 'AREA'),
  dataCard(name: 'VIEW', level: '1'),
  dataCard(name: 'EXT', level: '2', mode: 'E', description: '99V99'),
  dataCard(
    name: 'TOT',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999V99',
  ),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  SET TOT = EXT + 1.50.',
  '            IF EXT GT 4.00 THEN SET NUM = NUM + 1.',
  '            IF EXT GT 4.25 THEN SET NUM = NUM + 10.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that compares operands of unequal scales (M6-9). EXT reads
/// 40.0 through the REDEF row, as HOURS does in the applied deck. If
/// the compare skips the alignment, four of the five comparisons give
/// the wrong value; only 4.5 GT 4 stays true.
final List<String> _scales = <String>[
  '      *DATA',
  dataCard(name: 'AREA', level: '1'),
  dataCard(level: '2', description: "'400'"),
  dataCard(type: 'REDEF', description: 'AREA'),
  dataCard(name: 'VIEW', level: '1'),
  dataCard(name: 'EXT', level: '2', mode: 'E', description: '99V9'),
  dataCard(
    name: 'FRAC',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V9',
  ),
  dataCard(name: 'FIVE', level: '1', mode: 'I', justify: 'R', description: '9'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9999',
  ),
  dataCard(name: 'TOT', level: '1', mode: 'I', justify: 'R', description: '9'),
  '      *PROCEDURE',
  '      START.  SET FRAC = 4.5, SET FIVE = 5.',
  '            IF FRAC GT 4 THEN SET NUM = NUM + 1.',
  '            IF FRAC GT 5 THEN SET NUM = NUM + 10.',
  '            IF EXT = 40 THEN SET NUM = NUM + 100.',
  '            IF EXT GT 40 THEN SET NUM = NUM + 1000.',
  '            IF FRAC LT FIVE THEN SET TOT = TOT + 1.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that loads a nonzero literal of equal scale into the
/// accumulator (M6-9). A vector read the wrong way round gives NUM 10.
final List<String> _literalLeft = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  IF 5 GT NUM THEN SET NUM = NUM + 1.',
  '            IF 5 LT NUM THEN SET NUM = NUM + 10.',
  '            IF 4 LT 5 THEN SET NUM = NUM + 100.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that computes the shape of the applied deck's statement
/// 141,00 (M6-9). HRS reads 45.0 through the REDEF row, so the product
/// is 5.0 * RATE * 1.5 at scale 5, and the store divides it by 1000.
final List<String> _product = <String>[
  '      *DATA',
  dataCard(name: 'AREA', level: '1'),
  dataCard(level: '2', description: "'450'"),
  dataCard(type: 'REDEF', description: 'AREA'),
  dataCard(name: 'VIEW', level: '1'),
  dataCard(name: 'HRS', level: '2', mode: 'E', description: '99V9'),
  for (final String name in <String>['RATE', 'EVEN'])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: '99V999',
    ),
  for (final String name in <String>['GROSS', 'GROSS2'])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: '99999V99',
    ),
  '      *PROCEDURE',
  '      START.  SET RATE = 2.505, SET EVEN = 2.500.',
  '            SET GROSS = (HRS - 40) * RATE * 1.5.',
  '            SET GROSS2 = (HRS - 40) * EVEN * 1.5.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that stores into external-decimal fields (M6-9). HRS reads
/// 45.0 through the REDEF row. GROSS is unsigned, MINUS carries a minus
/// overpunch and PLUS a plus overpunch.
final List<String> _externalStore = <String>[
  '      *DATA',
  dataCard(name: 'AREA', level: '1'),
  dataCard(level: '2', description: "'450'"),
  dataCard(type: 'REDEF', description: 'AREA'),
  dataCard(name: 'VIEW', level: '1'),
  dataCard(name: 'HRS', level: '2', mode: 'E', description: '99V9'),
  dataCard(
    name: 'RATE',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '99V999',
  ),
  dataCard(name: 'GROSS', level: '1', mode: 'E', description: '99999V99'),
  dataCard(name: 'MINUS', level: '1', mode: 'E', description: '9V9R'),
  dataCard(name: 'PLUS', level: '1', mode: 'E', description: '9V9I'),
  dataCard(
    name: 'BACK',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V99',
  ),
  '      *PROCEDURE',
  '      START.  SET RATE = 2.505.',
  '            SET GROSS = (HRS - 40) * RATE * 1.5.',
  '            ADD GROSS TO GROSS.',
  '            SET MINUS = (HRS - 47.5) * 1.1.',
  '            SET PLUS = (HRS - 40) * 1.05.',
  '            SET BACK = MINUS.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that stores chains of scale 3 into fields of scale 2
/// (M6-9). UP, DOWN, NEG and CUT are internal; EUP, EDOWN and ENEG are
/// external, ENEG with a minus overpunch.
final List<String> _chainStore = <String>[
  '      *DATA',
  for (final (String name, String picture) in <(String, String)>[
    ('RATE', '99V999'),
    ('LOW', '99V999'),
    ('UP', '99V99'),
    ('DOWN', '99V99'),
    ('NEG', '99V99'),
    ('CUT', '99V99'),
  ])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: picture,
    ),
  dataCard(name: 'EUP', level: '1', mode: 'E', description: '9V99'),
  dataCard(name: 'EDOWN', level: '1', mode: 'E', description: '9V99'),
  dataCard(name: 'ENEG', level: '1', mode: 'E', description: '9V9R'),
  '      *PROCEDURE',
  '      START.  SET RATE = 2.505, SET LOW = 2.504.',
  '            SET UP = RATE + 1, SET DOWN = LOW + 1.',
  '            SET NEG = RATE - 4.99, SET CUT = RATE + 1 TRUNCATED.',
  '            SET EUP = RATE + 1, SET EDOWN = LOW + 1.',
  '            SET ENEG = RATE - 4.99.',
  '            STOP RUN.',
  '      *FINISH',
];

/// The shape of statement 145,00 of the applied deck (M6-9): six
/// external fields of DETAIL's pictorials, chained into PAYRECORD
/// NETPAY's `$88889.99-` once for a positive and once for a negative
/// net pay.
final List<String> _editedChain = <String>[
  '      *DATA',
  for (final (String name, String picture) in <(String, String)>[
    ('GROSS', '99999V99'),
    ('FICA', '999V99'),
    ('WHT', '9999V99'),
    ('RETIRE', '999V99'),
    ('INSURE', '999V99'),
    ('BOND', '99V99'),
  ])
    dataCard(name: name, level: '1', mode: 'E', description: picture),
  dataCard(name: 'NETPAY', level: '1', description: r'$88889.99-'),
  dataCard(name: 'NETNEG', level: '1', description: r'$88889.99-'),
  '      *PROCEDURE',
  '      START.  SET GROSS = 412.50, SET FICA = 12.38, SET WHT = 45.10.',
  '            SET RETIRE = 20.63, SET INSURE = 8.25, SET BOND = 18.75.',
  '            SET NETPAY = GROSS - FICA - WHT - RETIRE - INSURE - BOND.',
  '            SET GROSS = 40.00.',
  '            SET NETNEG = GROSS - FICA - WHT - RETIRE - INSURE - BOND.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that moves an edited field into a narrower one (M6-9):
/// statement 146,00's pictorials over [net], then F p. 43's `99999` row
/// into an edited receiver over [ext].
List<String> _droppedDigits(String net, String ext) => <String>[
  '      *DATA',
  dataCard(name: 'NET', level: '1', description: r'$88889.99-'),
  dataCard(name: 'AMT', level: '1', description: r'$***9.99'),
  dataCard(name: 'EXF', level: '1', mode: 'E', description: '99999'),
  dataCard(name: 'EDF', level: '1', description: '999.9'),
  '      *PROCEDURE',
  '      START.  SET NET = $net, MOVE NET TO AMT.',
  '            SET EXF = $ext, MOVE EXF TO EDF.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that moves external fields into external fields (M6-9):
/// statement 162,00's `999V99` pair, then a minus value into each sign
/// convention, then a plus value into a plus overpunch.
final List<String> _externalMove = <String>[
  '      *DATA',
  for (final (String name, String picture) in <(String, String)>[
    ('SRC', '999V99'),
    ('NEG', '999V9R'),
    ('SAME', '999V99'),
    ('MOUT', '999V9R'),
    ('POUT', '999V9I'),
    ('UOUT', '999V99'),
    ('PLUS', '999V9I'),
  ])
    dataCard(name: name, level: '1', mode: 'E', description: picture),
  '      *PROCEDURE',
  '      START.  SET SRC = 275.33, MOVE SRC TO SAME.',
  '            SET NEG = 2.75 - 5.50.',
  '            MOVE NEG TO MOUT, POUT, UOUT.',
  '            MOVE SRC TO PLUS.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that compares the expressions of the applied deck's
/// statements 152,00 and 156,00 (M6-9), with every operand external at
/// the deck's pictorials. FIRST reads 1 when the THEN arm of 152 runs
/// and 2 when the OTHERWISE arm does; SECOND does the same for 156.
List<String> _expressionCompare(
  String fica,
  String gross,
  String ex,
) => <String>[
  '      *DATA',
  dataCard(name: 'FICA', level: '1', mode: 'E', description: '999V99'),
  dataCard(name: 'GROSS', level: '1', mode: 'E', description: '99999V99'),
  dataCard(name: 'EX', level: '1', mode: 'E', description: '99'),
  for (final String name in <String>['FIRST', 'SECOND'])
    dataCard(name: name, level: '1', mode: 'I', justify: 'R', description: '9'),
  '      *PROCEDURE',
  '      START.  SET FICA = $fica, SET GROSS = $gross, SET EX = $ex.',
  '            IF FICA + 0.03 * GROSS IS LESS THAN 144.00 THEN SET',
  '            FIRST = 1 OTHERWISE SET FIRST = 2.',
  '            IF 13 * EX IS LESS THAN GROSS THEN SET SECOND = 1',
  '            OTHERWISE SET SECOND = 2.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program whose expression comparison holds a truth function that
/// compares an expression (M6-9). The truth function is the first term,
/// so its chain reads RS)0 before the outer chain parks in RS)1, and its
/// park takes TS)2 above the outer TS)1. FLAG reads 1 on the THEN arm.
List<String> _nestedCompare(String num, String frac) => <String>[
  '      *DATA',
  dataCard(name: 'NUM', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'FRAC',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V9',
  ),
  dataCard(name: 'FLAG', level: '1', mode: 'I', justify: 'R', description: '9'),
  '      *PROCEDURE',
  '      START.  SET NUM = $num, SET FRAC = $frac.',
  '            IF TR (NUM + 1 GT FRAC) * 1 + NUM * 2 GT 14 THEN SET',
  '            FLAG = 1 OTHERWISE SET FLAG = 2.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program whose chain sits above its edited target's scale (M6-9):
/// the scaling tail ends in `XCA` and the SYS)180 call.
final List<String> _editedTail = <String>[
  '      *DATA',
  dataCard(
    name: 'FR3',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '9V999',
  ),
  dataCard(name: 'NET', level: '1', description: r'$88889.99-'),
  '      *PROCEDURE',
  '      START.  SET FR3 = 1.238, SET NET = FR3 + FR3.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that stores into an external-decimal field of a located
/// input record (M6-9): the store's `MZE` reference names the record's
/// base locator.
final List<String> _locatedStore = <String>[
  '      *DATA',
  dataCard(name: 'IREC', level: '1', type: 'RECORD'),
  dataCard(name: 'IFLD', level: '2', mode: 'E', description: '99R'),
  dataCard(name: 'IPAD', level: '2', description: 'AAA'),
  '      *ENVIRONMENT',
  environmentCard(
    name: 'TAPE1',
    type: 'FILE',
    options: 'INPUT,BCD,TAPE,IREC,BLOCKSIZE 1',
  ),
  environmentCard(type: 'SPECIF', options: "TAPE1,UNIT1 'D1'"),
  '      *PROCEDURE',
  '      START.  OPEN ALL FILES, GET IREC, AT END GO TO RTN.',
  '            SET IFLD = IFLD - 200.',
  '      RTN.  STOP RUN.',
  '      *FINISH',
];

/// A program whose entry point is a labelled section (D2.1). The `GO TO`
/// ahead of the section runs only if the entry lands on `GN)000`.
final List<String> _section = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '            GO TO WRAP.UP.',
  '      PROGRAM.START.  BEGIN SECTION.',
  '            SET NUM = NUM + 1.',
  '            STOP RUN.',
  '            END PROGRAM.START.',
  '      WRAP.UP.  STOP RUN.',
  '      *FINISH',
];

/// A program that loops 1(1)12 over an external-decimal index (M6-9).
/// Each pass counts in NUM. The comparison reads CELL (EXI), so the
/// loop drives an indicator, and is never true over a zero table.
final List<String> _externalIndex = <String>[
  '      *DATA',
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  for (final String name in ['CELL', 'NUM'])
    dataCard(
      name: name,
      level: name == 'CELL' ? '2' : '1',
      mode: 'I',
      justify: 'R',
      description: '999',
    ),
  dataCard(name: 'EXI', level: '1', mode: 'E', description: '99'),
  '      *PROCEDURE',
  '      START.  DO RTN FOR EXI = 1(1)12.',
  '            STOP RUN.',
  '      RTN.  BEGIN SECTION.',
  '            SET NUM = NUM + 1.',
  '            IF NUM LT CELL (EXI) THEN STOP RUN.',
  '            END RTN.',
  '      *FINISH',
];

/// A program that loops 1(1)12 and reads three fields of one table
/// through three indicators (M6-9). Element k holds k, 100 + k and
/// 200 + k, each a word of external decimal. Each pass moves the three
/// fields out, counts in NA, NB and NC the fields that read element
/// k, and sums them in SA, SB and SC.
final List<String> _indicators = <String>[
  '      *DATA',
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 12; k++)
    dataCard(
      level: '2',
      description:
          "'${[k, 100 + k, 200 + k].map((v) => '$v'.padLeft(6, '0')).join()}'",
    ),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  for (final String name in ['A', 'B', 'C'])
    dataCard(name: name, level: '2', mode: 'E', description: '9(6)'),
  for (final String name in [
    'IDX',
    'WA',
    'WB',
    'WC',
    'KB',
    'KC',
    'NA',
    'NB',
    'NC',
    'SA',
    'SB',
    'SC',
  ])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: '9(6)',
    ),
  '      *PROCEDURE',
  '      START.  DO RTN FOR IDX = 1(1)12.',
  '            STOP RUN.',
  '      RTN.  BEGIN SECTION.',
  '            MOVE A (IDX) TO WA, MOVE B (IDX) TO WB.',
  '            MOVE C (IDX) TO WC.',
  '            SET KB = WB - 100, SET KC = WC - 200.',
  '            IF WA = IDX THEN SET NA = NA + 1.',
  '            IF KB = IDX THEN SET NB = NB + 1.',
  '            IF KC = IDX THEN SET NC = NC + 1.',
  '            SET SA = SA + WA, SET SB = SB + WB, SET SC = SC + WC.',
  '            END RTN.',
  '      *FINISH',
];

/// The corpus's TABLE (statements 101,00 to 112,00 of the applied
/// deck): six rows of 22 characters, twelve packed items of 11. Item k
/// starts at character 11·(k − 1), so its byte runs 0, 5, 4, 3, 2, 1.
const List<String> _tableRows = <String>[
  '0099908006001499100060',
  '0199912009002499150090',
  '0299915012003499200120',
  '0399920015004499250150',
  '0499930018006499300250',
  '0799930035099999300500',
];

/// The three fields of each item, as the characters of its row.
List<(String, String, String)> _tableItems() => <(String, String, String)>[
  for (final String row in _tableRows)
    for (final int at in <int>[0, 11])
      (
        row.substring(at, at + 5),
        row.substring(at + 5, at + 8),
        row.substring(at + 8, at + 11),
      ),
];

/// A loop over the corpus's TABLE through three indicators of an
/// 11-character stride. EXPECT holds each item's fields again, one word
/// apiece, so each pass compares item k with a whole-word copy of it.
final List<String> _byteStride = <String>[
  '      *DATA',
  dataCard(name: 'TABLE', level: '1'),
  for (final String row in _tableRows)
    dataCard(level: '2', description: "'$row'"),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TABLE.ITEM', level: '1', quantity: '12'),
  dataCard(name: 'RATE', level: '2', description: '99V999'),
  dataCard(name: 'INSURANCE.PREM', level: '2', description: '9V99'),
  dataCard(name: 'RETIREMENT.PREM', level: '2', description: '9V99'),
  dataCard(name: 'EXPECTED', level: '1'),
  for (final (String rate, String insurance, String retirement)
      in _tableItems())
    dataCard(
      level: '2',
      description:
          "'0$rate${insurance.padLeft(6, '0')}${retirement.padLeft(6, '0')}'",
    ),
  dataCard(type: 'REDEF', description: 'EXPECTED'),
  dataCard(name: 'EXPECT', level: '1', quantity: '12'),
  dataCard(name: 'XR', level: '2', description: '999V999'),
  dataCard(name: 'XI', level: '2', description: '9999V99'),
  dataCard(name: 'XT', level: '2', description: '9999V99'),
  dataCard(name: 'INDEX', level: '1', description: '99'),
  dataCard(name: 'SI', level: '1', description: '9999V99'),
  dataCard(name: 'ST', level: '1', description: '9999V99'),
  for (final String name in ['NR', 'NI', 'NT'])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: '99',
    ),
  '      *PROCEDURE',
  '      START.  DO SEARCH FOR INDEX = 1(1)12.',
  '            STOP RUN.',
  '      SEARCH.  BEGIN SECTION.',
  '            IF RATE (INDEX) = XR (INDEX) THEN SET NR = NR + 1.',
  '            IF INSURANCE.PREM (INDEX) = XI (INDEX)',
  '            THEN SET NI = NI + 1.',
  '            IF RETIREMENT.PREM (INDEX) = XT (INDEX)',
  '            THEN SET NT = NT + 1.',
  '            ADD INSURANCE.PREM (INDEX) TO SI.',
  '            ADD RETIREMENT.PREM (INDEX) TO ST.',
  '      SEARCH.END.  END SEARCH.',
  '      *FINISH',
];

/// A loop over twelve items of two whole words: A `99`, B `9999` at
/// byte 2, and C `9(6)`. Item k holds A = k, B = k and C = 100 + k, so a
/// reader that took B from byte 0 would read `0k00` for k below 10.
final List<String> _wordStrideByte = <String>[
  '      *DATA',
  dataCard(name: 'TABLE', level: '1'),
  for (var k = 1; k <= 12; k++)
    dataCard(
      level: '2',
      description:
          "'${'$k'.padLeft(2, '0')}${'$k'.padLeft(4, '0')}"
          "${'${100 + k}'.padLeft(6, '0')}'",
    ),
  dataCard(type: 'REDEF', description: 'TABLE'),
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(name: 'A', level: '2', description: '99'),
  dataCard(name: 'B', level: '2', description: '9999'),
  dataCard(name: 'C', level: '2', description: '9(6)'),
  dataCard(name: 'INDEX', level: '1', description: '99'),
  dataCard(name: 'SB', level: '1', description: '9(6)'),
  for (final String name in ['NB', 'NG', 'SN'])
    dataCard(
      name: name,
      level: '1',
      mode: 'I',
      justify: 'R',
      description: '9(6)',
    ),
  '      *PROCEDURE',
  '      START.  DO RTN FOR INDEX = 1(1)12.',
  '            STOP RUN.',
  '      RTN.  BEGIN SECTION.',
  '            ADD B (INDEX) TO SB.',
  '            IF B (INDEX) GT 6 THEN SET NG = NG + 1.',
  '            MOVE B (INDEX) TO NB.',
  '            SET SN = SN + NB.',
  '            END RTN.',
  '      *FINISH',
];

/// A program that never reaches its `STOP RUN`.
final List<String> _loop = <String>[
  '      *DATA',
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  GO TO START.',
  '            STOP RUN.',
  '      *FINISH',
];

/// A program that trips the base-locator guard: the comparison loads
/// `IDX`'s positional indicator, which nothing has set (RT-2).
final List<String> _guard = <String>[
  '      *DATA',
  dataCard(name: 'TAB', level: '1', quantity: '12'),
  dataCard(
    name: 'CELL',
    level: '2',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  dataCard(name: 'IDX', level: '1', mode: 'I', justify: 'R', description: '99'),
  dataCard(
    name: 'NUM',
    level: '1',
    mode: 'I',
    justify: 'R',
    description: '999',
  ),
  '      *PROCEDURE',
  '      START.  IF NUM GT CELL (IDX) THEN GO TO RTN.',
  '      RTN.  STOP RUN.',
  '      *FINISH',
];

/// Writes the two input tapes the sample reads: one master record and
/// one detail record, whose employee number is the lower of the two.
/// The comparison then takes LOW.DETAIL, which files an error record at
/// the sample's first FILE ([J 90.05] statement 196).
void _sampleTapes(Directory tapes) {
  tapeImage(tapes, 'D1', <List<int>>[
    // MASTER is 15 words, and only its employee number is read on that
    // path. The rest reads as the BCD zeros of an untouched field.
    <int>[characters('992222'), ...List<int>.filled(14, 0)],
  ]);
  tapeImage(tapes, 'C2', <List<int>>[
    // DETAIL is the employee number, the date, and the hours.
    <int>[characters('111111'), characters('010161'), characters('400000')],
  ]);
}

/// The print lines of the image unit [unit] holds in [tapes] (M5-11).
/// The lister runs to the file mark, so it also proves the close wrote
/// one.
List<String> _report(Directory tapes, String unit) =>
    listTape(File('${tapes.path}/$unit.tap').readAsBytesSync()).toList();

/// Compiles the 90.05 job deck with [options].
ProcessResult _compileSample(List<String> options) => Process.runSync(
  Platform.resolvedExecutable,
  ['run', 'comtran:comtranc', jobDeckPath, ...options],
);

/// Punches [source] into a temporary deck and compiles it with `--run`.
ProcessResult _compileAndRun(List<String> source) {
  final Directory directory = tempDirectory('comtran-run');
  final path = '${directory.path}/job.ctd';
  File(
    path,
  ).writeAsBytesSync(encodeCanon(mirrorToDeck('${source.join('\n')}\n')));
  return Process.runSync(Platform.resolvedExecutable, [
    'run',
    'comtran:comtranc',
    path,
    '--run',
  ]);
}

void main() {
  group('the dispatch rule', () {
    test('an entry with no handler names itself', () {
      // IOC)2 locates the 12-word IOCS file blocks. It has no emitter
      // and stays unbuilt, because the file table is Dart's (M5-3).
      expect(
        () => machine({start: tsx(2)}).run(maxSteps: 4),
        throwsA(
          isA<UnimplementedRuntimeEntry>().having(
            (UnimplementedRuntimeEntry e) => e.toString(),
            'toString',
            'unimplemented runtime entry IOC)2',
          ),
        ),
      );
    });

    test('the budget bounds a program that never stops', () {
      // D5.1 as amended: the emulator reproduces non-termination, so
      // the cap is the caller's and the run returns.
      final RunResult result = machine({
        start: typeB(0x010, address: start), // TRA *
      }).run(maxSteps: 50);
      expect(result.outcome, RunOutcome.stepLimit);
    });

    test('the display survives an entry the machine lacks', () {
      // No compiled program reaches this: the generator emits no
      // call to an entry the machine lacks.
      final Machine subject = machine({
        start: tsx(178),
        start + 1: typeA(0, decrement: start + 0x101, address: start + 0x100),
        start + 2: typeA(0, decrement: start + 0x103, address: start + 0x102),
        start + 3: tsx(2),
        start + 0x100: octal('606060011111'),
        start + 0x101: octal('730104606060'),
        start + 0x102: octal('606263464760'),
        start + 0x103: octal('605164456060'),
      });
      expect(
        () => subject.run(maxSteps: 4),
        throwsA(isA<UnimplementedRuntimeEntry>()),
      );
      expect(subject.printed, <String>['AT 199,14 STOP RUN']);
    });
  });

  group('the 90.05 sample', () {
    test('reads its two records and runs to the end of the job', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards, tapes: tapes);
      expect(subject.program.words, hasLength(936));
      expect(subject.program.origin, Machine.programOrigin);
      expect(subject.program.entry, Machine.programOrigin + octal('165'));
      expect(subject.state.ic, subject.program.entry);
      // IOC)1 counts the seven FILE cards of the sample (M5-3).
      expect(Word36.decrement(subject.state.read(1)), 7);
      // The program's last placed word is relative 01771, so the buffers
      // start at 5114: INPUTMASTER takes 300 words, OUTPUTMASTER the 300
      // above them, and DETAILFILE the three above those (M5-10).
      expect(subject.program.extent, 5114);
      expect(subject.files.map((RuntimeFile file) => file.buffer), <int>[
        5114,
        5414,
        5714,
        5717,
        5737,
        5757,
        5763,
      ]);
      final RunResult result = subject.run(maxSteps: 5000);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.display, <String>['AT 199,14 STOP RUN']);
      // CLOSE ALL FILES and the STOP RUN behind it close every file
      // (M5-4).
      expect(
        subject.files.map((RuntimeFile file) => file.open),
        everyElement(isFalse),
      );
      // Each record entered its own buffer. END.OF.DETAILS then wrote
      // HIGH.VALUE over the detail employee number through BL)3, so the
      // date is the word of DETAILFILE's buffer left to read (M5-7).
      expect(subject.state.read(5114), characters('992222'));
      expect(subject.state.read(5715), characters('010161'));
      // LOW.DETAIL files the detail record (196), and its GET's AT END
      // runs END.OF.DETAILS (198) into HIGH.DETAIL (193), which files
      // the master one.
      expect(_report(tapes, 'D4'), <String>[
        'D111111010161400',
        'M992222000000000000000',
      ]);
      // The department total and the grand total reach PAYFILE.
      final List<String> pay = _report(tapes, 'D3');
      expect(pay, hasLength(2));
      expect(pay.first, contains('DEPARTMENT 99 TOTALS'));
      expect(pay.last, startsWith('GT'));
      // OUTPUTMASTER, CHECKFILE and BONDORDERFILE take no record on this
      // path, so the close writes each of them the tape mark alone
      // (M5-10).
      for (final unit in <String>['C1', 'D2', 'C3']) {
        expect(File('${tapes.path}/$unit.tap').readAsBytesSync(), <int>[
          0,
          0,
          0,
          0,
        ]);
      }
    });

    test('an empty master file ends at the base-locator guard', () {
      // The first GET takes its AT END exit into END.OF.MASTERS, which
      // reads the detail record before any GET DETAIL has run. BL)3 is
      // still zero, so the guard fires (RT-2).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', const <List<int>>[]);
      tapeImage(tapes, 'C2', const <List<int>>[]);
      final JobCompilation job = compileDeck(loadJobDeck()).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards, tapes: tapes);
      final RunResult result = subject.run(maxSteps: 5000);
      expect(result.outcome, RunOutcome.errorExit);
      expect(result.display, <String>['BASE LOCATOR NOT LOADED']);
    });

    test('a declared input file needs its tape image', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
      ]);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains(
          'error: job 1: no tape image for input file INPUTMASTER at '
          '${tapes.path}/D1.tap',
        ),
      );
    });

    test('comtranc --run carries the sample to the end of the job', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(run.stdout, contains('AT 199,14 STOP RUN'));
    });

    test('comtranc --list-tapes prints the reports after the run', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
        '--list-tapes',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      // The whole listing, from the last display line on: the four BCD
      // output files in `*FILE` card order. OUTPUTMASTER punches mode
      // B, so a binary tape stands nowhere in it (M5-11).
      expect(
        run.stdout,
        endsWith(
          'AT 199,14 STOP RUN\n'
          'CHECKFILE REPORT\n'
          '\n'
          '\n'
          'PAYFILE REPORT\n'
          '\n'
          '          DEPARTMENT 99 TOTALS        0.0      0.00      0.00     '
          '0.00     0.00     0.00     0.00      0.00      0.00\n'
          'GT                        -  -        0.0      0.00      0.00     '
          '0.00     0.00     0.00     0.00      0.00      0.00\n'
          '\n'
          'BONDORDERFILE REPORT\n'
          '\n'
          '\n'
          'ERRORFILE REPORT\n'
          '\n'
          'D111111010161400\n'
          'M992222000000000000000\n',
        ),
      );
    });

    test('the reconstructed tapes print the report of PDF p. 217', () {
      // The four reports the run writes, byte for byte (M6-5). The
      // golden is our output; test/acceptance_test.dart measures its
      // distance from the page.
      final Directory tapes = tempDirectory('comtran-tapes');
      for (final unit in <String>['D1', 'C2']) {
        File('$sampleTapesPath/$unit.tap').copySync('${tapes.path}/$unit.tap');
      }
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
        '--list-tapes',
      ]);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      const display = 'AT 199,14 STOP RUN\n';
      final stdout = '${run.stdout}';
      expect(
        stdout.substring(stdout.indexOf(display) + display.length),
        File('test/goldens/90.05-payroll.report').readAsStringSync(),
      );
    });

    test('comtranc --list-tapes lists nothing the run never opened', () {
      // The first run leaves its reports in the directory. Open-all then
      // refuses the second run ahead of the truncation, so every image
      // is the first run's and none is this run's (M5-11).
      final Directory tapes = tempDirectory('comtran-tapes');
      _sampleTapes(tapes);
      final flags = ['--run', '--tapes=${tapes.path}', '--list-tapes'];
      expect(_compileSample(flags).exitCode, 0);
      File('${tapes.path}/C2.tap').deleteSync();
      final ProcessResult run = _compileSample(flags);
      expect(run.exitCode, 1);
      expect(run.stderr, contains('no tape image for input file DETAILFILE'));
      expect(run.stdout, isNot(contains('REPORT')));
    });

    test('comtranc --list-tapes ends a report at the reader fault', () {
      // Two empty input tapes take the run to the base-locator guard,
      // which exits before close-all writes any file mark (M5-11).
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', const <List<int>>[]);
      tapeImage(tapes, 'C2', const <List<int>>[]);
      final ProcessResult run = _compileSample([
        '--run',
        '--tapes=${tapes.path}',
        '--list-tapes',
      ]);
      expect(run.exitCode, 1);
      expect(run.stdout, contains('ERRORFILE REPORT\n\n'));
      expect(
        run.stderr,
        contains(
          'error: job 1: ERRORFILE: unreadable tape record: the tape ends '
          'with no file mark',
        ),
      );
    });

    test('comtranc --list-tapes needs a run', () {
      final ProcessResult run = _compileSample(['--list-tapes']);
      expect(run.exitCode, 2);
      expect(run.stderr, startsWith('Usage:'));
    });

    test('comtranc --run refuses the sample with no tape directory', () {
      final ProcessResult run = _compileSample(['--run']);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains(
          'error: job 1: no tape directory for input file INPUTMASTER: '
          'pass --tapes=DIR',
        ),
      );
    });
  });

  group('the --tapes directory', () {
    test('an empty path is a usage error', () {
      final ProcessResult run = _compileSample(['--run', '--tapes=']);
      expect(run.exitCode, 2);
      expect(run.stderr, startsWith('Usage:'));
    });

    test('a directory that is not there names itself', () {
      final missing = '${tempDirectory('comtran-tapes').path}/gone';
      final ProcessResult run = _compileSample(['--run', '--tapes=$missing']);
      expect(run.exitCode, 2);
      expect(run.stdout, isEmpty);
      expect(run.stderr, 'error: no tape directory at $missing\n');
    });
  });

  group('an I/O-free program', () {
    test('runs to STOP RUN and stores its result', () {
      final JobCompilation job = compileDeck(
        mirrorToDeck('${_source.join('\n')}\n'),
      ).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards);
      final RunResult result = subject.run(maxSteps: 1000);
      expect(result.outcome, RunOutcome.endOfJob);
      expect(result.display, <String>['AT 4,00 STOP RUN']);
      final AssemblyUnit total = job.codegen!.units.firstWhere(
        (AssemblyUnit unit) => unit.labels.contains('TOT'),
      );
      // `SET TOT = NUM + 1` generates CLA, ADD, STO with no MOVPAK, and
      // NUM's reserved cell reads +0 (ED-6).
      expect(subject.state.read(Machine.programOrigin + total.location!), 1);
    });

    test('comtranc --run prints the display after the listing', () {
      final ProcessResult run = _compileAndRun(_source);
      expect(run.exitCode, 0, reason: '${run.stderr}');
      expect(run.stdout, contains('AT 4,00 STOP RUN'));
    });

    test('STOP n prints its line and resumes with the next statement', () {
      final (JobCompilation job, Machine subject) = compiled(_halt);
      expect(subject.printed, <String>[
        'AT 2,00 STOP 1234',
        'AT 4,00 STOP RUN',
      ]);
      expect(subject.state.read(addressOf(job, 'NUM')), 1);
    });

    test('an external-decimal operand converts and computes', () {
      final (JobCompilation job, Machine subject) = compiled(_external);
      expect(subject.printed, <String>['AT 11,00 STOP RUN']);
      // 4.25 + 1.50, at the scale of TOT.
      expect(subject.state.read(addressOf(job, 'TOT')), 575);
      // 4.25 is greater than 4.00 and not greater than 4.25.
      expect(subject.state.read(addressOf(job, 'NUM')), 1);
    });

    test('a comparison aligns its scales by the decimal point', () {
      final (JobCompilation job, Machine subject) = compiled(_scales);
      expect(subject.printed, <String>['AT 16,00 STOP RUN']);
      // 4.5 > 4, 4.5 > 5 is false, 40.0 = 40, and 40.0 > 40 is false.
      expect(subject.state.read(addressOf(job, 'NUM')), 101);
      // 4.5 < 5: unaligned, the compare reads 45 against 5.
      expect(subject.state.read(addressOf(job, 'TOT')), 1);
    });

    test('a nonzero literal compares from the accumulator', () {
      final (JobCompilation job, Machine subject) = compiled(_literalLeft);
      // 5 > 0, 5 < 1 is false, and 4 < 5.
      expect(subject.state.read(addressOf(job, 'NUM')), 101);
    });

    test('a product of a product scales back once at the store', () {
      final (JobCompilation job, Machine subject) = compiled(_product);
      expect(subject.printed, <String>['AT 13,00 STOP RUN']);
      // 5.0 * 2.505 * 1.5 is 18.7875, and the half-adjust stores 18.79.
      // A product that dropped the scale of 1.5 would store 187.88.
      expect(subject.state.read(addressOf(job, 'GROSS')), 1879);
      // 5.0 * 2.5 * 1.5 is 18.75 exactly.
      expect(subject.state.read(addressOf(job, 'GROSS2')), 1875);
    });

    test('an external-decimal store writes the characters back', () {
      final (JobCompilation job, Machine subject) = compiled(_externalStore);
      expect(subject.printed, <String>['AT 17,00 STOP RUN']);
      // 5.0 * 2.505 * 1.5 rounds to 18.79, and the ADD doubles it.
      expect(glyphsAt(subject, addressOf(job, 'GROSS'), 7), '0003758');
      // -2.5 * 1.1 is -2.75; `N` is 5 over an 11 punch.
      expect(glyphsAt(subject, addressOf(job, 'MINUS'), 3), '27N');
      // 5.0 * 1.05 is 5.25; `E` is 5 over a 12 punch.
      expect(glyphsAt(subject, addressOf(job, 'PLUS'), 3), '52E');
      // The fetch reads the overpunched field back to its value.
      expect(
        subject.state.read(addressOf(job, 'BACK')),
        Word36.fromSignMagnitude(1, 275),
      );
    });

    test('a chain rounds away from zero at the store', () {
      final (JobCompilation job, Machine subject) = compiled(_chainStore);
      expect(subject.printed, <String>['AT 15,00 STOP RUN']);
      // 3.505 rounds up to 3.51, and 3.504 down to 3.50.
      expect(subject.state.read(addressOf(job, 'UP')), 351);
      expect(subject.state.read(addressOf(job, 'DOWN')), 350);
      // -2.485 rounds to -2.49. An `ADD` of the half would give -2.48.
      expect(
        subject.state.read(addressOf(job, 'NEG')),
        Word36.fromSignMagnitude(1, 249),
      );
      // TRUNCATED drops the 5.
      expect(subject.state.read(addressOf(job, 'CUT')), 350);
      expect(glyphsAt(subject, addressOf(job, 'EUP'), 3), '351');
      expect(glyphsAt(subject, addressOf(job, 'EDOWN'), 3), '350');
      // `R` is 9 over an 11 punch.
      expect(glyphsAt(subject, addressOf(job, 'ENEG'), 3), '24R');
    });

    test('a chain stores into an edited field through SYS)267', () {
      final (JobCompilation job, Machine subject) = compiled(_editedChain);
      expect(subject.printed, <String>['AT 14,00 STOP RUN']);
      // 412.50 less 105.11 is 307.39. The dollar floats to the first
      // significant digit, and a plus value leaves the sign blank.
      expect(glyphsAt(subject, addressOf(job, 'NETPAY'), 10), r'  $307.39 ');
      // 40.00 less 105.11 is -65.11, and the trailing minus prints.
      expect(glyphsAt(subject, addressOf(job, 'NETNEG'), 10), r'   $65.11-');
    });

    test('an edit run drops zero high-order digits and arms nothing', () {
      final (JobCompilation job, Machine subject) = compiled(
        _droppedDigits('8889.99', '234'),
      );
      expect(subject.printed, <String>['AT 7,00 STOP RUN']);
      expect(glyphsAt(subject, addressOf(job, 'AMT'), 8), r'$8889.99');
      expect(glyphsAt(subject, addressOf(job, 'EDF'), 5), '234.0');
      expect(subject.state.read(overflowCell), 0);
    });

    test('an external move keeps the characters and the sign', () {
      final (JobCompilation job, Machine subject) = compiled(_externalMove);
      expect(subject.printed, <String>['AT 12,00 STOP RUN']);
      expect(glyphsAt(subject, addressOf(job, 'SAME'), 5), '27533');
      // -2.75; `N` is 5 over an 11 punch under either overpunch, and
      // the unsigned target keeps the magnitude.
      expect(glyphsAt(subject, addressOf(job, 'MOUT'), 5), '0027N');
      expect(glyphsAt(subject, addressOf(job, 'POUT'), 5), '0027N');
      expect(glyphsAt(subject, addressOf(job, 'UOUT'), 5), '00275');
      // `C` is 3 over a 12 punch.
      expect(glyphsAt(subject, addressOf(job, 'PLUS'), 5), '2753C');
      expect(subject.state.read(conditionCell), 0);
    });

    test('an edited source drops a significant digit and arms SYS)130', () {
      final (JobCompilation job, Machine subject) = compiled(
        _droppedDigits('12345.67', '234'),
      );
      expect(subject.printed, <String>['AT 7,00 STOP RUN']);
      // The low-order digits print. The EDF move drops a zero.
      expect(glyphsAt(subject, addressOf(job, 'AMT'), 8), r'$2345.67');
      expect(glyphsAt(subject, addressOf(job, 'EDF'), 5), '234.0');
      expect(subject.state.read(overflowCell), isNot(0));
    });

    test('the F p. 43 row drops a significant digit and arms SYS)130', () {
      final (JobCompilation job, Machine subject) = compiled(
        _droppedDigits('8889.99', '1234'),
      );
      expect(subject.printed, <String>['AT 7,00 STOP RUN']);
      // `01234` gives `234.0`, as F's `2340`. The AMT move drops a zero.
      expect(glyphsAt(subject, addressOf(job, 'AMT'), 8), r'$8889.99');
      expect(glyphsAt(subject, addressOf(job, 'EDF'), 5), '234.0');
      expect(subject.state.read(overflowCell), isNot(0));
    });

    test('a comparison of expressions takes the branch of its value', () {
      // (FICA, GROSS, EX) and the arms of 152 and 156 they take.
      const cases = <(String, String, String, int, int)>[
        // 100.00 + 30.00 is below 144.00; 26 is below 1000.00.
        ('100.00', '1000.00', '2', 1, 1),
        // 114.00 + 30.00 equals 144.00, so LT is false.
        ('114.00', '1000.00', '2', 2, 1),
        // 120.00 + 30.00 is above 144.00.
        ('120.00', '1000.00', '2', 2, 1),
        // 113.99 + 30.0099 is 143.9999. A chain rounded to the scale of
        // 144.00 would read 144.00 and take the OTHERWISE arm.
        ('113.99', '1000.33', '2', 1, 1),
        // 13 * 2 equals 26.00, so LT is false; 26 is below 26.01.
        ('0.00', '26.00', '2', 1, 2),
        ('0.00', '26.01', '2', 1, 1),
        ('0.00', '25.99', '2', 1, 2),
      ];
      for (final (String fica, String gross, String ex, int first, int second)
          in cases) {
        final (JobCompilation job, Machine subject) = compiled(
          _expressionCompare(fica, gross, ex),
        );
        final reason = 'FICA $fica, GROSS $gross, EX $ex';
        expect(subject.printed, <String>['AT 9,00 STOP RUN'], reason: reason);
        expect(
          subject.state.read(addressOf(job, 'FIRST')),
          first,
          reason: reason,
        );
        expect(
          subject.state.read(addressOf(job, 'SECOND')),
          second,
          reason: reason,
        );
      }
    });

    test('a truth function inside an expression comparison', () {
      // (NUM, FRAC, FLAG): 1 + 14 is above 14 and 1 + 12 is not. With
      // the truth function false, 0 + 14 is not above 14.
      const cases = <(String, String, int)>[
        ('7', '0.5', 1),
        ('6', '0.5', 2),
        ('7', '9.5', 2),
      ];
      for (final (String num, String frac, int flag) in cases) {
        final (JobCompilation job, Machine subject) = compiled(
          _nestedCompare(num, frac),
        );
        expect(
          subject.state.read(addressOf(job, 'FLAG')),
          flag,
          reason: 'NUM $num, FRAC $frac',
        );
      }
    });

    test('a chain above the edited scale rounds through the tail', () {
      final (JobCompilation job, Machine subject) = compiled(_editedTail);
      expect(subject.printed, <String>['AT 4,00 STOP RUN']);
      // 2.476 half-adjusts to 2.48.
      expect(glyphsAt(subject, addressOf(job, 'NET'), 10), r'    $2.48 ');
    });

    test('a located external-decimal store writes into the buffer', () {
      final Directory tapes = tempDirectory('comtran-tapes');
      tapeImage(tapes, 'D1', <List<int>>[
        <int>[characters('123ABC')],
      ]);
      final JobCompilation job = compileDeck(
        mirrorToDeck('${_locatedStore.join('\n')}\n'),
      ).jobs.single;
      final subject = Machine.load(jobDeck(job, _options)!.cards, tapes: tapes);
      expect(subject.run(maxSteps: 5000).outcome, RunOutcome.endOfJob);
      // 123 - 200 is -77. `P` is 7 over an 11 punch, and IPAD keeps its
      // characters, so the store wrote three characters from byte 0.
      expect(glyphsAt(subject, subject.files.single.buffer, 6), '07PABC');
    });

    test('a loop over an external-decimal index runs 1(1)12', () {
      final (JobCompilation job, Machine subject) = compiled(_externalIndex);
      expect(subject.printed, <String>['AT 6,00 STOP RUN']);
      expect(subject.state.read(addressOf(job, 'NUM')), 12);
      // The exit leaves the index at the first value past 12.
      expect(glyphsAt(subject, addressOf(job, 'EXI'), 2), '13');
    });

    test('a loop steps three indicators over one table', () {
      final (JobCompilation job, Machine subject) = compiled(_indicators);
      // Each field read element k on each of the 12 passes.
      for (final count in ['NA', 'NB', 'NC']) {
        expect(subject.state.read(addressOf(job, count)), 12, reason: count);
      }
      // 1 + ... + 12 is 78, and the other two add 1200 and 2400.
      expect(subject.state.read(addressOf(job, 'SA')), 78);
      expect(subject.state.read(addressOf(job, 'SB')), 1278);
      expect(subject.state.read(addressOf(job, 'SC')), 2478);
    });

    test('a loop steps three indicators by 11 characters', () {
      final (JobCompilation job, Machine subject) = compiled(_byteStride);
      expect(subject.printed, <String>['AT 38,00 STOP RUN']);
      // Each field of each of the 12 items equals its whole-word copy,
      // so every pass read the right characters, byte 0 to byte 5.
      for (final count in ['NR', 'NI', 'NT']) {
        expect(subject.state.read(addressOf(job, count)), 12, reason: count);
      }
      String total(int field) {
        var sum = 0;
        for (final (String, String, String) item in _tableItems()) {
          sum += int.parse(field == 1 ? item.$2 : item.$3);
        }
        return '$sum'.padLeft(6, '0');
      }

      expect(glyphsAt(subject, addressOf(job, 'SI'), 6), total(1));
      expect(glyphsAt(subject, addressOf(job, 'ST'), 6), total(2));
    });

    test('a whole-word stride reads a field from its own byte', () {
      final (JobCompilation job, Machine subject) = compiled(_wordStrideByte);
      // 1 + ... + 12 is 78. A read from byte 0 gives 7800 for the sum.
      expect(glyphsAt(subject, addressOf(job, 'SB'), 6), '000078');
      // B exceeds 6 for k = 7 to 12. A read from byte 0 counts 12.
      expect(subject.state.read(addressOf(job, 'NG')), 6);
      // The subscripted MOVE source reads through the same pointer.
      expect(subject.state.read(addressOf(job, 'SN')), 78);
    });

    test('a labelled section runs from the entry point it takes', () {
      // `test/codegen_test.dart` pins the entry word on PROGRAM.START.
      // NUM reads 1 only if the run entered the section: the `GO TO`
      // ahead of it reaches STOP RUN over an untouched cell (ED-6).
      final (JobCompilation job, Machine subject) = compiled(_section);
      expect(subject.state.read(addressOf(job, 'NUM')), 1);
    });
  });

  group('the --run exit status', () {
    test('an exhausted budget names the budget and fails the job', () {
      final ProcessResult run = _compileAndRun(_loop);
      expect(run.exitCode, 1);
      expect(
        run.stderr,
        contains('error: job 1: still running after 1000000 steps'),
      );
    });

    test('an error exit fails the job on the monitor message alone', () {
      final ProcessResult run = _compileAndRun(_guard);
      expect(run.exitCode, 1);
      expect(run.stdout, contains('BASE LOCATOR NOT LOADED'));
      expect(run.stderr, isNot(contains('error:')));
    });
  });
}
