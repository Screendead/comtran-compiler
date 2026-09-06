# [J 90.02] contracts: MOVPAK second half — SYS)219–258 and SYS)267–282

All line citations are `comtran-manuals/J28-6169/90.02-generated-code.md` unless another path is written. Sample-listing citations are `comtran-manuals/J28-6169/90.05-sample-program.md`. Scans checked: `comtran-manuals/J28-6169/images/page-162.png`, `page-163.png`, `page-164.png`, `page-165.png`, `page-167.png`, `page-169.png`.

---

## MOVPAK STRUCTURE

**Why the package exists.** 90.02.10 states the packaging: "Many of the SYS Reference numbers are concerned with subroutines to move fields at object time. The interaction of various of these 'MOVE' subroutine made it desirable to package several of them together into one subroutine (called MOVPAK)." (line 386).

**Entry selection — four dispatch entries, by what the caller has already set.** Each is a `TSX SYS)nnn,4`, so index register 4 carries the linkage.

| Entry | Calling sequence (verbatim) | Parameter words | Manual's resume statement | Lines |
|---|---|---|---|---|
| SYS)179 | `TSX  SYS)179,4` / `SOURCE-ADDRESS-REFERENCE` / `TARGET-ADDRESS-REFERENCE` / `Begin specific Move subroutine call` | 2 | "the instructions beginning at 3,4 are executed to actually perform the moving operation" | 660–670 |
| SYS)180 | `TSX  SYS)180,4` / `TARGET-ADDRESS-REFERENCE` / `Begin specific subroutine call` | 1 | "the specific MOVE instructions beginning at 2,4 are executed" | 700–709 |
| SYS)181 | `TSX  SYS)181,4` / `SOURCE-ADDRESS-REFERENCE` / `Begin specific subroutine call` | 1 | "the specific Move instructions are executed" … "beginning at 2,4" | 711–719 |
| SYS)182 | `TSX  SYS)182,4` / `Begin specific subroutine call` | 0 | "The specific Move instructions are executed beginning at 1,4." | 721–728 |

SYS)179 "uses the information in the calling sequence to set up the Move Source Pointer, SYS)132, and the Move Target Pointer, SYS)133" (line 670). SYS)180 is for a source already in SYS)132 "or the source item is in a machine register (AC or MQ)" (line 709); SYS)181 the mirror for the target (line 719); SYS)182 for "both the Source Pointer, SYS)132 and the Target Pointer SYS)133, have been preset by inline instructions; or a machine register is used for either or both source and target" (line 728).

`docs/design/m4-codegen.md:479–482` records this as our convention: "The MOVPAK dispatch entries and their return-skip convention: SYS)179 (both descriptors in the calling sequence, resume 3,4), SYS)180 (target only, 2,4), SYS)181 (source only, 2,4), SYS)182 (both preset, 1,4) — resume offset is parameter-word count plus one ([J 90.02.14]–15)."

**The pointer cells.** SYS)132 is `PZE LOC,,BYTE`, "This cell points to the first word address (LOC) and first BYTE (0-5) of the source field involved in a Move" (lines 416–420); SYS)133 the same for the target (lines 460–464). Three in-line forms set them: `LDI CP)+NN / STI SYS)132` for working storage; `CAL BL)NN / ACL CP)+NN / SLW SYS)132` for a simple base locator; and the six-word `CAL/ACL/PDX/TXL/ACL/SLW` form for a complex base locator (lines 429–457).

**Address-reference forms in a dispatch calling sequence** (lines 672–697): `PZE LOC,,BYTE` for working storage; `MZE BL)NN,,CP)+NN` for a base-located item; `MON PI)NN,,0` for a positional-indicator item.

**The specific-move words that follow.** They are machine instructions in the object program, not data. Three word shapes occur across 219–282:

- `TXI SYS)nnn,1,COUNT` — the count rides in the **decrement** and the tag is index register **1**. The sample confirms the encoding: `TXI SYS)267,1,4` punches `1 00004 1 00413` (90.05 line 963), i.e. prefix `1` (TXI), decrement `00004`, tag `1`, address `00413`.
- `TRA SYS)nnn` — no count. Used by the four round steps 219–222 (lines 1201, 1209, 1217, 1225), by SYS)274 (line 1744), and by the transfer-linked converts 248, 249, 252, 253, 254, 255, 256 (lines 1455, 1478, 1511, 1521, 1534, 1544, 1553).
- `TSX SYS)nnn,4` — used inside the range only by SYS)250, 251, 257 and 258 (lines 1487, 1502, 1562, 1571). These reload index register 4 and therefore break the enclosing MOVPAK linkage; each takes exactly one following control word.

**Terminators.** The manual states one terminator rule explicitly, for the XD→XD family: "This type of MOVPAK call is always terminated by the instruction" `TXI SYS)223, 1, TARGET-NUMERIC-LENGTH` (lines 766–769). The other four families mark it in the step list only: `TXI SYS)225 … (End of call sequence)` (line 814), `SYS)224 … (End of call sequence)` (line 900), `SYS)226 … (End of call sequence)` (line 945), `SYS)275 … (end of call sequence)` (lines 1682–1683). The four *own* entries for 223–226 (lines 1230–1260) and for 275 (lines 1749–1755) do **not** repeat the "end of call sequence" tag.

Resume after a terminator is attested in the sample as the immediately following word: `TXI SYS)225,1,5` at LOC 00611 → `CLA 3)HOURS` at 00612 (90.05 lines 1126–1127); `TXI SYS)275,1,5` at 01361 → `STO 3.RS)1` at 01362 (90.05 lines 1586–1587); `TXI SYS)226,1,7` at 01377 → `TSX IOC)9,4` at 01400 (90.05 lines 1600–1601).

**Two families end without a `TARGET-NUMERIC-LENGTH` word.** SYS)267's sequence ends in `AXT NUMBER-OF-DIGITS-TO-CONVERT, 1` (line 1662); resume is the word after the AXT — LOC 00400 `AXT 7,1` → 00401 `CLA 6)WHT` (90.05 lines 1000-region, printed at 90.05 lines corresponding to LOC 00400/00401). The alphabetic movers 239/243/244 are one word and return directly: `TXI SYS)239,1,15` at 01353 → `LDI CP)+59` at 01354 (90.05 lines 1580–1581).

**Full menu of step kinds the appendix names**, drawn from the five family lists (lines 750–760 for SYS)183; 808–818 for SYS)185; 889–905 for SYS)189; 934–950 for SYS)190; 1676–1691 for SYS)268): move, convert, develop, bypass, insert leading zeros, insert trailing zeros, develop decimal zeros, test for overflow, test for overpunch, scan for sign, round current character, and the terminating target-numeric-length word. Each list is prefaced "two or more of the following instructions" (lines 743, 806, 887, 931, 1673), and 90.02.16 calls them a menu, not an ordering: "Immediately following the TXI instruction will be two or more of the following instructions" (line 743).

**Sign-examination notes.** Two forms recur. "The last character processed under control of this instruction is examined for source field sign" attaches to the 227/228/229/230 move steps, the 231/232/233/234 test steps and the 235/236/237/238 bypass steps (lines 762, 837, 883, 927; and inside SYS)268's list to 276/277/278, line 1696). "The first character processed under control of this instruction is examined for source field sign" attaches to SYS)200 and SYS)202 in the EF-source families (lines 881, 925) and, inside SYS)268's list, to SYS)282 (line 1694).

**The two flag cells every numeric member can set.** SYS)130: "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)." (line 412). SYS)131: "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects an improper data condition." (line 414). SYS)134: "This cell is set non zero whenever a floating point underflow results from a Move." (line 466).

**Registers, as the printed words show them.**
- Index register 4 carries the dispatch linkage (`TSX SYS)179–182,4`, lines 662, 702, 713, 723) and is reloaded by SYS)250/251/257/258.
- Index register 1 carries every step count (tag `1` in every `TXI SYS)nnn,1,COUNT`), and SYS)267 loads it outright with `AXT NUMBER-OF-DIGITS-TO-CONVERT, 1` (line 1662).
- The accumulator and MQ are the register source or target for the converts: SYS)184 "leaving results in the AC or AC-MQ" (line 791), SYS)186/187/188 "from internal decimal in the AC or AC-MQ" (lines 862, 870, 878), SYS)246/247 (lines 1442, 1450), SYS)250/251/253/254/257/258 (lines 1491, 1506, 1526, 1539, 1566, 1575), SYS)267 "from internal decimal in the AC-MQ" (line 1665), SYS)268 "leaving the results in the AC-MQ" (line 1673).

**Stated vs inferred — read this before writing a handler.** Stated: the 1,4 / 2,4 / 3,4 resume offsets; the terminator rule for SYS)183; the "(End of call sequence)" tags; the count in the TXI decrement with tag 1. **Not stated anywhere in 90.02, and therefore inference:** that MOVPAK executes each `TXI SYS)nnn,1,COUNT` as a live transfer that accumulates the count into index register 1; that index register 1 is cleared or saved on dispatch entry so the accumulated value is the count alone; how a step subroutine finds the *next* calling-sequence word after it finishes; and how the terminator computes the return address. Mark all four unverified. `lib/src/codegen/procedure.dart:1038` already assumes the register is clobbered — "Every MOVPAK sequence ends in an `AXT` that writes index register 1, so that one register empties" — so the handler contract must settle it either way.

---

## ENTRIES SYS)219 TO SYS)258

Common to every entry in this section: no entry states a skip-return distance of its own. The step words (219–222, 227–238) are reached from inside a calling sequence and the manual gives no return mechanism for them; the terminators (223–226) and the standalone converts have the word counts given per entry below.

### SYS)219–222 — round steps

| # | Calling sequence (verbatim) | Family | Description (quoted) | Lines |
|---|---|---|---|---|
| 219 | `TRA     SYS)219          Round current character` | with SYS)183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | header 1198, code 1201, desc 1204; family list 755 |
| 220 | `TRA     SYS)220          Round current character` | with SYS)185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | 1206, 1209, 1212; list 813 |
| 221 | `TRA     SYS)221          Round current character` | with SYS)189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | 1214, 1217, 1220; list 899 |
| 222 | `TRA     SYS)222          Round current character` | with SYS)190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | 1222, 1225, 1228; list 944 |

Inputs: none in the word — no count, no tag. Outputs and side effects: unstated. Skip-return: N/A (in-sequence step). Scan-verified on `page-162.png` (90.02.23), which prints all four as `TRA` with the comment "Round current character".

Documentation quality: **PARTIAL** for all four. Missing: the rounding algorithm; whether the effect is confined to one character position; which pointer "current character" tracks; whether the step sets SYS)130. `docs/design/decisions.md:646` (D4.1(e)) supplies our algorithm as a design decision and notes the single-position choice is amendable.

Sample attestation: none. Zero sites for 219, 220, 221, 222 in 90.05.

### SYS)223–226 — call-sequence terminators

| # | Calling sequence (verbatim) | Family | Description (quoted) | Lines |
|---|---|---|---|---|
| 223 | `TXI     SYS)223, 1, TARGET-NUMERIC-LENGTH` | with SYS)183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | 1230, 1233, 1236; family list 756; terminator rule 769; worked example 782 |
| 224 | `TXI     SYS)224, 1, TARGET-NUMERIC-LENGTH` | with SYS)189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | 1238, 1241, 1244; list 900 |
| 225 | `TXI     SYS)225, 1, TARGET-NUMERIC-LENGTH` | with SYS)185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | 1246, 1249, 1252; list 814 |
| 226 | `TXI     SYS)226, 1, TARGET-NUMERIC-LENGTH` | with SYS)190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | 1254, 1257, 1260; list 945 |

Input: the target's numeric length in the decrement. Output: the completed target field. Side effect: ends the call. Skip-return: the word after the terminator, attested (below).

Documentation quality: **PARTIAL** for all four. Missing: what the routine *does* with TARGET-NUMERIC-LENGTH (sign placement, zero fill, blank-when-zero suppression are all candidates and none is named); and the return-address rule.

Sample attestation: SYS)225 three sites — LOC 00611 count 5 (90.05 line 1126), LOC 01444 count 6 (line 1650), LOC 01463 count 6 (line 1665). SYS)226 one site — LOC 01377 count 7 (line 1600). SYS)223 and SYS)224 have zero sites. The full attested SYS)185 call at LOC 01437–01444 is `TSX SYS)182,4 / TXI SYS)185,1,4 / OCT 000004000003 / TXI SYS)212,1,3 / TXI SYS)193,1,3 / TXI SYS)225,1,6` (90.05 lines 1645–1650).

### SYS)227–230 — sign-examining move steps

| # | Calling sequence (verbatim) | Family | Description (quoted) | Lines |
|---|---|---|---|---|
| 227 | `TXI     SYS)227, 1, NUMBER-OF-CHARACTERS-TO-MOVE` | with SYS)183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | 1262, 1265, 1268; family list 757 with `*Note 1.` |
| 228 | `TXI     SYS)228, 1, NUMBER-OF-CHARACTERS-TO-MOVE` | with SYS)185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | 1273, 1276, 1279; list 815 with `*Note 3.` |
| 229 | `TXI     SYS)229, 1, NUMBER-OF-CHARACTERS-TO-MOVE` | with SYS)189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | 1281, 1284, 1287; list 901 with `*Note 3.` |
| 230 | `TXI     SYS)230, 1, NUMBER-OF-CHARACTERS-TO-MOVE` | with SYS)190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | 1289, 1292, 1295; list 946 with `*Note 3.` |

Inputs: a character count. Outputs: n characters moved. Side effect, stated only in the family list, not in the entry: "The last character processed under control of this instruction is examined for source field sign" (lines 762, 837, 883, 927). Skip-return: N/A.

Documentation quality: **PARTIAL** for all four. Missing from the entry itself: the sign-examination side effect (it lives only in the family-list footnote); and what distinguishes 227 from its no-sign twin SYS)191 (lines 961–966), which the entry text does not say — the two descriptions are word-for-word identical.

Sample attestation: zero sites for all four.

### SYS)231–234 — the overpunch/overflow test steps

| # | Calling sequence (verbatim, own entry) | Family | Description (quoted) | Lines |
|---|---|---|---|---|
| 231 | `TXI     SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH` | with SYS)183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | 1297, 1300, 1303; family list 758 as `…TEST-FOR-OVERFLOW` with `*Note 1.` |
| 232 | `TXI     SYS)232, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH` | with SYS)185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | 1305, 1308, 1311; list 816 as `…OVERFLOW` with `*Note 3.` |
| 233 | `TXI     SYS)233, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH` | with SYS)189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | 1313, 1316, 1319; list 903 as `…OVERFLOW` with `*Note 3.` |
| 234 | `TXI     SYS)234, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH` | with SYS)190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | 1321, 1324, 1327; list 948 as `…OVERFLOW` with `*Note 3.` |

Scan-verified on `page-163.png` (90.02.24): all four own entries print OVERPUNCH, in a page that prints BYPASS for 235/236 and MOVE for 228/229/230 on the same lines — so the word is not a scan artefact.

Documentation quality: **PARTIAL** for all four, plus a printed contradiction (below). Missing: what an overpunch test concludes (arm SYS)131? set a sign? both?); which cell if any it sets; whether a positive test aborts the remaining steps.

Repository position: `docs/design/decisions.md:665` (D4.2, Implementation) — "Note the printed inconsistency preserved in J: SYS)231–234 occupy the test slot in the family lists but their own entries print NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH; our handlers follow the individual entries (overpunch) and the calling-sequence position is recorded as a printed defect." `docs/design/m4-codegen.md:912–914` repeats it as the M4-17 handler rule: "SYS)231–234 follow their own entries (overpunch test), not the family lists' overflow naming (D4.2's note)."

Sample attestation: zero sites for all four.

### SYS)235–238 — bypass steps

| # | Calling sequence (verbatim) | Family | Description (quoted) | Lines |
|---|---|---|---|---|
| 235 | `TXI     SYS)235, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | with SYS)183, XD→XD | "This MOVPAK subroutine is used in conjunction with SYS)183 to move external decimal fields to external decimal fields." | 1329, 1332, 1335; family list 760 with `*Note 1.` |
| 236 | `TXI     SYS)236, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | with SYS)185, XD→EF | "This MOVPAK subroutine is used in conjunction with SYS)185 to move external decimal fields to edited fields." | 1337, 1340, 1343; list 818 with `*Note 3.` |
| 237 | `TXI     SYS)237, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | with SYS)189, EF→XD | "This MOVPAK subroutine is used in conjunction with SYS)189 to move edited fields to external decimal fields." | 1348, 1351, 1354; list 905 with `*Note 3.` |
| 238 | `TXI     SYS)238, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | with SYS)190, EF→EF | "This MOVPAK subroutine is used in conjunction with SYS)190 to move edited fields to edited fields." | 1356, 1359, 1362; list 950, printed `NUMBERS-OF-CHARACTERS-TO-BYPASS` |

Documentation quality: **PARTIAL** for all four. Missing: whether the bypass advances the source pointer, the target pointer, or both — the single most consequential unstated fact in the step vocabulary. The sign side effect again lives only in the family footnote.

Sample attestation: zero sites for all four.

### SYS)239–245 — alphabetic and figurative movers (not numeric members)

**SYS)239.** `TXI     SYS)239, 1, NUMBER-OF-CHARACTERS-TO-MOVE` (line 1367). "This MOVPAK subroutine moves alphabetic fields to alphabetic fields." (line 1370). Lines: header 1364, code 1367, desc 1370. One-word call; resume is the next word, attested at LOC 01353 → 01354 (90.05 lines 1580–1581). Quality: **PARTIAL** — the count's referent (source length or target length) is unstated, and there is no padding rule when the two differ. Sample: 2 sites, counts 15 and 15 (90.05 lines 1398, 1580).

**SYS)240.** `TXI     SYS)240, 1, NUMBER-OF-CHARACTERS-TO-MOVE` (line 1375). "This MOVPAK subroutine moves alphabetic fields to alphabetic fields with additional blank insertion." (line 1378). Lines 1372, 1375, 1378. Quality: **PARTIAL** — where the blanks go (leading or trailing) is unstated; the count itself comes from SYS)241. Sample: 3 sites, counts 21, 15 (90.05 lines 879, 900) and one more.

**SYS)241.** `TXI     SYS)241, 1, NUMBER-OF-BLANKS-TO-INSERT` (line 1383). "This MOVPAK subroutine is used in conjunction with SYS)240 to move alphabetic fields to alphabetic fields." (line 1386). Lines 1380, 1383, 1386. Quality: **PARTIAL** — the insertion position is unstated. Sample: 3 sites, counts 2, 8 (90.05 lines 880, 901) and one more. `docs/design/m4-codegen.md:432–434` records our pairing rule: "`SYS)239` alone on equal storage lengths, `SYS)240` then `SYS)241` on a shorter source".

**SYS)242.** Two words:
```
TXI     SYS)242, 1, ALPHABETIC-CONTROL     *Note 1.
PZE     CONTROL1,, CONTROL2
```
(lines 1391–1392). "This MOVPAK subroutine moves alphabetic fields to alphabetic fields where some information was unknown at compile time." (line 1395). Note 1: "Bits are placed in the decrement which indicate the following about CONTROL1 and CONTROL2." (line 1399), with the table at lines 1401–1406: `00001` target length is in words not characters; `00002` source length is in words not characters; `00004` CONTROL2 is the location of the target field's length; `00010` CONTROL1 is the location of the source field's length. Lines: 1388, 1391–1392, 1395, 1397–1406. Skip-return: two words, unattested. Quality: **PARTIAL** — the mixing rule when one length is in words and the other in characters is unstated, as is the behaviour on a length mismatch. Sample: zero sites. Scan note below on the fourth table row.

**SYS)243.** `TXI     SYS)243, 1, NUMBER-OF-BLANKS-TO-INSERT` (line 1411). "This MOVPAK subroutine moves blanks to an alphabetic field." (line 1414). Lines 1408, 1411, 1414; and an early illustrative appearance at line 263 in the SYS-reference introduction ("Typical references to such subroutines might appear in the listing as: `STI SYS)133` / `TSX SYS)182,4` / `TXI SYS)243,1,84`", lines 258–264). Quality: **FULL**. Sample: 8 sites, counts 15, 4, 2, 2, 2, 7, 8 and one more (90.05 lines 1030, 1034, 1038, 1042, 1046, 1190, 1194). `docs/design/decisions.md:778` (D4.14) builds the BLANKS move on this entry.

**SYS)244.** `TXI     SYS)244, 1, NUMBER-OF-ZEROS-TO-INSERT` (line 1422). "This MOVPAK subroutine moves zeros to an alphabetic field." (line 1425). Lines 1419, 1422, 1425. Quality: **FULL**. Sample: 3 sites, all count 54 (90.05 lines 789, 793, 1095).

**SYS)245.** Two words:
```
TXI     SYS)245, 1, NUMBER-OF-CHARACTERS-TO-INSERT
OCT     CHARACTERS
```
(lines 1430–1431). "This MOVPAK subroutine moves characters to an alphabetic field. The second word contains 6 characters of the type to be moved." (line 1434). Lines 1427, 1430–1431, 1434. Skip-return: two words; attested — `TXI SYS)245,1,6` at LOC 00346, `OCT 747474747474` at 00347, resume `TRA* END.OF.MASTERS` at 00350 (90.05 lines 924–926). Quality: **PARTIAL** — how a count other than 6 consumes a 6-character word is unstated. Sample: 2 sites, both count 6 (90.05 lines 924, 953).

### SYS)246–247 — internal-decimal justification

**SYS)246.** `TXI     SYS)246, 1, NUMBER-OF-CHARACTERS-IN-TARGET-AREA` (line 1439). "This MOVPAK subroutine moves the internal decimal right justified field in the AC or AC-MQ to an internal decimal field not justified." (line 1442). Lines 1436, 1439, 1442. Input: the accumulator (or accumulator-MQ pair) and a target character count. Output: the not-justified target area. Skip-return: N/A (one in-sequence word). Quality: **PARTIAL** — the storage layout of an "internal decimal field not justified" is nowhere defined in 90.02. Sample: zero sites. `docs/design/decisions.md:661` (D4.2) records this entry as carrying no test step.

**SYS)247.** `TXI     SYS)247, 1, NUMBER-OF-CHARACTERS-IN-SOURCE-AREA` (line 1447). "This MOVPAK subroutine moves from an internal decimal field not justified to internal decimal right justified in the AC or AC-MQ." (line 1450). Lines 1444, 1447, 1450. Quality: **PARTIAL** — same missing layout, plus no rule for when the result occupies the accumulator alone rather than the accumulator-MQ pair. Sample: zero sites.

### SYS)248–258 — scientific-decimal, floating-point and internal-decimal converts

The two control-word formats these entries share:

**CONTROL-WORD-TYPE-SD** (SYS)248 Note 1, lines 1461–1470; scan-verified `page-165.png`): "Prefix — = MZE if decimal in pictorial. = PZE if no decimal in pictorial." / "Address — = Scale applied to mantissa in pictorial." / "Tag — is Sign Convention." with `0` both minus, `1` mantissa minus and exponent plus, `2` mantissa plus and exponent minus, `3` both plus / "Decrement — = Total length in characters, of the field."

**CONTROL-WORD-TYPE-ID** (SYS)250 Note 1, lines 1493–1497): "Prefix — is the sign of the scale. = PZE for plus. = MZE for minus." / "Address — = Scale applied to internal decimal value." / "Decrement — = Numeric length of value." No tag field is described.

| # | Calling sequence (verbatim) | Words | Description (quoted) | Lines |
|---|---|---|---|---|
| 248 | `TRA     SYS)248` / `TARGET-CONTROL-WORD-TYPE-SD     *Note 1.` | 2 | "This MOVPAK subroutine converts the floating point AC to scientific decimal." | 1452, 1455–1456, 1459, note 1461–1470 |
| 249 | `TRA     SYS)249` / `SOURCE-CONTROL-WORD-TYPE-SD` | 2 | "This MOVPAK subroutine converts from scientific decimal to floating point leaving the results in the AC. The SOURCE-CONTROL-WORD-TYPE-SD has the same form as described under SYS)248." | 1475, 1478–1479, 1482 |
| 250 | `TSX     SYS)250, 4` / `TARGET-CONTROL-WORD-TYPE-ID     *Note 1.` | 2 | "This MOVPAK subroutine converts the floating point value in the AC to internal decimal and leaves the results in the AC or AC-MQ." | 1484, 1487–1488, 1491, note 1493–1497 |
| 251 | `TSX     SYS)251, 4` / `SOURCE-CONTROL-WORD-TYPE-ID` | 2 | "This MOVPAK subroutine converts the internal decimal value in the AC or AC-MQ to floating point leaving the results in the AC. The SOURCE-CONTROL-WORD-TYPE-ID has the same form as described under SYS)250." | 1499, 1502–1503, 1506 |
| 252 | `TRA     SYS)252` / `SOURCE-CONTROL-WORD-TYPE-SD` / `TARGET-CONTROL-WORD-TYPE-SD` | 3 | "This MOVPAK subroutine moves a scientific decimal field to a scientific decimal field. The CONTROL-WORD-TYPE-SD for both source and target have the same form as described under SYS)248." | 1508, 1511–1513, 1516 |
| 253 | `TRA     SYS)253` / `SOURCE-CONTROL-WORD-TYPE-SD` / `TARGET-CONTROL-WORD-TYPE-ID` | 3 | "This MOVPAK subroutine converts a scientific decimal field to internal decimal leaving the results in the AC or AC-MQ. CONTROL-WORD-TYPE-SD has the same format as described under SYS)248 and CONTROL-WORD-TYPE-ID has the same format as described under SYS)250." | 1518, 1521–1523, 1526 |
| 254 | `TRA     SYS)254` / `SOURCE-CONTROL-WORD-TYPE-ID` / `TARGET CONTROL-WORD TYPE-SD` | 3 | "This MOVPAK subroutine converts from internal decimal in the AC or AC-MQ to scientific decimal. CONTROL-WORD-TYPE-ID has the same format as described under SYS)250 and CONTROL-WORD-TYPE-SD has the same format as described under SYS)248." | 1531, 1534–1536, 1539 |
| 255 | `TRA     SYS)255` / `TARGET-CONTROL-WORD-TYPE-SD` | 2 | "This MOVPAK subroutine converts from double precision floating point in the AC-MQ to scientific decimal. The CONTROL-WORD-TYPE-SD has the same form as described under SYS)248." | 1541, 1544–1545, 1548 |
| 256 | `TRA     SYS)256` / `SOURCE-CONTROL-WORD-TYPE-SD` | 2 | "This MOVPAK subroutine converts from scientific decimal to double precision floating point leaving the results in the AC-MQ. CONTROL-WORD-TYPE-SD has the same form as described under SYS)248." | 1550, 1553–1554, 1557 |
| 257 | `TSX     SYS)257, 4` / `TARGET-CONTROL-WORD-TYPE-ID` | 2 | "This MOVPAK subroutine converts from double precision floating point in the AC-MQ to internal decimal leaving the results in the AC or AC-MQ. TARGET-CONTROL-WORD-TYPE-ID has the same form as described under SYS)250." | 1559, 1562–1563, 1566 |
| 258 | `TSX     SYS)258, 4` / `SOURCE-CONTROL-WORD-TYPE-ID` | 2 | "This MOVPAK subroutine converts from internal decimal in the AC or AC-MQ to double precision floating point leaving the results in the AC-MQ. SOURCE-CONTROL-WORD-TYPE-ID has the same form as described under SYS)250." | 1568, 1571–1572, 1575 |

Skip-return distance: the printed word count above (2 or 3), i.e. resume at the word after the last control word. For 250, 251, 257 and 258 the entry is `TSX …,4`, so the routine has its own index-register-4 linkage and resumes at 2,4 by the same rule the dispatch entries use; the other seven are `TRA`-entered and must locate their control words through the enclosing dispatch linkage. None of this is stated; mark it unverified. Scan-verified: 254 and 255–258 on `page-167.png`, 248 on `page-165.png`.

Documentation quality:
- **248, 252, 254, 255: PARTIAL.** Missing: the character layout of a scientific-decimal field — which characters hold the mantissa, where the exponent begins, and where the two signs sit — is nowhere in 90.02. `docs/comtran-language-definition.md:1209` supplies "Scientific decimal is the edited form of the floating point. The maximum fractional portion of a scientific decimal field is 16 digits."
- **249, 253, 256: PARTIAL.** Missing: the parse rule for a scientific-decimal *source*. `docs/comtran-language-definition.md:1748` closes it from J 02.04.04: "For the source fields of the scientific decimal type, a free form of data is allowed within the limits of the field."
- **250, 251, 257, 258: PARTIAL.** Missing: whether the internal-decimal value occupies the accumulator alone or the accumulator-MQ pair, and the rounding rule of the float-to-fixed direction. `docs/comtran-language-definition.md:1562` narrows the first: "Fixed point double precision numbers are denoted in the Data Description by formats representing more than 10 digits."

Sample attestation: zero sites for 246, 247 and 248–258. Every one of these thirteen entries is unexercised by the sample program.

---

## ENTRIES SYS)267 TO SYS)282

### SYS)267 — internal decimal in the accumulator-MQ pair to an edited field

Calling sequence, verbatim (lines 1660–1662):
```
TXI     SYS)267, 1, TARGET-EDIT-CONTROL
OCT     TARGET-CONTROL-WORD-BITS
AXT     NUMBER-OF-DIGITS-TO-CONVERT, 1
```

Description, quoted (line 1665): "This MOVPAK subroutine converts from internal decimal in the AC-MQ to form an edited field. The TARGET-EDIT-CONTROL and TARGET-CONTROL-WORD-BITS have the same form as described under SYS)185."

Inputs: the value in the accumulator-MQ pair; the edit-control bits in the first word's decrement; the control word; the digit count in the third word. The referenced formats are SYS)185's Note 1 (lines 822–832: `00001` asterisks, `00002` comma(s), `00004` decimal point, `00010` dollar sign, `00020` Blank When Zero) and Note 2 (lines 834–843): "Prefix = 0 if no target field commas; otherwise = number of digits to the left of first comma." / "Address = number of leading \*'s, or 8's in pictorial." / "Decrement = number of 8's, 9's, \*'s, to the left of the real or implied decimal point in target pictorial." / "Tag = TARGET-SIGN-CONVENTION" with `0` no sign, `1` overpunch minus, `2` overpunch plus, `3` right minus, `4` right plus, `5` left minus, `6` left plus.

Outputs: the edited target field. Side effects: no test step is carried — `docs/design/decisions.md:661` records "SYS)186–188 (external decimal), SYS)267 (edited) and SYS)246 (internal decimal not justified) each carry no test step." Skip-return: three words; resume at the word after the `AXT`, attested at LOC 00376–00400 → 00401 `CLA 6)WHT` (90.05 lines 963–966).

Lines: header 1657, code 1660–1662, description 1665. Scan-verified on `page-169.png` (90.02.30).

Documentation quality: **PARTIAL**. Missing: whether the `AXT` is executed as a real instruction (loading index register 1 with the digit count) or read as a parameter; the character placement for sign conventions 3 to 6 (right minus, right plus, left minus, left plus), which the SYS)185 table names but never locates; and what the routine does when the value's digit count exceeds the target's.

Sample attestation: 26 sites, the most-used entry in the range. 25 punch `TXI SYS)267,1,<edit>`; one punches `TRA SYS)267,0,0` at LOC 01327 (90.05 line 1560), the site whose edit control is zero. Attested control words: `000003000001` once (90.05 line 1561), `000004000003` fifteen times, `000005000004` nine times. The full attested shape, LOC 00373–00400: `CLA 6)GROSS / TSX SYS)180,4 / PZE 2)GROSS,,1 / TXI SYS)267,1,4 / OCT 000005000004 / AXT 7,1` (90.05 lines 962–966). `docs/design/m4-codegen.md:443–448` records this as the attested edited-store shape, and `lib/src/codegen/procedure.dart:2129–2145` emits both variants.

### SYS)268 — edited field to internal decimal, the family head

Calling sequence, verbatim (line 1670):
```
TXI     SYS)268, 1, 1
```

Description, quoted (line 1673): "This MOVPAK subroutine converts an edited field to internal decimal leaving the results in the AC-MQ. This instruction is followed by two or more of the following instructions:" — the menu at lines 1676–1691, reproduced verbatim:
```
TXI     SYS)269, 1, NUMBER-OF-CHARACTERS-TO-CONVERT
TXI     SYS)270, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI     SYS)271.1, NUMBER-OF-CHARACTERS-TO-BYPASS
TXI     SYS)272, 1, NUMBER-OF-DECIMAL-ZEROS-TO-DEVELOP
TXI     SYS)273, 1, NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN
TRA     SYS)274     Round Current Character
TXI     SYS)275, 1, TARGET-DECIMAL-NUMERIC-LENGTH (end of call
                                                    sequence)
TXI     SYS)276, 1, NUMBER-OF-CHARACTERS-TO-CONVERT          *Note 2
TXI     SYS)277, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
                                                              *Note 2
TXI     SYS)278, 1, NUMBER-OF-CHARACTERS-TO-BYPASS           *Note 2
TXI     SYS)279, 1, NUMBER-OF-LEADING-DECIMAL-ZEROS-TO-DEVELOP
TXI     SYS)280, 1, NUMBER-OF-CHARACTERS-TO-CONVERT
TXI     SYS)281, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW
TXI     SYS)282, 1, NUMBER-OF-CHARACTERS-TO-BYPASS           *Note 1
```
"\*Note 1  The first character processed under control of this instruction is examined for source field sign." (line 1694). "\*Note 2  The last character processed under control of this instruction is examined for source field sign." (line 1696).

Inputs: the source pointer SYS)132, already set by the dispatch entry; the literal decrement `1`. Outputs: the value in the accumulator-MQ pair. Side effect: the family carries an overflow-test step, so `docs/design/decisions.md:661` puts SYS)268 among the five handlers that arm SYS)130. Skip-return: the family terminates at SYS)275, and resume is the word after it.

Lines: header 1667, code 1670, description 1673, menu 1676–1691, notes 1694, 1696. Scan-verified on `page-169.png`.

Documentation quality: **PARTIAL**. Missing: what the literal decrement `1` means — every sibling family head carries a meaningful parameter (a sign convention or an edit control) and this one carries a bare 1 with no explanation.

Sample attestation: one site, LOC 01356–01362 (90.05 lines 1583–1587): `TSX SYS)182,4 / TXI SYS)268,1,1 / TXI SYS)269,1,5 / TXI SYS)275,1,5 / STO 3.RS)1`. Note the sample stores the result with `STO`, which stores the accumulator alone, although the entry says the result is left "in the AC-MQ".

### SYS)269–274, 276–282 — the SYS)268 step words

Every one of these thirteen entries carries the identical description sentence, "This MOVPAK subroutine is used in conjunction with SYS)268 to convert an edited field to internal decimal." — except SYS)275, which prints "suvroutine" for "subroutine". None states a skip-return distance; each is an in-sequence step word.

| # | Calling sequence (verbatim, own entry) | Role | Lines (header, code, desc) | Menu line |
|---|---|---|---|---|
| 269 | `TXI     SYS)269, 1, NUMBER-OF-CHARACTERS-TO-CONVERT` | convert n characters | 1698, 1701, 1704 | 1676 |
| 270 | `TXI     SYS)270, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | overflow test | 1706, 1709, 1712 | 1677 |
| 271 | `TXI     SYS)271, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | bypass n characters | 1717, 1720, 1723 | 1678, printed `SYS)271.1` |
| 272 | `TXI     SYS)272, 1, NUMBER-OF-DECIMAL-ZEROS-TO-DEVELOP` | develop decimal zeros | 1725, 1728, 1731 | 1679 |
| 273 | `TXI     SYS)273, 1, NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN` | scan for sign | 1733, 1736, 1739 | 1680 |
| 274 | `TRA     SYS)274     Round Current Character` | round | 1741, 1744, 1747 | 1681 |
| 275 | `TXI     SYS)275, 1, TARGET-DECIMAL-NUMERIC-LENGTH` | terminator | 1749, 1752, 1755 | 1682–1683, tagged "(end of call sequence)" |
| 276 | `TXI     SYS)276, 1, NUMBER-OF-CHARACTERS-TO-CONVERT` | convert, last character examined for sign | 1757, 1760, 1763 | 1684, `*Note 2` |
| 277 | `TXI     SYS)277, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | overflow test, last character examined for sign | 1765, 1768, 1771 | 1685–1686, `*Note 2` |
| 278 | `TXI     SYS)278, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | bypass, last character examined for sign | 1773, 1776, 1779 | 1687, `*Note 2` |
| 279 | `TXI     SYS)279, 1, NUMBER-OF-LEADING-DECIMAL-ZEROS-TO-DEVELOP` | develop leading decimal zeros | 1781, 1784, 1787 | 1688 |
| 280 | `TXI     SYS)280, 1, NUMBER-OF-CHARACTERS-TO-CONVERT` | convert | 1792, 1795, 1798 | 1689 |
| 281 | `TXI     SYS)281, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` | overflow test | 1800, 1803, 1806 | 1690 |
| 282 | `TXI     SYS)282, 1, NUMBER-OF-CHARACTERS-TO-BYPASS` | bypass, **first** character examined for sign | 1808, 1811, 1814 | 1691, `*Note 1` |

Documentation quality, per entry:
- **269, 280: PARTIAL.** Missing: what distinguishes the two — the descriptions are word for word identical and neither carries a sign note; and where the converted digits accumulate relative to the assumed decimal point.
- **276: PARTIAL.** Missing: the same distinction from 269 and 280 in the entry itself; the "last character examined for source field sign" fact lives only in the menu footnote at line 1696.
- **270, 281: PARTIAL.** Missing: what the test does on a positive result — set SYS)130? abort the sequence? — and what distinguishes 270 from 281.
- **277: PARTIAL.** Same missing fact, plus the sign note lives only in the menu.
- **271, 278, 282: PARTIAL.** Missing: whether a bypass advances the source pointer, the target position, or both; and what distinguishes the three. For 282 the "first character examined for source field sign" fact is in the menu only.
- **272, 279: PARTIAL.** Missing: where a "developed" decimal zero is placed and how 272 differs from 279 beyond the word LEADING, which appears in 279's name and not 272's.
- **273: PARTIAL.** Missing: which characters count as a sign, and what the routine does when it finds one — a sign scan across n characters implies a search, but nothing states the search order or the failure behaviour.
- **274: PARTIAL.** Missing: the rounding algorithm and its scope, exactly as for 219–222. `docs/design/decisions.md:644` (D4.1(d)) names SYS)274 as the fifth round step and `:646` (D4.1(e)) supplies our algorithm as a design decision.
- **275: PARTIAL.** Missing: the meaning of TARGET-DECIMAL-NUMERIC-LENGTH for a register target (there is no target field to size), and the return-address rule.

Sample attestation: SYS)269 one site, count 5 (90.05 line 1585); SYS)275 one site, count 5 (90.05 line 1586). Zero sites for 270, 271, 272, 273, 274, 276, 277, 278, 279, 280, 281, 282.

---

## PRINTED INCONSISTENCIES

Each is quoted from the conversion and, where noted, checked on the page scan.

**1. SYS)231–234: OVERFLOW in the family lists, OVERPUNCH in the own entries.** The four family lists print `TXI  SYS)231, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` (line 758), `TXI  SYS)232, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` (line 816), `TXI  SYS)233, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` (line 903) and `TXI  SYS)234, 1, NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERFLOW` (line 948). The own entries print `NUMBER-OF-CHARACTERS-TO-TEST-FOR-OVERPUNCH` in all four cases (lines 1300, 1308, 1316, 1324). Scan-confirmed on `page-163.png`. Repository ruling: `docs/design/decisions.md:665` — "our handlers follow the individual entries (overpunch) and the calling-sequence position is recorded as a printed defect"; restated at `docs/design/m4-codegen.md:912–914`.

**2. SYS)238: plural NUMBERS in the family list.** Line 950 prints `TXI  SYS)238, 1, NUMBERS-OF-CHARACTERS-TO-BYPASS`; the own entry at line 1359 prints `TXI     SYS)238, 1, NUMBER-OF-CHARACTERS-TO-BYPASS`. The same plural also appears at line 990 for SYS)194 (`NUMBERS-OF-CHARACTERS-TO-MOVE`), outside this range.

**3. SYS)221: plural "characters" in the family list.** Line 899 prints `TRA  SYS)221               Round current characters`; the own entry at line 1217 prints `TRA     SYS)221          Round current character`. The other three round steps are singular in both places. `docs/design/decisions.md:646` (D4.1(e)) cites this as "the one place the manual hints at a wider scope" and makes the single-position choice amendable on it.

**4. SYS)254: unhyphenated third word.** Line 1536 prints `TARGET CONTROL-WORD TYPE-SD` where the line directly above it prints `SOURCE-CONTROL-WORD-TYPE-ID`. Scan-confirmed on `page-167.png`. The conversion note records it at line 1907.

**5. SYS)271: a period where every sibling has a comma.** Line 1678 prints `TXI     SYS)271.1, NUMBER-OF-CHARACTERS-TO-BYPASS`. The own entry at line 1720 prints `TXI     SYS)271, 1, NUMBER-OF-CHARACTERS-TO-BYPASS`. Scan-confirmed on `page-169.png`. The conversion note records it at line 1908.

**6. SYS)275: "suvroutine".** Line 1755 prints "This MOVPAK suvroutine is used in conjunction with SYS)268 to convert an edited field to internal decimal." The conversion note records it at line 1909.

**7. The SYS)268 menu inverts the sign-note numbering used by every other family.** In SYS)189's list (lines 879–883) Note 2 is "The first character processed…" and Note 3 is "The last character processed…"; SYS)190's list is the same (lines 923–927). In SYS)268's list (lines 1694, 1696) Note 1 is the *first*-character note and Note 2 the *last*-character note. A handler generator that carries note numbers between families will bind the wrong step.

**8. Inside SYS)268's menu the first-character sign note sits on a bypass step, not on the sign-scan step.** `TXI SYS)282, 1, NUMBER-OF-CHARACTERS-TO-BYPASS           *Note 1` (line 1691), while `TXI SYS)273, 1, NUMBER-OF-CHARACTERS-TO-SCAN-FOR-SIGN` (line 1680) carries no note at all. The same pattern holds in the EF-source families outside this range — SYS)200 and SYS)202 are bypass steps carrying the first-character note (lines 881, 925) while SYS)217 and SYS)218 are the sign-scan steps.

**9. SYS)272 and SYS)279 differ only by the word LEADING and are otherwise undistinguished.** Line 1679 `TXI     SYS)272, 1, NUMBER-OF-DECIMAL-ZEROS-TO-DEVELOP` against line 1688 `TXI     SYS)279, 1, NUMBER-OF-LEADING-DECIMAL-ZEROS-TO-DEVELOP`; both own entries (lines 1731, 1787) carry the identical description sentence.

**10. Appendix against listing: SYS)267 is punched as a TRA when its edit control is zero.** 90.02.30 prints only the TXI form (line 1660). The sample punches `TRA    SYS)267,0,0` with octal `0020 00 0 00413` at LOC 01327 (90.05 line 1560), followed by `OCT 000003000001` and `AXT 5,1` (90.05 lines 1561–1562). Of the 26 sites, 25 are TXI and 1 is TRA. `lib/src/codegen/procedure.dart:2129–2140` reproduces both, commenting "The one site whose edit control computes to zero punches a real transfer where every other punches the step's `TXI`".

**11. Appendix against listing: SYS)268 says "AC-MQ", the sample stores with STO.** Line 1673 says the result is left "in the AC-MQ"; LOC 01362 is `STO 3.RS)1` (90.05 line 1587), which stores the accumulator alone.

**12. Conversion-note defect, not a printed one.** The conversion note at line 1912 cites the SYS)242 ALPHABETIC CONTROL table as "PDF 163". The table is on PDF page 164, section marker 90.02.25 (source marker at line 1345, `<!-- 90.02.25 | PDF 164 -->`); PDF page 163 is section 90.02.24 and holds SYS)228 to SYS)236. Verified by reading both scans.

**13. Doubtful reading, SYS)242's fourth control bit.** On `page-164.png` the fourth octal value prints as `0001C` — the fifth glyph is a broken open ring, checked at 3× enlargement. The conversion reads `00010` (line 1406) and the conversion note (line 1912) says so. The reading follows the bit doubling 00001, 00002, 00004 rather than a clean glyph read; treat it as inference.

**14. Possible conversion divergence, unverified.** The same table's first row prints, on `page-164.png` at 3× enlargement, what reads as "Target fields's length is in words (not characters)" — a doubled possessive — while the conversion prints "Target field's length is in words (not characters)" (line 1403). The second row unambiguously prints "Source field's". I cannot settle the first row at 150 dpi; a higher-resolution crop or Jack's eye would. No handler contract turns on it.

---

## SYS)259 TO SYS)266 — the boundary

**SYS)259 does not exist.** It appears nowhere in 90.02. `page-167.png` (section 90.02.28) prints SYS)258 and then SYS)260 on the same page with no gap, scan-confirmed. `docs/comtran-language-definition.md:4379` states the same finding: "MOVPAK is entered at SYS)179–182 and its members run SYS)183–258 and SYS)267–282 (no SYS)259 exists; each member is identified in its own entry as a MOVPAK subroutine)".

**SYS)260–266 are GET-path and error-termination routines. Not one is called a MOVPAK subroutine.** M4-17 excludes them and assigns them to M5: `docs/design/m4-codegen.md:900–903` — "M5 lands IOCS: IOC)2–17, 29, 46, 53, 54 and SYS)260–266, 283, and 286–296 less the already-landed 294."

| # | What it is | Lines |
|---|---|---|
| 260 | Not a `TSX` target. It rides in the decrement of the second word of the IOC)8 read sequence: `TSX IOC)8, 4` / `PZE FILENAME, , SYS)260` / `PZE SYS)265, , SYS)283` / `IOCDN* BL)NN, , 14`. "The SYS)260 subroutine prints an error message indicating processing terminated due to record length error." | 1577–1588 |
| 261 | `TSX SYS)261, 4` / `TSX SYS)263, 6`. "converts the logical accumulator from a BCD number to binary, checking for non-numeric characters and/or imbedded or trailing blanks; and leaves the result in the decrement of the AC." Error return is "1,4 to routine SYS)263". | 1593–1601 |
| 262 | `TSX SYS)262, 4`. "converts the binary AC address to a 6 character (with leading blanks) BCD word to be used in Filing' a variable length BCD record." | 1603–1608 |
| 263 | `TSX SYS)263, 4`. "prints an error message in conjunction with SYS)261 upon GET error condition… and exits to the CT monitor." | 1611–1617 |
| 264 | `TXL *+5, 1, BLOCKSIZE-1` / `TSX SYS)264, 4` / `PZE FILENAME` / `OCT STATEMENT-NUMBER` / `OCT SUB-STATEMENT-NUMBER`. "When the record size (in IR1) exceeds the Blocksize for the file, SYS)264 prints a message and exits to the CT Monitor." | 1619–1629 |
| 265 | Also a word inside the IOC)8 sequence, not a `TSX` target. "This SYS number appears as part of the GET calling sequence to the IOCS Read routine whenever the 'AT END' option is not used with the GET verb." … "SYS)265 prints a message concerning the unexpected end-of-file and exits to the CT Monitor." | 1631–1642 |
| 266 | `TRA SYS)266` or `TXI SYS)266, 0, 0`. "This routine performs a 'panic' Close-All-Files and exits to the CT Monitor." | 1644–1650 |

SYS)283, the sibling word in the same read sequence, sits outside this range at lines 1816–1828 and is likewise M5's.

---

## GAPS — facts a stage-4 handler needs that no record settles

Each gap names what is missing, and where the repository already closes it if it does.

**G1. How a step subroutine returns to the next calling-sequence word.** 90.02 states the dispatch entries' 1,4 / 2,4 / 3,4 offsets (lines 670, 709, 719, 728) and never states how SYS)219–238 or SYS)269–282 hand control on. Unsettled by any design record: `docs/design/m4-codegen.md:479–482` covers the dispatch entries only. A dispatch-layer handler must invent a rule.

**G2. Whether index register 1 is cleared on dispatch entry, and what it holds at return.** Every step word is a `TXI …,1,COUNT`, which on real hardware *adds* to the register. Nothing states the register's entry value. `lib/src/codegen/procedure.dart:1038` already assumes the register is clobbered by the end of every sequence, so the handler contract must state the entry and exit values explicitly or the codegen's liveness model rests on air.

**G3. Whether a bypass advances the source pointer, the target pointer, or both.** Eight entries in range turn on it — 235, 236, 237, 238, 271, 278, 282, plus SYS)200/202/205–208 outside it. No entry says. No design record says.

**G4. What "test for overpunch" (SYS)231–234) concludes.** D4.2 fixes the *naming* dispute (`docs/design/decisions.md:665`) and fixes which handlers arm SYS)130 (`:661`), but nothing states whether an overpunch test sets a sign, arms SYS)131, arms SYS)130, or does something else. D4.2 puts SYS)199/201/203/204 in the SYS)130 arming set and is silent on 231–234.

**G5. The rounding algorithm and its scope for SYS)219, 220, 221, 222, 274.** The manual gives five round steps and no algorithm. `docs/design/decisions.md:646` (D4.1(e)) supplies one as an explicitly amendable design decision, so this gap is closed by decision, not by evidence, and the plural "Round current characters" at line 899 argues against the single-position choice.

**G6. What a terminator does with TARGET-NUMERIC-LENGTH.** Five entries — 223, 224, 225, 226, 275 — take the length and no entry says what it is for. Sign placement, zero fill and blank-when-zero suppression are all candidates. No design record settles it.

**G7. The storage layout of an "internal decimal field not justified".** SYS)246 and SYS)247 convert to and from it (lines 1442, 1450) and nothing in 90.02 or in `docs/comtran-language-definition.md` defines how digits sit in the target area. Unattested in the sample.

**G8. The character layout of a scientific-decimal field.** Seven entries in range read or write one — 248, 249, 252, 253, 254, 255, 256. The control word gives total length, mantissa scale, decimal-point presence and the two sign conventions (lines 1461–1470), but never where the exponent starts or where either sign character sits. `docs/comtran-language-definition.md:1209` gives only "Scientific decimal is the edited form of the floating point. The maximum fractional portion of a scientific decimal field is 16 digits." The *source* side is closed: the free-form rule at `docs/comtran-language-definition.md:1748`, and D4.3 exempts scientific-decimal sources from the invalid-character test (`docs/design/decisions.md:674`).

**G9. When an internal-decimal result occupies the accumulator alone rather than the accumulator-MQ pair.** Eleven entries say "in the AC or AC-MQ" without a rule. Partly closed: `docs/comtran-language-definition.md:1562` — "Fixed point double precision numbers are denoted in the Data Description by formats representing more than 10 digits." That is a compile-time property; nothing states how the handler recovers it at run time except from the control word's "Numeric length of value" decrement (line 1497), which is inference.

**G10. The meaning of SYS)268's literal decrement `1`.** Line 1670 prints `TXI SYS)268, 1, 1` and the sample punches exactly that (`1 00001 1 00414`, 90.05 line 1584). No record explains it. If it is a sign convention it is the only family head whose convention table is missing.

**G11. Character placement for edited sign conventions 3 to 6.** SYS)185's Note 2 names right minus, right plus, left minus and left plus (lines 840–843), used by SYS)267 through the cross-reference at line 1665, and never says which character position carries the sign or what character it is. The sample exercises only convention 0 (every attested SYS)267 control word has tag 0).

**G12. The behaviour of SYS)242 when one field's length is in words and the other's in characters.** The bit table (lines 1401–1406) permits the mixture and the entry gives no conversion or mismatch rule. Unattested in the sample; also the one in-range entry whose control-bit value rests on a broken glyph (inconsistency 13 above).

**G13. What the routines do on the conditions they detect.** SYS)130 "is set non-zero" on overflow (line 412), SYS)131 on an improper data condition (line 414), SYS)134 on floating-point underflow (line 466) — and no entry in 90.02.00 through 90.02.33 reads, tests or clears any of the three. D4.2 (`docs/design/decisions.md:661`) and D4.3 (`:674`) settle our arming sets and make the cells sticky, both as amendable design decisions under D0.4; neither is evidence.

**G14. Almost nothing in this range is exercised by the acceptance oracle.** Of the 56 entries covered here, only 225 (3 sites), 226 (1), 239 (2), 240 (3), 241 (3), 243 (8), 244 (3), 245 (2), 267 (26), 268 (1), 269 (1) and 275 (1) appear in the 90.05 sample. The 44 others — 219, 220, 221, 222, 223, 224, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 242, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 270, 271, 272, 273, 274, 276, 277, 278, 279, 280, 281, 282 — have zero sites, so listing-diff can never test their handlers. Their tests must be decision-conformance tests written against the contracts above.
