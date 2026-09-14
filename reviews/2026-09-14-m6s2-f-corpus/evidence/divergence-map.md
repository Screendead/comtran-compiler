# F-sample shapes against the current compiler (Explore agent, 2026-09-14)

F1. A refusal is not a diagnostic: UnrecoveredShape (procedure.dart:147-160); driver stops the job's codegen at the first one (driver.dart:140-147). 96 _unruled sites in procedure.dart, 5 in control_cards.dart.
F2. Severity 1-4 does not stop codegen; only severity 5 (driver.dart:137).
F3. CALL cascade: non-unique old name -> 166,00 (resolver.dart:443-447, sev 3), synonym never entered (:299-302). Six of F's seven pairs collide (EMPLOYEE.NUMBER, BONDEDUCTION, BONDENOMINATION, BONDACCUMULATION, INSURANCE.PREM, RETIREMENT.PREM); only (DEPARTMENT.TOTAL) DPT enters, and every qualified use of DPT -> 101,00 (resolver.dart:424-431).
F4. F declares no internal-mode field. _decimal (procedure.dart:996-1002) refuses any arithmetic operand, SET target, ADD operand, numeric comparand or DO index that is not internalDecimal -> every arithmetic sentence in F refuses.
F5. Division order unconstrained (front_end.dart:133-169; parser.dart:135-153); no message for a missing division.

§9.8 rows:
- No environment division: accepted, no diagnostic; controlCards empty (control_cards.dart:18-56). Open-all with zero files is a no-op (machine.dart:264-271, 331, 358; monitor.dart:31-41). GET/FILE of a name no FILE card lists refuse (procedure.dart:1791-1792, 1853-1854).
- CALL shared old name: 166,00; CALL emits no code (procedure_parser.dart:400).
- 99/9999 EMPLOYNO vs HIGH.VALUE: the operand is the group EMPLOYEE.NUMBER -> alphameric class (legality.dart:375-383); no 82,00; codegen fill _figurativeFill + TXI 245 (procedure.dart:2288-2300), compare CAL high-value word (:3104-3106). Blocked only by F3.
- STOP 1234: parsed (procedure_parser.dart:857-874); missing STOP RUN -> 175,00 sev 4; codegen refuses 'STOP n (notes section 7)' (procedure.dart:1418-1419). SYS)178 exists (monitor.dart:26,45-58).
- 1COPY: 110,00 sev 4 (data_parser.dart:168-171); item reserves nothing (mapper.dart:385-399); MOVE CORRESPONDING GRAND.TOTAL then 97,00 (legality.dart:190-196).
- Level on REDEF line -> 906,00 (data_parser.dart:139-145); level 2 vs 1 -> 81,00 sev 3 (mapper.dart:639-646); QUANTITY 12 fine.
- Six 22-char literals: accepted (mapper.dart:388, 179-184); one 132-char literal over continuations would also scan (data_lexer.dart:217, 344).
- MOVE CORRESPONDING DETAIL TO PAYRECORD, CHECK: qualifier-chain rule (legality.dart:244-262); matches HOURS and BONDENOMINATION only; external->edited = _editRun (procedure.dart:2016-2022) works.
- ADD CORRESPONDING DETAIL TOTALS TO MASTER TOTALS: 3 pairs; refuses at _addPair -> _decimal (procedure.dart:2589-2593).
- MOVE CORRESPONDING DETAIL TO PAYRECORD, CURRENT: matches nothing silently (944,00 under --pedantic only; legality.dart:231-233).
- SET DETAIL GROSS = ...: refuses at _leafOperand -> _decimal (procedure.dart:2796) / _store (:2840-2843).
- FILE MASTER IN ERROR.FILE: parsed (procedure_parser.dart:981-985); binder 21,00 name is not a file (verb_binder.dart:234); codegen refuses 'FILE record IN file' (procedure.dart:1849-1850). MOVE 'M' TO ERRORCODE = _literalInsert (:1905) fine.
- OTHERWISE SET WHT = ZEROS: accepted, _figurativeFill (procedure.dart:2276-2279).
- DO SEARCH FOR INDEX = 1(1)12 with INDEX 99 in RECORD CURRENT: refuses twice: _decimal(index) (procedure.dart:1523) and 'a located DO FOR index' (:1524-1527).

Edited pictures: all five parse (pictorial.dart:355-363, 391-420) and pass the control-word gates (pictorial.dart:205-213; procedure.dart:2122-2128). None of the six HANDOVER defects fires as F writes them (all sources external/edited -> _editRun/_editSteps :2065-2084, which aligns). If sources are retyped IR, defect 1 fires wherever scales differ. MOVE PAYRECORD NETPAY ($88889.99-, 5 int digits) TO CHECK AMOUNT ($***9.99, 4) refuses 'an edit run that bypasses source digits' (procedure.dart:2074-2075). 9(6), 9(5)V99 fine (<10 digits). Runtime: asterisk fill real (movpak.dart:32-35), $ stays put under asterisk fill (:478-487); trailing minus = SignConvention.minusTrailing, code 3 (procedure.dart:2134-2142; movpak.dart:473-476) but no emitted step reads the source sign (runtime.md:721-726).

Card shapes: data-name continuation accepted (data_lexer.dart:79-81, 139-144, 203); punch in cols 23-37 of a continuation card -> 186,00 (:178-183). CURRENT with no L fine (data_lexer.dart:173-176). TABLE 1 with blank type fine (data_parser.dart:96-112).

Relations: IS NOT GREATER THAN / IS EQUAL TO / IS LESS THAN accepted (expression_parser.dart:559-563, 633-648). IS NOT EQUAL TO ZERO on 99V99: _zeroBuild (procedure.dart:3044-3055) but _decimal refuses upstream. (H-40)*RATE*1.5: product of a product refuses at _accumulated (:2780-2782); _decimal first. Literals fine (procedure_lexer.dart:362-414).

Figurative MOVEs: MOVE BLANKS to group EMPLOYNO legal (group = alphameric); MOVE ZEROS TO DPT HOURS -> 101,00 x9 (qualified synonym).

Environment: FILE needs INPUT/OUTPUT, BCD/BINARY, TAPE, BLOCKSIZE mandatory (environment_parser.dart:198-264, 387); SPECIF UNIT1/2, LOW, OPENW, CLOSER (:440-497). One *FILE + *SPEC pair per file, numbered from 1 (control_cards.dart:36-56); operand 04000+k (M5-3). FILE r IN f: f must be a file (verb_binder.dart:234), direction 22,00 (:240), FILE card must list the record (:244-251).

A. RETPREM/INSPREM defect is a general rule: _dataAddress ignores sem.byte for located items (procedure.dart:930-939); base word punches no decrement (:2245-2249). With F's 11-char TABLE.ITEM the two fields land in different words, so no identity; but _strideWords = strideChars ~/ 6 truncates 11 chars to a 1-word stride (procedure.dart:1706-1713; mapper.dart:884-887) silently. F's shape refuses earlier anyway (F4).
B. --run needs no environment division to reach OPEN ALL FILES; with no FILE cards open-all/close-all are no-ops; but GET/FILE refuse at codegen so no object text is produced.
