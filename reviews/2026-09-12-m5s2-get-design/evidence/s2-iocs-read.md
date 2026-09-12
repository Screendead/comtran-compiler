# IBM 709/7090 IOCS (C28-6100-2) — locate-style reading of a blocked tape file

**Correction to earlier project notes, up front:** the FCB diagram is at **PDF p. 73 / printed p. 65** (Appendix A's first page), not PDF 75 / printed 67 — PDF 74–76 are the word-by-word detail. The glossary runs **PDF pp. 83–86 / printed pp. 75–78**, not 83–85 (WRITE, TRUNCATE, UNBUFFERING, SKIP, TRANSMIT are on printed 78). The EOF pages (PDF 34 / printed 26) and the abnormal-conditions table (PDF 79 / printed 71) are exactly where the notes said.

---

## 1. Table of contents — where everything lives

From the Contents (external: C28-6100-2, PDF pp. 5–7 / printed pp. i–iii, unnumbered). Printed page → PDF page is +8 throughout.

| Topic | Printed p. | PDF p. |
|---|---|---|
| Buffer Definition (Introduction) | 1 | 9 |
| File Processing / File Closing (Introduction) | 2 | 10 |
| **Section 1: The Data File** | 3 | 11 |
| **Section 2: Buffer and Buffer Pool Definition** | 4 | 12 |
| **Section 3: File Initialization** | 6 | 14 |
| — Attachment of Immediate Files | 6 | 14 |
| — Attachment of Reserve Files | 7 | 15 |
| — Attachment of Internal Files | 7 | 15 |
| — File List | 7 | 15 |
| — **Opening Reserve Files** (OPEN) | 9 | 17 |
| **Section 4: File Processing** | 10 | 18 |
| — IOCS Commands | 10 | 18 |
| — Transmitting Commands (IOCP/IOCT/IOCD, IORP/IORT, IOSP/IOST, TCH) | 11–12 | 19–20 |
| — **Non-transmitting Commands** (IOCPN/IOCTN/IOCDN, IORPN/IORTN, IOSPN/IOSTN) | 13–14 | 21–22 |
| — **IOCS Routines: READ** | **15** | **23** |
| — **WRITE** | **16** | **24** |
| — History Records | 17 | 25 |
| — Transfer of Data: COPY, STASH | 18 | 26 |
| — **CLOSE** | 18 | 26 |
| — WEF / REW / BSR / BSF | 19–20 | 27–28 |
| Section 5: Labels and Labeled File Procedures | 21 | 29 |
| **Section 6: Unlabeled File Procedures** (single-reel p. 26, multi-reel p. 26, multi-file reels p. 26) | **26** | **34** |
| Section 7: Reserve Group Option | 27 | 35 |
| — **Using More than one Buffer for a File** | 28 | 36 |
| Section 8: Use of the Internal Group | 30 | 38 |
| Section 13: Program Preparation — Storage Conventions, **References to System Subroutines** | 38 | 46 |
| — **File Control Blocks / File Block / Unit Control Blocks** | 40–41 | 48–49 |
| Part II: Example of the Use of IOCS (Buffer Pools 49, Processing Master Files 50, Transaction Files 51, **End of File** 51–52, **Variable Length Records** 53) | 47–53 | 55–61 |
| **Appendix A: FILE CONTROL BLOCK FORMAT** | **65** | **73** |
| Appendix B — Preservation of File Lists / File Position After File Closing / Backspace File / **Use of Copy When "Reading" with Transmitting Commands** | 69 | 77 |
| — Re-use of a Buffer Pool / Joining Pools / **Actions of IOCS Routines Under Abnormal Conditions** | 70–71 | 78–79 |
| — **IOCS Command Execution Tables** | 72–73 | 80–81 |
| **GLOSSARY** | **75** | **83** |
| INDEX | 79 | 87 |

**On "locate" vs. "move".** The manual never says "locate mode" or "move mode." There is no mode bit on a file and no mode word in the calling sequence. The dichotomy is **transmitting** (`IOXY`) vs. **non-transmitting** (`IOXYN`) *commands*, and non-transmitting commands do either **locating** or **skipping** depending on one word of the READ calling sequence. "Move" does not appear anywhere; the manual's word for the transmitting style is **TRANSMIT**. Glossary entries exist for LOCATE, TRANSMIT, SKIP, NON-TRANSMITTING COMMANDS (printed 76–78).

*Settles:* the COMTRAN `READ` handler must not look for a mode flag — it selects locate or move per call, in the command list it builds.

---

## 2. The READ routine, verbatim and in full

### 2.1 The calling sequence

> **READ** — Words are transmitted from, or located within, the buffers by the sequence
>
> ```
>         TSX     READ,4
>         PZE     FILE,,EOB
>         PZE     EOF,,ERR
>         IOXY    A,,m          ⎫
>                               ⎬ IOCS command list
>                               ⎭
> ```
>
> where
>   FILE is the file designation,
>   EOB is the end of buffer switch,
>   EOF is the end of file exit, and
>   ERR is the error exit.
>
> The command list is terminated by the first IOXT, IOCD, IOXTN or IOCDN command encountered.

(external: C28-6100-2, PDF p. 23 / printed p. 15)

There are **only two fixed words** after the TSX. There is no record-count word, no record-address word, no working-storage word. Everything else is an inline IOCS command list of arbitrary length whose commands IOCS itself rewrites.

`READ` is not a fixed absolute address; it is defined relative to the IOCS origin:

> ```
> IOCS    EQU     L
> DEFINE  EQU     IOCS+4
> JOIN    EQU     IOCS+6
> ATTACH  EQU     IOCS+8
> CLOSE   EQU     IOCS+10
> OPEN    EQU     IOCS+12
> READ    EQU     IOCS+14
> WRITE   EQU     IOCS+16
> COPY    EQU     IOCS+18
> REW     EQU     IOCS+20
> WEF     EQU     IOCS+22
> BSR     EQU     IOCS+24
> BSF     EQU     IOCS+26
> CKPT    EQU     IOCS+28
> STASH   EQU     IOCS+30
> MWR     EQU     IOCS+38
> ```
> The actual location corresponding to symbolic location IOCS may vary from installation to installation. For any installation, however, this location and those defined relative to it, as shown above, can be expected to remain fixed, even when modifications are made to the IOCS system itself.

(external: C28-6100-2, PDF p. 46 / printed p. 38)

*Settles:* IOC)8's READ entry is `TSX IOCS+14,4` — a two-word header plus a caller-owned, caller-modified command list; linkage is index register 4.

### 2.2 The three exits and the EOB switch

> 1. EOF is the location to which transfer is made when an end of file condition occurs. For a labeled file, the condition is recognized from the trailer label. For an unlabeled file, any EOF mark is recognized as end of file. For any file, recognition of the EOF mark suspends buffering, so that there is no information for the file in any buffer when the EOF exit is taken. Buffering will be restarted when the next READ (if any) is given for the file.
>
> 2. ERR is the location to which transfer is made when any of three types of error conditions occur: (a) a redundancy which cannot be corrected; (b) check sum error (binary file); and (c) sequence error. The condition is recognized at the first reference to a buffer in which it occurs. The error encountered may be ignored by continuing to "read" the file.
>
> 3. The end of buffer switch (EOB) is interrogated each time the end of a buffer is reached, regardless of whether a transmitting or non-transmitting command is being executed.
>
>     a. If EOB = 0, truncation of the buffer and automatic transition to the next one occur; command execution continues without interruption.
>
>     b. If EOB ≠ 0, all information located will be retained until the next reference to the file by any IOCS routine. Further, since information located by a *single* IOCS command must be in sequential cells, the execution of a count command interrupted by the end of buffer condition is discontinued, and EOB itself is used as the exit of transfer address. Otherwise, transition to a new buffer is automatic, and the interpretation of the command sequence continues.
>
> Non-transmitting commands may be freely intermixed with transmitting commands in any command sequence. However, since the EOB switch is set on or off by each entry into the READ or WRITE routines, skipping and locating cannot be done by the same sequence.

(external: C28-6100-2, PDF p. 24 / printed p. 16)

And the selector rule, stated on the command side:

> IOCS determines whether a non-transmitting command is intended to locate or to skip information, in accordance with the end of buffer (EOB) switch specified in the calling sequence for READ and WRITE. If EOB = 0, the command is interpreted as a skip, and if EOB ≠ 0, it is interpreted as an attempt to locate information. The EOB switch is interrogated when the end of a buffer is reached.

(external: C28-6100-2, PDF p. 21 / printed p. 13)

*Settles:* **the second word of the READ calling sequence is the locate/move switch.** `PZE FILE,,0` = move (transmit, or skip); `PZE FILE,,<nonzero addr>` = locate. And one READ call cannot mix skipping with locating.

Note the trap: in every example in the manual, EOB is set to *the instruction after the command list* — e.g. `PZE MAITRE,,PROSS` where `PROSS` is the next instruction, and `PZE TRANS,,W3+1`. So a genuine EOB exit lands at the **same place as the normal return**, and the handler can only distinguish the two by inspecting the MQ prefix (see §2.5).

### 2.3 How the address of the next logical record is delivered

> Data can be processed within the buffers by not transmitting the data at all, but by *locating* it instead. Words are "located" in the buffers by using IOXYN commands.
>
> In most cases, the IOXYN commands operate exactly like the corresponding IOXY, commands except that no words are transmitted. The location of the processed words is instead filled into the address of that IOCS command. As in example 1 above, one could use
>
> **IOCTN \*\*,,26**
>
> and IOCS would replace \*\* with the location of that record in an input buffer.

(external: C28-6100-2, PDF p. 21 / printed p. 13)

The generic rule, from the command-format section:

> 5. A is the address of the first word processed. If the command specifies transmission (not an IOXYN type), the address A is supplied by the programmer. If the command is non-transmitting, the system supplies the location of the next available word in the buffer. Normally, the location replaces the address of the command. However, if the non-transmitting command is indirectly addressed, the location of the next available word replaces the address of the cell specified in the address of the IOCS command.
>
> 6. m is the number of words processed. This is normally supplied by the programmer; however, if buffer control is used for "reading," the count is supplied by the system.

(external: C28-6100-2, PDF p. 19 / printed p. 11)

Indirect addressing is computed specially:

> 4. \* is used, if appropriate, to specify that the address A is indirect. *The effective address computation is performed as though all the index registers contained zero.*

(external: C28-6100-2, PDF p. 19 / printed p. 11)

Per-command detail for the count-control non-transmitting group:

> **Count Control — IOCPN, IOCTN, IOCDN**
> ```
>         IOCYN   **,,m
> ```
> *READ* — The next m words of the file are located or skipped, and the location of the first of these replaces the \*\* in the command. IOCDN, in addition, sets an indicator that will cause the buffer to be truncated the next time the file is referred to.

(external: C28-6100-2, PDF pp. 21–22 / printed pp. 13–14)

> **Buffer Control — IORPN, IORTN**
> ```
>         IORYN   **,,**
> ```
> *READ* — The location of the next data word from the file replaces the address of the command, and the count (m) of the remaining available words is inserted into the decrement. The next reference to the file will cause the m located words to be bypassed.

(external: C28-6100-2, PDF p. 22 / printed p. 14)

> **Special Count Control — IOSPN, IOSTN**
> ```
>         IOSYN   **,,m
> ```
> *READ* — Words in the buffer are skipped until either m words have been located, or the end of the buffer is reached. The address \*\* is replaced by the location of the first of the words located.
>
> The actual number of words skipped over is reflected in the History Record (see page 17).

(external: C28-6100-2, PDF p. 22 / printed p. 14)

Worked examples of the delivery mechanism:

> 1. Suppose an entire block from a given input file is to be located. Then the command
>
>     **IORTN \*\*,,\*\***
>
>     should be used. When an exit is taken from the READ routine the command would have been changed to
>
>     **IORTN RECORD,,n**
>
>     where RECORD is the location of the next block of the file and n is the length of the block.
>
> 2. Suppose the next word of a file is to be placed into the accumulator. Then the following command could be given:
>
>     **IOCTN\*    CLAI,,1**
>
>     where CLAI is the symbolic location of some particular CLA instruction. The CLA would be modified as follows:
>
>     ```
>     before READ:   CLAI    CLA     **
>     after  READ:   CLAI    CLA     LOC
>     ```
>
>     where LOC is the location of the desired word.
>
> 3. Suppose it is desired to locate space in an output buffer in which to create a variable length output record. The command
>
>     **IOSTN \*\*,,MAX**
>
>     will locate an area of MAX number of words, and the location of that area will replace \*\*. […] he must subsequently inform IOCS of the actual number of words placed in the located area by means of a skipping command such as
>
>     **IOCTN \*\*,,ACT**

(external: C28-6100-2, PDF p. 23 / printed p. 15)

**A second delivery channel — fixed cells near the IOCS origin.** This is the closest thing to "returns it in a cell":

> | Location Symbol | Position Relative to Location IOCS | Contents |
> |---|---|---|
> | LTRAD | IOCS + 64 | The last history word loaded into the AC: Prefix: PZE. Decrement: 1 + the location of the last word processed. Address: Count of words remaining in the last buffer used. |
> | TRANS | IOCS + 65 | Address: Location of the first word processed by the last IOCS command |
> | WDCT | IOCS + 66 | Decrement: Word count of last IOCS command executed |
> | IRS | IOCS + 67 | Address: Contents of index register 2 at last entry to IOCS. Decrement: Contents of index register 1 at last entry to IOCS |
> | SENSE | IOCS + 68 | Contents of Sense Indicators at last entry to IOCS. |
> | FCW | IOCS + 69 | Address: If = 0, IOCS was not in control. If ≠ 0, this is the current file being used |

(external: C28-6100-2, PDF p. 48 / printed p. 40)

*Settles:* the located record address arrives **in the caller's own command word** (self-modification of the READ command list), optionally redirected into an arbitrary cell via `IOCxYN* CELL,,m`, and is additionally readable from `IOCS+65` (address field) for the *last* command only. It never arrives in an index register — the manual's idiom is that the program then loads it itself (`PROSS LAC IO1,1`, see §3.3).

### 2.4 Stepping through blocked records within a block

> The transmitting commands, as the name implies, cause movement of information between buffers and working storage. The execution of each IOCS command, of course, depends upon the previous commands executed. **In general, each file is treated as a continuous string of words. For example, if thirteen words were "read" by one IOCS command, the next command given for the file will start to "read" the 14th word, etc.**

(external: C28-6100-2, PDF p. 19 / printed p. 11)

The position itself is not held in the FCB; it is held in the first control word of the buffer currently in use:

> When a buffer is being used by a file, the available word locator contains the following: bits 21-35, the location of the next available word; bits 3-17, the number of available words. When a buffer is not in use by any file, the first word contains the address of another buffer in the pool which is not in use (this is the *Chain Address*.) If there are no more available buffers in the pool, the Chain Address will be the location of the first Buffer Pool Control Word.

(external: C28-6100-2, PDF p. 13 / printed p. 5)

> **AVAILABLE WORD LOCATOR** — The first word of each buffer, to keep track of the location of the next available word and the number of available words remaining in the buffer.

(external: C28-6100-2, PDF p. 83 / printed p. 75)

Rules governing locate across buffers:

> 1. In "reading," words located by an IOXYN command are considered used when the file is next referenced by any IOCS routine. Hence, the buffer in which the words were located is retained until then.
>
> 2. In "writing," the space located for output words is considered filled when the file is next referred to by any IOCS routine. Hence, it is not written until then.
>
> 3. No single command is allowed to locate words in more than one buffer.
>
> 4. A sequence of commands may locate words in more than one buffer if sufficient buffers have been allocated to that file by defining a Reserve Group which consists of that file only.

(external: C28-6100-2, PDF p. 21 / printed p. 13)

*Settles:* there is no record counter and no "step to next record" call. Stepping is implicit — the file is one word stream, each IOCS command consumes the next m words, and the FCB/buffer pair remembers the cursor. A blocked file of 100 5-word records is read by giving 5-word non-transmitting commands, one per record, or by re-entering READ.

### 2.5 What the routine returns, and where

> **HISTORY RECORDS** — When the normal exit from the READ or WRITE routine occurs, a record of action, similar to the record produced by a Store Channel instruction, is supplied, as explained below. This "history record" is provided to supply the user with information concerning the last IOCS command that was executed. The count of the remaining words in the buffer can be used to create future IOCS commands or to make other logical decisions. The investigation of the last word "read" or "written" may be necessary to determine what the command actually did, as in the case of IOST in reading, where the count specified may not have been satisfied because the end of the buffer was encountered.
>
> Similarly, IORY, in writing, may not write the specified number of words if it encounters the end of buffer condition.
>
> At each exit from the READ or WRITE routines the AC will contain the following:
>
> | Bits | Contents |
> |---|---|
> | 3–17 | Number of usable words remaining in the buffer which contained the last word "read," or the number of unused words in the buffer containing the last word "written." |
> | 21–35 | 1 plus the location of the last word transmitted. |
>
> If an end of buffer, an end of file, a sequence error, a check sum error, or a redundancy which cannot be corrected occurs while reading, or an end of buffer occurs while writing, the following information is provided:
>
> | Register | Bits | Contents |
> |---|---|---|
> | AC | 3–17 | The 2's complement of the quantity (1 plus the location of the command being executed when the condition was encountered). |
> | AC | 21–35 | 1 plus the location of the last word "read" or "written." |
> | MQ | 3–17 | The 2's complement of the location of the TSX to the READ or WRITE routine. |
> | MQ | 21–35 | Location of the normal return from the IOCS routine. |
>
> In addition, when a redundancy, check sum, or sequence error occurs during reading, the MQ will contain:
>
> 6 – if check sum and redundancy errors occurred.
> 5 – if sequence and redundancy errors occurred.
> 4 – if a redundancy occurred which could not be corrected.
> 2 – if a check sum error occurred (see page 33).
> 1 – if a sequence error occurred.
>
> The order in which these errors are detected is: check sum, block sequence, and redundancy. If all three checks are being made on a file, the occurrence of only a redundancy error is probably a *false* redundancy error, as the check sum is correct; however, the user must realize that check sums are not a foolproof check.

(external: C28-6100-2, PDF p. 25 / printed p. 17)

> When an EOB exit occurs during either reading or writing, the prefix of the MQ will be:
>
> 4 – if all available buffers are in use.
>
> 2 – if the end of buffer condition was encountered during execution of an IOCYN.

(external: C28-6100-2, PDF p. 26 / printed p. 18)

*Settles:* the AC is a two-field history word — remaining-words count in the decrement, one-past-last-word in the address. On an abnormal exit MQ 21–35 holds the normal return, so a runtime handler that shares an exit label with the normal return can reconstruct which case it is. **Nothing is returned in an index register.**

### 2.6 Where READ returns to

The normal return is **not** a fixed offset from the TSX. It is the word after the first terminating command:

> The command list is terminated by the first IOXT, IOCD, IOXTN or IOCDN command encountered.

(external: C28-6100-2, PDF p. 23 / printed p. 15)

> **TCH** — The command list continues at location A. The exit from an IOCS routine is to the location after the first TCH command in the list.

(external: C28-6100-2, PDF p. 20 / printed p. 12)

### 2.7 WRITE, briefly

> **WRITE** — Words are transmitted to, or space for words is located within, the buffers by the sequence:
>
> ```
>         TSX     WRITE,4
>         PZE     FILE,,EOB
>         IOXY    A,,m          ⎫
>                               ⎬ IOCS command list
>                               ⎭
> ```
>
> The command list must be terminated by an IOXT, IOCD, IOXTN or IOCDN command. The EOB switch functions exactly as described under READ.

(external: C28-6100-2, PDF p. 24 / printed p. 16)

*Settles:* WRITE has **no EOF/ERR word** — its header is two words, not three. This asymmetry matters for the handler's stack layout.

### 2.8 The formal execution table for READ

The definitive specification. Legend first:

> where
>   B — the location in the current buffer of the first available word
>   m — the number of available words in the current buffer
>   C — the location of the first word in the next buffer
>   s — the size of all buffers in the pool
>
> In the tables which follow, the general form of the IOCS command executed is:
>   **IOXY  A,,N**  or  **IOXYN  \*\*,,N**
> where
>   A — the location in working storage to be "read" into or "written" from
>   N — the number of words to be processed
>
> Indirect addressing of commands is not shown, however, it may be specified for all IOCS commands except TCH.
>
> In the two tables there are several actions indicated for buffer release or truncation, these are:
>
> **Hold** — the end of the buffer was passed, however, it will not be released to the pool (READ) or written (WRITE) until next reference to the file, because it contains words located by this READ or WRITE sequence.
>
> **Conditional Hold** — the buffer will go into HOLD status if some IOXYN command were executed on it during the current READ or WRITE sequence.

(external: C28-6100-2, PDF p. 80 / printed p. 72)

**Execution of IOCS Commands Read — LOCATE half (EOB ≠ 0)** (external: C28-6100-2, PDF p. 81 / printed p. 73):

| IOCS Command | changed to | History Record in AC | Words Read | Buffer Release Action | EOB exit |
|---|---|---|---|---|---|
| `IOCYN **,,n`  n≤m | `IOCYN B,,n` | `PZE B+n,,m−n` | n | no | no |
| `IOCYN **,,n`  n>m | `IOCYN B,,n` | `PZE B+m,,0` | m | Hold | code 2 |
| `IOCDN **,,n`  n≤m | `IOCDN B,,n` | `PZE B+n,,m−n` | n | Hold | no |
| `IOCDN **,,n`  n>m | `IOCDN B,,n` | `PZE B+m,,0` | m | Hold | code 2 |
| `IOSYN **,,n`  n≤m | `IOSYN B,,n` | `PZE B+n,,m−n` | n | no | no |
| `IOSYN **,,n`  n>m | `IOSYN B,,n` | `PZE B+m,,0` | m | no | no |
| `IORYN **,,**` | `IORYN B,,m` | `PZE B+m,,0` | m | Hold | no |

**SKIP half (EOB = 0), same table:**

| IOCS Command | changed to | History Record in AC | Words Read | Buffer Released |
|---|---|---|---|---|
| `IOCYN **,,n`  n≤m | `IOCYN B,,n` | `PZE B+n,,m−n` | n | no |
| `IOCYN **,,n`  n>m | `IOCYN C,,n` | `PZE C+n−m,,s−n+m` | n | 1st |
| `IOCDN **,,n`  n≤m | `IOCDN B,,n` | `PZE B+n,,m−n` | n | yes |
| `IOCDN **,,n`  n>m | `IOCDN C,,n` | `PZE C+n−m,,s−n+m` | n | both |
| `IOSYN **,,n`  n≤m | `IOSYN B,,n` | `PZE B+n,,m−n` | n | no |
| `IOSYN **,,n`  n>m | `IOSYN B,,m` | `PZE B+m,,0` | m | no |
| `IORYN **,,**` | `IORYN B,,m` | `PZE B+m,,0` | m | yes |

**Transmitting half (EOB = 0)**, for contrast:

| IOCS Command | changed to | History Record in AC | Words Read | Buffer Released |
|---|---|---|---|---|
| `IOCY A,,n`  n≤m | — | `PZE A+n,,m−n` | n | no |
| `IOCY A,,n`  n>m | — | `PZE A+n,,s−n+m` | n | 1st |
| `IOCD A,,n`  n≤m | — | `PZE A+n,,m−n` | n | yes |
| `IOCD A,,n`  n>m | — | `PZE A+n,,s−n+m` | n | both |
| `IOSY A,,n`  n≤m | — | `PZE A+n,,m−n` | n | no |
| `IOSY A,,n`  n>m | — | `PZE A+m,,0` | m | no |
| `IORY A,,**` | `IORY A,,m` | `PZE A+m,,0` | m | yes |

[uncertain] The two `IOSYN` "changed to" cells in the SKIP half and the exact `s−n+m` vs `s−n+m` sub/superscripts are at the limit of the scan's legibility; the arithmetic is self-consistent as transcribed but verify against a second scan before hard-coding.

*Settles the decisive difference:* under **transmit** (EOB = 0), n > m simply continues into the next buffer (`A+n`, first buffer released). Under **locate** (EOB ≠ 0), n > m delivers **only m words**, sets the history to `PZE B+m,,0`, holds the buffer, and takes the **EOB exit with MQ prefix code 2**. A locate never crosses a block.

---

## 3. Buffering

### 3.1 How many buffers a file gets, and from where

> I/O areas, referred to as *buffers*, must be defined for use by IOCS. The efficiency which can be obtained in the overlapping of processing and input/output is directly related to the assignment of buffer areas and the size of each individual buffer.

(external: C28-6100-2, PDF p. 9 / printed p. 1)

> a. *Attachment* of the file to previously defined buffer area(s). IOCS differs from most buffering systems in that the file is attached to buffers rather than buffers being attached to the file. In fact, several files will normally be attached to the same group of buffer areas, called a *Buffer Pool*. Because of this feature, a buffer within a pool can be used at different times by different files. IOCS adjusts the number of buffers used for each file according to the relative volume of data in the file and the frequency of use.

(external: C28-6100-2, PDF p. 9 / printed p. 1)

> A *buffer* is an area used for intermediate storage of input/output data. Buffers are used by IOCS to hold an input block until it can be processed and to hold an output block until it can be written. It is analogous to the IN-OUT box found on most office desks. […]
>
> A *buffer pool* is a group of buffers connected so that a file using the pool can use any of the available buffers for holding information. Of course, two files cannot use the same buffer at the same time. Normally, the size of each buffer in a pool will correspond to the size of the blocks in the files using that pool.
>
> Every *buffer pool* has two control words which serve to control usage of the buffers within the pool. In addition, the first two words of each *buffer* are control words; one is used to keep a record of the status of information within the buffer, and the other serves as a machine I/O command when the contents of the buffer are to be written, or a block is to be read into the buffer. Thus, if N is the maximum number of words a buffer is to hold, and if the pool is to consist of M buffers, the programmer must reserve M(N+2)+2 cells. For example, to reserve space for a pool of eight 30-word buffers, the following symbolic instruction could be used:
>
> **POOL      BSS      8\*30+8\*2+2**
>
> The structure of a buffer pool is set up by:
> ```
>         TSX     DEFINE,4
>         PZE     POOL
>         PZE     M,,N
> ```
> This calling sequence defines the area beginning with symbolic location POOL as a pool of M buffers, each of effective size N, with the first buffer pool control word having symbolic location POOL. All further references to this pool are specified by referring to the symbolic location POOL.

(external: C28-6100-2, PDF p. 12 / printed p. 4)

Minimum buffer requirements per file type:

> 1. *Input files (I)* — each input file requires at least one buffer at all times.
> 2. *Partial block output files (P)* — this type of file permits writing of any number of machine words regardless of buffer size. Each type P file requires at least one buffer.
> 3. *Total block output file (T)* — this type of output file requires writing of exact number of physical blocks each time it is referred to by a WRITE sequence. As this type of file does not withhold a buffer from the pool except when the file is in use, all files of this type could use the same buffer at different times. Thus, all type T files which use one pool require only one buffer.

(external: C28-6100-2, PDF p. 14 / printed p. 6)

To guarantee more than one buffer, a file must be its own Reserve Group:

> If a file is being used in such a way as to withhold more than one buffer at a time from a pool, then it must be treated as a Reserve Group (by itself) and the buffer requirements expressed by a sufficiently high count.

(external: C28-6100-2, PDF p. 36 / printed p. 28)

> It is clear that this procedure will require the use of no fewer than five buffers by the file at all times. Actually, IOCS would try to use at least ten, for at each entry to the READ routine, when the five buffers just processed are released to the pool, minimum delay (that is, maximum overlap) occurs if the next five have already been filled and are waiting to be located. If, however, ten are not available — either because there are not ten in the pool, or because other files are using them — the system can still operate properly as long as there are at least five available to the file. This condition can be guaranteed only by an attachment of the form:
> ```
>         SVN     1,,M
>         PZE     FILE
> ```
> with M not less than 5.
>
> Finally, it should be noted that if the programmer had erred and written:
> ```
>         SVN     1,,3
>         PZE     FILE
> ```
> then the EOB exit would have been taken after execution of the third IORPN\*, and this would occur even if, at that particular time, a buffer were available in the pool for use by another file. IOCS control forces this action, since otherwise some file might later be unable to obtain a buffer. **In this usage, EOB is to be interpreted as "end-of-available-buffers."**

(external: C28-6100-2, PDF pp. 36–37 / printed pp. 28–29)

The multi-buffer locate idiom itself:

> ```
>         TSX     READ,4
>         PZE     FILE,,EOB
>         PZE     EOF,,ERR
>         IORPN*  R1,,**
>         IORPN*  R2,,**
>         IORPN*  R3,,**
>         IORPN*  R4,,**
>         IORTN*  R5,,**
> ```
> In this READ usage, since EOB ≠ 0, the non-transmitting IOCS commands locate the initial address of each card buffer. Since indirect addressing is used, these addresses are placed by IOCS into the addresses of the words located at R1, R2, R3, R4, and R5, respectively. If, then, these words were
> ```
> R1      AXC     **,4
> ```
> then the Nth word in any of the buffers can be referenced by first executing the appropriate instruction at location R₁, and then executing:
> ```
> OP      N,4
> ```

(external: C28-6100-2, PDF p. 36 / printed p. 28)

*Settles:* IOC)8 gets **one** buffer per input file by default, and IOCS decides how many more. To hold two blocks at once (necessary if a COMTRAN record group can straddle a block boundary), the file must be attached as a one-file Reserve Group with an explicit `SVN 1,,M` count.

### 3.2 Buffer size vs. block size; blocking; spanning; truncation

> **BUFFER SIZE** — The maximum number of data words which a buffer can hold. This restricts output blocks to that maximum length and determines the maximum number of words which can be read from an input block.
>
> **BLOCK** — A physical record; that is, a tape record, a card, or a line of print.
>
> **BLOCKING** — The arrangement of data into blocks whose size is convenient and efficient for processing.
>
> **UNBLOCKING** — The separation of blocked data into its data groups.

(external: C28-6100-2, PDF pp. 83, 86 / printed pp. 75, 78)

Buffer size must include the overhead word when a file carries a check sum / sequence number:

> 501 words are needed for each buffer in the BIGBUF pool because the master files have block check sums and sequence numbers. (This extra word will be automatically bypassed by the system routines, and the programmer will never be aware of it again unless an error occurs.)

(external: C28-6100-2, PDF pp. 57–58 / printed pp. 49–50)

Logical records versus blocks:

> A logical record may consist of one word, several words, an entire block (one physical record of the external storage media, i.e., a card, a tape record, or a line of print), more than one block (e.g., all of one block and part of another), or several blocks. The form of each logical record may be the same as, or different from, the preceding one. **The definition of the logical record is expressed implicitly in the user's choice of IOCS commands and not explicitly by any definition to the system.**

(external: C28-6100-2, PDF p. 11 / printed p. 3)

**Spanning.** The manual never uses the word "spanned"; it uses "overlaps" and "span":

> Clearly, locating words within the buffers adds restrictions to file design and to the IOCS command sequences. For example, **one cannot locate a logical record that overlaps a physical block, since the record will not occupy consecutive memory cells.**

(external: C28-6100-2, PDF p. 21 / printed p. 13)

> […] assuming also that a record will not span a block, the master file is now read by: […]

(external: C28-6100-2, PDF p. 61 / printed p. 53)

> Writing is accomplished with special count control to insure that records do not cross a block gap.

(external: C28-6100-2, PDF p. 62 / printed p. 54)

**Truncation.** The manual has no "BEGIN." Its word is TRUNCATE:

> **TRUNCATE** — To ignore any remaining words in a processed buffer and release it from a file; for an input file, the buffer is made available; for an output file, action is initiated to write the contents of the buffer on that file's I/O unit.
>
> **DISCONNECT (buffer)** — To release a processed buffer from a file.
>
> **UNBUFFERING** — The process of adjusting the physical position of a tape to correspond to its logical position. For an output file, all buffers in use are truncated, and a delay occurs until all writing ceases. For an input file, all buffers in use are returned to the pool, and the tape is positioned to a point following the block corresponding to the buffer which contained the last word "read."

(external: C28-6100-2, PDF pp. 84, 86 / printed pp. 76, 78)

> D — Terminate the command list and truncate any attached buffer. **When an input buffer is truncated, the remainder of the block is discarded.** When an output buffer is truncated, the size of the block written is equal to the number of data words in the buffer, which need not be the same size as the buffer.

(external: C28-6100-2, PDF pp. 18–19 / printed pp. 10–11)

*Settles:* an input `IOCD`/`IOCDN` throws away the rest of the block. A COMTRAN handler must terminate blocked-file READ lists with `IOCTN`, never `IOCDN`, or it loses the remaining records in the block.

### 3.3 The update-in-place idiom (read a record in place, write it out from the same buffer)

The manual demonstrates this twice. First, per-record, from Part II. The read:

> The old master file is read by the sequence:
> ```
>         TSX     READ,4          READ OLD MASTER FILE
>         PZE     MAITRE,,PROSS   LOCATING:
>         PZE     NONE,,TILT
> IO1     IOCPN   **,,5           MASTER ACCOUNT RECORD
> IO2     IOCPN   **,,5           ACCOUNT DETAIL, CODE 1
> IO3     IOCPN   **,,5           ACCOUNT DETAIL, CODE 2
> IO4     IOCPN   **,,5           ACCOUNT DETAIL, CODE 3
> IO5     IOCPN   **,,5           ACCOUNT DETAIL, CODE 4
> IO6     IOCTN   **,,5           ACCOUNT DETAIL, CODE 5
> PROSS   LAC     IO1,1           BEGIN PROCESSING WITH
>                                 MASTER ACCOUNT RECORD.
> ```
> When PROSS is reached, each of the commands IO1-IO6 will have the address of the first word of the corresponding record type for the current account.

(external: C28-6100-2, PDF p. 58 / printed p. 50)

And the write-back, straight out of the same input buffers:

> When the account group is to be written on the new master file, all that is needed is:
> ```
>         TSX     WRITE,4         WRITE ON NEW MASTER, TRANS-
>         PZE     NEWMR           MITTING EACH RECORD FROM ITS
> OUT1    IOCP*   IO1,,5          LOCATION IN THE INPUT BUFFERS.
>         IOCP*   IO2,,5
>         IOCP*   IO3,,5
>         IOCP*   IO4,,5
>         IOCP*   IO5,,5
>         IOCT*   IO6,,5
> ```
> Since the indirect effective address is computed *without index registers*, the non-transmitting bits in the tags of the commands IO1-IO6 have no effect.

(external: C28-6100-2, PDF p. 59 / printed p. 51)

Second, whole-buffer, with the count passed through:

> The completion is carried out by:
> ```
> NOMORE  TSX     CLOSE,4         CLOSE TRANSACTION, ERROR,
>         PZE     LIST2,,3        AND HISTORY FILES WITH
> *                                 REWIND-UNLOAD
>         TSX     WRITE,4         PUT OUT THE CURRENT
>         PZE     NEWMR           ACCOUNT RECORD
>         TCH     OUT1
> FIND    TSX     READ,4          LOCATE WORDS
>         PZE     MAITRE,,DUPE+1  REMAINING IN READ
>         PZE     END,,TILT       BUFFER
> DUPE    IORTN   **,,**
>         CLA     *−1             SET UP WRITE SEQUENCE
>         STD     FILL
>         TSX     WRITE,4         TRANSMIT INFORMATION FROM
>         PZE     NEWMR           INPUT TO OUTPUT BUFFERS
> FILL    IOCT*   DUPE,,**
>         TRA     FIND
> END     TSX     CLOSE,4         CLOSE MASTER FILES WITH
>         PZE     LIST1,,2        REWIND-UNLOAD
> ```
> The first write, at NOMORE + 2, writes the account records which had previously been located. The loop from FIND to FILL+1 copies the remainder of the old master file onto the new master file. When an end of file is reached on the old master file, the close at END writes the trailer label and rewinds and unloads the files. **This use of record control for the read location and count control for the write transmission completely eliminates the problem of adjusting for the fact that the old and new master file records may be in different positions within the block.**

(external: C28-6100-2, PDF p. 60 / printed p. 52)

The mixed transmit-plus-locate call, which is exactly the "key fields to working storage, body located in place" pattern:

> The transaction file is read by the sequence:
> ```
>         TSX     READ,4          READ TRANSACTION FILE TRANS-
>         PZE     TRANS,,W3+1     MITTING ACCOUNT NUMBER
>         PZE     NOMORE,,REDUN   AND CODE TO WORKING
>         IOCP    WORD1,,2        STORAGE, AND LOCATING
> W3      IORTN   **,,**          THE REMAINDER OF THE RECORD.
> ```
> Since the sequence ends with a non-transmitting buffer control command, the entire transaction record is available in the buffer. In addition, the account number and type code are in cells WORD1 and WORD1 + 1, ready for some conversion routine. The address of the command in location W3 has the buffer location of the data fields for this transaction.

(external: C28-6100-2, PDF p. 59 / printed p. 51)

The no-copy alternative, COPY:

> Information which was located by the last I/O command sequence on the input file FILE1, may be transferred to the output file FILE2 without actual word transmission by:
> ```
>         TSX     COPY,4
>         PZE     FILE1,,FILE2
> ```
> The rules for information transfer with COPY are:
>
> 1. All words in the same buffer with, and preceding, the first word located are included in the output.
> 2. All words in the same buffer with, and subsequent to, the last word located are not included in the output; furthermore, they will behave as if skipped when FILE1 reading is resumed.
> 3. If more than two buffers are involved, an intermediate buffer is included in the output provided at least one word within it has been located by a non-transmitting command.

(external: C28-6100-2, PDF p. 26 / printed p. 18)

> **COPY** — The IOCS routine which transfers data from an input file to an output file by connecting processed input buffers to that output file.

(external: C28-6100-2, PDF p. 84 / printed p. 76)

And the transmit-then-copy interaction:

> 2. Even if all of the words in a buffer are transmitted to working storage, the buffer is still connected to the file unless the last word was "read" with an IOCD or IORY command. The transmitted words can then be copied. For example, if the block is "read" by
>     **IOCT     WS,,BLOCK-SIZE**
> it may be copied. If, however, the block is "read" by
>     **IORT     WS,,\*\***
> it cannot be copied, because the IORT command has disconnected the buffer from the file.

(external: C28-6100-2, PDF p. 78 / printed p. 70)

Finally, the consequence of closing a file mid-buffer:

> When a file is closed, whether at the end of file position or not, it is always unbuffered, so that its physical position corresponds to the last logical usage of the file. Note, however, that in the case of an input file, information in a partially processed buffer may be lost if the file is closed and then reopened, because the tape will be positioned beyond the block which occupied this buffer.

(external: C28-6100-2, PDF p. 77 / printed p. 69)

*Settles:* a partially consumed input buffer is **held** (not released) as long as the last READ located words in it; it is released on the *next* reference to the file by any IOCS routine, and it is lost entirely if the file is closed.

---

## 4. End-of-file behaviour

### 4.1 Unlabeled single-reel and multi-reel

> **Section 6 — Unlabeled File Procedures**
>
> Although the handling of labeled files is entirely automatic, IOCS is equally capable of processing unlabeled files. The difference is that multi-reel file handling is only semi-automatic for unlabeled files, since the occurrence of the EOF mark can have several meanings.
>
> **Single-Reel Unlabeled Files**
>
> An unlabeled file which is contained on one reel of tape may have any number of EOF marks. The detection, during reading, of each EOF mark temporarily suspends buffering on that reel. When an EOF is detected by the READ routine, the EOF exit is given. If the file is again referred to by a READ calling sequence, buffering will continue until the next EOF mark is encountered. It is the programmer's responsibility, in this case, to determine which EOF mark signifies the actual end of the file. No reel switching is possible for input files of this type. If EOT is encountered while writing a supposedly single reel unlabeled file, a reel switch will occur and processing will continue. In some instances, such as peripheral output files, no harm occurs from this action. However, if the file is to be processed by IOCS at a later time, the file is not describable. (It is a multiple-reel file with more than one EOF mark on a reel, a situation which is not allowable.)
>
> **Multi-Reel Unlabeled Files**
>
> A multi-reel unlabeled file may have only one EOF mark — that which signifies the end of the reel. This EOF mark is written automatically when the EOT reflective spot is sensed while writing. Reel switching occurs after the EOF is written. When an EOF mark is detected while reading a multi-reel unlabeled file, all buffering is suspended until the EOF record is reached. An EOF exit is given once per reel for each EOF encountered and if the file is again referenced by a READ operation, reel switching will occur and buffering will be resumed. For this type of file, the user must have a recognizable data record to indicate that the end of the file has been reached.

(external: C28-6100-2, PDF p. 34 / printed p. 26)

### 4.2 What the EOF exit means for the read in progress

> 1. EOF is the location to which transfer is made when an end of file condition occurs. For a labeled file, the condition is recognized from the trailer label. For an unlabeled file, any EOF mark is recognized as end of file. **For any file, recognition of the EOF mark suspends buffering, so that there is no information for the file in any buffer when the EOF exit is taken.** Buffering will be restarted when the next READ (if any) is given for the file.

(external: C28-6100-2, PDF p. 24 / printed p. 16)

> **EOF (end of file)** — An address, specified in the calling sequence to the READ routine, which is used as an exit upon recognition of an end of file condition.

(external: C28-6100-2, PDF p. 84 / printed p. 76)

*Settles decisively:* **when the EOF exit is taken, every located address from the previous READ is stale.** No buffer holds data for the file. A COMTRAN handler must not let user code touch the "current record" after EOF. It also means the EOF exit is not "the read succeeded and then hit EOF" — the read in progress delivered nothing for this call.

Multi-reel unlabeled files require the *program* to decide the file is over; IOCS will keep switching reels for as long as READs keep coming.

The manual's own worked example of the two-file EOF race:

> When the transaction tape is depleted of records, the READ sequence will exit to the routine at location NOMORE. That routine will handle the case of an end of file on the transaction file before the old master has reached end of file; the routine at NONE will handle the case where end of file occurs first on the old master file.

(external: C28-6100-2, PDF p. 59 / printed p. 51)

---

## 5. File Control Block layout

> **Appendix A: File Control Block Format**
>
> The 12 words which make up a File Control Block are arranged as follows:

Diagram, word by word (external: C28-6100-2, PDF p. 73 / printed p. 65):

| Word | S / left half (S,1,2,3–17) | right half (18,19,20,21–35) |
|---|---|---|
| 1 | (shaded) UCW2 | (shaded) UCW1 |
| 2 | Control bits | bits 21–27 Number of Buffers in logical use ; bits 28–35 Number of Buffers ahead |
| 3 | Entry point for non-standard label image routines | **Location of buffer in use; if none, location of buffer pool** |
| 4 | Block count for sequence check | Location of group control word if reserve or internal file |
| 5 | Location of buffer pool | Sync chain, or request chain at end of tape condition |
| 6 | Number of erases if output, or of permanent redundancies if read | Number of corrected redundancies on the current reel |
| 7 | File Serial Number (all 36 bits) | |
| 8 | Reel Sequence Number | |
| 9 | Retention Days | |
| 10 | File Name (first six characters) | |
| 11 | File Name (second six characters) | |
| 12 | File Name (last six characters) | |

> The details of these twelve words are given below. Items marked with an asterisk are generated in the File Control Block by the Preprocessor. The remaining positions are initially zero.

**Word 1** (external: C28-6100-2, PDF p. 73 / printed p. 65):

> | Bits | Contents |
> |---|---|
> | S\* | Mounting flag secondary unit (operator has been instructed to mount a reel on the secondary unit). |
> | 1–2 | Unused. |
> | 3–17\* | Unit Control Block for secondary unit. If no secondary unit is used, this is the same as bits 21–35. |
> | 18\* | Mounting flag, primary unit (operator has been instructed to mount a reel on the primary unit). |
> | 19–20 | Unused. |
> | 21–35\* | Unit Control Block for primary unit. Note: If this is an Internal File, the first word is of the form: `PZE CHAIN,,0` where CHAIN = L(0) if no chain exists. |

**Word 2 — the flag word** (external: C28-6100-2, PDF pp. 74–75 / printed pp. 66–67):

> | Bits | Contents |
> |---|---|
> | S\* | Mixed mode file: 0 – No; 1 – Yes |
> | 1–2\* | Checkpoint control: 00 – No checkpoints initiated by this file. 01 – Checkpoints are to be written on the checkpoint file at the beginning of every reel of this file. 10 – Checkpoints are to be written on this file at the beginning of every reel of the file (labeled output files only). |
> | 3 | 0 – File is not open. 1 – File is open. |
> | 4 | 0 – Not a Reserve file. 1 – Reserve file. |
> | 5 | 0 – File is inhibited. 1 – File is not inhibited. |
> | 6\* | Mode: 0 – BCD; 1 – Binary |
> | 7–8\* | File type: 00 – Input file; 01 – Partial block output file; 10 – Total block output file; 11 – Checkpoint file |
> | 9\* | Label: 0 – No; 1 – Yes |
> | 10–11\* | Block sequence and check sums: 00 – No block sequence words. 10 – Block sequence word is present, no check sums. 11 – Block sequence word is present, check sums are present (input) or are to be computed (output). |
> | 12\* | Reel control flag: 0 – Single reel file, if unlabeled; no label search, if labeled. 1 – Multi-reel file, if unlabeled; search for label on open, if labeled |
> | 13 | Has a buffer been released: 0 – No; 1 – Yes |
> | 14 | Has a rush occurred for this buffer: 0 – No; 1 – Yes |
> | 15 | End-of-tape: 1 – No; 0 – Yes |
> | 16 | File permanently closed: 0 – No; 1 – Yes |
> | 17 | Has a rush occurred in this sequence: 0 – No; 1 – Yes |
> | 18\* | Density of label to be read: 0 – Low; 1 – High |
> | 19\* | Label density to be written: 0 – Low density; 1 – High density |
> | 20\* | File density: 0 – Low density; 1 – High density |
> | 21–35 | Count of Read buffers, or Output file chain — 21–27 Number of buffers in logical use; 28–35 Number of buffers ahead |

**Words 3–6** (external: C28-6100-2, PDF pp. 75–76 / printed pp. 67–68):

> | Word | Bits | Contents |
> |---|---|---|
> | 3 | S | Regenerative Internal file if S = 1 |
> | 3 | 1–2 | Unused. |
> | 3 | 3–17 | Location of entry point for standard or non-standard label image routines. |
> | 3 | 18–20 | Unused. |
> | 3 | **21–35** | **Location of the control word for the buffer or buffer pool to be used with this file.** |
> | 4 | S\* | File control: 0 – Regular file; 1 – Internal file |
> | 4 | 1–2 | Unused. |
> | 4 | 3–17 | **Counter for block sequence checking.** |
> | 4 | 18–20 | Unused. |
> | 4 | 21–35 | Location of the Reserve Group control word, if this is a Reserve file. |
> | 5 | S\* | List control: 0 — List this FILE card; 1 – Do not list this FILE card. |
> | 5 | 1–2 | Unused. |
> | 5 | 3–17 | **Location of the Buffer Pool.** |
> | 5 | 18–20 | Unused. |
> | 5 | 21–35\* | Buffer synchronization chain or location of zero cell (end of chain); Buffer request chain at end of tape condition. |
> | 6 | S, 1–2 | Unused. |
> | 6 | 3–17 | Count of erase areas on the current output reel, or of permanent redundancies on the current input reel. |
> | 6 | 18–20 | Unused. |
> | 6 | 21–35 | Number of corrected redundancies for the current reel. |
> | 7 | All\* | File serial number in the form bXXXXX. |
> | 8 | All\* | Reel sequence number in the form bXXXXb. |
> | 9 | All\* | Retention days: bbbXXX. |
> | 10–12 | All\* | File name in BCD. |

Note the wording differs between the diagram and the detail table for word 3 bits 21–35 ("Location of buffer in use; if none, location of buffer pool" vs. "Location of the control word for the buffer or buffer pool to be used with this file"). Both are quoted above.

Programmer-side reservation and the prohibition on touching it:

> Twelve locations must be reserved for each IOCS file, these being reserved by BSS instructions such as:
> ```
> MASFIL          BSS     12      MASTER FILE
> DETFIL          BSS     12      DETAIL FILE
> ```
> Of these, the first six are used for control information of the file, and the last six for labeling information. **In no case should any information be loaded into these locations by the object program**, since they are used by the Preprocessor to store information generated from FILE cards.

(external: C28-6100-2, PDF p. 11 / printed p. 3)

> IOCS requires twelve words — a File Control Block — for control information pertaining to each file to be processed using the system. **All references to a particular file in an object program are made by referring to the first word of the File Control Block of that file.**

(external: C28-6100-2, PDF p. 9 / printed p. 1)

> If L is the File Block origin, the origin of File Control Block K is L+12(K−1).

(external: C28-6100-2, PDF p. 49 / printed p. 41)

> 5. At each TSX, index register 2 will contain the 2's complement of the location of the first word of the File Control Block for the file being processed.

(external: C28-6100-2, PDF p. 33 / printed p. 25 — stated for the non-standard-label callback, not for READ's caller)

*Settles, and this is the biggest surprise for the handler design:* **the FCB contains no current-record pointer, no block size, and no record count.** It has word 3 bits 21–35 pointing at the *buffer control word*, and the cursor (`next available word`, `available word count`) lives in that buffer's first control word. Block size lives in N from `DEFINE` and in each buffer's second control word (`IORT *+1,,N`). The only counter in the FCB is word 4 bits 3–17, a block-sequence counter, not a record counter. A COMTRAN runtime that wants a per-file "current record address" must keep its own cell — the FCB will not hold it.

---

## 6. Glossary entries

All from (external: C28-6100-2, PDF pp. 83–86 / printed pp. 75–78).

> **BLOCK** — A physical record; that is, a tape record, a card, or a line of print.

> **BLOCKING** — The arrangement of data into blocks whose size is convenient and efficient for processing.

> **BLOCK COUNT** — The number of blocks processed on the current reel of a file, kept in the corresponding File Control Block.

> **BUFFER** — An area assigned for IOCS to use as an intermediate storage area for data which are to be transmitted between storage and the input/output devices.

> **BUFFER CONTROL** — The control used by a class of IOCS commands which treat all, or the remainder, of a buffer as a data group.

> **BUFFER POOL** — A group of equal sized buffers connected in such a way as to permit sharing of buffers among a group of files.

> **BUFFER SIZE** — The maximum number of data words which a buffer can hold. This restricts output blocks to that maximum length and determines the maximum number of words which can be read from an input block.

> **AVAILABLE BUFFER** — A buffer not presently in use nor reserved for later use.

> **AVAILABLE BUFFER COUNT** — The number of currently available buffers in a pool, kept by IOCS for each buffer pool.

> **AVAILABLE WORD LOCATOR** — The first word of each buffer, to keep track of the location of the next available word and the number of available words remaining in the buffer.

> **AVAILABLE WORDS** — Those words in an input buffer which have not yet been "read," or, in an output buffer, which have not yet been filled with data.

> **CONNECTED BUFFER** — A buffer currently in use by a file.

> **LOGICAL RECORD** — Data which, as a group, has some logical significance to the user.

> **READ** — The IOCS routine which, by direction of IOCS commands, "reads" input data from a file.

> **WRITE** — The IOCS routine which, by direction of IOCS commands, "writes" output data on a file.

> **ERR (error exit)** — An address, specified in the calling sequence of the READ routine, which is used as an exit upon recognition of an uncorrectable redundancy, or a block sequence or check sum error.

> **EOF (end of file)** — An address, specified in the calling sequence to the READ routine, which is used as an exit upon recognition of an end of file condition.

> **EOB (end of buffer)** — A programmed switch, specified in the calling sequence to the READ and WRITE routines, which determines the system interpretation of non-transmitting IOCS commands. Under certain circumstances it is used as an exit from those routines.

> **EOT (end of tape)** — An address, specified in the calling sequence of the WEF routine, which is used as an exit upon recognition of the end-of-tape condition.

Entries containing "locate" or "current":

> **LOCATE** — In IOCS, the process of determining the location of data in a buffer. Locating is accomplished by the use of IOXYN commands.

> **NON-TRANSMITTING COMMANDS** — Those IOCS commands, of the form IOXYN, which provide the location of data within a buffer, rather than transmitting the data between buffers and working storage.

> **TRANSMIT** — In IOCS, the process by which IOXY commands move data between buffers and the user's working storage.

> **SKIP** — In IOCS, the process of bypassing data words in a buffer while "reading" or "writing." Skipping is accomplished by use of the IOXYN commands.

> **AVAILABLE BUFFER COUNT** — The number of **currently** available buffers in a pool, kept by IOCS for each buffer pool.

> **CONNECTED BUFFER** — A buffer **currently** in use by a file.

> **BLOCK COUNT** — The number of blocks processed on the **current** reel of a file, kept in the corresponding File Control Block.

> **BLOCK SEQUENCE NUMBER** — The position of a data block among the other data blocks in the **current** reel of a file. This number is found in positions 21-35 of the Block Sequence Word.

> **CKPT** — The IOCS routine which prepares a checkpoint on the **current** checkpoint file.

Also directly relevant:

> **COMMAND (IOCS)** — Specified in the calling sequence to the READ or WRITE routines, it controls the "reading" or "writing" of data. The general form of an IOCS command is IOXY(N)(\*).

> **COUNT CONTROL** — The control used by a class of IOCS commands which "reads" or "writes" a specified number of words.

> **SPECIAL COUNT CONTROL** — The control used by a class of IOCS commands which process by count unless terminated by the end of buffer condition. These commands are of the form IOSY(N).

> **TRUNCATE** — To ignore any remaining words in a processed buffer and release it from a file; for an input file, the buffer is made available; for an output file, action is initiated to write the contents of the buffer on that file's I/O unit.

> **FILE CONTROL BLOCK** — 12 cells allocated for control information about a file IOCS is to process. The File Control Block is prepared by the Preprocessor from the symbolic information on a FILE card.

*Settles:* there is no glossary entry for "current record," "record pointer," or "mode." The system has no notion of a current logical record at all — only a current *buffer* and, within it, a next-available-word locator.

---

## 7. Abnormal-conditions table, READ entries

> **Actions of IOCS Routines Under Abnormal Conditions**
>
> | Routine | Condition | Action |
> |---|---|---|
> | READ | File never opened | EOF exit |
> | | File already closed | EOF exit |
> | | Block sequence error | ERROR exit MQ<sub>S–2</sub> = 1 |
> | | Check sum error | ERROR exit MQ<sub>S–2</sub> = 2 |
> | | Redundancy error | ERROR exit MQ<sub>S–2</sub> = 4 |
> | | Sequence and redundancy errors | ERROR exit MQ<sub>S–2</sub> = 5 |
> | | Check sum and redundancy errors | ERROR exit MQ<sub>S–2</sub> = 6 |
> | | Attempt to locate information in two buffers with one command | EOB exit MQ<sub>S–2</sub> = 2 |
> | | Attempt to locate in more buffers than are available | EOB exit MQ<sub>S–2</sub> = 4 |
> | | Attempt to transmit a word into the system | Stop: Illegal Transmit |

(external: C28-6100-2, PDF p. 79 / printed p. 71)

For contrast, WRITE on the same page:

> | WRITE | File never opened | Normal exit |
> | | File already closed | Normal exit |
> | | Attempt to locate information in two buffers with one command | EOB exit MQ<sub>S–2</sub> = 2 |
> | | Attempt to locate in more buffers than are available | EOB exit MQ<sub>S–2</sub> = 4 |

(external: C28-6100-2, PDF p. 79 / printed p. 71)

*Settles:* reading a never-opened or already-closed file is **not** an error — it silently takes the EOF exit. A COMTRAN handler that relies on the EOF exit to mean "tape exhausted" will mistake a missing OPEN for a zero-record file. And the two EOB codes (2 = record crossed a block; 4 = out of buffers) are the only way to distinguish "your record straddles a block gap" from "your Reserve Group count is too low."

---

## What the manual leaves unsaid about locate-mode reading

1. **Index-register preservation across `TSX READ,4`.** The manual tells the *user's* non-standard label routine that "the contents of all index registers used must be saved and restored" (PDF p. 33 / printed p. 25), but never states what READ itself preserves. `IOCS+67` records XR1 and XR2 at entry, which hints they are clobbered, but that is a diagnostic cell, not a contract. What XR4 contains on return is never stated.

2. **Whether a modified `**` is ever restored.** IOCS writes the located address into the command's address field; it never says the `**` is put back. The Part II loop implies it is not — `DUPE IORTN **,,**` is re-executed with its previous contents still in place and works, but the manual doesn't say why that is safe. Re-entrancy and recursion of a READ command list are undefined.

3. **Whether data *modified* in a located input buffer is what COPY writes out.** COPY is described as "connecting processed input buffers to that output file," which implies yes, but the manual never states that in-place modification of a located record survives to the output tape.

4. **The interaction of a held buffer with an intervening reference to the same file.** Rule 1 on printed p. 13 says the buffer is retained "until the file is next referenced by any IOCS routine" — but not what happens to a *still-live* located address if the program calls, say, `BSR` or `CLOSE` on that file, or issues a second READ, before consuming the record. Empirically the address goes stale; the manual never says so.

5. **How to recover a partial record after an EOB code-2 exit.** The execution table says a locate that hits end-of-buffer delivers only m words and holds the buffer. It never says how to obtain the remaining n−m words of that record from the *next* buffer, nor whether the held buffer's contents and the next buffer's contents can be made contiguous. In practice they cannot — but no recovery procedure is given.

6. **Whether the EOB exit and the normal return can be distinguished without inspecting MQ.** Every example sets EOB to the address of the next instruction, which merges the two. The manual never discusses the alternative (a separate EOB label) or its cost.

7. **Any per-record or per-block accounting.** No record count, no "records remaining in block," no way to ask "is this the last record in the block." The only count the system offers is the AC decrement — words remaining in the buffer — and the programmer must divide by his own record length.

8. **Record length as a file property.** There is none. "The definition of the logical record is expressed implicitly in the user's choice of IOCS commands." Neither the FILE card nor the FCB records it, so a COMTRAN compiler must carry the record length itself and emit it as the `m` of each command.

9. **Variable-length records that reach the end of a block.** The manual's variable-length recipe (PDF p. 61 / printed p. 53) explicitly assumes "a record will not span a block" and the writing side uses special count control "to insure that records do not cross a block gap" — but it never says how to detect, on input, that the remaining words in a block are padding rather than a record.

10. **Timing and the trap.** Buffering is driven by the Data Channel Trap, but the manual never states whether located data can be overwritten by an in-flight read into the same buffer, nor gives any interlock the programmer can rely on beyond "the buffer is retained until next reference."