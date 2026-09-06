All page/line citations below are to `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.02-generated-code.md` unless another path is named. "90.02:NNN" means that file, line NNN.

## 0. CONVENTIONS THAT APPLY TO EVERY ENTRY (established once, not repeated per row)

**Type 1 vs Type 2, and the number ranges.** 90.02:295 — "Each of these System Subroutines and Communication Cells has been assigned a number. Type 1 entries received a number between 1 and 127 and Type 2 entries received a number greater than 127." Type 1 = "placed in core as part of the CT Monitoring System and remain in core" (90.02:287); Type 2 = "placed in core by the CT Loader as required by the particular object program being loaded" (90.02:289). So every `IOC)nnn` in this task is monitor-resident; every `SYS)nnn` is loaded on demand.

**The TSX linkage and the resume distance — DERIVED, never stated in 90.02.** The manual never writes down a return convention. It is forced by three MOVPAK sentences plus the TSX semantics:
- 90.02:670 (SYS)179, two parameter words) — "the instructions beginning at 3,4 are executed";
- 90.02:709 (SYS)181, one parameter word) — "the specific MOVE instructions beginning at 2,4 are executed";
- 90.02:728 (SYS)182, no parameter words) — "The specific Move instructions are executed beginning at 1,4."
- `docs/design/emulator.md:131` — "| +0074 | TSX | XR(T) ← 2^15 − (location of TSX); IC ← Y |".

Therefore XR4 holds the complement of the **TSX's own** location, parameter word *k* sits at `k,4`, and a routine with *p* parameter words resumes at `(p+1),4`. Every "resume" figure in the tables below is derived by that rule, not quoted.

**SYS)nnn / IOC)nnn assemble to absolute address nnn (decimal) — DERIVED from the 1962 listing, stated nowhere.** In `90.05-sample-program.md`: `TSX SYS)175,4` assembles as `0074 00 4 00257` (90.05:784; 0257₈ = 175), `TSX SYS)177,4` as `...00261` (90.05:1056; 0261₈ = 177), `TSX SYS)178,4` as `...00262` (90.05:1058), `STI SYS)133` as `0604 00 0 00205` (90.05:787; 0205₈ = 133), `TXL SYS)294,1,0` as `7 00000 1 00446` (90.05:818; 0446₈ = 294), `PZE IOC)1` as `0 00000 0 00001` (90.05:785), `TXI IOC)40,0` as `1 00000 0 00050` (90.05:1063; 050₈ = 40), `TSX IOC)9,4` as `0074 00 4 00011` (90.05:1053). The dispatch layer can therefore key on the decimal reference number directly.

**Numbers that do not exist.** 90.02 defines `SYS)128, 130, 131, 132, 133, 134`, then jumps to `155, 156, 160, 161, …`. There is **no SYS)135–154 and no SYS)157–159** anywhere in the file (the bold-label sequence runs 134 at 90.02:469 → 155 at 90.02:471 → 156 at 90.02:478 → 160 at 90.02:482). `SYS)129` has no label of its own; it is defined jointly with 128 at 90.02:410.

---

## 1. PER-ENTRY CONTRACTS

### IOC)1 — file list locator (Type 1 communication cell)

| | |
|---|---|
| **Kind** | Cell in the CT Monitor communication area. Not called. |
| **Format, verbatim** | `PZE L,,N` (90.02:319–321) |
| **Description, verbatim** | "A cell in the CT Monitor communications area which locates (L) a list of files, and designates the number (N) of files in the list. This List is used in Opening and Closing files." (90.02:322) |
| **Inputs / outputs** | Read by SYS)175 and SYS)177 as their single parameter word. Address field = list origin; decrement field = file count. |
| **Side effects** | None (a cell). |
| **Quality** | **PARTIAL** — the *entry* format of the file list at L is stated nowhere in either manual. Greps for "file list"/"list of files" return only 90.02:322/631/649 and operator-facing prose in `03-loader.md:124, 261, 454, 459`; 90.03 (object deck) and 90.08 (loader symbolic cards) contain no `IOC)1` reference at all. |
| **Occurrences in 90.02** | 318 (label), 322 (description), 628 (`PZE IOC)1` in SYS)175), 631, 646 (`PZE IOC)1` in SYS)177), 649. |
| **Attested in 90.05** | Three sites, all as the parameter of an open-all/close-all: 90.05:785, 1057, 1062. |

### IOC)40 — end-of-job return point (Type 1 communication cell)

| | |
|---|---|
| **Kind** | A location in the CT Monitor communication area, entered by transfer. Not a TSX call. |
| **Calling form** | Not printed in 90.02. Attested in the sample as `TXI IOC)40,0` — `1 00000 0 00050  10010  +94  TXI IOC)40,0` (90.05:1063). |
| **Description, verbatim** | "This is the end of job return point in the CT Monitor communication area for all CT jobs." (90.02:365) |
| **Inputs / outputs / side effects** | None stated. Control does not return. |
| **Related manual text** | `05-systems-operation.md:331` (J 05.06.04) on STOP RUN — "This message means that object-time processing of the job is completed and control has returned to the CTM supervisor." |
| **Quality** | **PARTIAL** — the entry form (`TXI …,0` with decrement 0) is attested only in the sample listing, not in 90.02; nothing states what register or memory state the monitor expects on arrival. |
| **Occurrences in 90.02** | 365 only. |

### SYS)128, SYS)129 — multi-precision arithmetic cells

| | |
|---|---|
| **Kind** | Two data cells. |
| **Description, verbatim** | "These two cells serve as storage for multi precision arithmetic operations." (90.02:410) |
| **Who reads them** | SYS)155 (single-precision power in 128, 90.02:471); SYS)156 ("double precision power located SYS)128 - SYS)129", 90.02:480); SYS)169 ("the double precision fixed point number in SYS)128 and SYS)129", 90.02:576); SYS)170 and SYS)171 ("multiplies the double precision AC-MQ by SYS)128 SYS)129", 90.02:585, 594); SYS)172 (90.02:602); SYS)173 (90.02:610). |
| **Who writes them** | **Nothing in 90.02.** No calling sequence, no in-line code form, and no verb shape in the appendix stores into 128 or 129. |
| **Quality** | **PARTIAL** — the cells' *use* is documented; the word order within a double-precision pair is only implied by the recurring "SYS)128 - SYS)129" phrasing, never stated, and the instruction that loads them is never shown. |
| **Occurrences in 90.02** | 128: 410, 471, 480, 576, 585, 594, 602, 610. 129: 410, 480, 576, 585, 594, 610. |
| **Attested in 90.05** | Zero occurrences of either. |

### SYS)130 — overflow flag

| | |
|---|---|
| **Kind** | Flag cell. |
| **Description, verbatim** | "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects the truncation of significant high order values (i.e. overflow)." (90.02:412) |
| **Quality** | **PARTIAL** — the non-zero *value* is unspecified, no reader is documented, and no clearing is documented. `docs/design/decisions.md:661` (D4.2) states the same finding: "No entry in [J 90.02.00]–90.02.33 reads, tests or clears SYS)130 … our runtime never clears it, so it is a sticky, statement-wide flag". |
| **Occurrences in 90.02** | 412 only. |
| **Attested in 90.05** | Zero. |

### SYS)131 — improper-data flag

| | |
|---|---|
| **Kind** | Flag cell. |
| **Description, verbatim** | "This cell is set non-zero whenever any one of the numeric move or convert subroutines of MOVPAK detects an improper data condition." (90.02:414) |
| **Quality** | **PARTIAL** — "improper data condition" is never defined. `docs/design/decisions.md:674` (D4.3) makes the trigger a design decision and notes "no appendix entry reads or clears it" (line 676). |
| **Occurrences in 90.02** | 414 only. |
| **Attested in 90.05** | Zero. |

### SYS)132 — Move Source Pointer

| | |
|---|---|
| **Kind** | Cell, written by generated in-line code or by MOVPAK entry points. |
| **Format, verbatim** | `PZE LOC,,BYTE` (90.02:417–419) |
| **Description, verbatim** | "This cell points to the first word address (LOC) and first BYTE (0-5) of the source field involved in a Move. The cell is set by one of the following:" (90.02:420) then "1. It is set automatically by calls upon subroutines SYS)179 or SYS)181 (see calling sequences)." (90.02:422) and "2. It is set by in-line coding preceding calls upon subroutines SYS)180 or SYS)182 … one of three forms:" (90.02:427). |
| **The three in-line setter forms, verbatim** | Case 1 (working storage), 90.02:431–434: `LDI    CP)+NN` / `STI    SYS)132`, "where CP)+NN will contain the location and byte of the data item." Case 2 (simple base locator, byte always 0), 90.02:441–444: `CAL    BL)NN` / `ACL    CP)+NN` / `SLW    SYS)132`, "where CP)+NN is a constant of the form: `PZE WORD-DISPLACEMENT,,BYTE`". Case 3 (complex base locator, byte 0–5), 90.02:454–461: `CAL    BL)NN` / `ACL    CP)+NN1     Displacement Constant` / `PDX    0,4` / `TXL    *2,4,5` / `ACL    CP)+NN2     OCT 777772000000` / `SLW    SYS)132`. |
| **Quality** | **FULL** for the cell itself (format, setters and semantics all printed). |
| **Occurrences in 90.02** | 416 (label), 433, 443, 460 (setter code), 467 (referenced from SYS)133's text), 670, 709, 728 (MOVPAK entry descriptions), 776. |
| **Attested in 90.05** | 13 occurrences. |

### SYS)133 — Move Target Pointer

| | |
|---|---|
| **Kind** | Cell. |
| **Format, verbatim** | `PZE LOC,,BYTE` (90.02:464–466) |
| **Description, verbatim** | "This cell points to the first word address (LOC), and the first BYTE(0-5) of the target field involved in a Move. The cell is set by calls upon subroutines SYS)179 or SYS)180 or by means of in-line coding of the same form as described under SYS)132." (90.02:467) |
| **Quality** | **FULL.** |
| **Occurrences in 90.02** | 261 (as the specimen SYS reference in the symbolic-listing tutorial: `STI    SYS)133`), 463, 467, 670, 709, 719, 728, 778. |
| **Attested in 90.05** | 23 occurrences (e.g. `LDI CP)+40 / STI SYS)133 / TSX SYS)182,4`, 90.05:786–788). |

### SYS)134 — floating-point underflow flag

| | |
|---|---|
| **Kind** | Flag cell. |
| **Description, verbatim** | "This cell is set non zero whenever a floating point underflow results from a Move." ("non zero" unhyphenated as printed; 90.02:469) |
| **Quality** | **PARTIAL** — scoped to "a Move" with no list of which movers set it; no value, no reader, no clearing. |
| **Occurrences in 90.02** | 469 only. |
| **Attested in 90.05** | Zero. |

### SYS)155 — FP exponential, double base ** single power

| | |
|---|---|
| **Kind** | Subroutine. **No calling sequence is printed** — the entry is a bare prose sentence with no code block. |
| **Description, verbatim** | "This floating point exponential routine raises the double precision number in the AC-MQ to the single precision power located in SYS)128. The double precision result is left in the AC-MQ." (90.02:471) |
| **Inputs** | AC-MQ = base (double precision FP); SYS)128 = exponent (single precision FP). |
| **Outputs** | AC-MQ = result. Resume distance: **unstated and underivable** (no TSX form printed). |
| **Quality** | **PARTIAL** — the arithmetic is stated; the linkage is not. |
| **Occurrences in 90.02** | 471 only. |
| **Attested in 90.05** | Zero. |

### SYS)156 — FP exponential, double base ** double power

| | |
|---|---|
| **Kind** | Subroutine. No calling sequence printed. |
| **Description, verbatim** | "This floating point exponential routine raises the double precision number in the AC-MQ to the double precision power located SYS)128 - SYS)129. The double precision result is left in the AC-MQ." ("located SYS)128" — the preposition is missing as printed; 90.02:480) |
| **Quality** | **PARTIAL** — same missing linkage as SYS)155. |
| **Occurrences in 90.02** | 478 (label), 480. |
| **Attested in 90.05** | Zero. |

### SYS)160 — double-precision fixed-point sign adjustment

| | |
|---|---|
| **Kind** | Subroutine, TSX-linked, zero parameter words. |
| **Calling sequence, verbatim** | `TSX  SYS)160,4` (90.02:484–486) |
| **Description, verbatim** | "This is a subroutine for sign adjustment for double precision fixed point numbers. The routine is entered with the number in the AC-MQ and the result is left in the AC-MQ." (90.02:487) |
| **Inputs/outputs** | AC-MQ in, AC-MQ out. Resume at `1,4` (derived). |
| **Quality** | **PARTIAL** — "sign adjustment" is never defined. The 7090 double-precision fixed-point convention (whether the MQ carries its own sign bit, and what the routine forces it to) is not stated here or anywhere in 90.02. |
| **Occurrences in 90.02** | 482, 485. |
| **Attested in 90.05** | Zero. |

### SYS)161 — 709→705 collating conversion table

| | |
|---|---|
| **Kind** | **Table (data), not a subroutine.** |
| **Description, verbatim, in full** | "This is a conversion table used in converting from 709 to 705 collating sequence." (90.02:495) — that is the entire entry. |
| **How it is addressed** | As the address field of the `OP` word of a SYS)162 call: `OP    SYS)161` (90.02:501). |
| **Quality** | **NAME-ONLY.** |
| **Occurrences in 90.02** | 493 (label), 495 (description), 501 (inside SYS)162's calling sequence). |
| **Attested in 90.05** | Zero — the table is never loaded by the sample program. |

### SYS)162 — alphabetic comparison of two fields

| | |
|---|---|
| **Kind** | Subroutine, TSX-linked, **five** words after the TSX, then a three-way skip return. |
| **Calling sequence, verbatim (90.02:499–510)** | `TSX   SYS)162,4` / `OP    SYS)161` / `PZE   LOC(1), T(1), LOCATOR(1)` / `PZE   LENGTH(1), ,6*BYTE(1)` / `PZE   LOC(2), T(2), LOCATOR(2)` / `PZE   LENGTH(2), ,6*BYTE(2)` / `HIGH  RETURN from comparison` / `EQUAL RETURN from comparison` / `LOW   RETURN from comparison` |
| **Description, verbatim** | "This subroutine performs an alphabetic comparison on two fields. OP is a CVR or NOP depending of the need to adjust the collating sequence before the comparison. If T(J) is 0, LOC(J) is the location of the field. If T(J) is not zero, the field is located by the 'pointer' word LOCATOR(J) and LOC(J) is the word displacement from the base. LENGTH(J) is the length of the field in characters and BYTE(J) is the beginning byte position of the field." (90.02:511; "depending of" is the printed original) |
| **Parameter word fields** | Word at `1,4` is an **instruction**, not a PZE datum: `CVR` (apply the 705 table at SYS)161) or `NOP` (native 709 order). Words at `2,4`/`4,4`: address = LOC(J), tag = T(J), decrement = LOCATOR(J). Words at `3,4`/`5,4`: address = LENGTH(J) in characters, decrement = `6*BYTE(J)` — i.e. the byte index pre-multiplied by six, a bit offset. |
| **Outputs — skip return distances (derived, §0)** | HIGH at `6,4`, EQUAL at `7,4`, LOW at `8,4`. The manual names the three exits but never their offsets. |
| **Side effects** | None stated. Register clobbering unstated. |
| **Quality** | **PARTIAL** — missing: the CVR word's count field (the emulator record notes CVR "carries its count C in positions 10–17", `docs/design/emulator.md:85`, and 90.02 never says what count the OP word carries); what happens when LENGTH(1) ≠ LENGTH(2); which of HIGH/EQUAL/LOW is taken relative to which operand. |
| **Occurrences in 90.02** | 497 (label), 500 (TSX line), 511 (description), 1193 (conversion note recording the dropped "y" in "located b[y] the 'pointer' word"). |
| **Attested in 90.05** | Zero. `docs/design/decisions.md:877` (D5.3 oracle): "All five of its alphameric relations are equal-length and compile to inline `LAS` three-way compares, with SYS)162 never called in the program". |

### SYS)163 to SYS)171 — fixed-point scaling and double-precision arithmetic

All nine are TSX-linked. SYS)163–168, 170, 171 take one parameter word (`PZE CP)+NN`) and resume at `2,4`; SYS)169 takes none and resumes at `1,4`. All derived per §0.

| # | Calling sequence, verbatim | Description, verbatim | Lines | Quality |
|---|---|---|---|---|
| **163** | `TSX  SYS)163,4` / `PZE  CP)+NN` (90.02:515–518) | "This routine upscales the single precision AC by 10\*\*10 and then upscales by the constant located at CP)+NN." (90.02:520) | 513, 516, 520 | PARTIAL |
| **164** | `TSX  SYS)164,4` / `PZE  CP)+NN` (90.02:524–527) | "This routine upscales the number in the MQ by 10\*\*10 and then upscales by the constant located at CP)+NN." (90.02:529) | 522, 525, 529 | PARTIAL |
| **165** | `TSX  SYS)165,4` / `PZE  CP)+NN` (90.02:533–536) | "This routine upscales the double precision AC-MQ by the constant located at CP)+NN." (90.02:538) | 531, 534, 538 | PARTIAL |
| **166** | `TSX  SYS)166,4` / `PZE  CP)+NN` (90.02:542–545) | "This routine upscales the double precision AC-MQ by the constant located at CP)+NN. **On entry to the routine, the high order part of the number is in the MQ and the low order in the AC.**" (90.02:547; emphasis added — this is the only entry in the whole set that states an AC-MQ half order) | 540, 543, 547 | PARTIAL |
| **167** | `TSX  SYS)167,4` / `PZE  CP)+NN` (90.02:554–557) | "This routine downscales the double precision AC-MQ by the constant located at CP)+NN and leaves the result in the AC-MQ." (90.02:559) | 552, 555, 559 | PARTIAL |
| **168** | `TSX  SYS)168,4` / `PZE  CP)+NN` (90.02:563–566) | "This routine downscales the double precision AC-MQ by 10\*\*10 and then downscales by the constant located at CP)+NN **leaving the result in the MQ**." (90.02:568) | 561, 564, 568 | PARTIAL |
| **169** | `TSX  SYS)169,4` (90.02:572–574; **no parameter word**) | "This routine divides the double precision fixed point number in SYS)128 and SYS)129 by the AC-MQ. The result is left in the AC-MQ." (90.02:576) | 570, 573, 576 | PARTIAL |
| **170** | `TSX  SYS)170,4` / `PZE  CP)+NN` (90.02:580–583) | "This routine multiplies the double precision AC-MQ by SYS)128 SYS)129, scales the product down by the constant located at CP)+NN and leaves the result in the AC-MQ." (90.02:585) | 578, 581, 585 | PARTIAL |
| **171** | `TSX  SYS)171,4` / `PZE  CP)+NN` (90.02:589–592) | "This routine multiplies the double precision AC-MQ by SYS)128 SYS)129, scales the product down by 10\*\*10, and then downscales by the constant located at CP)+NN. The result is left in the AC-MQ." (90.02:594) | 587, 590, 594 | PARTIAL |

Common missing facts for all nine (see GAPS): the *format* of the word at `CP)+NN` (the manual says "the constant located at CP)+NN" and never says whether it is a power of ten, a shift count, or a scale exponent); rounding vs truncation on every downscale; the overflow reaction on every upscale; the AC-MQ half order for every entry except 166; SYS)169's remainder disposition and divide-check behaviour; SYS)168's discarded high-order half. None of the nine appears in the 1962 sample (`90.05-sample-program.md`, zero occurrences of each) — `docs/design/decisions.md:661` (D4.2) confirms "The fixed-point scaling and arithmetic handlers SYS)163–171 lie outside MOVPAK altogether and set no cell; this too is attested, not chosen."

### SYS)172 — FP exponential, single base ** single power

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)172,4` (90.02:598–600) — no parameter word; resume at `1,4` (derived). |
| **Description, verbatim** | "This floating point exponential routine raises the single precision number in the AC to the single precision power located in SYS)128. The result is left in the AC." (90.02:602) |
| **Quality** | **PARTIAL** — no domain rules (negative base, zero base, zero or negative exponent), no error exit, no exponent-overflow behaviour. |
| **Occurrences in 90.02** | 596, 599, 602. |

### SYS)173 — FP exponential, single base ** double power

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)173,4` (90.02:606–608) — no parameter word; resume at `1,4` (derived). |
| **Description, verbatim** | "This floating point exponential routine raises the single precision number in the AC to the double precision power located in SYS)128 - SYS)129. The double precision result is left in the AC-MQ." (90.02:610) |
| **Quality** | **PARTIAL** — same gaps as 172. |
| **Occurrences in 90.02** | 604, 607, 610. |

### SYS)174 — open one file

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)174,4` / `PZE  FILENAME` (90.02:614–617); resume at `2,4` (derived). |
| **Description, verbatim** | "This routine opens the file designated FILENAME." (90.02:619) |
| **Quality** | **PARTIAL** — the encoding of FILENAME is not given here. In the sample the analogous IOCS word is `PZE PAYFILE,,0` = `0 00000 0 04005` (90.05:1054–1055), and `docs/design/m4-codegen.md:849` records the rule as "the `04000 + k` ordinal reads off the FILE cards". Error behaviour (file already open, file absent) unstated. |
| **Occurrences in 90.02** | 612, 615, 619. |
| **Attested in 90.05** | Zero. |

### SYS)175 — open all files

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)175,4` / `PZE  IOC)1` (90.02:626–629); resume at `2,4` (derived). |
| **Description, verbatim** | "This routine opens all files in the file list located by IOC)1." (90.02:631) |
| **Quality** | **PARTIAL** — depends on IOC)1's unstated list-entry format. |
| **Occurrences in 90.02** | 624, 627, 628, 631. |
| **Attested in 90.05** | One site, the program entry word: `00165  0074 00 4 00257  10010  START  TSX SYS)175,4` / `00166 … PZE IOC)1` (90.05:784–785). `docs/design/m4-codegen.md:840` — "the run frame opens with `TSX SYS)175,4 / PZE IOC)1` (open all) at the entry word GN)000". |

### SYS)176 — close one file

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)176,4` / `PZE  FILENAME` (90.02:635–638); resume at `2,4` (derived). |
| **Description, verbatim** | "This routine closes the file designated FILENAME." (90.02:640) |
| **Quality** | **PARTIAL** — same FILENAME-encoding gap as 174; no statement of end-of-file writing, rewind, or label handling. |
| **Occurrences in 90.02** | 633, 636, 640. |
| **Attested in 90.05** | Zero. |

### SYS)177 — close all files

| | |
|---|---|
| **Calling sequence, verbatim** | `TSX  SYS)177,4` / `PZE  IOC)1` (90.02:644–647); resume at `2,4` (derived). |
| **Description, verbatim** | "This routine closes all files in the file list located by IOC)1." (90.02:649) |
| **Quality** | **PARTIAL** — same IOC)1 gap. |
| **Occurrences in 90.02** | 642, 645, 646, 649. |
| **Attested in 90.05** | Two sites: 90.05:1056–1057 (the source's explicit `CLOSE ALL FILES`) and 90.05:1061–1062 (the implicit close-all inside STOP RUN). |

### SYS)178 — STOP message display

| | |
|---|---|
| **Kind** | Subroutine, TSX-linked, two parameter words, resume at `3,4` (derived). |
| **Calling sequence, verbatim** | `TSX  SYS)178,4` / `PZE  CP)+NN1,,CP)+NN2` / `PZE  CP)+NN3,,CP)+NN4` (90.02:653–657) |
| **Description, verbatim** | "This routine displays a message concerning a STOP verb. The CP (Constant Pool) entries contain the Statement Number of the Stop (in BCD), and the type of STOP (STOP NNN or STOP RUN)." (90.02:659) |
| **Parameter fields** | Four constant-pool references packed two per word: address and decrement of each of the two words. Which of the four carries the statement number and which the STOP type is **not** stated. |
| **Message text — stated outside 90.02** | `05-systems-operation.md:328` (J 05.06.04) — "STOP nnnnnn where nnnnnn is any number 6 digits or less. The computer will stop, and hitting the START key will cause the object program to continue in execution." `:331` — "STOP RUN … This message means that object-time processing of the job is completed and control has returned to the CTM supervisor." `:333` — "The STOP messages will be accompanied by the source language statement number at which the STOP occurred, i.e. **AT xxxxx,yy STOP nnnnnn** where xxxxx,yy is the statement number." |
| **Quality** | **PARTIAL** — the message *form* is recoverable from J 05.06.04, but the CP word layout is not printed, and whether the halt for `STOP n` happens inside the handler is unstated (`docs/design/decisions.md:539` records that as a design decision: "that the halt for STOP type NNN occurs inside the SYS)178 runtime handler (no STOP n appears in the sample, and no instruction-level evidence survives)"). |
| **Occurrences in 90.02** | 651, 654, 659, 1193 (conversion note: the NN1–NN4 subscripts on PDF p. 153 were "confirmed by zoomed crop"). |
| **Attested in 90.05** | One site: `00521 TSX SYS)178,4` / `00522  0 01727 0 01726  PZE CP)+26,,CP)+27` / `00523  0 01731 0 01730  PZE CP)+28,,CP)+29` (90.05:1058–1060). The four pool words are printed: `CP)+26 OCT 606060011111`, `CP)+27 OCT 730104606060`, `CP)+28 OCT 606263464760`, `CP)+29 OCT 605164456060` (90.05:1829–1832). Source statement: `CLOSE ALL FILES,  STOP RUN.` (90.05:513). `docs/design/m4-codegen.md:813–823` reads the pair as "the statement stamp and the words ` STOP ` / ` RUN  `" with "the statement number in BCD, a comma, two digits, and three blanks". |

### SYS)294 — base-locator guard

| | |
|---|---|
| **Kind** | Subroutine, but **not TSX-linked and it does not return.** Reached by a conditional transfer with no calling sequence. |
| **Calling sequence, verbatim (90.02:1882–1885, section [90.02.33], PDF p. 172)** | `LAC     BL)NN, N` / `TXL     SYS)294, N, 0` |
| **Description, verbatim, in full** | "This subroutine prints an error message whenever a reference is made to a Base Locator before the locator has been loaded, and exits back to the CT Monitor." (90.02:1887) |
| **Second manual statement of the same routine** | `02-compiler.md:1913` shows the CRYPT-generated form `LAC BASE.LOCATOR.OF.DATE,4` / `TXL SYS)294,4,0` / `CLA DATE.DISP,4`, and `:1920` — "**SYS)294** is an error message routine that prints the fact that BASE.LOCATOR.OF.DATE has not been set if such is the case." `:1922` adds "Note that the contents of index register 4 are destroyed, and that instructions have been inserted in the program." |
| **Inputs** | Only the index register named by the tag N, which the preceding `LAC` has just loaded. No parameter words follow the `TXL`. |
| **Outputs** | None; control does not return. |
| **Quality** | **PARTIAL** — the message text is not printed anywhere in either manual, and 90.04's message list has no entry for it (the only base-locator message, `90.04-error-messages.md:291` msg 202,00, is the compile-time "NUMBER OF DATA GROUPS ASSOCIATED WITH BASE LOCATOR EXCEEDS INTERNAL TABLE CAPACITY."). |
| **Occurrences in 90.02** | 1880 (label), 1884 (the `TXL` line). |
| **Attested in 90.05** | 20 sites, all identical in shape, all resolving to address `00446` — e.g. `00212 LAC BL)2,1` / `00213  7 00000 1 00446  TXL SYS)294,1,0` / `00214 CAL 1)DEPARTMENT,1` (90.05:812–814), and the paired form at 90.05:844–847 (`LAC BL)3,1` / `TXL SYS)294,1,0` / `CAL 2)EMPLOYEE.NUMBER,1` / `LAC BL)2,2` / `TXL SYS)294,2,0` / `LAS 1)EMPLOYEE.NUMBER,2`). Tags used: 1 and 2. |

---

## 2. CELLS AND FLAGS SYS)128–134 — how generated code uses each

The headline: **in 90.02, the only cells generated code demonstrably writes are SYS)132 and SYS)133.** Everything else in this range is read-only from the appendix's point of view, or has no documented access at all.

| Cell | Read by generated code? | Written by generated code? | Verb sequence in 90.02 that touches it |
|---|---|---|---|
| **SYS)128** | Only inside runtime routines (155, 156, 169, 170, 171, 172, 173 — 90.02:471, 480, 576, 585, 594, 602, 610). No generated-code read. | **Never, in any printed sequence.** | None. No calling sequence in 90.02 contains a store to SYS)128. |
| **SYS)129** | Same as 128 (90.02:410, 480, 576, 585, 594, 610). | **Never.** | None. |
| **SYS)130** | Never — no entry in 90.02 reads or tests it. | Only by MOVPAK numeric movers, by class ("any one of the numeric move or convert subroutines of MOVPAK", 90.02:412), never by an in-line instruction. | None. Nothing clears it. |
| **SYS)131** | Never. | Same class-scoped rule (90.02:414). | None. Nothing clears it. |
| **SYS)132** | Read by MOVPAK entries SYS)181 and SYS)182 — "either the source address of the data item has been previously stored in SYS)132" (90.02:709), "both the Source Pointer, SYS)132 and the Target Pointer SYS)133, have been preset by inline instructions" (90.02:728). | **Yes, by three printed in-line forms**, all preceding a `TSX SYS)180,4` or `TSX SYS)182,4` (90.02:427): `LDI CP)+NN / STI SYS)132` (90.02:431–434); `CAL BL)NN / ACL CP)+NN / SLW SYS)132` (90.02:441–444); `CAL BL)NN / ACL CP)+NN1 / PDX 0,4 / TXL *2,4,5 / ACL CP)+NN2 / SLW SYS)132` (90.02:454–461). Also written automatically by SYS)179 and SYS)181 (90.02:422). |
| **SYS)133** | Read by SYS)180 and SYS)182 (90.02:719, 728). | **Yes** — set by SYS)179 and SYS)180 calls, or "by means of in-line coding of the same form as described under SYS)132" (90.02:467). The specimen instruction in the appendix's own tutorial is `STI SYS)133` (90.02:261). Attested 23 times in the sample, always as `LDI CP)+nn / STI SYS)133 / TSX SYS)182,4 / TXI SYS)2xx,1,n` (e.g. 90.05:786–789). |
| **SYS)134** | Never. | Only "whenever a floating point underflow results from a Move" (90.02:469) — no mover is named. | None. Nothing clears it. |

Two consequences for the handler set. First, a dispatch layer that owns SYS)128/129 must supply the writer itself, because no generated instruction fills them — under the printed evidence, the only way a compiled program can put an operand in SYS)128 is by a codegen sequence 90.02 never shows. Second, SYS)130, 131 and 134 are write-only sinks in the appendix; nothing in the compute set reads them, which matches `docs/design/decisions.md:661` and `:674` (D4.2, D4.3) declaring both flags sticky and never cleared.

---

## 3. THE COLLATING TABLE SYS)161

**The table's content is printed nowhere in either manual.** The complete entry is one sentence: "This is a conversion table used in converting from 709 to 705 collating sequence." (90.02:495). There is no word list, no length, no OCT block, no `BSS`. Its only appearance in a calling sequence is as the address field of the SYS)162 OP word, `OP    SYS)161` (90.02:501). It appears zero times in the 1962 sample listing.

**What the manuals do print is the two orderings, not the table.** `02-compiler.md:1351–1360` (J 02.06.16, PDF p. 50) gives both sequences. The 709/7090 order, verbatim as transcribed:

```
0 through 9  =  '  +  A through I  0̅  .  )  −  J through R  0̅  $  *  blank  /  S through Z
                                                                              ‡  ,  (
```

and the Commercial (705) order:

```
Blank  .  ×  ‡  &  $  *  −  /  ,  %  #  @  0̅  A through I  0̅  J through R  ‡  S through Z
0 through 9
```

**Legibility, read from the scan.** I read `images/page-050.png` directly. The page is clean and the typing is sharp; the *words* ("0 through 9", "A through I", "blank") are unambiguous. The **special print-train glyphs are not**. Four separate problems survive at 150 dpi: (a) two positions in each line are struck-over composites — a `0` with a superscript cross and a `0` with an overbar — which the conversion itself flags, "Overbar (0̅) marks a special (non-alphameric) character position in this chart, not a numeral" (`02-compiler.md:1357`); (b) the glyph transcribed `‡` and the one transcribed `×`/`¤` in the 705 line are not separable from each other by shape at this resolution; (c) both lines wrap, and the wrapped fragment (`‡ , (` for the 709 line, `0 through 9` for the 705 line) has no printed marker saying it continues the sequence rather than starting a new column — the transcription's own hedge is "[Transcription uncertain for some special 709/7090 print-train characters in this collating-sequence display — see page image.]" (`02-compiler.md:1357`, repeated at `:1370`); (d) no BCD code chart appears in either manual, so even a fully legible ordering does not yield the six-bit codes the table would be indexed by (grep for "BCD code", "character code", "internal code", "code chart" over `comtran-manuals/` returns nothing).

**Verdict: NAME-ONLY, and this is a gap the handler must record as an Open Question.** A handler cannot build the 64-word table from the manuals: the 705 rank order is legible only for letters, digits and blank, the special characters are typographically unresolved, and the source-code alphabet is unmapped. The repository already carries the adjacent question — `docs/comtran-language-definition.md:4489` (Open Question 58, still-open item (a)) records that "whether COM forces such compares through SYS)162 or instead emits inline CVRs is unrecorded", and `:4489` also observes "The runtime library likewise contains exactly one collating artifact and exactly one consumer of it — SYS)161". The new question is narrower and is not covered by 58: *what are the 64 table words?* Nothing in 90.02, 02.06, 02.04 or the sample answers it.

---

## 4. SYS)294 — the guard

**What condition it detects.** The manual says only "whenever a reference is made to a Base Locator before the locator has been loaded" (90.02:1887) and "prints the fact that BASE.LOCATOR.OF.DATE has not been set if such is the case" (`02-compiler.md:1920`). Neither sentence says what "not loaded" looks like in the word. That is **derivable from the two-instruction sequence, not stated**:

- `LAC BL)NN, N` — `docs/design/emulator.md:138`: "| +0535 | LAC | XR(T) ← 2^15 − C(Y)(21–35) |". So XR_N receives 2^15 minus the address field of the base-locator word.
- `TXL SYS)294, N, 0` — `docs/design/emulator.md:134`: "| −3 (A) | TXL | if XR(T) ≤ D: IC ← Y |", with D = 0 as printed (90.02:1885, `TXL     SYS)294, N, 0`).
- Index registers are 15 bits (`docs/design/emulator.md:216`: "memory indices are always 15-bit"). If `C(BL)NN)(21–35)` is non-zero, XR_N lands in 1…32767 and the TXL does not fire. If it is zero, `2^15 − 0` masks to 0 and the TXL fires.

So the detected condition is: **the address field (positions 21–35) of the base-locator word BL)NN is zero.** Report that as derived from instruction semantics, not as manual text. The 20 sample sites all use decrement 0 and tags 1 or 2 (e.g. 90.05:818, 847), which is consistent with it.

**What it prints.** "an error message" (90.02:1887) — the text is nowhere printed. `90.04-error-messages.md` has no object-time entry for it; the sole base-locator message there is compile-time (msg 202,00, `90.04-error-messages.md:291`).

**"Exits back to the CT Monitor" — the manual's own words, and what they leave open.** The exact phrase is "and exits back to the CT Monitor" (90.02:1887). The same construction, without "back", is the standard object-time abort formula elsewhere in 90.02: SYS)263 "exits to the CT monitor" (90.02:1617), SYS)264 "prints a message and exits to the CT Monitor" (90.02:1629), SYS)265 (90.02:1642), SYS)266 "performs a 'panic' Close-All-Files and exits to the CT Monitor" (90.02:1652), SYS)283 (90.02:1827), SYS)291 (90.02:1867). The manual **never connects that phrase to IOC)40**, and IOC)40's own entry calls itself something narrower — "the end of job return point … for all CT jobs" (90.02:365). The only prose that describes the aftermath is `05-systems-operation.md:335`: "Object program error messages, usually concerning I/O errors. Object-time processing will terminate and control will revert back to the CT Monitor." Whether "exits to the CT Monitor" means a transfer to IOC)40, a different monitor entry, or a distinct abort vector is unrecorded — see GAPS.

Note also `02-compiler.md:1922`: the guard sequence "destroys" the contents of the index register it uses, and "instructions have been inserted in the program", which is why the sequence appears 20 times in the sample around otherwise ordinary `CAL`/`LAS` references.

---

## 5. GAPS — facts a handler needs that no manual states

One line each, keyed to the entry.

1. **SYS)128/129** — no printed instruction anywhere stores into either cell; the writer side of the multi-precision protocol is undocumented.
2. **SYS)128/129** — which of the two holds the high-order half is implied by the recurring order "SYS)128 - SYS)129" (90.02:480, 610) but never stated.
3. **SYS)130 / 131 / 134** — the non-zero value written is unspecified, no reader exists in 90.02, and no clearing operation is documented (already carried as D4.2 and D4.3 design decisions, `docs/design/decisions.md:661`, `:674`).
4. **SYS)134** — the set of movers that can raise floating-point underflow is not named; "results from a Move" (90.02:469) is the whole scope statement.
5. **SYS)155 / SYS)156** — no calling sequence is printed at all, so the parameter count, the resume distance and the register save convention are all unknown.
6. **SYS)155 / 156 / 172 / 173** — the exponential domain is undefined: negative base, zero base, zero exponent, non-integral exponent, and the exponent-overflow/underflow reaction are all unstated.
7. **SYS)160** — "sign adjustment for double precision fixed point numbers" (90.02:487) is never defined; the double-precision fixed-point sign convention it normalises is not given.
8. **SYS)163–168, 170, 171** — the format of the word at `CP)+NN` is unstated; "the constant located at CP)+NN" does not say whether it is 10^k, a shift count, or a scale exponent.
9. **SYS)163–171** — rounding vs truncation on every downscale is unstated; so is the reaction to an upscale that overflows.
10. **SYS)163–171** — the AC-MQ half order is stated only for SYS)166 ("the high order part of the number is in the MQ and the low order in the AC", 90.02:547), and 166 states the *reverse* of the layout the other eight would need if AC were high; the default layout for 165, 167, 168, 169, 170, 171 is therefore undetermined.
11. **SYS)168** — the result is left "in the MQ" (90.02:568); what becomes of the discarded high-order half, and whether the AC is cleared or left dirty, is unstated.
12. **SYS)169** — the remainder's disposition, the operand order (SYS)128-129 ÷ AC-MQ), and the divide-check reaction on a zero divisor are all unstated.
13. **SYS)161** — the table's 64 words are printed nowhere; the 705 ordering at J 02.06.16 is legible only for letters, digits and blank, and no BCD code chart survives in either manual. **Record as an Open Question.**
14. **SYS)162** — the count field of the `CVR` OP word is unspecified (a CVR carries its count in positions 10–17, `docs/design/emulator.md:85`).
15. **SYS)162** — behaviour when LENGTH(1) ≠ LENGTH(2) is unstated (D5.3 already fills this by decision, `docs/design/decisions.md:869`, with "no listing evidence exists for this rule", `:877`).
16. **SYS)162** — no register-clobber list; the three exits are named (90.02:507–509) but their offsets are only derivable.
17. **Every TSX-linked entry** — the resume distance is nowhere stated as a rule; it is derived from three MOVPAK sentences (90.02:670, 709, 728) plus TSX's own semantics.
18. **SYS)174 / SYS)176** — the encoding of the FILENAME operand is not in 90.02; the `04000 + k` ordinal comes from the sample and `docs/design/m4-codegen.md:849`.
19. **SYS)174 / SYS)176** — behaviour when the file is already open, already closed, or absent from the file list is unstated.
20. **SYS)175 / SYS)177 / IOC)1** — the *entry* format of the file list at address L is stated nowhere; only the header word `PZE L,,N` is given (90.02:321).
21. **SYS)178** — which of CP)+NN1…NN4 carries the statement number and which the STOP type is unstated; the sample's four words (90.05:1829–1832) are the only evidence, and `docs/design/m4-codegen.md:822` marks the sub-statement digit rule "**fitted, not derived**".
22. **SYS)178** — whether the halt for `STOP n` occurs inside this handler is unstated (recorded as a decision, `docs/design/decisions.md:539`); J 05.06.04 gives the message form "AT xxxxx,yy STOP nnnnnn" (`05-systems-operation.md:333`) but not the print channel or line format.
23. **SYS)294** — the error message text is printed nowhere, and 90.04 carries no object-time entry for it.
24. **SYS)294** — "exits back to the CT Monitor" (90.02:1887) is never connected to IOC)40 or to any address; whether the guard ends the job the way `TXI IOC)40,0` does, or takes an abort vector, is undetermined.
25. **IOC)40** — the transfer form `TXI IOC)40,0` is attested only in the sample (90.05:1063), never in 90.02, and nothing states the register or memory state the monitor expects on arrival.
26. **CLAUDE.md §11 exposure.** Of the entries M4-17 lands, the 1962 sample exercises only SYS)132, SYS)133, SYS)175, SYS)177, SYS)178, SYS)294, IOC)1 and IOC)40. **SYS)128, 129, 130, 131, 134, 155, 156, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174 and 176 have zero occurrences in `90.05-sample-program.md`**, so each needs a written test plan in the design record rather than a listing-diff oracle — the "no caller, but tested" row of the §11 table.

**Transcription-evidence notes (not manual content).** The conversion note at 90.02:1193 records two readings inside this set: the `NN1`/`NN2` subscripts in the SYS)132 in-line example are "faint/broken in the scan; read with high confidence as '1' and '2'", and the dropped "y" in SYS)162's "the field is located b[y] the 'pointer' word" is "a faint/dropped 'y' in the original print (confirmed by zoomed crop showing a gap, not a genuine short word)". The same note misdates the SYS)162 page as PDF p. 153; the section marker at 90.02:491 puts it at `90.02.12 | PDF 151`, and `docs/comtran-language-definition.md:4489` records the same correction ("the page the 90.02 conversion note misdates as PDF p.153").
