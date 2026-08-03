import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import 'support/deck_fixtures.dart';

// Builds procedure cards: a label starts in the name margin (column
// 7); unlabeled text starts at column 13.
(List<Sentence>, List<Diagnostic>) _parse(
  List<String> lines, {
  bool finish = false,
}) {
  final ProcedureScan scan = scanProcedure(sourceCards(lines));
  expect(scan.diagnostics, isEmpty, reason: 'scan must be clean');
  final diagnostics = <Diagnostic>[];
  final parser = ProcedureParser(diagnostics);
  final List<Sentence> sentences = parser.parseGroup(scan);
  if (finish) {
    parser.finishProgram(sourceCards(['      X']).single);
  }
  return (sentences, diagnostics);
}

void main() {
  group('the 90.05 procedure division', () {
    late final ParseResult parse;
    late final ParsedProcedureGroup group;

    setUpAll(() {
      parse = runParser(runFrontEnd(loadPayrollDeck()));
      group = parse.groups.whereType<ParsedProcedureGroup>().single;
    });

    test('parses its 43 sentences with zero diagnostics', () {
      expect(parse.parserDiagnostics, isEmpty);
      // Statements 187,00-229,00 (M1 golden numbering).
      expect(group.sentences, hasLength(43));
      expect(group.sentences.any((Sentence s) => s.deleted), isFalse);
    });

    test('parses START and the end-of-run sentence as documented', () {
      final Sentence start = group.sentences.singleWhere(
        (Sentence s) => s.scan.label == 'START',
      );
      expect(start.clauses.first, isA<OpenClause>());
      expect((start.clauses.first as OpenClause).allFiles, isTrue);
      final Sentence endOfRun = group.sentences.singleWhere(
        (Sentence s) => s.scan.label == 'END.OF.RUN',
      );
      expect(endOfRun.clauses.first, isA<DoClause>());
      expect(endOfRun.clauses.last, isA<StopClause>());
      expect((endOfRun.clauses.last as StopClause).run, isTrue);
      // Clause numbering runs 1..n in source order (design note M2-6).
      expect(endOfRun.clauses.first.clause, 1);
      expect(endOfRun.clauses.last.clause, endOfRun.clauses.length);
    });

    test('parses the conditional GO TO of statement 192', () {
      final Sentence compare = group.sentences.singleWhere(
        (Sentence s) => s.scan.label == 'COMPARE.EMPLOYEE.NUMBERS',
      );
      final goTo = compare.clauses.single as GoToClause;
      expect(goTo.targets, hasLength(2));
      expect(goTo.targets[0].name.text, 'CHECK.NEW.DEPT');
      expect(goTo.targets[0].when, isA<Relation>());
      expect(goTo.targets[1].name.text, 'LOW.DETAIL');
      expect(goTo.index, isNull);
    });

    test('parses the IF sentences with their arms', () {
      final Sentence endOfMasters = group.sentences.singleWhere(
        (Sentence s) => s.scan.label == 'END.OF.MASTERS',
      );
      final ifClause = endOfMasters.clauses.single as IfClause;
      expect(ifClause.thenArm.single, isA<GoToClause>());
      expect(ifClause.otherwiseArm.single, isA<SetClause>());
      expect(ifClause.clause, 1);
      expect(ifClause.thenArm.single.clause, 2);
      expect(ifClause.otherwiseArm.single.clause, 3);
    });

    test('parses the CALL synonym pairs of statement 187', () {
      final call = group.sentences.first.clauses.single as CallClause;
      expect(call.pairs, hasLength(5));
      expect(call.pairs.first.oldName.text, 'MASTER EMPLOYEE.NUMBER');
      expect(call.pairs.first.newName.text, 'M.EMP.NO');
      expect(call.pairs.last.oldName.text, 'MASTER BONDACCUMULATION');
      expect(call.pairs.last.newName.text, 'M.BND.ACC');
    });

    test('parses the GET sentences with their AT END transfers', () {
      final Iterable<GetClause> gets = group.sentences
          .expand((Sentence s) => s.clauses)
          .whereType<GetClause>();
      expect(gets, isNotEmpty);
      for (final get in gets) {
        expect(get.recordFrom, isFalse);
        expect(get.atEnd, isNotNull);
        expect(get.atEnd!.statement, anyOf(isA<DoClause>(), isA<GoToClause>()));
      }
    });
  });

  group('verbs', () {
    test('a literal MOVE source parses, as the sample writes', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        "            MOVE 'M' TO ERRORTYPE.",
      ]);
      expect(diagnostics, isEmpty);
      final move = sentences.single.clauses.single as MoveClause;
      expect((move.source as LiteralOperand).literal.text, 'M');
    });

    test('SET condition-name closes before a following clause (D5.6)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            SET MARRIED, GO TO NEXT.STEP.',
      ]);
      expect(diagnostics, isEmpty);
      expect(sentences.single.clauses, hasLength(2));
      expect(sentences.single.clauses[0], isA<SetConditionClause>());
      expect(sentences.single.clauses[1], isA<GoToClause>());
    });

    test('ON OVERFLOW with more than one result draws 192 (F p. 44)', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '            SET A, B = C * D, ON OVERFLOW GO TO E.',
      ]);
      expect(diagnostics.single.message, msgSentenceStructureError);
      final (_, List<Diagnostic> clean) = _parse([
        '            SET A = C * D TRUNCATED, ON OVERFLOW GO TO E.',
      ]);
      expect(clean, isEmpty);
    });

    test('a bare STOP is a syntax error (D2.7)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            STOP.',
      ]);
      expect(diagnostics.single.message, msgIncompleteStatement);
      expect(sentences.single.deleted, isTrue);
    });

    test('RUN outside STOP RUN is deleted with msg 2 (D2.7)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            RUN MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgRunDeleted);
      expect(sentences.single.clauses.single, isA<MoveClause>());
    });

    test('the assigned GO TO parses its parenthesized list (F p. 49)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GO TO (FIRST.CASE, SECOND.CASE, THIRD.CASE) ON SWITCH.',
      ]);
      expect(diagnostics, isEmpty);
      final goTo = sentences.single.clauses.single as GoToClause;
      expect(goTo.targets, hasLength(3));
      expect(goTo.index!.text, 'SWITCH');
    });

    test('per-level subscripts parse in a verb context (F p. 30)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            MOVE PAGE (150) LINE (10) WORD (4) TO X.',
      ]);
      expect(diagnostics, isEmpty);
      final move = sentences.single.clauses.single as MoveClause;
      final NameReference source = (move.source as NameOperand).name;
      expect(source.text, 'PAGE LINE WORD');
      expect(source.subscripts, hasLength(3));
    });

    test('ADD takes TRUNCATED and ON OVERFLOW (M2-9)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            ADD CORRESPONDING G TO T TRUNCATED, ON OVERFLOW GO TO E.',
      ]);
      expect(diagnostics, isEmpty);
      final add = sentences.single.clauses.single as AddClause;
      expect(add.corresponding, isTrue);
      expect(add.truncated, isTrue);
      expect(add.onOverflow, isA<GoToClause>());
    });

    test('MOVE takes neither TRUNCATED nor ON OVERFLOW (M2-9, §8.5.4)', () {
      final (List<Sentence> truncated, List<Diagnostic> onTruncated) = _parse([
        '            MOVE A TO B TRUNCATED.',
      ]);
      expect(onTruncated.single.message, msgIllegalSentenceStructure);
      expect(truncated.single.deleted, isTrue);
      final (List<Sentence> overflow, List<Diagnostic> onOverflow) = _parse([
        '            MOVE A TO B, ON OVERFLOW GO TO E.',
      ]);
      expect(onOverflow.single.message, msgSentenceStructureError);
      expect(overflow.single.deleted, isTrue);
    });

    test('MOVE without a source draws 119 and deletes', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            MOVE TO B.',
      ]);
      expect(diagnostics.single.message, msgIncompleteMove);
      expect(sentences.single.deleted, isTrue);
    });

    test('a misplaced CORRESPONDING draws 63 and is skipped', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            CORRESPONDING MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgCorrespondingMisplaced);
      expect(sentences.single.clauses.single, isA<MoveClause>());
    });

    test('a subscripted condition-name deletes the sentence (D5.6)', () {
      final (List<Sentence> set, List<Diagnostic> onSet) = _parse([
        '            SET MARRIED (I).',
      ]);
      expect(onSet.single.message, msgSubscriptedConditionName);
      expect(set.single.deleted, isTrue);
      final (List<Sentence> tested, List<Diagnostic> onIf) = _parse([
        '            IF MARRIED (I) THEN GO TO X.',
      ]);
      expect(onIf.single.message, msgSubscriptedConditionName);
      expect(tested.single.deleted, isTrue);
    });

    test('STOP n parses; over six digits draws 192 (J 05.06.04)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            STOP 77.',
      ]);
      expect(diagnostics, isEmpty);
      final stop = sentences.single.clauses.single as StopClause;
      expect(stop.run, isFalse);
      expect(stop.number!.text, '77');
      final (List<Sentence> seven, List<Diagnostic> overSeven) = _parse([
        '            STOP 1234567.',
      ]);
      expect(overSeven.single.message, msgSentenceStructureError);
      expect(seven.single.deleted, isFalse);
    });

    test('DO EXACTLY n TIMES parses (F p. 50)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO RTN EXACTLY 5 TIMES.',
      ]);
      expect(diagnostics, isEmpty);
      final doClause = sentences.single.clauses.single as DoClause;
      expect((doClause.exactlyTimes! as LiteralOperand).literal.text, '5');
      final (_, List<Diagnostic> noTimes) = _parse([
        '            DO RTN EXACTLY 5.',
      ]);
      expect(noTimes.single.message, msgInvalidDoForm);
    });

    test('DO FOR parses p(q)r; a fourth index draws 83 (D5.2)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO REORDER.RTN FOR PART.NO = 1001(1)1499.',
      ]);
      expect(diagnostics, isEmpty);
      final doClause = sentences.single.clauses.single as DoClause;
      expect(doClause.indices, hasLength(1));
      expect(
        (doClause.indices.single.from as LiteralOperand).literal.text,
        '1001',
      );
      final (_, List<Diagnostic> four) = _parse([
        '            DO R FOR I = 1(1)2, J = 1(1)2, K = 1(1)2, L = 1(1)2.',
      ]);
      expect(four.single.message, msgInvalidDoForm);
    });

    test('a name initial parameter parses in DO FOR (F p. 51; M2-16)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO RTN FOR I = P(1)10, J = 1(Q)R.',
      ]);
      expect(diagnostics, isEmpty);
      final doClause = sentences.single.clauses.single as DoClause;
      expect(doClause.indices, hasLength(2));
      expect((doClause.indices[0].from as NameOperand).name.text, 'P');
      expect((doClause.indices[1].by as NameOperand).name.text, 'Q');
      expect((doClause.indices[1].to as NameOperand).name.text, 'R');
    });

    test('DO USING GIVING parses its argument lists (F p. 52)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO MINIMUM USING GROSS, 15.00 GIVING TAX.',
      ]);
      expect(diagnostics, isEmpty);
      final doClause = sentences.single.clauses.single as DoClause;
      expect(doClause.usingArguments, hasLength(2));
      expect(doClause.givingResults.single.text, 'TAX');
    });

    test('the AT END slot accepts a bare name; junk draws 106 (D6.6)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GET MASTER, AT END WRAP.UP.',
      ]);
      expect(diagnostics, isEmpty);
      final get = sentences.single.clauses.single as GetClause;
      expect(get.atEnd!.bareName!.text, 'WRAP.UP');
      final (_, List<Diagnostic> junk) = _parse([
        '            GET MASTER, AT END THEN.',
      ]);
      expect(junk.single.message, msgAtEndNeedsName);
    });

    test('a non-transfer AT END clause draws the 911 warning (D6.6)', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '            GET MASTER, AT END MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgAtEndNotTransfer);
      expect(diagnostics.single.severity, 1);
    });

    test('OPEN without a file name draws 139', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            OPEN.',
      ]);
      expect(diagnostics.single.message, msgOpenNeedsFileName);
      expect(sentences.single.deleted, isTrue);
    });

    test('CLOSE parses its file list; a bare CLOSE draws 138', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            CLOSE PAYFILE, MASTERFILE.',
      ]);
      expect(diagnostics, isEmpty);
      final close = sentences.single.clauses.single as CloseClause;
      expect(close.allFiles, isFalse);
      expect(close.files.map((NameReference f) => f.text), [
        'PAYFILE',
        'MASTERFILE',
      ]);
      final (List<Sentence> bare, List<Diagnostic> missing) = _parse([
        '            CLOSE.',
      ]);
      expect(missing.single.message, msgCloseNeedsFileName);
      expect(bare.single.deleted, isTrue);
    });

    test('DISPLAY separates name references with commas (M2-10)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        "            DISPLAY 'GROSS IS' WORKING GROSS, NET.",
      ]);
      expect(diagnostics, isEmpty);
      final display = sentences.single.clauses.single as DisplayClause;
      expect(display.items, hasLength(3));
      expect((display.items[0] as LiteralOperand).literal.text, 'GROSS IS');
      expect((display.items[1] as NameOperand).name.text, 'WORKING GROSS');
      expect((display.items[2] as NameOperand).name.text, 'NET');
    });

    test('an empty or numeric DISPLAY item draws 131 (M2-10)', () {
      final (_, List<Diagnostic> empty) = _parse(['            DISPLAY.']);
      expect(empty.single.message, msgInvalidDisplay);
      final (List<Sentence> sentences, List<Diagnostic> numeric) = _parse([
        '            DISPLAY 45, NET.',
      ]);
      expect(numeric.single.message, msgInvalidDisplay);
      final display = sentences.single.clauses.single as DisplayClause;
      expect(display.items.single, isA<NameOperand>());
    });

    test('NOTE commentary parses as its own clause (F p. 59)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            NOTE GROSS IS COMPUTED WEEKLY.',
      ]);
      expect(diagnostics, isEmpty);
      expect(sentences.single.clauses.single, isA<NoteClause>());
    });

    test('LIBRARY refuses with msg 110 like COPY and INCLUDE (D9.8)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            LIBRARY UTILITY.DECK.',
      ]);
      expect(diagnostics.single.message, msgCopyNotHandled);
      expect(sentences.single.clauses.single, isA<DeferredVerbClause>());
    });

    test('INCLUDE draws 110; LOAD draws the non-historical 916 (M2-11)', () {
      final (_, List<Diagnostic> include) = _parse([
        '            INCLUDE STANDARD.DEDUCTIONS.',
      ]);
      expect(include.single.message, msgCopyNotHandled);
      final (List<Sentence> sentences, List<Diagnostic> load) = _parse([
        '            LOAD MAIN.ROUTINE, GO TO MAIN.ROUTINE.',
      ]);
      expect(load.single.message, msgDeferredVerb);
      expect(sentences.single.clauses[0], isA<DeferredVerbClause>());
      expect(sentences.single.clauses[1], isA<GoToClause>());
    });

    test('ENTER CRYPT passes text through until the reverse (M2 scope)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            ENTER CRYPT.',
        '            CLA SOMETHING.',
        '            ENTER COMMERCIAL TRANSLATOR.',
        '            MOVE A TO B.',
      ]);
      expect(diagnostics, isEmpty);
      expect((sentences[0].clauses.single as EnterClause).crypt, isTrue);
      expect(sentences[1].clauses, isEmpty);
      expect(sentences[1].deleted, isFalse);
      expect((sentences[2].clauses.single as EnterClause).crypt, isFalse);
      expect(sentences[3].clauses.single, isA<MoveClause>());
    });

    test('a deleted ENTER CRYPT sentence leaves the mode off (M2-13)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            ENTER CRYPT, FOO BAR BAZ.',
        '            MOVE A TO B.',
        '            GROSS TO NET.',
      ]);
      expect(diagnostics.map((Diagnostic d) => d.message.number), [
        '125,00',
        '125,00',
      ]);
      expect(sentences[0].deleted, isTrue);
      expect(sentences[1].clauses.single, isA<MoveClause>());
      expect(sentences[2].deleted, isTrue);
    });
  });

  group('sentence structure and recovery', () {
    test('a sentence starting with OTHERWISE draws 208 and deletes', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            OTHERWISE MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgSentenceStartsOtherwise);
      expect(sentences.single.deleted, isTrue);
    });

    test('IF without THEN draws 196 and deletes', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            IF A GT B MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgIllegalSentenceStructure);
      expect(sentences.single.deleted, isTrue);
    });

    test('two verbs without a comma draw 126 and delete', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            MOVE A TO B GO TO C.',
      ]);
      expect(diagnostics.single.message, msgStatementTwoVerbs);
      expect(sentences.single.deleted, isTrue);
    });

    test('a name where a verb belongs draws 125 and deletes', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GROSS.PAY TO NET.PAY.',
      ]);
      expect(diagnostics.single.message, msgStatementWithoutVerb);
      expect(sentences.single.deleted, isTrue);
    });

    test('a deleted sentence keeps its place in the list', () {
      final (List<Sentence> sentences, _) = _parse([
        '            STOP.',
        '            MOVE A TO B.',
      ]);
      expect(sentences, hasLength(2));
      expect(sentences[0].deleted, isTrue);
      expect(sentences[1].deleted, isFalse);
    });

    test('program and processor verbs cannot mix (M2-12, F p. 60)', () {
      final (List<Sentence> call, List<Diagnostic> onCall) = _parse([
        '            MOVE A TO B, CALL (X) Y.',
      ]);
      expect(onCall.single.message, msgIllegalSentenceStructure);
      expect(call.single.deleted, isTrue);
      final (List<Sentence> begin, List<Diagnostic> onBegin) = _parse([
        '      S.          BEGIN SECTION, MOVE A TO B.',
      ]);
      expect(onBegin.single.message, msgIllegalSentenceStructure);
      expect(begin.single.deleted, isTrue);
    });

    test("F p. 60's canonical mixed sentence is deleted (M2-12)", () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            IF A = B THEN GO TO C OTHERWISE OVERLAP S1, S2.',
      ]);
      expect(diagnostics.map((Diagnostic d) => d.message.number), [
        '916,00',
        '196,00',
      ]);
      expect(sentences.single.deleted, isTrue);
    });

    test('the 61st operator deletes the sentence (msg 171; M2-6)', () {
      List<String> deck(int operands) {
        final text = 'SET A = ${List.filled(operands, 'B').join(' + ')}.';
        final lines = <String>[];
        var line = '';
        for (final String word in text.split(' ')) {
          if (line.isNotEmpty && line.length + word.length + 1 > 58) {
            lines.add('${' ' * 12}$line');
            line = word;
          } else {
            line = line.isEmpty ? word : '$line $word';
          }
        }
        lines.add('${' ' * 12}$line');
        return lines;
      }

      // `=` plus 59 `+` signs: 60 operators, at the cap.
      final (List<Sentence> pass, List<Diagnostic> clean) = _parse(deck(60));
      expect(clean, isEmpty);
      expect(pass.single.deleted, isFalse);
      // One more addend: 61 operators.
      final (List<Sentence> cut, List<Diagnostic> over) = _parse(deck(61));
      expect(over.single.message, msgTooManyOperators);
      expect(cut.single.deleted, isTrue);
    });
  });

  group('sections and the whole program', () {
    test('BEGIN SECTION and END pair; a wrong END draws 65', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '      CALC.       BEGIN SECTION.',
        '            MOVE A TO B.',
        '            END CALC.',
      ]);
      expect(diagnostics, isEmpty);
      final (_, List<Diagnostic> wrong) = _parse([
        '      CALC.       BEGIN SECTION.',
        '            END OTHER.',
      ]);
      expect(wrong.single.message, msgEndWrongSection);
      expect(wrong.single.operands, ['OTHER', 'CALC']);
    });

    test('END with no open section draws 64; unclosed draws 66', () {
      final (_, List<Diagnostic> none) = _parse(['            END CALC.']);
      expect(none.single.message, msgEndWithoutSection);
      final (_, List<Diagnostic> open) = _parse([
        '      CALC.       BEGIN SECTION.',
        '            MOVE A TO B.',
      ], finish: true);
      expect(
        open.map((Diagnostic d) => d.message),
        contains(msgSectionsNotClosed),
      );
    });

    test('END must be the only clause in its sentence (msg 179)', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '      CALC.       BEGIN SECTION.',
        '            MOVE A TO B, END CALC.',
      ]);
      expect(diagnostics.single.message, msgEndNotAlone);
    });

    test('a missing STOP RUN draws 175 (D2.7)', () {
      final (_, List<Diagnostic> without) = _parse([
        '            MOVE A TO B.',
      ], finish: true);
      expect(without.map((Diagnostic d) => d.message), contains(msgNoStopRun));
      final (_, List<Diagnostic> withStop) = _parse([
        '            MOVE A TO B, STOP RUN.',
      ], finish: true);
      expect(withStop, isEmpty);
    });

    test('PROGRAM.START: a duplicate draws 141; a DO on it draws 143', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '      PROGRAM.START.  MOVE A TO B.',
        '      PROGRAM.START.  MOVE B TO C.',
        '            DO PROGRAM.START, STOP RUN.',
      ], finish: true);
      expect(diagnostics.map((Diagnostic d) => d.message.number), [
        '141,00',
        '143,00',
      ]);
    });

    test('a deleted sentence contributes no STOP RUN (M2-13, D2.7)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            STOP RUN, FOO TO B.',
      ], finish: true);
      expect(sentences.single.deleted, isTrue);
      expect(diagnostics.map((Diagnostic d) => d.message.number), [
        '125,00',
        '175,00',
      ]);
    });

    test('a deleted DO draws no 143 on PROGRAM.START (M2-13)', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '      PROGRAM.START.  MOVE A TO B.',
        '            DO PROGRAM.START, FOO TO B.',
        '            STOP RUN.',
      ], finish: true);
      expect(diagnostics.single.message, msgStatementWithoutVerb);
    });

    test('an END inside an IF arm is seen and draws 179', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '      CALC.       BEGIN SECTION.',
        '            IF A = B THEN END CALC.',
        '            STOP RUN.',
      ], finish: true);
      expect(diagnostics.single.message, msgEndNotAlone);
    });

    test('a BEGIN SECTION inside an IF arm is deleted as mixed', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            IF A = B THEN BEGIN SECTION.',
      ]);
      expect(diagnostics.single.message, msgIllegalSentenceStructure);
      expect(sentences.single.deleted, isTrue);
    });

    test('the 36th section stops compilation with one 149 (D9.1)', () {
      final lines = <String>['      *PROCEDURE'];
      for (var i = 1; i <= 36; i++) {
        lines
          ..add('      ${'S$i.'.padRight(12)}BEGIN SECTION.')
          ..add('            END S$i.');
      }
      lines.add('            STOP RUN.');
      final ParseResult parse = runParser(
        runFrontEnd(mirrorToDeck('${lines.join('\n')}\n')),
      );
      expect(parse.parserDiagnostics.map((Diagnostic d) => d.message.number), [
        '149,00',
      ]);
      expect(parse.maxSeverity, 5);
    });

    test('nesting past 18 stops compilation with one 915 (D9.7)', () {
      final lines = <String>['      *PROCEDURE'];
      for (var i = 1; i <= 19; i++) {
        lines.add('      ${'N$i.'.padRight(12)}BEGIN SECTION.');
      }
      // Junk that would draw 125 proves parsing stopped before it.
      lines.add('            GROSS TO NET.');
      final ParseResult parse = runParser(
        runFrontEnd(mirrorToDeck('${lines.join('\n')}\n')),
      );
      expect(parse.parserDiagnostics.map((Diagnostic d) => d.message.number), [
        '915,00',
      ]);
      expect(parse.maxSeverity, 5);
    });
  });

  group('clause numbering (design note M2-6)', () {
    test('a deleted sentence keeps n,00 and loses its STOP RUN', () {
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck(
          '      *PROCEDURE\n'
          "${' ' * 12}MOVE 'X' TO A B C TO D, STOP RUN.\n",
        ),
      );
      final ParseResult parse = runParser(result);
      // The stray TO deletes the sentence (196) before its STOP RUN is
      // reached, so the mandatory-STOP-RUN check fires too (M2-13).
      expect(parse.parserDiagnostics.map((Diagnostic d) => d.message.number), [
        '196,00',
        '175,00',
      ]);
      // A deleted sentence's diagnostics reference the whole unit.
      expect(parse.parserDiagnostics.first.clause, isNull);
      const options = ListingOptions(date: '01/01/62', time: '1.00');
      final String listing = writeListing(
        result,
        options,
        diagnostics: parse.diagnostics,
      );
      expect(listing, contains('   1,00    3    ILLEGAL SENTENCE STRUCTURE'));
    });

    test('diagnostics in a one-clause sentence carry clause 01', () {
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck(
          '      *PROCEDURE\n'
          '${' ' * 12}SET A = B ** C ** D.\n'
          '${' ' * 12}STOP RUN.\n',
        ),
      );
      final ParseResult parse = runParser(result);
      final Diagnostic diagnostic = parse.parserDiagnostics.single;
      expect(diagnostic.message, msgUnparenthesizedPower);
      expect(diagnostic.clause, 1);
      const options = ListingOptions(date: '01/01/62', time: '1.00');
      final String listing = writeListing(
        result,
        options,
        diagnostics: parse.diagnostics,
      );
      expect(listing, contains('   1,01    3    CONSECUTIVE'));
    });
  });

  group('attested forms restored by the 2026-08-03 review', () {
    test("SET target = 'M' parses clean (F p. 46; PROC-1)", () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        "            SET MARITAL.STATUS = 'M'.",
      ]);
      expect(diagnostics, isEmpty);
      final set = sentences.single.clauses.single as SetClause;
      expect(set.value, isA<LiteralOperand>());
    });

    test('an alphameric literal inside a SET expression keeps 912', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        "            SET X = 'M' * 2.",
      ]);
      expect(diagnostics.single.message, msgAlphamericArithOperand);
    });

    test('a MOVE source can be a function reference (F p. 34; PROC-2)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            MOVE MINIMUM ((CALCULATED.PRICE, MARKET.PRICE,',
        '            HIGH.VALUES)) TO PRICE.LIST.',
      ]);
      expect(diagnostics, isEmpty);
      final move = sentences.single.clauses.single as MoveClause;
      final call = move.source as FunctionCall;
      expect(call.function.text, 'MINIMUM');
      expect(call.arguments.map((NameReference a) => a.text), [
        'CALCULATED.PRICE',
        'MARKET.PRICE',
        'HIGH.VALUES',
      ]);
      expect(move.targets.single.text, 'PRICE.LIST');
    });

    test('a DO USING argument can be a function reference (PROC-2)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO CALC USING MINIMUM ((A, B)), RATE.',
      ]);
      expect(diagnostics, isEmpty);
      final doClause = sentences.single.clauses.single as DoClause;
      expect(doClause.usingArguments.first, isA<FunctionCall>());
      expect(doClause.usingArguments, hasLength(2));
    });

    test('GO TO A IF condition repairs to WHEN with 170 (PROC-3)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GO TO A IF X GT Y.',
      ]);
      expect(diagnostics.single.message, msgWhenSubstitutedForIf);
      expect(sentences.single.deleted, isFalse);
      final go = sentences.single.clauses.single as GoToClause;
      expect(go.targets.single.when, isNotNull);
    });

    test('the continuation targets take the same 170 repair', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GO TO A WHEN X GT Y, B IF X LT Y.',
      ]);
      expect(diagnostics.single.message, msgWhenSubstitutedForIf);
      final go = sentences.single.clauses.single as GoToClause;
      expect(go.targets, hasLength(2));
      expect(go.targets.last.when, isNotNull);
    });

    test("OTHERWISE ends a deferred verb's operands (PROC-4)", () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            IF A GT B THEN LOAD OVERLAY.ONE OTHERWISE GO TO Y.',
      ]);
      expect(diagnostics.single.message, msgDeferredVerb);
      final ifClause = sentences.single.clauses.single as IfClause;
      final load = ifClause.thenArm.single as DeferredVerbClause;
      expect(load.operands.map((Token t) => t.text), ['OVERLAY.ONE']);
      expect(ifClause.otherwiseArm.single, isA<GoToClause>());
    });

    test('a key word as a sentence label draws 192 (D1.5; PROC-5)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '      EQUALS.     MOVE A TO B.',
      ]);
      expect(diagnostics.single.message, msgSentenceStructureError);
      expect(sentences.single.deleted, isFalse);
      expect(sentences.single.scan.label, 'EQUALS');
    });

    test('ADD -1 TO COUNTER parses the signed literal (PROC-9)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            ADD -1 TO COUNTER.',
      ]);
      expect(diagnostics, isEmpty);
      final add = sentences.single.clauses.single as AddClause;
      expect(add.source, isA<UnaryExpr>());
    });

    test('a signed DO parameter parses (D10.7)', () {
      final (_, List<Diagnostic> diagnostics) = _parse([
        '            DO PAY FOR X = 10(-1)1.',
      ]);
      expect(diagnostics, isEmpty);
    });

    test('nested ON OVERFLOW and AT END clauses number (PROC-11)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            SET X = Y, ON OVERFLOW GO TO ERR.',
        '            GET MASTER, AT END GO TO EXIT.',
      ]);
      expect(diagnostics, isEmpty);
      final set = sentences[0].clauses.single as SetClause;
      expect(set.clause, 1);
      expect(set.onOverflow!.clause, 2);
      final get = sentences[1].clauses.single as GetClause;
      expect(get.clause, 1);
      expect(get.atEnd!.statement!.clause, 2);
    });
  });
}
