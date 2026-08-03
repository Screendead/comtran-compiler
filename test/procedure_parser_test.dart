import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

// Builds procedure cards: a label starts in the name margin (column
// 7); unlabeled text starts at column 13.
List<SourceCard> _cards(List<String> lines) {
  final List<CardImage> deck = mirrorToDeck('${lines.join('\n')}\n');
  return [for (var i = 0; i < deck.length; i++) SourceCard(deck[i], i + 1)];
}

(List<Sentence>, List<Diagnostic>) _parse(
  List<String> lines, {
  bool finish = false,
}) {
  final ProcedureScan scan = scanProcedure(_cards(lines));
  expect(scan.diagnostics, isEmpty, reason: 'scan must be clean');
  final diagnostics = <Diagnostic>[];
  final parser = ProcedureParser(diagnostics);
  final List<Sentence> sentences = parser.parseGroup(scan);
  if (finish) {
    parser.finishProgram(_cards(['      X']).single);
  }
  return (sentences, diagnostics);
}

void main() {
  group('the 90.05 procedure division', () {
    late final ParseResult parse;
    late final ParsedProcedureGroup group;

    setUpAll(() {
      parse = runParser(
        runFrontEnd(
          decodeCanon(File('tests/90.05-payroll.ctdeck').readAsBytesSync()),
        ),
      );
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
      final GoToClause goTo = compare.clauses.single as GoToClause;
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
      final IfClause ifClause = endOfMasters.clauses.single as IfClause;
      expect(ifClause.thenArm.single, isA<GoToClause>());
      expect(ifClause.otherwiseArm.single, isA<SetClause>());
      expect(ifClause.clause, 1);
      expect(ifClause.thenArm.single.clause, 2);
      expect(ifClause.otherwiseArm.single.clause, 3);
    });

    test('parses the GET sentences with their AT END transfers', () {
      final Iterable<GetClause> gets = group.sentences
          .expand((Sentence s) => s.clauses)
          .whereType<GetClause>();
      expect(gets, isNotEmpty);
      for (final GetClause get in gets) {
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
      final MoveClause move = sentences.single.clauses.single as MoveClause;
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
      final GoToClause goTo = sentences.single.clauses.single as GoToClause;
      expect(goTo.targets, hasLength(3));
      expect(goTo.index!.text, 'SWITCH');
    });

    test('DO FOR parses p(q)r; a fourth index draws 83 (D5.2)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO REORDER.RTN FOR PART.NO = 1001(1)1499.',
      ]);
      expect(diagnostics, isEmpty);
      final DoClause doClause = sentences.single.clauses.single as DoClause;
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

    test('DO USING GIVING parses its argument lists (F p. 52)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            DO MINIMUM USING GROSS, 15.00 GIVING TAX.',
      ]);
      expect(diagnostics, isEmpty);
      final DoClause doClause = sentences.single.clauses.single as DoClause;
      expect(doClause.usingArguments, hasLength(2));
      expect(doClause.givingResults.single.text, 'TAX');
    });

    test('the AT END slot accepts a bare name; junk draws 106 (D6.6)', () {
      final (List<Sentence> sentences, List<Diagnostic> diagnostics) = _parse([
        '            GET MASTER, AT END WRAP.UP.',
      ]);
      expect(diagnostics, isEmpty);
      final GetClause get = sentences.single.clauses.single as GetClause;
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
  });

  group('clause numbering (design note M2-6)', () {
    test('a single-clause diagnostic prints n,01 in the listing', () {
      final FrontEndResult result = runFrontEnd(
        mirrorToDeck(
          '      *PROCEDURE\n'
          "${' ' * 12}MOVE 'X' TO A B C TO D, STOP RUN.\n",
        ),
      );
      final ParseResult parse = runParser(result);
      expect(parse.parserDiagnostics, isNotEmpty);
      final Diagnostic diagnostic = parse.parserDiagnostics.first;
      expect(diagnostic.clause, isNull); // deleted sentence: whole unit
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
}
