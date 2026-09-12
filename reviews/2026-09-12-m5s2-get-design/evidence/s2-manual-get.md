# Manual evidence for the GET runtime handler (IOC)8)

Paths are absolute. `J/` = `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/`, `F/` = `/Users/jacklusher/development/comtran-compiler/comtran-manuals/F28-8043/`, `D/` = `/Users/jacklusher/development/comtran-compiler/docs/` — every citation below spells the path out in full at least once per block.

---

## 1. The GET calling sequence as J 90.02 gives it

### The generic template and its explanation

> References to Base Locators occur in the symbolic listing whenever the pointer word must be changed. This type of reference to a Base Locator is usually part of a 'GET' calling sequence to the Input/Output system. An example of a sequence that changes the value of a Base Locator due to locating data within an input buffer might be:
>
> ```
> TSX      IOC)8,4
> PZE      FILENAME,,SYS)260
> PZE      END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE
> IOCDN*   BL)2,,14
> ```
>
> This sequence of instructions fills in the cell BL)2 with the location of the first word of a 14 word record which is in an input buffer.

`J 90.02.04` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.02-generated-code.md:165-174`

This is the whole interface in one place. Four words: the `TSX` with the link in index register 4, then three parameter words. Word 2 address = the file; word 2 decrement = SYS)260. Word 3 address = the AT END exit; word 3 decrement = the ON ERROR exit. Word 4 = the `IOCDN*`/`IOCTN*` word, whose address is the base locator to fill and whose decrement is the record length in words. The handler's contract is stated flatly: *fill in the cell BL)2 with the location of the first word of a 14 word record which is in an input buffer.*

> Following the updating of a Base Locator further references to BL's may occur in the form:
>
> ```
> LAC    BL)2,4
> CAL    DATANAME,4
> ```
>
> References to data located by means of a Base Locator is usually done in this manner, i.e., by first loading an index register with the 2's complement of the location of the first word (the base) of the data block and then referencing any data item within that block by using the relative word position or displacement from the beginning of the block.

`J 90.02.04` — `J/90.02-generated-code.md:176-183`

`LAC` loads the **2's complement**, so the program addresses `displacement,n`. That fixes the sign convention the handler must write.

> The form of a Base Locator word is:
>
> ```
> PZE    LOC,,BYTE
> ```
>
> where LOC is the word address of the first word of the data organization, and BYTE is the position in that word (0-5) of the first data item. By definition, a 'simple' Base Locator is one with BYTE always 0. Input records are located by 'simple' Base Locators.

`J 90.02.05` — `J/90.02-generated-code.md:209-215`

The handler writes `PZE address,,0` into BL)n — decrement **must** be zero for an input record, because the sample later does `CAL BL)2 / ACL CP)+45` (byte arithmetic) on that word.

> **VIII. IOC - Input Output Subroutines and Communication**
>
> References to Input/Output subroutines and communication cells appear in the listing in the form IOC)NNN. […] Most of these are routines that are a part of the CT monitoring system which is in core at all times.

`J 90.02.06` — `J/90.02-generated-code.md:268-278`

### The three SYS entries the sequence names

> **SYS)260**
>
> This SYS number may appear in a GET calling sequence to the IOCS Read routine:
>
> ```
> TSX     IOC)8, 4
> PZE     FILENAME, , SYS)260
> PZE     SYS)265, , SYS)283
> IOCDN*  BL)NN, , 14
> ```
>
> The SYS)260 subroutine prints an error message indicating processing terminated due to record length error.

`J 90.02.28` — `J/90.02-generated-code.md:1577-1588`

> **SYS)265**
>
> This SYS number appears as part of the GET calling sequence to the IOCS Read routine whenever the 'AT END' option is not used with the GET verb.
>
> ```
> TSX     IOC)8, 4
> PZE     FILENAME, , SYS)260
> PZE     SYS)265, , SYS)283
> IOCDN*  BL)NN, , 14
> ```
>
> SYS)265 prints a message concerning the unexpected end-of-file and exits to the CT Monitor.

`J 90.02.29` — `J/90.02-generated-code.md:1631-1642`

> **SYS)283**
>
> This SYS number appears as part of a GET calling sequence to the IOCS Read routine whenever the 'ON ERROR' option in not used in the Environment description of the file.
>
> ```
> TSX     IOC)8, 4
> PZE     FILENAME, , SYS)260
> PZE     SYS)265, , SYS)283
> IOCDN*  BL)NN, , 14
> ```
>
> SYS)283 prints a message concerning the GET error and exits to the CT Monitor.

`J 90.02.32` — `J/90.02-generated-code.md:1816-1827` (the printed "option in not used" is a source typo, flagged at `J/90.02-generated-code.md:1910`)

Note the asymmetry: SYS)265 and SYS)283 each name the *source option* they stand in for; SYS)260 says only "may appear" and names no option. SYS)260 is therefore not a programmer-replaceable slot — it is the fixed record-length/EOB exit of every GET.

### A fourth variant: the card GET

> **SYS)287**
>
> This SYS number appears as part of the calling sequence to GET a record from the on-line card reader and convert the record to BCD.
>
> ```
> TSX     IOC)8, 4
> PZE     FILENAME, , SYS)260
> PZE     SYS)265, , SYS)283
> IOCDN*  SYS)287, , 24
> ```
>
> SYS)287 is a pointer word which serves to locate the record for the hollerith to BCD conversion routine, SYS)286.

`J 90.02.32` — `J/90.02-generated-code.md:1837-1848`

The pointer-word slot need not hold a `BL)n` — it can hold any cell (`SYS)287`, or `*+1` in the WRITE forms at `J/90.02-generated-code.md:1864,1896`). IOC)8 writes a pointer into whatever address that word names.

### `IOCDN*` vs `IOCTN*` — do not collapse them

Three distinct printings, all attested:

| Spelling | Where | Line |
|---|---|---|
| `IOCDN*  BL)NN,,14` | the 90.02 appendix templates (.04, .28, .29, .32) | `J/90.02-generated-code.md:171,1585,1639,1824` |
| `IOCTN*  BL)2,,15` | all four GET sequences in the compiled sample | `J/90.05-sample-program.md:810,828,838,888` |
| `IOCTN 0,,length.of.record.in.words.` | the *variable-length record control word written on tape* — a record header, not a calling-sequence word | `J 02.07.03`, `J/02-compiler.md:1498` |

The octal decides which spelling the assembler actually punched:

```
00203      5 00017 6 01667   10001            +14     IOCTN*  BL)2,,15
00236      5 00003 6 01670   10001            +4      IOCTN*  BL)3,,3
```
`[J 90.05] listing, PDF p. 201` — `J/90.05-sample-program.md:810,838`

Prefix digit **5**. In this listing the leading octal digit tracks the mnemonic: `PZE`→0, `TXI`→1, `TXH`→3, `TXL`→7, `IOST`→7 (compare `J/90.05-sample-program.md:808,789,794,818,883`). Prefix 5 is neither the PZE class that `IOCDN` would assemble to nor the IOST class. Tag prints **6** on every `IOCTN*` and **0** on every `IOST`, consistent with the printed `*`. Decrement `00017`₈ = 15 and `00003`₈ = 3 — the MASTER and DETAIL record lengths in words, not the appendix's generic 14. The octal sides with the listing spelling. The existing decision already rules on this:

> Reproduce the printed mnemonic spellings as they stand (`IOCDN*` in the appendix template, `IOCTN*` in the listing).

`D6.6` — `/Users/jacklusher/development/comtran-compiler/docs/design/decisions.md:1015`

### The statement-number stamp before every GET

Every `TSX IOC)8,4` in the sample is immediately preceded by a tag-0 `TXH`, and no FILE sequence has one:

```
00177      3 01713 0 01712   10101            +10     TXH   CP)+14,0,CP)+15
00221      3 01717 0 01716   10101    GET.MASTER      TXH   CP)+18,0,CP)+19
00232      3 01717 0 01720   10101    GET.DETAIL      TXH   CP)+20,0,CP)+19
00276      3 01717 0 01722   10101            +16     TXH   CP)+22,0,CP)+19
```
`[J 90.05] listing, PDF pp. 201-202` — `J/90.05-sample-program.md:794,824,834,884`

The constant pool cells decode as BCD statement stamps (`[J 90.05] listing, PDF p. 215`, `J/90.05-sample-program.md:1806-1826`): `CP)+14 = 606060011010` = `␣␣␣188`; `CP)+15 = 730002606060` = `,02␣␣␣`; `CP)+18 = 606060011100` = `␣␣␣190`; `CP)+19 = 730000606060` = `,00␣␣␣`; `CP)+20 = ...011101` = `191`; `CP)+22 = ...011104` = `194`. Those are exactly the four GET statement numbers (188, 190, 191, 194) in J's own on-line message format:

> The STOP messages will be accompanied by the source language statement number at which the STOP occurred, i.e. AT xxxxx,yy STOP nnnnnn where xxxxx,yy is the statement number.

`J 05.06.04` — `J/05-systems-operation.md:333`

and match SYS)264's parameter words `OCT STATEMENT-NUMBER / OCT SUB-STATEMENT-NUMBER` (`J/90.02-generated-code.md:1622-1627`). **Consequence for the handler:** SYS)260/265/283 have no parameter words of their own, so the only way they can name the failing statement is by walking back from the link the `TSX` left in IR4 to the `TXH` at `IR4−2`. IOC)8 must therefore leave IR4 intact when it transfers to any of the three exits. M4 already records the stamp:

> The statement stamp is a pool pair: the statement number in BCD, a comma, two digits, and three blanks. Each GET sequence opens with it as a tag-0 no-op, `TXH CP)+a,0,CP)+b`; SYS)178's parameters carry it; no other statement emits one (five attested sites, statements 188, 190, 191, 194 and 199).

`M4-14` — `/Users/jacklusher/development/comtran-compiler/docs/design/m4-codegen.md:828-832`

---

## 2. What IOC)8 does: the CT system subroutines and communication cells (J 90.02.08)

> #### IOC REFERENCE NUMBERS
>
> A knowledge of the 7090 IOCS is necessary in understanding most of the IOC Numbers.
>
> SYSTEM REFERENCE — FORMAT and/or FUNCTION
>
> **IOC)1**
> ```
> PZE L,,N
> ```
> A cell in the CT Monitor communications area which locates (L) a list of files, and designates the number (N) of files in the list. This List is used in Opening and Closing files.
>
> **IOC)2**
> ```
> PZE L,,12*N
> ```
> A cell in the CT Monitor communication area which locates (L) a number (N) of IOCS file blocks. I/O information is kept in each of the 12 word blocks for every file in the CT program.
>
> **IOC)3** The entry point to the IOCS DEFINE subroutine.
>
> **IOC)4** The entry point to the IOCS JOIN subroutine.
>
> **IOC)5** The entry point to the IOCS ATTACH subroutine.
>
> **IOC)6** The entry point to the IOCS CLOSE subroutine.
>
> **IOC)7** The entry point to the IOCS OPEN subroutine.
>
> **IOC)8** The entry point to the IOCS READ subroutine.
>
> **IOC)9** The entry point to the IOCS WRITE subroutine.
>
> **IOC)10** The entry point to the IOCS COPY subroutine.
>
> **IOC)11** The entry point to the IOCS REWIND subroutine.
>
> **IOC)12** The entry point to the IOCS WRITE-END-OF-FILE subroutine.
>
> **IOC)13** The entry point to the IOCS BACKSPACE-RECORD subroutine.
>
> **IOC)14** The entry point to the IOCS BACKSPACE-FILE subroutine.
>
> **IOC)15** The entry point to the IOCS CHECKPOINT subroutine.
>
> **IOC)16** The entry point to the IOCS STASH subroutine.
>
> **IOC)17** The entry point to the IOCS MESSAGE-WRITER subroutine.
>
> **IOC)29** This is a 14 word area within IOCS which is used to process all labels.

`J 90.02.08` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.02-generated-code.md:312-360`

> **IOC)40** This is the end of job return point in the CT Monitor communication area for all CT jobs.
>
> **IOC)46** This is the first cell of the CT Monitor communication area.
>
> **IOC)53** This is a cell in the CT Monitor communication area which contains the current date in BCD in the form:
>
> ```
> MM DD YY
> ```
>
> MM is the month / DD is the day / YY is the year
>
> **IOC)54** This is a cell in the CT Monitor communication area which contains the current time in BCD. (Subject to each installation providing an accounting routine which fills in this cell).

`J 90.02.09` — `J/90.02-generated-code.md:365-379`

That is the entire IOC) inventory in the manual — 1–17, 29, 40, 46, 53, 54, and nothing else. **IOC)8 is one line: "The entry point to the IOCS READ subroutine."** Everything else about what the READ does comes from `J 02.07` (question 6/§6.2 below) and from the calling-sequence template in 90.02.04. Note the split of duties: IOC)7 and IOC)6 are the *IOCS* OPEN/CLOSE, whereas the whole-file-list forms the compiler actually emits go to SYS)175 and SYS)177:

> This routine opens all files in the file list located by IOC)1.

`J 90.02.14` — `J/90.02-generated-code.md:631`; the close counterpart at `:649`

The 12-word file block (IOC)2) is where "I/O information is kept … for every file", and `J 03.03.02` restates it: *"File Block — this is a 12-word File Control Block for each file required by the program."* (`J/03-loader.md:424`). The manual never lists the 12 words.

### Where the record is delivered — the buffer

> #### 4. Buffers
>
> The Loader reserves a portion of core storage for use by the I/O system as operating storage. This storage area is subdivided into buffers into which all input blocks of data are read and from which all output blocks of data are written. Since the IOCS routine attempts dynamic optimization of buffer assignments, data blocks of a particular file may be located within any of the buffers associated with this or several files.

`J 02.07.02` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/02-compiler.md:1452-1454`

> #### 5. Locate and Transmit
>
> In the 709/7090 Commercial Translator system it is possible to process the records of an input file in the buffers or in an area(s) reserved for them outside the buffer area; all records in a file must be processed in the same manner.
>
> **a) Locate Mode of Operation**
>
> The GET command when dealing with a record to be processed in the buffer area
>
> i. 'locates' the next record in the file, i.e., determines the position of the record within the buffer area, and
>
> ii. adjusts all program references to data within the record to reflect the new base reference address of the record within the buffer area.
>
> **b) Transmit Mode of Operation**
>
> The GET command when dealing with a record to be processed in an area assigned outside of the buffer area
>
> i. locates the next record in the file, and
>
> ii. 'transmits' the record to its assigned area. As the area assignment is fixed no adjustment of references to data within the record is necessary.

`J 02.07.02` — `J/02-compiler.md:1456-1474`

> The 'transmit' mode is triggered by the selection of the SPANS, HOLD or CARD options on the Environment FILE card. 'Locate' is assumed when none of these options have been selected.

`J 02.07.03` — `J/02-compiler.md:1479`

> The GET command makes available for processing the next record of an open file. If the file is not open and a GET command is given, the end of file exit is taken. No error message is given.

`J 02.07.04` — `J/02-compiler.md:1510`

> i. If the locate mode is being used, no references can be made to the record or its fields until after execution of a GET command for that record. All references to fields of a located record initially specify location zero. Upon a GET these references are adjusted to reflect the location of the data within the buffer area. If references are made to located fields prior to the first automatic GET adjustment the low order portions of memory (the monitor) will be irreparably damaged.

`J 02.07.05` — `J/02-compiler.md:1554`

Together: locate mode = "the address of the record" is a *pointer the handler stores*, not a copy. The buffer is loader-allocated core that can be shared across files and reassigned dynamically. Where a given file's buffer lives at any instant is deliberately unspecified.

Core layout (the only manual statement of where buffers sit):

> | Address | Core storage region |
> | 32767 | *(top of core)* | 32256 | Available for Customer Usage |
> | | Primary Object Time Subroutines |
> | | Program Initialization and Loading Routines (Overlaid by buffer pools) |
> | | Buffer Pools |
> | | Secondary Object Time Subroutines |
> | | Program |
> | | Transfer to Program Start |
> | | Define, Attach Calling Sequences |
> | | File Lists |
> | 3840 | File Block | 1856 | IOBS | 1400 | CTM | 350 | IOEX | 0 | Basic Monitor |
>
> Note: The core addresses shown above are approximate.

`J 03.03.01` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/03-loader.md:396-417`

> Define and Attach Calling Sequences — each buffer pool must be defined by a reference to the IOCS subroutine, DEFINE. Files are attached to this pool by reference to the ATTACH subroutine. These calling sequences are generated by the Loader and are the first instructions executed.

`J 03.03.02` — `J/03-loader.md:428`

---

## 3. The `*FILE` and `*SPEC` loader cards

### The `*FILE` card as the compiler fills it

> | Columns | Contents | Source of Information |
> |---|---|---|
> | 1-6 | deck.name | $CMPLE |
> | 7-11 | \*FILE | Compiler emitted |
> | 14-15 | file number | Compiler generated |
> | 17 | tape mounting indicator | SPECIF - DEFER |
> | | blank | option specified |
> | | \* | option not specified |
> | 18-21 | unit1 | SPECIF - UNIT1 'unit.1' |
> | 22-25 | unit2 | SPECIF - UNIT2 'unit.2' |
> | 27 | File List Control (blank) | Compiler emitted |
> | 28 | file type | FILE |
> | | I - input | INPUT |
> | | T - total block output | OUTPUT, SPANS |
> | | P - partial block output | OUTPUT |
> | 29 | reel control | SPECIF |
> | | blank - single reel unlabeled | MULTI nor LABELS nor LABELN specif. |
> | | blank - not to be searched for label | LABELS or LABELN bu no OPENF |
> | | L - label to be searched for on labeled, open file only | OPENF and LABELS or LABELN |
> | | M - multi-reel unlabeled file | MULTI, neither LABELS nor LABELN |
> | 30 | File density | SPECIF | H - high | HIGH | L - low | HIGH |
> | 31 | file mode | FILE | D - BCD | BCD | B - binary | BINARY |
> | 32 | labeling conventions | SPECIF | H - high | LABELS or LABELN and HIGH | L - low | LABELS or LABELN and LOW | S - same as file | LABELS or LABELN |
> | 33 | block sequence numbers to be checked | SPECIF - SEQ |
> | 34 | block checksums to be checked | SPECIF - CKSUMS |
> | 35 | checkpoint conventions | FILE and SPECIF | C - on checkpoint file | FILE CHECKPOINT AND SPECIF CHKS | F - on specified file | FILE OUTPUT and SPECIF CHECKF and LABELS or LABELN |
> | 38-41 | sequence number of first reel | SPECIF - REEL 'reel.no' |
> | 44-48 | file serial number | SPECIF - SERIAL 'serial.no' |
> | 51-53 | retention days | SPECIF - RETAIN days |
> | 54-72 | file name | FILE - name field |

`J 90.08.01` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.08-loader-symbolic-cards.md:17-55` (the "L - low ← HIGH" row and "bu no OPENF" are print errors reproduced as-is, per the conversion note at `:85`)

### The `*SPEC` card

> | Columns | Contents | Source of Information |
> |---|---|---|
> | 1-6 | deck.name | $CMPLE card |
> | 7-11 | \*SPEC | Compiler emitted |
> | 14 15 | file number | Compiler generated |
> | 17-20 | blocksize | FILE - BLOCKSIZE nn |
> | 22-23 | activity | SPECIF - ACTIVITY nn |
> | 25 | opening conventions | SPECIF | N - without rewind | OPENW | R or blank - with rewind | OPENW not specified |
> | 27 | closing conventions | SPECIF | N - without rewind | CLOSEW | R or blank - with rewind | CLOSER | U - with rewind and unload | neither CLOSEW nor CLOSER specified |

`J 90.08.02` — `J/90.08-loader-symbolic-cards.md:67-80`

### The loader's own reading of the same cards

> ```
> 1-6         7-11    14-15    17    18-21    22-25    27-35      38-41
> deck.name   *FILE   file.no  M     unit1    unit2    controls   reel.seq
>
> 44-48           51-53        55-72
> file.serial      ret.days    File name
> ```

`J 03.02.02` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/03-loader.md:137-141` (note 90.08 says file name is 54-72, the loader chapter says 55-72 — an unreconciled one-column discrepancy)

> ```
> 1-6         7-11    14-15    17-20        22-23      25     27
> deck.name   *SPEC   file.no  blocksize    activity   open   close
> ```
>
> 'blocksize' is normally a number (0-999) but may be left blank. A number in this field specifies the maximum number of words to be input or output in a single block. It may be desirable to change the blocksize in an attempt to obtain better input/output processing speeds or tape utilization. Conflict with file specifications entered in the Commercial Translator Environment section must be avoided. The loader will check most normal situations in accordance with information supplied to it by the Compiler.
>
> 'activity' may be specified as a number 0-99 or may be left blank. A number in this field specifies the relative activity of the file in respect to other files and is used by the Loader in the allocation of buffer areas.
>
> The 'open' options are: 1. N — No rewind / 2. R or blank — Rewind
>
> The 'close' options are: 1. U — Rewind and unload / 2. R or blank — Rewind / 3. N — No Rewind / 4. S — No file mark or trailers, no rewind

`J 03.02.05` — `J/03-loader.md:226-246`

**Neither card carries a buffer count or a buffer size.** Buffers are set by the separate `*POOL` and `*GROUP` cards:

> The \*POOL card designates which files are to share common buffer areas. The format of this card is:
> ```
> deck.name   *POOL   pool.no   blocksize buffer.cnt                file1, file2...filen
> ```

`J 03.02.05` — `J/03-loader.md:252-256`

> ```
> deck.name   *GROUP   group.no   pool.no   Opn.cnt   Buffer.cnt
> ```
> […] All \*POOL cards are processed first, in the order read, then \*GROUP cards. If there is a conflict in pool or group assignments […] the first assignment is used.

`J 03.02.06` — `J/03-loader.md:290-300`

> In the absence of any \*POOL or \*GROUP cards, the Loader will make its own assignments.

`J 03.02.07` — `J/03-loader.md:305`

The Environment side of those:

> nn buffers will be assigned to the files in the pool by the loading program. nn must be equal to or greater than the number of files in the pool. […] If BUFFERCOUNT is not specified, it will be assigned automatically by the compiler.

`J 02.06.13` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/02-compiler.md:1263`

> nn is the number of words to be allocated to each of the buffers in the POOL. The POOL BLOCKSIZE should be equal to or greater than the largest BLOCKSIZE specified for any file in the pool. If BLOCKSIZE nn is not entered on the POOL card, the POOL BLOCKSIZE used will be the same as the BLOCKSIZE of the largest file in the POOL.

`J 02.06.13` — `J/02-compiler.md:1268`

> These cards are optional. The information (normally provided in the GROUP card) may be punched into a load-time control card. If GROUP specifications are not made at all, the compiler will attempt to assign at least 2 buffers to each file.

`J 02.06.14` — `J/02-compiler.md:1277`

> nn is the number of buffers which are to be assigned by the loader to this GROUP. The BUFFERCOUNT of a GROUP must be equal to or greater than the OPENCOUNT of the GROUP. If no BUFFERCOUNT is given for the GROUP, the loader will attempt to assign at least twice the OPENCOUNT number of buffers to the GROUP.
>
> If the POOL BUFFERCOUNT or storage limitations prevent such assignment, buffers (in addition to the minimum necessary) are allocated to the GROUP on the basis of the activity of the files in the GROUP.

`J 02.06.14` — `J/02-compiler.md:1308-1310`

### Blocking / grouping / labels on the Environment FILE and SPECIF cards

> nn is an integer representing the size of the largest block to be output or the maximum number of words to be input from an input block. This specification must be made. All input card files must have a block size of at lease 24 words. Maximum blocksize is 9999 words.

`J 02.06.04` (BLOCKSIZE) — `J/02-compiler.md:981`

> CARD is specified if the on-line card reader or card punch is the processing unit. When CARD is specified BEGIN is assumed, i.e., each record starts at the beginning of a physical block. With this option only columns 1 through 72 are read. For the most efficient handling of card input a GROUP card should be used when more than two cards constitute a record. If no specification is made TAPE processing is assumed.

`J 02.06.04` — `J/02-compiler.md:975`

> - **i** For an input file: forces data to be processed in the transmit mode. This is required if records in the file overrun the boundaries of a block (SPANS); when it is required that each named record of the file be available until another of the same name is input (HOLD).
> - **ii** For an output file: specifies that output records are to be written in blocks of the specified length. This allows the existence of partial records in blocks for the sake of compactness (SPANS). Files written in this manner must be processed in the transmit mode when input.
>
> The compiler does not differentiate between the words HOLD and SPANS. […] If neither HOLDS or SPANS is selected an input file will be processed in the locate mode; an output file will be created with all records complete within blocks.

`J 02.06.05` — `J/02-compiler.md:1007-1012`

> The BEGIN option specifies that each record to be read or written by the program starts at the beginning of a physical block.

`J 02.06.05` — `J/02-compiler.md:1018`

> LABELS specifies a file with a standard label, i.e., labels to be checked or written automatically by IOCS.
>
> LABELN indicates the use of a non-standard label, i.e., a label of 14 words or less which is to be checked by the programmer using a linkage supplied by the FOR LABEL option of the Environment FILE card. Either LABELS or LABELN must be explicitly stated if labels are to be recognized by IOCS and acted upon in either a standard or non-standard fashion. If neither option is exercised the file is considered to be unlabeled.

`J 02.06.11` — `J/02-compiler.md:1205-1207`

> MULTI specifies a tape file which is contained in more than one tape reel. A single reel file is assumed if MULTI is not specified.

`J 02.06.11` — `J/02-compiler.md:1189`

> SEQ specifies that each block in the file contains a block sequence number which is to be checked by the I/O system. (see IOCS)
>
> CKSUMS specifies that each block in the file carries a checksum of data in the block which is to be checked by the I/O system. (see IOCS).

`J 02.06.11` — `J/02-compiler.md:1194-1199`

---

## 4. The 90.05 sample's data description for INPUTMASTER and DETAILFILE

### MASTER — record layout and environment

> Master records on tape or in storage occupy 709/7090 words in the following manner:
>
> | Word | Field |
> | Word 1 | EMPLOYEE.NUMBER | Word 2 | first 6 characters of NAME | Word 3 | second 6 characters of NAME | Word 4 | last 3 characters of NAME | Word 5 | RATE | Word 6 | DATE | Word 7 | EXEMPTIONS | Word 8 | GROSS | Word 9 | RETIREMENT | Word 10 | INSURANCE | Word 11 | FICA | Word 12 | WHT | Word 13 | BONDEDUCTION | Word 14 | BONDACCUMULATION | Word 15 | BONDENOMINATION |

`J 90.05.01-.02` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.05-sample-program.md:59-81`

> #### 2. Environment for MASTER Records
>
> The master file is a standard binary tape file containing only MASTER records. Twenty 15-word records are grouped to form 300-word blocks on tape, with each record complete within a block, since it is desired to process input records in the buffer area, in the locate mode. The FILE and SPECIF cards for INPUTMASTER and OUTPUTMASTER, provide the system with these characteristics.

`J 90.05.02` — `J/90.05-sample-program.md:83-90`

15 words × 20 records = 300 = BLOCKSIZE. "each record complete within a block" is the locate-mode precondition. This is the *grouped* case.

### DETAIL — record layout and environment

> Data Description entries specify that all fields of the detail records are in external mode since they are generated on a card punch. HOURS is the only field upon which arithmetic operations are performed, and consequently, is the only field specified as numeric (9's in description). Detail records consist of the following 709/7090 words:
>
> | Word | Field |
> | Word 1 | EMPLOYEE NUMBER | Word 2 | DATE | Word 3 | HOURS in the first three characters; 3 blanks (supplied automatically) |

`J 90.05.02` — `J/90.05-sample-program.md:100-110`

> #### 2. Environment Description
>
> The detail input file is a non-labeled, ungrouped, BCD tape file produced on card-to-tape equipment. On the input tape a 3-word record occupies the first portion of tape blocks 14 words long.
>
> Only the 3-word record is to be brought into storage and processed, and the specification BLOCKSIZE 3 on the DETAILFILE FILE cards accomplishes this aim. Alternatively, BEGIN and BLOCKSIZE 14 might have been specified on the FILE card which would have enabled correct processing but allowed the full 14-word block to enter core.

`J 90.05.03` — `J/90.05-sample-program.md:115-125`

**This is the load-bearing paragraph for the handler.** "ungrouped" here means one record per physical block (contrast "Twenty 15-word records are *grouped* to form 300-word blocks" above); it is not the GROUP card. And BLOCKSIZE 3 against a 14-word physical block means: **IOCS reads at most BLOCKSIZE words of each physical block and discards the rest.** The block on tape is 14 words; only the first 3 enter core; the tail is dropped with no record-length error. The IOC)8 handler must therefore treat BLOCKSIZE as a read ceiling, not as the tape block length.

### The ENVIRONMENT division text as compiled

```
        173,00           INPUTMASTER      FILE   INPUT,BINARY,TAPE,MASTER,BLOCKSIZE 300
        174,00                            SPECIFINPUTMASTER, UNIT1 'D1',OPENW,CLOSER
        175,00           OUTPUTMASTER     FILE   OUTPUT,BINARY,TAPE,MASTER,BLOCKSIZE 300
        176,00                            SPECIFOUTPUTMASTER, UNIT1 'C1',OPENW,CLOSER
        177,00           DETAILFILE       FILE   INPUT,BCD,TAPE,DETAIL,BLOCKSIZE 3
        178,00                            SPECIFDETAILFILE,UNIT1 'C2',OPENW,CLOSER,LOW
```
`[J 90.05] listing, PDF p. 195` — `J/90.05-sample-program.md:445-450`

No SPANS, no HOLD, no BEGIN, no CARD on either input file → **both are locate mode** (`J 02.07.03`). No LABELS/LABELN, no MULTI, no SEQ, no CKSUMS → unlabeled, single-reel, no block checks. No ON ERROR → SYS)283 stands in every GET. No POOL and no GROUP cards anywhere in the sample.

### The generated loader cards

```
    *FILE  01 *D1        I HB              INPUTMASTER                     1
    *SPEC  01  300       N R                                               2
    *FILE  03 *C2        I LD              DETAILFILE                      5
    *SPEC  03    3       N R                                               6
```
`[J 90.05] listing, PDF p. 198` — `J/90.05-sample-program.md:646-651`

Decoded against `J 90.08.01`/`.02`: col 17 `*` = DEFER not specified (tape must be mounted before the run); col 28 `I` = input; **col 29 blank = single reel unlabeled**; col 30 `H`/`L` = density; col 31 `B`/`D` = binary/BCD; col 32 blank = no labeling; cols 33-35 blank = no SEQ, no CKSUMS, no checkpoint; `*SPEC` cols 17-20 = 300 / 3 blocksize; cols 22-23 blank = no ACTIVITY; col 25 `N` = OPENW (no rewind on open); col 27 `R` = CLOSER (rewind on close).

---

## 5. The PROCEDURE division around every GET

### Source

```
        188,00   71466  START.          OPEN ALL FILES,
                                         MOVE ZEROS TO INTERNAL.TOTALS, GRAND.TOTALS,
                                         GET MASTER, AT END DO END.OF.MASTERS.
        189,00                          MOVE MASTER DEPARTMENT TO CURRENT.DEPT,  GO TO GET.DETAIL.
        190,00   71471  GET.MASTER.     GET MASTER, AT END DO END.OF.MASTERS.
        191,00   71474  GET.DETAIL.     GET DETAIL, AT END GO TO END.OF.DETAILS.
        192,00   71477  COMPARE.EMPLOYEE.NUMBERS.  GO TO CHECK.NEW.DEPT WHEN D.EMP.NO =
                                         M.EMP.NO,  LOW.DETAIL WHEN D.EMP.NO LT M.EMP.NO.
        193,00   71500  HIGH.DETAIL.    MOVE 'M' TO ERRORTYPE,  MOVE MASTER DAT  TO
                                         ERROROUT INFO,
                                         FILE ERROROUT.
        194,00                          GET MASTER, AT END DO END.OF.MASTERS.
        195,00                          GO TO COMPARE.EMPLOYEE.NUMBERS.
```
`[J 90.05] listing, PDF p. 195` — `J/90.05-sample-program.md:468-480`

```
        197,00   71504  END.OF.MASTERS. IF D.EMP.NO = HIGH.VALUE THEN GO TO END.OF.RUN
                                         OTHERWISE SET M.EMP.NO = HIGH.VALUE.
        198,00   71507  END.OF.DETAILS. IF M.EMP.NO = HIGH.VALUE THEN GO TO END.OF.RUN
                                         OTHERWISE SET D.EMP.NO = HIGH.VALUE,  GO TO HIGH.DETAIL.
        199,00   71512  END.OF.RUN.     DO DEPARTMENT.END,
                                         […]
                                         CLOSE ALL FILES,  STOP RUN.
```
`[J 90.05] listing, PDF p. 196` — `J/90.05-sample-program.md:499-513`

So: four GETs, three on INPUTMASTER (188, 190, 194) and one on DETAILFILE (191). Three carry `AT END DO END.OF.MASTERS`, one carries `AT END GO TO END.OF.DETAILS`. This is the classic high-value-sentinel merge: neither AT END goes to end of job directly; each sets its side's key to HIGH.VALUE and lets the *other* stream drain, and only the second end-of-file reaches END.OF.RUN, which does the departmental total, files the grand total, `CLOSE ALL FILES` and `STOP RUN`.

### Generated code — the shape is uniform across all four

```
00200      0074 00 4 00010   10010            +11     TSX   IOC)8,4
00201      0 00404 0 04001   11010            +12     PZE   INPUTMASTER,,SYS)260
00202      0 00433 0 00205   11001            +13     PZE   GN)058,,SYS)283
00203      5 00017 6 01667   10001            +14     IOCTN*  BL)2,,15
00204      0020 00 0 00210   10001            +15     TRA   GN)059
00205      0774 00 7 00210   10001    GN)058          AXT   *+3,7
00206      0634 00 4 00331   10001            +1      SXA   END.OF.MASTERS,4
00207      0020 00 0 00332   10001            +2      TRA   END.OF.MASTERS+1
00210      4500 00 0 01714   10001    GN)059          CAL   CP)+16
```
`[J 90.05] listing, PDF p. 201` — `J/90.05-sample-program.md:807-815`

```
00233      0074 00 4 00010   10010            +1      TSX   IOC)8,4
00234      0 00404 0 04003   11010            +2      PZE   DETAILFILE,,SYS)260
00235      0 00433 0 00240   11001            +3      PZE   GN)062,,SYS)283
00236      5 00003 6 01670   10001            +4      IOCTN*  BL)3,,3
00237      0020 00 0 00241   10001            +5      TRA   GN)063
00240      0020 00 0 00351   10001    GN)062          TRA   END.OF.DETAILS
```
`[J 90.05] listing, PDF p. 201` — `J/90.05-sample-program.md:835-840`

Normal return is **four words on** (the `TRA` at `+15`/`+5`), which jumps over the out-of-line AT END block. `AT END DO x` becomes the ordinary three-instruction DO triple; `AT END GO TO x` becomes one `TRA`.

### Control flow after the FIRST GET on an empty input tape

The first GET is statement 188's third clause at 00200. On an empty INPUTMASTER, IOC)8 takes the AT END exit to `GN)058` (00205), which is the DO triple into `END.OF.MASTERS` at 00331:

```
00331      0774 00 0 00000   10000    END.OF.MASTERS  AXT   0
00332      4500 00 0 01723   10001            +1      CAL   CP)+23
00333      0535 00 1 01670   10001            +2      LAC   BL)3,1
00334      7 00000 1 00446   10010            +3      TXL   SYS)294,1,0
00335      4340 00 1 00000   10000            +4      LAS   2)EMPLOYEE.NUMBER,1
```
`[J 90.05] listing, PDF p. 202` — `J/90.05-sample-program.md:911-915`

`END.OF.MASTERS` tests `D.EMP.NO` — a DETAIL field, addressed through **BL)3**. On an empty master tape the program has not yet executed its first `GET DETAIL`, so BL)3 is still zero and the guard fires:

> **SYS)294**
> ```
> LAC     BL)NN, N
> TXL     SYS)294, N, 0
> ```
> This subroutine prints an error message whenever a reference is made to a Base Locator before the locator has been loaded, and exits back to the CT Monitor.

`J 90.02.33` — `J/90.02-generated-code.md:1880-1887`

**So the sample on an empty master tape dies with the base-locator message and an exit to the CT Monitor — not a clean end of job.** That is a property of this program, not of IOC)8, but the handler must reproduce it exactly: leave BL)3 at zero, take the AT END exit, and let `TXL SYS)294` catch it.

### After the last record — and a hard constraint the manuals never state

The OTHERWISE branch of END.OF.MASTERS is `SET M.EMP.NO = HIGH.VALUE`:

```
00342      4500 00 0 01667   10001    GN)066          CAL   BL)2
00343      0361 00 0 01751   10001            +1      ACL   CP)+45
00344      0602 00 0 00205   10010            +2      SLW   SYS)133
00345      0074 00 4 00266   10010            +3      TSX   SYS)182,4
00346      1 00006 1 00365   10010            +4      TXI   SYS)245,1,6
00347      747474747474      10000            +5      OCT   747474747474
00350      0020 60 0 00331   10001    GN)067          TRA*  END.OF.MASTERS
```
`[J 90.05] listing, PDF p. 202` — `J/90.05-sample-program.md:920-926`

`SYS)133` is the MOVPAK *target* cell (compare HIGH.DETAIL at `J/90.05-sample-program.md:874-880`, where `CAL BL)2 / ACL CP)+43 / SLW SYS)132` sets the *source*). So after the master file's end of file has been signalled, the program writes six `74` characters **through BL)2, into the located MASTER record that is still sitting in the input buffer** — and with no `TXL SYS)294` guard on that path. END.OF.DETAILS does the identical thing through BL)3 at `GN)068` (`J/90.05-sample-program.md:949-954`).

Two constraints on IOC)8 follow, neither of them stated anywhere in either manual:

1. **On the AT END exit, BL)n must be left untouched** — still pointing at the last record delivered.
2. **That buffer's storage must stay valid and writable** after end of file, for the rest of the run. Combined with `J 02.07.02`'s "data blocks of a particular file may be located within any of the buffers associated with this or several files", a naïve implementation of dynamic buffer reuse would let a later DETAIL read land on the master's old buffer and be corrupted by this write. The sample depends on that not happening.

And `GN)067 TRA* END.OF.MASTERS` (indirect through the `AXT 0` head cell at 00331) is the DO return — so after `SET M.EMP.NO = HIGH.VALUE` control returns to the word after the GET's `SXA`, i.e. to GN)059/GN)061/GN)065, the code of the next sentence. The end-of-file and not-end paths converge.

End of job is `TXI IOC)40,0`, reached only through END.OF.RUN:

```
00517      0074 00 4 00261   10010            +87     TSX   SYS)177,4
00520      0 00000 0 00001   10010            +88     PZE   IOC)1
00521      0074 00 4 00262   10010            +89     TSX   SYS)178,4
00522      0 01727 0 01726   10101            +90     PZE   CP)+26,,CP)+27
00523      0 01731 0 01730   10101            +91     PZE   CP)+28,,CP)+29
00524      0074 00 4 00261   10010            +92     TSX   SYS)177,4
00525      0 00000 0 00001   10010            +93     PZE   IOC)1
00526      1 00000 0 00050   10010            +94     TXI   IOC)40,0
```
`[J 90.05] listing, PDF p. 204` — `J/90.05-sample-program.md:1056-1063`

Close-all runs **twice** (the source's `CLOSE ALL FILES` and STOP RUN's implicit one).

---

## 6. The language definition's entries

### GET

> "The GET command makes available for processing the next record of an open file. If the file is not open and a GET command is given, the end of file exit is taken. No error message is given" ([J 02.07.04]).

`§6.5` — `/Users/jacklusher/development/comtran-compiler/docs/comtran-language-definition.md:2589`

> **Object-time behavior.** Either form makes the next record available so the entire record or any part may be used; "the previous record of the file is no longer addressable after the execution of a GET command" ([F p. 40]; subject to the HOLD option, under which each named record remains available until another of the same name is input — [J 02.06.05] […]). Automatically provided auxiliary input operations: unblocking, tape alternation, tape identification, error checking, reading ahead ([F p. 39]). At end of tape, "the end-of-tape label is read, and checks are made. The input tape is rewound, and provision is made for an alternate tape unit to be substituted" ([F p. 40]); the secondary unit comes from the SPECIF UNIT2 assignment ([J 02.06.08]).

`§6.5` — `docs/comtran-language-definition.md:2607`

### AT END

> **End-of-file processing.** "The AT END clause which may be used with the GET command may consist of a single imperative statement only. […]" **F/J divergence:** F allows "any imperative clause" and says the clause is performed "after the last record of a file has been made available for processing and a subsequent GET command has been encountered" ([F p. 40]); J restricts the clause to a *single* imperative statement. If the clause is omitted and an end condition is discovered in attempting to GET a record, the result is "immediate termination of execution of the object program; an error message is printed on-line indicating the cause" ([J 02.07.06]).

`§6.5` — `docs/comtran-language-definition.md:2609`

The §8.5.6 ambiguity entry carries the mechanism verbatim, including the IOCS correspondence:

> J's generic GET calling sequence is `TSX IOC)8,4` / `PZE FILENAME,,SYS)260` / `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE` / `IOCDN* BL)2,,14` ([J 90.02.04]); the address field of the third word holds the AT END exit — occupied by SYS)265 […] — while its decrement holds the ON ERROR exit, defaulting to SYS)283 ([J 90.02.32]).

`§8.5.6` — `docs/comtran-language-definition.md:4405`

> the appendix template prints the buffer-pointer line as `IOCDN* BL)2,,14` while the sample listing prints the mnemonic as `IOCTN*` in all four GET sequences (`IOCTN* BL)2,,15` for the three MASTER GETs at 00203, 00225 and 00302, `IOCTN* BL)3,,3` for the DETAIL GET at 00236); both spellings are reproduced as printed.

`§8.5.6` — `docs/comtran-language-definition.md:4411`

### ON ERROR

> For the first three classes, the **ON ERROR statement.name** option of the Environment FILE card "provides for communication between IOCS and the programmer" ([J 02.07.07] […]). "In certain simple error situations such as an unrecoverable redundancy error discovered in a file whose records are complete within the block, the programmer may elect to return directly to the GET command ignoring the error(s) in the unreadable record. This is accomplished by specifying in the ON ERROR clause of the FILE card the procedure.name associated with the GET command" […]. If no ON ERROR provision exists and an IOCS-unrecoverable error occurs, "the system prints an on-line message describing the type of error and the name and certain characteristics of the offending file. Control is then returned to the Commercial Translator Supervisor for processing the next job."

`§6.5` — `docs/comtran-language-definition.md:2620`

And the external-IOCS identification, which is the only place the repo states what the two decrement slots *are* in IOCS terms — **external via the definition (C28-6100-2), not J**:

> IOCS's READ being "`TSX READ,4` / `PZE FILE,,EOB` / `PZE EOF,,ERR` / `IOXY A,,m`" where "FILE is the file designation, EOB is the end of buffer switch, EOF is the end of file exit, and ERR is the error exit" (external: C28-6100-2, PDF p. 23 / printed p. 15) against J's `TSX IOC)8,4` / `PZE FILENAME,,SYS)260` / `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE` / `IOCDN* BL)2,,14` ([J 90.02.04]). The correspondence is word for word, so SYS)260 is the EOB switch and the COMTRAN ON ERROR procedure is IOCS's ERR exit, defaulting to SYS)283 when no ON ERROR is coded ([J 90.02.32]) — *inference* from the two templates […]. The error is resumable: "The error encountered may be ignored by continuing to 'read' the file."

`§8.5.6` — `docs/comtran-language-definition.md:4454`

### File description — BLOCKSIZE, record size, GROUP/ungrouped, BUFFER

> - **BLOCKSIZE nn** — *mandatory.* nn is "the size of the largest block to be output or the maximum number of words to be input from an input block. … All input card files must have a block size of at lease 24 words. Maximum blocksize is 9999 words" ([J 02.06.04]; "at lease" sic). A numeric integer must follow BLOCKSIZE (error 91,00, [J 90.04]).

`§7.1.4` — `docs/comtran-language-definition.md:2986`

> - **HOLD / SPANS** — for an input file, forces the *transmit* mode […] Default ("If neither HOLDS or SPANS is selected" — sic): input processed in the *locate* mode; output created with all records complete within blocks ([J 02.06.05]).

`§7.1.4` — `docs/comtran-language-definition.md:2990`

> | **Buffers** | "The Loader reserves a portion of core storage for use by the I/O system as operating storage. This storage area is subdivided into buffers into which all input blocks of data are read and from which all output blocks of data are written. Since the IOCS routine attempts dynamic optimization of buffer assignments, data blocks of a particular file may be located within any of the buffers associated with this or several files" ([J 02.07.02]). |

`§6.1` — `docs/comtran-language-definition.md:2467`

> Buffer allocation may be steered by POOL cards (files sharing a common buffer area) and GROUP cards (buffer sharing within a pool); absent these, "files will be grouped automatically by IOCS", and absent GROUP specifications "the compiler will attempt to assign at least 2 buffers to each file" ([J 02.06.13], 02.06.14).

`§6.1` — `docs/comtran-language-definition.md:2473`

Record-size limits table: max files 63, max BLOCKSIZE 9999, min card blocksize 24, `*SPEC` blocksize "normally a number (0-999)", PATTERN ≤ 16, ACTIVITY 1-99, **base locators ≈ 127 = the number of located records** — `§6.1`, `docs/comtran-language-definition.md:2477-2487`.

### Locate mode

> - **Locate mode:** GET "'locates' the next record in the file, i.e., determines the position of the record within the buffer area, and … adjusts all program references to data within the record to reflect the new base reference address of the record within the buffer area" ([J 02.07.02]).
> - **Transmit mode:** GET locates the next record and "'transmits' the record to its assigned area. As the area assignment is fixed no adjustment of references to data within the record is necessary" ([J 02.07.02]).

`§6.2` — `docs/comtran-language-definition.md:2495-2496`

> 1. **Base-address adjustment / aliasing.** In locate mode every reference to the record's fields is relative to a base locator updated by GET. "If the locate mode is being used, no references can be made to the record or its fields until after execution of a GET command for that record. All references to fields of a located record initially specify location zero. Upon a GET these references are adjusted to reflect the location of the data within the buffer area. If references are made to located fields prior to the first automatic GET adjustment the low order portions of memory (the monitor) will be irreparably damaged" ([J 02.07.05]).

`§6.2` — `docs/comtran-language-definition.md:2502`

Plus: REDEF forces transmit; REDEF'd records are all made available on one GET; **arrays force transmit in the field test**; constants may not be defined "as a part of a located input area" — `§6.2`, `docs/comtran-language-definition.md:2504-2507`.

---

## 7. F28-8043 on GET, AT END, buffering, and addressing a record in an input area

> Using the input/output commands, the programmer initiates the movement of data into buffers or internal storage, the checking of the validity of the file itself, the checking of the validity of the input or output operation, the storage of data in internal storage to insure its availability when required, and finally, the making available or filing away of data according to the needs of the program. Thus the input/output control system provides data flow control and, where feasible, a "look ahead" at the data flow.
>
> The input/output control system in the Commercial Translator is a record processing system. That is, the unit of data which is made available by the system and on which attention is focused during each processing cycle is the record. Should the needs of the program require that more than one record from a file be made available for processing at one time, it will be necessary for the programmer to provide working storage into which he will move the additional records as required.

`F p. 38` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/F28-8043/03-procedure-description.md:188-201`

> The GET command is used to fetch records from an input storage area which is filled automatically from a file stored on tape or cards. The programmer need be concerned only with the use of single records since all auxiliary input operations such as
>
> - unblocking
> - tape alternation
> - tape identification
> - error checking
> - reading ahead
>
> are automatically provided in the object program by the processor, based on information in the environment description.

`F p. 39` — `F/03-procedure-description.md:252-263`

> Either form of the GET causes the next record to be made available so that the entire record or any of its parts may be used in processing. Note that the previous record of the file is no longer addressable after the execution of a GET command.
>
> To provide for the execution of an alternate command conditional upon end of file, the optional phrase,
>
> ```
> ..., AT END any imperative clause
> ```
>
> may be appended to either form of the GET. A command thus specified is performed after the last record of a file has been made available for processing and a subsequent GET command has been encountered. The programmer should always use the AT END option if the possibility exists of reaching end of file upon execution of the GET.
>
> When the GET command is executed at object time, the following events take place:
>
> 1. The next record of the file is made available for processing.
> 2. If end of tape is reached, the end-of-tape label is read, and checks are made. The input tape is rewound, and provision is made for an alternate tape unit to be substituted.
> 3. If end of file is reached, any alternate command specified in the AT END phrase is performed.

`F p. 40` — `F/03-procedure-description.md:281-305`

F's timing rule ("after the last record of a file has been made available … and a subsequent GET command has been encountered") is the only timing statement in either manual and is the rule D6.6 adopts. Note also that F's "the previous record of the file is no longer addressable after the execution of a GET" is contradicted in spirit by what the sample actually does after EOF (§5 above): it writes into the last record's buffer image long after the EOF exit.

On OPEN filling the area:

> 2. Subsequent records are brought into the portion of storage governed by the input/output control system, filling the area which has been allocated to the file.
> 3. Checking is performed, and a record count is initiated.

`F p. 39` — `F/03-procedure-description.md:231-233`

F's own definition of a record, which is as close as F gets to "addressing a record inside an input area":

> A record is a portion of a file which can be made accessible to the system by the verb GET, assuming the file has previously been "opened." The size and position of a record in storage are determined by the specifications given in the data description. Its contents are referred to by their location in storage, whereas a file, as such, is never actually brought into storage.

`F p. 64` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/F28-8043/04-data-description.md:1465`

And the "input area" discussion, which explicitly disclaims the whole concept:

> For example, when an input record is brought into storage, space must be reserved for the original record before any processing is carried out. This may be thought of as an input area.
>
> Then, after processing begins, it is often necessary to move data from the input area into an area where it can be worked on. […]

`F p. 84` — `F/04-data-description.md:1023-1028`

> The experienced programmer often finds it convenient to distinguish among these various kinds of storage. Actually, of course, all storage areas are controlled by the same basic techniques—data is always addressed by its location, and data in any area may be governed by any of the system's basic operating instructions. Since the Commercial Translator system eliminates the need for the programmer to keep track of specific storage areas, it also eliminates, for the most part, the need to distinguish between types of storage areas. Storage areas are automatically reserved when the data description is written, regardless of how the area is to be used. Certain special provisions, especially those governing input and output, are built into the processor for each system, and these are described in the manuals for the various processors.

`F pp. 84-85` — `F/04-data-description.md:1048-1061`

**F has no concept of locate mode and no base locator.** The word "buffer" appears exactly once in the whole manual (`F p. 38`, quoted above). The `GET` syntax summary is:

```
GET  { RECORD FROM file.name  }
     { record.name            } AT END any imperative clause
```
`F p. 109` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/F28-8043/a2-supplementary-information.md:3706-3707`

---

## 8. J 90.01 (deferred features) and J 90.04 (error messages)

### 90.01 — GET verb restrictions

> **iv GET verb**
>
> Card files processed on-line may only be in BCD and fixed length for field test.
>
> All input records containing arrays will be processed in the transmit mode by the field test processor. This is true for both fixed and variable length records.
>
> Records from different files which have been REDEF'd together will not be automatically transmitted by the field test processor (see 02.07.05 c-ii for description of the feature). SPANS or HOLD must be used.

`J 90.01.01` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.01-deferred-features.md:37-43`

### 90.01 — FILE card restrictions and the object-time check policy

> **ii FILE card**
>
> A maximum of 63 files may be described.
>
> No file check table is produced in the object deck.
>
> CARD, BINARY and locate/transmit mode restrictions are discussed with the GET verb (A.1.a.iv. above).

`J 90.01.04` — `J/90.01-deferred-features.md:125-131`

> No object time check is made to insure that subscript references conform to the limits specified by the array dimensions in the Data Description.

`J 90.01.02` — `J/90.01-deferred-features.md:71`

> Caution if a variable length record is to be processed in the buffer area (located) it cannot be expanded unless each record in the file begins a new block. No check is made for violation of this rule either at compile time or at execute time.

`J 02.07.03` — `J/02-compiler.md:1503`

The house style is: no object-time bounds checking. The only inline object-time trap the compiler emits is `TXL SYS)294,n,0`.

> **d)** Number of base locators (for the field test version this is the number of located records). | 127

`J 90.01.05` — `J/90.01-deferred-features.md:153`

### 90.01 — IOCS module selection

> 4. Normally the MINIMUM module of IOCS is used with the object program. If checkpoints are desired or specified BASIC IOCS is used. If labeling exists the LABELS version of IOCS is necessary.

`J 90.01.05 B` — `J/90.01-deferred-features.md:170`

### 90.04 — the I/O-relevant messages

All are **compile-time**. There is no object-time message list anywhere in J.

> ```
>   5,00     0    RECORD LENGTH 24 OF 'NAME.2' EXCEEDS 'NAME.1' -BLOCKSIZE- 12.
>                     -FILE- CARD MUST HAVE -SPANS-.
> ```
`J 90.04.01` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/90.04-error-messages.md:31-32`

> ```
>  12,00     0    INCORRECT USE OF -GET RECORD FROM-. CANNOT DETERMINE RECORD LENGTH.
>                     CHECK ENVIRONMENT DESCRIPTION.
>  14,00     0    INCORRECT USE OF -GET RECORD FROM-. 'NAME.1' IS NOT AN INPUT FILE.
>                     CHECK ENVIRONMENT DESCRIPTION.
>  23,00     0    INCORRECT USE OF -GET RECORD FROM-. CHECK DATA DESCRIPTION OR ENVIRONMENT DESCRIPTION.
> ```
`J 90.04.01` — `J/90.04-error-messages.md:42-58`

> ```
>  91,00     0    NUMERIC INTEGER MUST FOLLOW -BLOCKSIZE- IN THE -FILE- CARD.
>  92,00     0    STATEMENT OR SECTION NAME MUST FOLLOW -ONERROR- IN THE -FILE- CARD.
>  93,00     0    STATEMENT OR SECTION NAME MUST FOLLOW -FORLABEL- IN THE -FILE- CARD.
>  94,00     0    DATA NAME MUST FOLLOW -PLACE LENGTH IN- IN THE -FILE- CARD.
>  95,00     0    DATA NAME MUST FOLLOW -FIND LENGTH IN- IN THE -FILE- CARD.
> ```
`J 90.04.01` — `J/90.04-error-messages.md:151-155`

> ```
> 106,00     0    STATEMENT OR SECTION NAME MUST FOLLOW -AT END-. CHECK 'NAME.1'.
> ```
`J 90.04.01` — `J/90.04-error-messages.md:170`

> ```
> 117,00     0    -FIND LENGTH IN- OPTION USED WITH SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE
>                     'NAME.1' REFERENCED BY A -GET RECORD FROM-.
> 118,00     0    -PLACE LENGTH IN- OPTION USED WITH SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE
>                     'NAME.1' REFERENCED BY A -GET RECORD FROM-.
> 121,00     0    -BLOCK CONTROL- OPTION USED WITH SOME BUT NOT ALL OF THE RECORDS BELONGING TO THE FILE
>                     'NAME.1' REFERENCED BY A -GET RECORD FROM-.
> ```
`J 90.04.01` — `J/90.04-error-messages.md:183-190`

> ```
> 202,00     0    NUMBER OF DATA GROUPS ASSOCIATED WITH BASE LOCATOR EXCEEDS INTERNAL TABLE CAPACITY.
> 209,00     0    'NAME.1' HAS INSUFFICIENT BLOCKSIZE. BLOCKSIZE USED IS
> ```
`J 90.04.01` — `J/90.04-error-messages.md:291,298`

The object-time side is described only in prose:

> 4. Object program error messages, usually concerning I/O errors. Object-time processing will terminate and control will revert back to the CT Monitor.
>
> The Field Test version of the CT Processor will use the on-line printer for the DISPLAY, STOP statements, and object program error messages. (not SYSOU)

`J 05.06.04` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/05-systems-operation.md:335-337`

**No manual anywhere prints the text of a SYS)260, SYS)263, SYS)264, SYS)265, SYS)283 or SYS)294 message.**

---

## 9. End of file, tape marks, end of reel, multi-reel, and the record-length check

### Record-length errors (the SYS)260 exit)

> **iv Record Length Errors**
>
> Record length errors (referred to as EOB errors in the IOCS manual) generally arise when information in a block does not conform with the blocking conventions described by the programmer in the Environment Description. (Records of an input file which span block boundaries cannot be processed unless the SPANS option is specified).
>
> Record length errors are totally unrecoverable by IOCS or the programmer and cause immediate termination of object program execution. An error message is given on the on-line printer.

`J 02.07.06` — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/02-compiler.md:1587-1591`

This is the condition SYS)260 reports. Because it is unrecoverable, SYS)260 is never a programmer-supplied procedure — consistent with 90.02.28 naming no source option for it.

The related but distinct *output-side* check:

> **SYS)264**
> ```
> TXL     *+5, 1, BLOCKSIZE-1
> TSX     SYS)264, 4
> PZE     FILENAME
> OCT     STATEMENT-NUMBER
> OCT     SUB-STATEMENT-NUMBER
> ```
> When the record size (in IR1) exceeds the Blocksize for the file, SYS)264 prints a message and exits to the CT Monitor.

`J 90.02.29` — `J/90.02-generated-code.md:1619-1629`

And the variable-length BCD length-word conversion, which is the *other* GET-path check:

> **SYS)261**
> ```
> TSX     SYS)261, 4
> TSX     SYS)263, 6
> (Normal Return)
> ```
> Subroutine SYS)261 converts the logical accumulator from a BCD number to binary, checking for non-numeric characters and/or imbedded or trailing blanks; and leaves the result in the decrement of the AC. This routine is used in conjunction with getting a variable length BCD record from tape where the first word of the record gives the remaining length of the record. If an error is detected during conversion, return is 1,4 to routine SYS)263 which prints an error message.

`J 90.02.29` — `J/90.02-generated-code.md:1593-1601`

> **SYS)263** … This subroutine prints an error message in conjunction with SYS)261 upon GET error condition (see SYS)261) and exits to the CT monitor.

`J 90.02.29` — `J/90.02-generated-code.md:1611-1617`

### End of file

> to be taken when the end of a file is reached. A programmer may omit the clause when it is felt no end of file condition will occur with a particular GET. However, when no alternative action is specified through use of the AT END clause, the discovery of an end condition in attempting to GET a record will cause immediate termination of execution of the object program; an error message is printed on-line indicating the cause.

`J 02.07.06` — `J/02-compiler.md:1567`

> If a file has not been OPENed or has been CLOSEd when a FILE command is encountered at execution time, the command acts as a NOP. No error message is given.

`J 02.07.08` — `J/02-compiler.md:1629`

(GET's counterpart is the EOF exit; FILE's is a NOP. Both silent.)

### End of reel / multi-reel

> The secondary unit specification UNIT2 'unit.2', allows for the assignment of the secondary reel of a multi-reel file on another or the same unit which will be automatically referenced upon a reel switch. If UNIT2 is left blank, the secondary unit assignment will be the same as the primary unit.

`J 02.06.08` — `J/02-compiler.md:1086`

> MULTI specifies a tape file which is contained in more than one tape reel. A single reel file is assumed if MULTI is not specified.

`J 02.06.11` — `J/02-compiler.md:1189`

> Use of this option specifies the reel sequence number of the first reel of a file. When the option is not exercised this sequence number is assumed to be 1. Reel sequence number is adjusted at object time to reflect reel switching, and is checked in standard input labels.

`J 02.06.12` (REEL) — `J/02-compiler.md:1224`

> FOR LABEL option provides transfer of control to statement.name.2 whenever a file is opened or closed or whenever a reel switch occurs.

`J 02.06.05` — `J/02-compiler.md:996`

> The usage of the words 'first' and 'second' denotes a multi-reel file with alternating units on which tape switching is performed automatically by that part of the CT Processor which uses the file. If a single physical tape unit is assigned to such files, the operator must perform the necessary mounting of a new tape whenever a reel switch occurs (the first tape will rewind and unload and the unit will be selected again as the second or alternating reel).

`J 06` (systems maintenance) — `/Users/jacklusher/development/comtran-compiler/comtran-manuals/J28-6169/06-systems-maintenance.md:88`

F's end-of-reel description (already quoted at §7): `F p. 40` step 2 (input) at `F/03-procedure-description.md:301-303`; `F p. 41` step 2 (output) at `F/03-procedure-description.md:350-352`.

### Tape marks

The phrase "tape mark" appears in **neither manual**. The nearest attestations:

> 3. Operator messages are written on-line printer. End-of-file marks are put on SYSOU and SYSPP as part of the reel switching operation and through the use of Basic Monitor Control Cards.

`J 05.05.01` — `J/05-systems-operation.md:205`

> **IOC)12** The entry point to the IOCS WRITE-END-OF-FILE subroutine.

`J 90.02.08` — `J/90.02-generated-code.md:348`

> The 'close' options are: […] 4. S — No file mark or trailers, no rewind

`J 03.02.05` — `J/03-loader.md:246`

So "file mark" is the manual's word; the `*SPEC` close code `S` is the only place a file mark is named as something a close either does or skips. **Nothing in either manual says a tape mark is what signals end of file to the READ routine** — that is an IOCS-level fact the manuals delegate ("A knowledge of the 7090 IOCS is necessary", `J 90.02.08`) and D0.9 seals the surviving IOCS source until M7.

---

## 10. `docs/design/decisions.md` — D0.7 and the D6 family

### D0.7 in full

> **D0.7 Files, tape, labels, PATTERN.** I/O is emulated at the IOCS level (external: C28-6100-2). Tape files are binary tape-image files (canonical); the card reader, card punch, and printer surface as deck and print files at the emulator boundary. Labels and PATTERN are modeled inside the emulated IOCS per the definition's Q41/Q45/Q46 annotations and §8.5.6. Detailed decisions land in D6 (I/O) and at M5.

`/Users/jacklusher/development/comtran-compiler/docs/design/decisions.md:253-258`

Constrained by D0.9's seal, which explicitly names IOCS:

> 1. The seal covers the whole recovered archive. It covers source, assembly listings, object files, and every sibling subsystem directory. IOCS is inside the seal, and D0.7 does not exempt it.

`docs/design/decisions.md:305-307`

### The D6 family — index line

> | [D6.1](#d61…) | The PATTERN option — used but never defined | Jack's call |
> | [D6.2](#d62…) | FOR LABEL / LABELN linkage documented only by a missing appendix | Locked |
> | [D6.3](#d63…) | Reopening a file after a named CLOSE | Locked |
> | [D6.4](#d64…) | The printer as a direct FILE target | Locked |
> | [D6.5](#d65…) | GET on an unopened file: silent exit vs terminate-with-message | Locked |
> | [D6.6](#d66…) | AT END: "any imperative clause" (F) vs "a single imperative statement only" (J) | Locked |
> | [D6.7](#d67…) | Short-record blocking and the BEGIN threshold | Locked |

`docs/design/decisions.md:105-111` — the D6 family is exactly D6.1 through D6.7; there are no others.

### D6.1 — PATTERN

> **Decision.** Implement PATTERN as a FILE-card option that declares the repeating sequence of record.names on the file, so the compiler knows each record's successor without control words. PATTERN is the precondition for `GET RECORD FROM file.name`. Accept 1 to 16 record.names, with the attested diagnostics mapped one to one: an empty PATTERN takes msg 48,00 […]; exactly one record.name is accepted and warned with msg 49,00 […]; more than 16 takes msg 50,00 […]. Message severities are unknown […]. The exact keyword syntax is unrecoverable (Open Question 44), so our surface form is an invented, documented and amendable decision: the FILE-card option `PATTERN record.name.1, record.name.2, … record.name.n` […]

> **Implementation.** Lexer/parser: FILE-card option list. Environment/data mapper: per-file pattern table of record.names and their order, consumed by the GET RECORD path in the SYS-IOC runtime for successor selection. Diagnostics: msgs 48, 49, 50 in the roles above, severities ours. --pedantic: no delta […]

`docs/design/decisions.md:941-954` (full record at `:941-954`)

### D6.2 — FOR LABEL / LABELN

> **Decision.** Implement the language surface as defined — FILE-card `FOR LABEL statement.name`, `SPECIF LABELN`, and the LABEL type code redefining the 14-word area IOC)29 — and implement the runtime per the IOCS manual, which Open Question 46 recovers in full. **Attested (Q46, confidence certain):** the five-entry vector at MYLBLS..MYLBLS+4, each entered by `TSX vector+k,1`. Index register 2 holds the 2's complement of the File Control Block address. The label image is passed in the 14-word area, with no parameter words. All index registers used must be saved and restored by the called code. Returns are skip returns through index register 1 (`TRA 1,1`, `TRA 2,1`, `TRA 3,1`) […] **Inference (Q46), not recovered fact […]:** input open = entry 1; output open = entry 3 then 5; input reel switch = entry 2 then 1; output reel switch = entry 4 (`1EORbb`) then 3 and 5; output close = entry 4 (`1EOFbb`); input close = no call. […] Card files: "Labeling is not available for files processed on any on-line card equipment" is attested; that our runtime therefore ignores the exit, with no compile-time diagnostic in default mode, is our decision.

`docs/design/decisions.md:956-967` (full record)

Relevant to GET: **input reel switch calls entry 2 then entry 1**, and entry 2 sets the MQ sign plus = EOR / minus = EOF. That is the only place in the repo where the EOR/EOF distinction gets a mechanism.

### D6.3 — Reopening after a named CLOSE

> **Decision.** Run `CLOSE file.name` through the same IOCS close path as any close, in F's stated order. **Output file:** (1) write any remaining information belonging to the file — the partial block is flushed; (2) write an end-of-file label containing the record count *if labels are specified*; (3) apply the file's close disposition; (4) release the storage area allocated to the file. **Input file:** (1) compare the record count with the count in the end-of-file label if label records are present and end of file has been reached […]; (2) apply the close disposition; (3) release the storage area. The close disposition is the file's \*SPEC close code […] The codes are U rewind and unload (the default when neither is given), R or blank rewind, N no rewind, and S no file mark or trailers and no rewind. […] Marking the File Control Block closed is our design decision. Treat a later OPEN of that file as undefined. […] `FILE` after CLOSE stays a defined no-operation.

`docs/design/decisions.md:969-980` (full record)

Note the collision with §5's finding: close "release[s] the storage area allocated to the file", yet the sample writes through BL)2 after EOF but *before* close, so the release point is close, not EOF.

### D6.4 — The printer as a direct FILE target

> **Decision.** Implement FILE to tape, to cards, and to the system output unit. The demonstrated report path is the default: print-image BCD records FILE'd to tape and listed off-line. One record is one *or more* print lines. RCDMRK-type one-character record marks delimit the lines inside a record. […] A file whose unit assignment is a printer (PRX) or the system output unit (OU) is handled as a print-image file; extending the RCDMRK line-delimiting and first-character carriage-control convention to such a file is our design decision, since J defines no COMTRAN-level semantics (carriage control, line length) for direct on-line printing.

`docs/design/decisions.md:982-993` (full record)

### D6.5 — GET on an unopened file *(the most directly binding record for IOC)8)*

> **Decision.** At object time, a GET on a file that is not open takes that GET's own end-of-file disposition. If the GET carries an AT END clause, execute the clause with no message. If it does not, take the standard no-AT-END path: the terminator routine SYS)265 prints the unexpected-end-of-file message and exits to the CT Monitor. Never emit a diagnostic that is specific to the unopened-file condition, at compile time or at object time.
>
> **Rationale.** J's "the end of file exit is taken. No error message is given." denies a specific unopened-file diagnostic, not the generic no-AT-END termination that [J 02.07.06] states; the generated GET sequence carries exactly one end-of-file exit word, which holds SYS)265 whenever AT END is absent.
>
> **Implementation.** SYS-IOC runtime: the IOC)8 read entry tests the FCB open flag and branches to the end-of-file exit held in the address field of the third calling-sequence word. SYS)265 handler prints the message and exits to the CT Monitor. No compile-time diagnostic. --pedantic: optional non-historical warning when a GET is reachable with no preceding OPEN of that file.
>
> **Oracle.** decision-conformance only (the sample opens every file it reads); the calling-sequence shape it depends on is covered by listing-diff.
>
> *Citations:* ([J 02.07.04]; [J 02.07.06]); Open Question 41 ([J 90.02.04], 90.02.29)

`docs/design/decisions.md:995-1006` (full record)

### D6.6 — AT END

Quoted in full at `docs/design/decisions.md:1008-1019`. The codegen and runtime clauses:

> Codegen: put the AT END exit in the address field of the third word of the GET calling sequence, `PZE END-OF-FILE-PROCEDURE,,ERROR-PROCEDURE`; compile the clause as an out-of-line block placed immediately after the calling sequence, its label planted in that word, and jump over the block with a normal-return `TRA` to the generated label that begins the next sentence's code. `AT END DO x` emits the identical DO triple `AXT *+3,7` / `SXA x,4` / `TRA x+1`, so a returning clause resumes at the sentence after the GET; `AT END GO TO x` emits a one-instruction block. With no AT END, plant SYS)265; with no ON ERROR on the file, plant SYS)283 in the decrement.

`docs/design/decisions.md:1011`

> **Implementation.** […] SYS-IOC runtime: the SYS)265 and SYS)283 handlers. […] Reproduce the printed mnemonic spellings as they stand (`IOCDN*` in the appendix template, `IOCTN*` in the listing).

`docs/design/decisions.md:1015`

> **Oracle.** listing-diff (statements 188, 190, 191 and 194; object locations 00200–00207, 00222–00231, 00233–00240, 00277–00306; [J 90.05] listing, PDF pp. 201–202); decision-conformance only for the bare-name and non-transfer clauses.

`docs/design/decisions.md:1017`

### D6.7 — Blocking

> **Decision.** Implement blocking as arithmetic, with no threshold rule. Pack records into BLOCKSIZE-word blocks in order. A record must be complete within one block, so if the room left in the current block is smaller than the next record, start a new block. Two records that are each longer than half the blocksize can therefore never share one block; a single record longer than half the blocksize may still sit second in a block when the room left is large enough (J's own Example 1 packs REC3, 192 words, together with a 64-word REC1 in a 256-word block). A record described with BEGIN always starts a new block. No special rule keys off the 10-word or 20-word figures in the 90.05 note.
>
> **Implementation.** Data mapper and Environment (BLOCKSIZE, BEGIN per record), SYS-IOC runtime (blocking on output, deblocking on input), and the compiler's buffer sizing and base locators (BL)n). […] Interacts with SPANS for records that exceed BLOCKSIZE; that case is Open Question 48 and is out of this unit.

`docs/design/decisions.md:1021-1032` (full record)

**"deblocking on input" is the IOC)8 side of D6.7 and is the only place the design states it.**

### Other decisions mentioning buffer / locate / GET / IOCS / IOC)

- **D7.3 — Who assigns the default BUFFERCOUNT.** Quoted in full at `docs/design/decisions.md:1066-1077`. Key: *"(b) When no GROUP specifications are made at all, the compiler attempts to assign at least 2 buffers to each file […] (c) For a GROUP with no BUFFERCOUNT, the loader attempts to assign at least twice the OPENCOUNT number of buffers […] Our CT Loader must implement rule (c), including the activity-based fallback."* Oracle: *"neither the \*FILE card […] nor the \*SPEC card […] carries a buffer-count field, so no oracle covers default buffer counts"* (`:1075`).
- **D7.1 — \*SPEC blocksize "(0-999)" vs Environment maximum 9999.** *"Honor Environment FILE BLOCKSIZE values up to 9999 words. […] Read the Loader manual's 'normally a number (0-999)' ([J 03.02.05]) as a typographical slip for (0-9999)."* — `docs/design/decisions.md:1036-1039`
- **D4.3 — Invalid characters in a numeric field at object time.** Its §8.5 backing text distinguishes the GET-path conversion check (SYS)261/263) from MOVPAK data handling — `docs/comtran-language-definition.md:4383`.
- **D4.1 (rounding)** cites SYS)265 and SYS)283 only as the model for how the appendix writes inclusion conditions — `docs/design/decisions.md:636`.
- **D10.8** covers "the mandatory BLOCKSIZE, and the 63-file tally" — `docs/design/decisions.md:1715`.
- **D8.6** covers the 90.08 density-table print error — `docs/design/decisions.md:1286`.

---

## 11. `docs/design/runtime.md` — RT-1, the off-by-one, and `resume`

### RT-1 in full

> ## RT-1. The machine
>
> `lib/src/runtime/machine.dart` holds the machine, its result and outcome types, the three faults of `RunFault`, and the run's file table. `Machine` writes a `LoadedProgram` into a fresh `MachineState`, enters at the program's entry point (D2.1), and runs. The file table is one control block per `*FILE` card, and `m5-io.md` M5-3 holds its design.
>
> ### The addresses
>
> The machine resolves every system reference to its own 15-bit code ([J 90.03.05]). `SYS)n` and `IOC)n` both take address n. A file reference k takes address 2048 + k. The runtime area is therefore addresses 0 to 4095.
>
> The 1962 listing attests the rule for the entries. `TSX SYS)175,4` assembles as `0074 00 4 00257`, and 0257 octal is 175 ([J 90.05] listing, LOC 00165). `TXI IOC)40,0` assembles as `1 00000 0 00050`, and 050 octal is 40.
>
> `SYS)n` and `IOC)n` share one number space. The object deck marks both with reference type `0000` and carries no discriminator ([J 90.03.05]). The two ranges do not collide ([J 90.02.07]):
>
> - 1 to 127 is a monitor-resident Type 1 entry.
> - A number above 127 is a Type 2 entry the loader brings in.
>
> **The program loads at address 4096. Design decision.** No manual states an origin. 4096 is the first address above the runtime area, so one comparison separates a runtime entry from the program's own text. The 90.05 sample then holds addresses 4096 to 5031, and its entry point is 4213.
>
> ### The dispatch rule
>
> The CPU core does not execute the runtime library (`emulator.md` §1; D0.3). The machine therefore decides before each instruction:
>
> - An address below 4096 is a runtime entry. The machine runs the Dart handler registered for it.
> - Every other address is the program's own text. The machine calls `Cpu.step()`.
>
> **A handler reads its calling sequence through index register 4 and returns to the parameter-word count plus one (M4-17).** `Machine` supplies both operations, and `MachineState` supplies everything else.
>
> Registration is a map merge. `monitor.dart` returns the run frame, and each later family returns its own entries in the same shape.
>
> ### The run loop and its outcomes
>
> `Machine.run` takes a step budget and returns a `RunResult`: the outcome and the display lines. A step is one instruction or one runtime entry, so the budget bounds every run. Three outcomes end a run:
>
> | Outcome | What produced it |
> | `endOfJob` | IOC)40, "the end of job return point" ([J 90.02.09]) |
> | `errorExit` | SYS)294, which "exits back to the CT Monitor" ([J 90.02.33]) |
> | `stepLimit` | The budget ran out |
>
> **The budget belongs to the caller, and an exhausted budget is not an error. Design decision.** […]
>
> ### The unimplemented-entry rule
>
> An address below 4096 with no handler throws `UnimplementedRuntimeEntry`. The exception names the entry: `SYS)` above 127 and `IOC)` at or below it, per the Type 1 and Type 2 ranges of [J 90.02.07]. A handler that meets work it does not do throws the same exception with a reason.
>
> The M4 to M5 boundary is this, in one line. The 90.05 sample calls open-all, which opens its seven files (RT-2). It then fills its work areas through MOVPAK (RT-3) and reaches IOC)8, the GET, which throws. M5 stage 2 lands that entry.
>
> ### What exercises the runtime
>
> `comtranc --run` loads and runs each job whose deck the compiler punched […] An unimplemented entry prints the display lines the run produced, then its message, and fails the run.
>
> `endOfJob` alone leaves the exit status at 0. An error exit and an exhausted budget each fail the job. […]
>
> ### The stage-4 set and what waits
>
> M4-17 charters about 130 runtime entries. Stage 4 built the entries an I/O-free program reaches, and no others:
>
> | the run frame (RT-2) | SYS)175, 177, 178, 294, and IOC)40 |
> | the MOVPAK entries (RT-3) | SYS)180 and SYS)182 |
> | the non-edited members (RT-4) | SYS)184, 239, 240, 241, 243, 244, 245, 268, 269, 275 |
> | the edited family (RT-5) | SYS)185, 190, 193, 198, 211, 212, 214, 216, 225, 226, 267 |
>
> That is 28 handlers, plus the four cells RT-2 names: SYS)132, SYS)133, IOC)1 and IOC)29.

`/Users/jacklusher/development/comtran-compiler/docs/design/runtime.md:10-119`

**The rule for which runtime entries land when** is the sentence at `:42-46` of `m5-io.md`, which cites RT-1: *"each remaining entry lands with the code-generator shape that first emits it. CLAUDE.md section 11 bans a handler that no test asserts on and no run reaches. It permits a tested handler with no caller on a recorded plan."* IOC)8 is the entry RT-1 explicitly names as M5 stage 2's target.

### "The off-by-one" and `resume`

> ### The off-by-one
>
> The entry leaves the instruction counter on the family head word. The entry does not execute that word. The CPU executes it next.
>
> A step handler runs with the cursor on its own `TXI` word, never on the next word. Each handler does this, in order:
>
> 1. Check that a session is open, and that the cursor word's address field names this entry. Either failure is a broken object program, so the handler throws a Dart error. This is not a D4.3 data condition, which never throws.
> 2. Take the count from index register 1, then clear that register.
> 3. Advance the cursor by one word plus the data words.
> 4. Read the data words it owns. It never executes them.
> 5. Do the work, then set the instruction counter to the cursor.
>
> ### The word shapes
>
> `c` is the cursor when the handler runs. Index register 1 is 0 at every resume, except SYS)267.
>
> | Shape | Members | Data words | Resume | Ends the move |
> |---|---|---|---|---|
> | bare step | 193, 198, 211, 212, 214, 216, 268, 269 | 0 | c+1 | no |
> | head and control word | 185, 190 | 1 | c+2 | no |
> | terminator | 225, 226, 275 | 0 | c+1 | yes |
> | one-word convert or mover | 184, 239, 243, 244 | 0 | c+1 | yes |
> | mover pair, first word | 240 | 0 | c+1 | no |
> | mover pair, last word | 241 | 0 | c+1 | yes |
> | fill with characters | 245 | 1 | c+2 | yes |
> | edited store | 267 | 1 | c+2 | yes |
>
> The sample attests the resume of each shape it carries. `TXI SYS)225,1,5` at LOC 00611 is followed by `CLA 3)HOURS` at 00612. `TXI SYS)245,1,6` with its `OCT 747474747474` at 00346 is followed by `TRA* END.OF.MASTERS` at 00350 ([J 90.05] listing).
>
> A handler that owns a data word reads it after the advance, at `cursor - 1`. SYS)267 owns one `OCT` word there and reads its `AXT` word at `cursor`.

`docs/design/runtime.md:286-326`

> ### The register contract
>
> - A MOVPAK entry or member writes index register 1 only, and leaves it 0. SYS)267 is the exception […]
> - Index register 2 must survive a call. `_assignRegister` hands out registers 1 and 2 and refuses a third […]
> - **Index register 4 must survive the link the `TSX` wrote. Every resume address is computed from it.**
> - **The run frame of RT-2 and the IOCS calls take a full cache clear after them, so they may write any register. That licence stops at MOVPAK.**

`docs/design/runtime.md:346-357`

The last two bullets are the ones that bind IOC)8: IR4 must survive (which is also what the `TXH` statement-stamp finding of §1 requires), and IOC)8 is licensed to clobber IR1 and IR2 because the code generator clears its register cache across an IOCS call.

The GET-specific application is already written down:

> **M5-5. The calling sequences are fixed, and the resume counts with them.** GET carries three parameter words and FILE carries two […]. The machine's `resume` takes the parameter count plus one, as it does for the MOVPAK entries (`runtime.md` RT-3, "The off-by-one"). **GET therefore resumes four words on, and FILE three.**
>
> GET has four exits and the sequence names three of them:
>
> | Exit | Where it is | What the sample plants |
> | normal | four words on | a `TRA` over the AT END block |
> | AT END | address of parameter 2 | the out-of-line clause (D6.6) |
> | ON ERROR | decrement of parameter 2 | SYS)283 at every site |
> | record length | decrement of parameter 1 | SYS)260 at every site |
>
> SYS)265 stands in the AT END field where the source gives no clause. Our generator refuses that shape, so no site plants it (M4-15 as amended). A GET on a file that is not open takes this GET's own AT END exit and prints nothing (D6.5).
>
> The `IOCTN*` word names a base locator and a record extent. The handler writes the address of the record into that locator, and the program then reads the record through it ([J 90.02.04]). That is locate mode, and it is why the buffer must live in core. **Where the buffer lives is stage 2's first decision, and this record does not take it.**

`M5-5` — `/Users/jacklusher/development/comtran-compiler/docs/design/m5-io.md:184-209`

---

# Gaps — what the manuals do NOT answer

Everything below must be labelled as our design decision, not recovered fact.

## About the calling sequence and the `IOCTN*` word

1. **What `IOCDN`/`IOCTN` stands for, and what its prefix-5 / tag-6 flag bits mean.** The octal is `5 00017 6 01667`; no manual decodes a single bit of it. It is the only place locate-vs-transmit, BCD-vs-binary, or a "first GET" flag *could* be encoded, and neither manual says. (`J/90.02-generated-code.md:171`; `J/90.05-sample-program.md:810`)
2. **Whether the decrement is a maximum, an exact length, or a request.** Appendix says 14, sample says 15 and 3. It is clearly "record length in words", but whether IOC)8 uses it to *check* the record it found (the record-length/SYS)260 test) or merely to *advance* its read position is nowhere stated.
3. **Whether IOC)8 must preserve IR4 into its three exits.** Required by the `TXH` statement-stamp inference (§1) but not stated. Likewise whether it may clobber IR1/IR2/IR7.
4. **The exact SYS)260 trigger.** "information in a block does not conform with the blocking conventions" (`J 02.07.06`) is not an algorithm. Specifically unresolved: what happens when the remainder of a block is non-zero but shorter than the requested record; whether a short final block is an error or a short delivery.
5. **Whether the `TXH` marker convention is what I decoded it to be.** The CP-cell decode is conclusive for statement numbers, but nothing in J states that the terminators read it, nor at what offset from IR4.

## About the buffer

6. **Where the buffer lives, how large it is, and how many exist per file.** `J 03.03.01` gives an approximate core region; `*FILE`/`*SPEC` carry no buffer field; `*POOL`/`*GROUP` carry counts but the sample punches neither. M5-5 explicitly leaves this open (`docs/design/m5-io.md:209`).
7. **What BL)n holds after the AT END exit fires.** The sample *requires* it to be unchanged and the buffer still writable (§5), but no manual sentence says so.
8. **Buffer lifetime and reuse across files.** `J 02.07.02`'s "dynamic optimization of buffer assignments … within any of the buffers associated with this or several files" is exactly the licence that would break the sample's post-EOF write. The safe rule (never recycle a buffer that a live BL) points at, until close) is ours.
9. **The 12-word IOCS File Control Block layout.** Named twice (`J 90.02.08`; `J 03.03.02`), tabulated nowhere.
10. **Whether the BL) decrement is always zero on input.** `J 90.02.05` says input records use "simple" base locators (BYTE = 0) and the sample does byte arithmetic on the word (`CAL BL)2 / ACL CP)+45`), so it must be — but that is our inference, not a stated rule.

## About end of file and blocks

11. **What physically signals end of file.** "Tape mark" appears in neither manual. The `*SPEC` close code `S` says "no file mark", IOC)12 is WRITE-END-OF-FILE — that is the entire evidence.
12. **End of file vs end of reel on an unlabeled MULTI file.** With no label there is no end-of-reel label to read (`F p. 40` step 2 assumes one). How IOCS distinguishes them on an unlabeled multi-reel tape is unstated. D6.2 gives an *inferred* mapping via FOR LABEL entry 2's MQ sign, which only exists for labeled files.
13. **A second GET after EOF has already been taken.** Undefined in both manuals. The sample never does it.
14. **Short last block / block longer than BLOCKSIZE.** The DETAILFILE case proves a 14-word block is read as 3 words with no error (`J 90.05.03`), so blocks longer than BLOCKSIZE are silently truncated. Whether a block *shorter* than one record's worth is a SYS)260 error or a short delivery is not stated.
15. **Deblocking arithmetic on input.** D6.7 gives output blocking as arithmetic; the input inverse ("deblocking on input", `docs/design/decisions.md:1028`) has no manual statement at all.

## About message texts and diagnostics

16. **The printed text of every object-time message.** SYS)260, 263, 264, 265, 283, 291, 294 are each described ("prints an error message indicating …") and none is quoted. `J 05.06.04` only says they go to the on-line printer. Every string we emit is invented.
17. **Whether the messages carry the file name, the statement number, or both.** SYS)264's sequence carries `PZE FILENAME / OCT STATEMENT-NUMBER / OCT SUB-STATEMENT-NUMBER`; the GET terminators carry none of their own.

## About other GET shapes we do not yet emit

18. **The transmit-mode GET calling sequence.** `J 02.07.02` describes the semantics; no template for it is printed anywhere. Field test forces transmit for any array-bearing record (`J 90.01.01`), so real programs hit it.
19. **The `GET RECORD FROM file.name` calling sequence,** and how PATTERN reaches the runtime. D6.1 invents the syntax; the object-code shape is unknown.
20. **Where SYS)261/SYS)263 sit inside a variable-length GET.** `J 90.02.29` gives their calling sequence but never places it relative to the `TSX IOC)8,4`.
21. **What replaces SYS)283 when a file *does* declare ON ERROR**, and how the ON ERROR procedure returns to resume the read. `J 02.07.07` says the programmer may name the GET's own procedure to retry; the mechanism of "return directly to the GET" is not given. (M4-15 currently refuses this shape — `docs/design/m4-codegen.md:857-863`.)
22. **The card-reader GET (`SYS)287`/`SYS)286`/`SYS)288`) end-to-end.** The template exists (`J 90.02.32`); when SYS)286 is called relative to IOC)8, and who invokes it, is not stated.

## Structural

23. **`J 90.08.01` says the `*FILE` file-name field is columns 54-72; `J 03.02.02` says 55-72.** Unreconciled.
24. **IOCS behaviour beyond what `docs/` already quotes is ours by construction.** `J 90.02.08` opens with "A knowledge of the 7090 IOCS is necessary in understanding most of the IOC Numbers", and D0.9 seals the surviving IOCS source until M7 — explicitly including IOCS, which D0.7 "does not exempt" (`docs/design/decisions.md:307`). Anything in `comtran-language-definition.md` §8.5.6 sourced to C28-6100-2 is **external via the definition**, not J.
