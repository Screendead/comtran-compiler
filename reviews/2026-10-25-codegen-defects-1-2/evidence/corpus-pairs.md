# Unequal-scale MOVE and ADD pairs in the two corpus programs

Method: inspection, not a compile. Each numeric MOVE, MOVE CORRESPONDING,
ADD and ADD CORRESPONDING statement of `test/fixtures/f-payroll-j.ct` at
ace4ee0 (lines 141 to 214) was paired with the pictures of its data cards
(lines 2 to 132), and the fraction digits of source and target compared.
A compile cannot reach these statements: the applied deck stops at
statement 141,00 on `a product of a product` (`test/f_corpus_test.dart`).
This is an inference from the pictures. CORRESPONDING matching was done by
hand under the same-name rule.

| Statement (f-payroll-j.ct line) | Pairs | Scales |
|---|---|---|
| 156 MOVE CORRESPONDING GRAND.TOTAL TO PAYRECORD | HOURS 9999V9 -> 8889.9-; GROSS, WHT, NETPAY 9(5)V99 -> $88889.99-; FICA, BONDEDUCTION 9999V99 -> $8889.99- | equal |
| 170 ADD CORRESPONDING DETAIL TOTALS TO MASTER TOTALS | GROSS 99999V99; RETIREMENT, INSURANCE 999V99, both sides | equal |
| 170-171 MOVE CORRESPONDING DETAIL TO PAYRECORD, CHECK | HOURS 99V9 -> 8889.9-; FICA 999V99 -> $8889.99-; WHT 9999V99 -> $88889.99-; BONDEDUCTION 99V99 -> $8889.99-; GROSS 99999V99 -> $88889.99-; date and number fields 99 / 9999 | equal |
| 171-172 MOVE PAYRECORD NETPAY TO CHECK AMOUNT | $88889.99- -> $***9.99 | equal |
| 176 MOVE CORRESPONDING DEPARTMENT.TOTAL TO PAYRECORD | as line 156 | equal |
| 183 MOVE CORRESPONDING DETAIL TO PAYRECORD, CURRENT | DEPARTMENT 99 -> 99 | equal |
| 183-184 ADD CORRESPONDING DETAIL TO DEPARTMENT.TOTAL, GRAND.TOTAL | HOURS 99V9 -> 9999V9; the money fields V99 -> V99 | equal |
| 191, 197 ADD DETAIL FICA / WHT TO MASTER FICA / WHT | V99 -> V99 | equal |
| 200 ADD M.BONDEDUCT TO M.BONDACCUM | 99V99 -> 999V99 | equal |
| 204-206 MOVE CORRESPONDING MASTER TO BONDORDER; ADD BONDORDER BONDENOMINATION TO DEPARTMENT.TOTAL BONDPURCHASES; MOVE ... TO PAYRECORD BONDENOMINATION | 999V99 -> 999V99, 9(5)V99, $88899.99- | equal |
| 212-213 ADD TABLE.ITEM INSURANCE.PREM / RETIREMENT.PREM (INDEX) TO DETAIL INSURANCE / RETIREMENT | 9V99 -> 999V99 | equal |

Result: no unequal-scale MOVE or ADD in the 1960 program. The
as-printed deck `f-payroll.ct` keys the same program with the procedure
first. Its pictures (lines 91 to 187) and its MOVE and ADD statements
(lines 15 to 80) name the same fields with the same scales, by the same
inspection.

The 1962 sample (J 90.05) has none either. That is measured, not
inspected: `docs/HANDOVER.md` "Codegen defects the runtime exposed"
(measured 2026-09-07), and on the prototype branch the golden
`test/goldens/90.05-payroll.code` test passes byte for byte with the
alignment in place.
