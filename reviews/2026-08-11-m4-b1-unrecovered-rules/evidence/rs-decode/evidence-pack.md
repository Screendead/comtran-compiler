# Evidence pack: the RS) per-section reservation decode

Repository: /Users/jacklusher/development/comtran-compiler (read-only for this task).
Primary sources in the repository:
- `test/fixtures/90.05-object-listing.target` — the scan-verified 1962 object listing.
- `test/goldens/90.05-payroll.listing` — the compile listing: data division with
  pictures/scales (statements 1–187), procedure division source (188–229).
- `test/fixtures/90.05-object-code-notes.md` — the chunk B1 shape catalogue and
  statement walk (LOC range per statement).
- `comtran-manuals/J28-6169/90.02-generated-code.md` — Appendix 90.02 (READ-ONLY).

## The question

`RS) BSS 30` reserves 30 words = 15 two-word cells at 01621–01656 (octal).
J 90.02.03 says: "N is the sum of maximum Result Storage used in each section."
It does not define what "maximum used" counts. Decode the counting rule.

## The six sections

The program has one main body plus five BEGIN SECTIONs, in source order:

| Index | Section | Statements |
|---|---|---|
| 0 | main body | 188–209 |
| 1 | FICA.ROUTINE | 210–213 |
| 2 | WITHOLDING.TAX.ROUTINE | 214–216 |
| 3 | BOND.ROUTINE | 217–223 |
| 4 | SEARCH | 224–226 |
| 5 | DEPARTMENT.END | 227–229 |

A cell `m` of section `k` prints as `k.RS)m` (section 0 prints unprefixed `RS)m`).

## The hard constraints (all proven from the listing's addresses)

- Section 0 base 01621; section 1 base (`1.RS)0`) 01627 → **s0 = 3 cells**.
- Section 2 base (`2.RS)0`) 01633 → **s1 = 2 cells**.
- Section 3 base (`3.RS)0`, from `3.RS)1` = 01643) 01641 → **s2 = 3 cells**.
- Block ends at 01657 (`TS)` base) → **s3 + s4 + s5 = 7 cells**, split unknown.
- `3.RS)1` is referenced → **s3 ≥ 2**.

## Every RS reference in the whole listing (there are no others)

```
00532  0602 00 0 01621   10001           +3      SLW    RS)0        (stmt 200)
00537  4340 00 0 01621   10001           +8      LAS    RS)0        (stmt 200)
00621  4600 00 0 01623   10001          +30      STQ    RS)1+0      (stmt 203)
00624  4600 00 0 01621   10001          +33      STQ    RS)0        (stmt 203)
00625  0500 00 0 01623   10001          +34      CLA    RS)1        (stmt 203)
00626  0402 00 0 01621   10001          +35      SUB    RS)0        (stmt 203)
01211  0601 00 0 01627   10001          +20      STO    1.RS)0      (stmt 212)
01213  0402 00 0 01627   10001          +22      SUB    1.RS)0      (stmt 212)
01226  4600 00 0 01633   10001           +6      STQ    2.RS)0      (stmt 215)
01230  0402 00 0 01633   10001           +8      SUB    2.RS)0      (stmt 215)
01362  0601 00 0 01643   10001          +34      STO    3.RS)1      (stmt 221)
01364  0400 00 0 01643   10001          +36      ADD    3.RS)1      (stmt 221)
01621  2 00000 0 00036   00001    RS)            BSS    30
```

Sections 4 (SEARCH) and 5 (DEPARTMENT.END) reference **nothing**, yet together
with section 3 they own 7 cells.

## Source text of the statements that matter

- 200: `IF CURRENT.DEPT IS NOT EQUAL TO D.DEPT THEN DO DEPARTMENT.END OTHERWISE GO TO COMPUTE.PAY.` (alphameric compare spills a masked word to RS)0)
- 203: `IF WORKING HOURS GT 40.0 THEN SET WORKING GROSS = (WORKING HOURS * 1.5 -20) * MASTER RATE OTHERWISE SET WORKING GROSS = WORKING HOURS * MASTER RATE.`
- 207: `SET WORKING NETPAY = WORKING GROSS - WORKING FICA - WORKING WHT - WORKING RETIREMENT - WORKING INSURANCE - M.BND.DED.` (six-operand chain; compiles to CLA/SUB…/STO, zero RS)
- 208: `ADD CORRESPONDING WORKING TO MASTER TOTALS, INTERNAL.TOTALS, …` then many MOVEs and FILEs (section 0; zero RS)
- 211: `SET WORKING FICA = .03 * WORKING GROSS, ADD WORKING FICA TO MASTER FICA.` (zero RS)
- 212: `IF MASTER FICA GT 144.00 THEN SET WORKING FICA = WORKING FICA - (MASTER FICA - 144.00), SET MASTER FICA = 144.00.` (parks the sub-chain at 1.RS)0)
- 215: `SET WORKING WHT = 0.18 * (WORKING GROSS - 13 * MASTER EXEMPTIONS), SET WORKING WHT = WORKING WHT * TR(WORKING WHT GT 0), ADD WORKING WHT TO MASTER WHT.` (parks 13*EXEMPTIONS at 2.RS)0; nothing else)
- 218: `ADD M.BND.DED TO M.BND.ACC,INTERNAL.TOTALS BONDEDUCTION.` (two straight CLA/ADD/STO chains, zero RS)
- 219: `MOVE M.BND.DED TO PAYRECORD BONDEDUCTION.` (edited store, zero RS)
- 220: `IF MASTER BONDENOMINATION NOT GT M.BND.ACC THEN SET M.BND.ACC = M.BND.ACC - MASTER BONDENOMINATION OTHERWISE MOVE BLANKS TO PAYRECORD BONDENOMINATION, GO TO BOND.END.` (straight chain, zero RS)
- 221: `MOVE CORRESPONDING MASTER TO BONDORDER, ADD BONDORDER BONDENOMINATION TO INTERNAL.TOTALS BONDPURCHASES, MOVE BONDORDER BONDENOMINATION TO PAYRECORD BONDENOMINATION.` (the edited operand is converted to a register, then parked at 3.RS)1, then CLA/ADD/STO)
- 225: `IF MASTER RATE GT TABLE.ITEM RATE (INDEX) THEN GO TO SEARCH.END OTHERWISE MOVE INDEX TO POS, MOVE INSPREM (POS) TO INS.PREM, WORKING INSURANCE, MOVE RETPREM (POS) TO RET.PREM, WORKING RETIREMENT, GO TO NET.` (all of SEARCH's body; zero RS)
- 228: `MOVE CORRESPONDING INTERNAL.TOTALS TO DEPARTMENT.TOTAL, FILE DEPARTMENT.TOTAL, ADD CORRESPONDING INTERNAL.TOTALS TO GRAND.TOTALS.` (nine edited stores + nine straight ADD pairs; zero RS)

Statements 199 (section 0) holds five edited stores, one with a divide, plus
figurative moves, CLOSE, STOP RUN — zero RS. The full object code of any
statement is in the target fixture; the notes file section 3.2 maps every
statement to its LOC range.

## A settled neighbouring rule (do not re-derive)

The **cell number** of a parked operand is the count of chain operands that
follow it at its own level of the expression, in source order (notes §6.2
item 21). Verified at all four parked sites:
- 203: `[HOURS*1.5]` followed at its level by `20` → cell 1. The scaled `20`
  followed by nothing → cell 0.
- 212: `[MASTER FICA - 144.00]` is the last operand of its outer chain → cell 0.
- 215: `[13*EXEMPTIONS]` is the last operand of `GROSS - […]` → cell 0.
- 221: `ADD X TO Y` is the chain `X + Y`; parked X has one follower → cell 1.

## Rules already refuted (do not re-propose without new evidence)

1. **Highest referenced index + one spare** — fails s2 (highest index 0 → 2, attested 3).
2. **Operand count of the largest chain − 1** and **non-leaf nodes of the
   largest statement** — both fail statement 207: its six-operand chain would
   give s0 = 5, attested 3.
3. **Comma-separated clause counts** and similar source-syntax counts — wrong
   family (they were tried on the statement stamp, but note them).
4. **Operator count of the largest expression, with straight chains exempt**
   (the review record's named hypothesis: an operator "needs a temporary"
   unless the whole chain folds into the accumulator). Reproduces s0=3
   (stmt 203), s1=2 (stmt 212), s2=3 (stmt 215), and 207's exemption — but
   sections 4 and 5 contain no non-straight arithmetic at all, and section 3's
   largest is 2 (or 1), so the tail sums to at most 2 against the attested 7.
   **Refuted by the tail unless some count in sections 3–5 has been missed.**

## What a successful decode must deliver

A single counting rule, stated precisely, that:
1. yields 3, 2, 3 for sections 0, 1, 2;
2. yields three values for sections 3, 4, 5 that sum to exactly 7, with
   section 3 ≥ 2;
3. survives every statement in every section (in particular 207 and 199 must
   not push section 0 past 3, and 215's three clauses must not push section 2
   past 3 — the per-section figure is a maximum over clauses, not a sum);
4. is mechanically computable by a compiler from the source text and the data
   division (scales/pictures are in the golden listing's data division).

If no such rule exists, say so and enumerate the space you searched: that
refutation is itself the deliverable.
