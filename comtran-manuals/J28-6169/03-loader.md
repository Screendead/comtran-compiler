# Section 03: Loader

<!-- 03.00.00 | PDF 69 -->
**[03.00.00]**

## SECTION 03.00 LOADER

### INTRODUCTION

The Loader, under the direction of the Commercial Translator Supervisor creates a machine language program from the relative binary deck(s) produced by the Compiler and normally turns control over to the program for execution. As part of the loading procedure, separately compiled program segments are combined; storage is allocated for program instructions, data and buffers; object program, system subroutines and specified IOCS modules are loaded; and control is transferred to the object program starting point.

A detailed description of the control cards which direct the Loader, and a discussion of the Loader input and output appear in this section.

Current Loader Deferred Features, Restrictions, and/or Limitations are found in Appendix 90.01.

<!-- 03.01.01 | PDF 70 -->
**[03.01.01]**

## 03.01 Composition of the Commercial Translator Deck to be Loaded

#### A. Deck Composition

A Commercial Translator deck to be Loaded is composed of the following types of cards and is processed in the order indicated.

1. $LOAD
2. Symbolic Control Cards (in any order)
   - \*FILE
   - \*SPEC
   - \*POOL
   - \*GROUP
   - \*RETAINS
   - \*DELETES
   - \*FILEQU
   - \*START
3. \*CTEXT
4. Relative Binary Program Deck (see section 90.03 for deck details and specifications).

   a) Control Break Table

      The control break table defines procedure and/or data areas in this deck which may be deleted; or replaced or referenced by other program segments, which have been separately compiled (see CONTRL in section 02.06).

   b) File Check Table (see section 90.03 for specifications)

      The file check table is used to validate the contents of the generated file block (see IOCS manual) and the assignment of each file to a buffer pool. It transmits the location of any non-standard label routines to the IOCS System.

   c) Text

      Compiler produced machine language instructions and data references.
5. \*CTEND
6. Special end-of-file card (or physical end-of-file)

#### B. Combination of Separately Compiled Decks (Not currently available).

This feature allows cross-referencing of common data fields and procedure sections. The data description for a common field must be included within each compilation which references this field. The allocation of a unique storage area to a common data field or section may be specified by loader control cards.

<!-- 03.01.02 | PDF 71 -->
**[03.01.02]**

If more than one deck is to be run as a single job, the symbolic control cards required for the combined program are loaded first, followed by the Relative Binary Program decks (each consisting of parts 3, 4 and 5); and, finally, the end-of-file. The symbolic control cards of the individual segments may be retained with their Relative Binary Program cards. However, all symbolic control cards appearing after the initial Relative Binary Program deck will be ignored by the Loader.

#### C. Requirements for Loading a Single Deck

To load a single deck, the required cards are

1. $LOAD
2. Symbolic Control Cards
   - \*FILE
   - \*SPEC
3. \*CTEXT
4. Relative Binary Deck
5. \*CTEND
6. End-of-file

The Compiler produces all of these except the $LOAD and the end-of-file card.

<!-- 03.02.01 | PDF 72 -->
**[03.02.01]**

## 03.02 Loader Control Cards

#### A. Introduction

Loader control cards direct and control the Loader in such functions as combining separately compiled programs and allocation of storage for buffers. Also, they describe the physical file characteristics required by the 709/7090 Input/Output Control System. Most control cards are supplied by the compiler. However, the programmer might wish to supplement or replace them in some cases. Loader control cards must be placed at the beginning of the program deck. If placed otherwise, they are not interpreted.

#### B. $LOAD Card

1. The Loader is called when the Commercial Translator Supervisor recognizes the $LOAD card of the form:

```
1-6     8-13        16                                              54
$LOAD   deck.name   [MIMIMUM                        [,LOGIC]  [,MAP]
                      BASIC
                      LABELS                         [,NOGO]  [,FILES]
                      IOEX]
                     55                                             72
                     [secondary.identifier]
```

   The options in the variable field must be separated by commas and may appear in any order. Any combination of options may be selected with no blanks separating them.

2. The options are defined as follows:

   **MINIMUM / BASIC / LABELS / IOEX**

   MIMIMUM requests that the minimum IOCS package be made available, BASIC requests that the basic IOCS be made available, LABELS request that the full IOCS with labeling features be made available, and IOEX requests that the Input/Output Executor be made available. (See 709/7090 IOCS manual for definition of these forms.) If no option is selected the MINIMUM IOCS will be made available unless checkpoint is specified. In this case BASIC IOCS will be available. However, the full (LABELS) IOCS will be made available if labels are to be handled.

   **[,LOGIC]**

   Instructs the Loader to list the origin and extent of all program sections, system subroutines required for execution (including IOCS) and buffer assignments. This option may be specified on the $CMPLE as a 'carry through' feature when a 'compile and load' run is to be made.

<!-- 03.02.02 | PDF 73 -->
**[03.02.02]**

   **[MAP]**

   This option has not yet been implemented. It will provide for obtaining load-time information in addition to that supplied by LOGIC.

   **[NOGO]**

   Instructs the Loader to inhibit execution of the program after loading. It does not affect the LOGIC option.

   **[FILES]**

   A list of files showing the I/O unit assignments made by the Loader, and any mounting instructions, is always prepared for the operator. If this option is specified, a duplicate of the file list is written on SYSOU1.

   **[secondary.identifier]**

   The information in these columns will appear in the page headings of all output prepared on SYSOU1.

#### C. \*FILE Card

1. Format

   The format of the \*FILE card is, with two exceptions, the same as that specified in the 709/7090 IOCS reference manual. That is,

```
1-6         7-11    14-15    17    18-21    22-25    27-35      38-41
deck.name   *FILE   file.no  M     unit1    unit2    controls   reel.seq

44-48           51-53        55-72
file.serial      ret.days    File name
```

   The two exceptions are:

   a) The file number (file.no) is assigned to each file by the Compiler and appears with the file name on the listing provided by the Compiler. In this card the field does not occupy column 13.

   b) The unit (unit1 and unit2) specification has been modified to include relative unit assignment, symbolic channels, and tape transport model type. The card fields have been enlarged from three to four columns: columns 18-21 for unit1 and columns 22-25 for unit2.

   Appendix 90.08 contains a chart showing how the options of the Environment FILE and SPECIF cards are used by the Compiler in preparing the \*FILE card.

2. Unit specifications (unit1, unit2)

   The notation employed in explaining these options is:

   | Symbol | Denotes |
   | --- | --- |
   | X | one of the real channels A, B, ..., H |
   | P | a symbolic (unspecified physical) channel S, T, ..., Z |
   | k | one of the unit numbers 1, ..., 9, 0 |
   | m | a tape transport model number, II or IV |

<!-- 03.02.03 | PDF 74 -->
**[03.02.03]**

   The unit specification may be made in any of the following ways:

   a) No specification — when the option is not exercised any available unit is to be assigned to the file.

   b) `m` — any available unit of this model type is to be assigned to the file.

   c) `X` — any available unit on this physical channel is to be assigned to the file.

   d) `P` — all files in the job having this symbolic channel designation are to be assigned to the same channel.

   e) `X(k)` — the kth available unit on the specified channel is to be assigned to the file; note that the parenthesis are required.

   f) `Pm` — any available unit of this model type on the symbolic channel specified is to be assigned to the file.

   g) `Pkm` — an available unit on the symbolic channel, having this model number, is to be assigned to the file. `k` in this use without parenthesis indicates the order of preference for the channel so that if the number of available units on the channel is less than the total requested for the channel those with lower numbers are to be assigned to the same channel.

   h) System units may be assigned by:

      i. `IN` — the current system Input unit is to contain the file.
      ii. `OU` — the current system Output unit is to be used for a printed output file.
      iii. `PP` — the current system Peripheral Punch unit is to be used for a punch output file.
      iv. `UTk` — System utility tape k (non-parenthesized k = 1-4) is to be used for the file.

   i) Card equipment is assigned for a file by:

      1) `RDX` — card reader, channel X
      2) `PRX` — printer, channel X
      3) `PUX` — card punch, channel X

<!-- 03.02.04 | PDF 75 -->
**[03.02.04]**

   j) As a special option, an `*` in the UNIT2 field indicates that the secondary unit of a file is to be any unit on the same channel and of the same model type, which is available after all other assignments have been made. At load-time if units are available, but of a different model, one will be assigned; if no units are available on the channel, no secondary unit is assigned prior to execution of the job.

3. Unit Assignment

   Units are assigned in the following order:

   1. System units
   2. Card units
   3. Units on specified channels
   4. Units on symbolic channels
   5. Units with model only specification
   6. Unit with no (blank) specification
   7. Secondary units designation with `*`

   It should be emphasized that relative unit specification is not the same as the physical setting of the tape unit. The use of A(3), for example, will result in the assignment of the third available unit on channel A; and not necessarily the physical unit A3. (An available unit is one presently attached to the machine, and not assigned for system use.) However, the assignment procedure is such that designation of a given relative unit on a given (physical) channel will always result in the same choice of unit, provided that the unit sequencing is not disturbed between jobs by use of the Basic Monitor $ATTACH – [$AS] control cards.

   When consistent tape assignments are required (e.g., when a file is used by two successive jobs or when a file is written and then read in the same job) the unit specifications should be identical in the FILE cards. The units should be specified as system utilities (UTk) or by means of specific channels (X) with low unit availability designations (k) in order to guarantee use of the same drives.

   Care should be taken in assigning system utility units (SYSUTk) to object program files. In particular, they should not be assigned to files which will specify in the printed file list the immediate mounting of tapes by the operator, since these tapes will still be in use after this list is printed.

#### D. \*SPEC Card

The \*SPEC card supplements the \*FILE card in supplying file information. The format of the \*SPEC card is:

<!-- 03.02.05 | PDF 76 -->
**[03.02.05]**

```
1-6         7-11    14-15    17-20        22-23      25     27
deck.name   *SPEC   file.no  blocksize    activity   open   close
```

The 'deck.name' and 'file.no' are used to identify the file as the same file described on a \*FILE card. Unless the same 'deck.name' and 'file.no' appear on a \*FILE in the deck the \*SPEC Card will be ignored.

'blocksize' is normally a number (0-999) but may be left blank. A number in this field specifies the maximum number of words to be input or output in a single block. It may be desirable to change the blocksize in an attempt to obtain better input/output processing speeds or tape utilization. Conflict with file specifications entered in the Commercial Translator Environment section must be avoided. The loader will check most normal situations in accordance with information supplied to it by the Compiler.

'activity' may be specified as a number 0-99 or may be left blank. A number in this field specifies the relative activity of the file in respect to other files and is used by the Loader in the allocation of buffer areas.

The 'open' options are:

1. N — No rewind
2. R or blank — Rewind

The 'close' options are:

1. U — Rewind and unload
2. R or blank — Rewind
3. N — No Rewind
4. S — No file mark or trailers, no rewind

Appendix 90.08 contains a chart showing the source of the fields of the \*SPEC card when it is generated by the Compiler.

#### E. \*POOL Card

The \*POOL card designates which files are to share common buffer areas. The format of this card is:

```
1-6         7-11    14-15     17-20                23-25         27
deck.name   *POOL   pool.no   blocksize buffer.cnt                file1, file2...filen
```

The 'blocksize and buffer count' specifications are described in the Environment Description POOL card (section 02.06).

1. If the file referenced is described in the deck named on the \*POOL card, specification of the file number shown in the compiler file list adequately

<!-- 03.02.06 | PDF 77 -->
**[03.02.06]**

identifies the file. Its format is

```
file.no
```

2. If the file reference is to a file in a deck other than the one named on the \*POOL card, the deck.name of the deck in which the file is described must be specified in addition to the file number. Its format with required parentheses is

```
deck.name(file.no)
```

The file references must be separated by commas and no blanks may be embedded in the field.

If the variable field information extends beyond a card additional cards may be used as needed. However, the 'deck.name' and a 'pool.no' must be the same on all cards for the same pool. All other remaining fields need appear in only one of the cards; if on more than one, the first (non-blank) value encountered is used.

#### F. \*GROUP Card

1. Format

   The information of the \*GROUP card corresponds to that on the Commercial Translator Environment GROUP card. The format of the \*GROUP card is:

```
1-6         7-12     14-15      17-18     20-21     23-25
deck.name   *GROUP   group.no   pool.no   Opn.cnt   Buffer.cnt

27
file1, file2, ..., filen
```

2. Specification

   File references and variable field overflow, follow the same rules as the \*POOL card. The deck.name, if used, must correspond to that of the \*POOL card with which it is associated through the pool number. The file references on the \*GROUP card need not be duplicated on the \*POOL card in order to be included in the pool. However, the \*POOL card may have file references other than those on associated \*GROUP cards.

   All \*POOL cards are processed first, in the order read, then \*GROUP cards. If there is a conflict in pool or group assignments (e.g., a file directly assigned to some pool, then to a group belonging to another pool, or a file assigned to two different groups or pools) the first assignment is used.

<!-- 03.02.07 | PDF 78 -->
**[03.02.07]**

In the absence of any \*POOL or \*GROUP cards, the Loader will make its own assignments. These cards enable the user to make a more sophisticated assignment, based on knowledge of file use and activity.

#### G. \*FILEQU Card

When separately compiled decks are combined, the loader must be told which files are common so that they can be processed as a single file. The names associated with a file at compile time are not available at load time; rather, files are identified by deck.name and file number. This identifying information is used on the \*FILEQU to specify file equivalence. The form of the \*FILEQU card is

```
1-6         7-13       16-72
deck.name   *FILEQU    file1,file2,...,filen
```

All files referenced on a \*FILEQU card take on the processing characteristics of the first file referenced whose characteristics are defined by a \*FILE card. File references may be of two forms:

1. deck.name(file.no)

   'deck.name' is the name of the referenced program segment in which the file appears (see deck.name in \*FILE card) and 'file.no' is the identifying number of the file within the referenced deck.

2. file.no

   'file.no' identifies a file whose deck identification is that specified in columns 1-6 of the \*FILEQU card. Note that all blanks in columns 1-6 of the \*FILEQU card may be used as a legitimate qualifier for each specified 'file.no'.

As all files referenced on a \*FILEQU card take the same processing characteristics as the first file mentioned, those processing characteristics may be altered by altering the content of the \*FILE and \*SPEC cards for that first file.

In case all of the equivalent files cannot be specified on a single card, additional cards may be used. At least one of the file references on the first card must appear on the subsequent cards.

#### H. \*RETAINS Card

When several separately compiled programs are to be run as a single job, certain areas of procedure or data, referenced in the individual compilations must be identical. These areas must be specified in the Environment Description of each compiled job on CONTRL cards (see section 02.06). The extent and nature of the area is entered into the Control Break table of the compiled program together with the external reference name (ex.nm) as given on the CONTRL card. The Loader identifies the equivalence of these areas by means of the external reference names. In the absence of any other information, the area is assumed to be located in the first program segment containing the 'ex.nm' in its Control

<!-- 03.02.08 | PDF 79 -->
**[03.02.08]**

Break table. All instructions and data corresponding to this area in the other segments are deleted by the Loader, and all references in these programs are changed to reflect the new location.

Since it is not always possible to arrange the order of the deck so that a CONTRL area is located in the first segment, the \*RETAINS card provides a means by which the location of such an area can be established as desired. The format of this card is:

```
1-6         7-15         16-72
deck.name   *RETAINS     ex.nm1,ex.nm2,...,ex.nmk
```

'deck.name' is the name of the program segment in which the CONTRL areas ex.nm1,ex.nm2,...,ex.nmk are to be retained. These named areas will be deleted from all other program segments. If ex.nmj does not appear as an entry in the Control Break table of program 'deck.name', it cannot be retained by the program, and will have no effect on the loading procedure.

The variable field entries, ex.nmj, are separated by commas, and there must be no embedded blanks in the field.

#### I. \*DELETES Card

The \*DELETES card eliminates procedure and data areas defined by an Environment CONTRL card. For example, to delete sections of a program that were originally intended as an aid in source language debugging. The format of the \*DELETES card is:

```
1-6         7-14         16-72
deck.name   *DELETES     ex.nm1,ex.nm2,...,ex.nmk
```

where ex.nmj is the external reference name appearing in the CONTRL card which defined the area. If a 'deck.name' is given, the CONTRL area(s) will be deleted only from the named program. If no 'deck.name' is given then the CONTRL area(s) will be deleted from all programs in which they appear.

#### J. \*START Card

The Loader will normally use the starting point of the first program of combined segments as the starting point for the combined deck. The \*START card permits this to be varied. The format of the \*START card is:

```
7        16
*START   deck.name
```

<!-- 03.02.09 | PDF 80 -->
**[03.02.09]**

Execution of the combined program will begin at the starting point of the deck named.

#### K. \*CTEXT and \*CTEND Cards

The \*CTEXT and the \*CTEND cards, supplied by the compiler mark the beginning and end of the relative binary deck (control dictionary, file check table, and text) produced on a single compilation. No modification or reordering of the binary deck should be attempted. The formats of these cards are:

```
1-6         7-12      26-54           55-72
deck.name   *CTEXT    date.and.time   secondary.identifier
deck.name   *CTEND    date.and.time   secondary.identifier
```

'deck.name' and 'secondary.identifier' are those supplied on the $CMPLE card and 'date.and.time' are supplied by the Compiler to specify when the deck was produced.

<!-- 03.03.01 | PDF 81 -->
**[03.03.01]**

## 03.03 Loader Output

#### A. Program for Execution

The binary object program deck, together with required subroutines, appropriate I/O routines and tables and a portion of the Basic Monitor, is placed in core storage by the Loader. If the program is to be executed, control is transferred to it at the conclusion of the loading process. The following chart illustrates the general layout of core storage at execution time.

| Address | Core storage region |
| --- | --- |
| 32767 | *(top of core)* |
| 32256 | Available for Customer Usage |
|  | Primary Object Time Subroutines |
|  | Program Initialization and Loading Routines (Overlaid by buffer pools) |
|  | Buffer Pools |
|  | Secondary Object Time Subroutines |
|  | Program |
|  | Transfer to Program Start |
|  | Define, Attach Calling Sequences |
|  | File Lists |
| 3840 | File Block |
| 1856 | IOBS |
| 1400 | CTM (Commercial Translator Monitor) |
| 350 | IOEX |
| 0 | Basic Monitor |

![Chart of core storage layout at execution time, showing address ranges from 0 to 32767 and the regions occupied by the Basic Monitor, IOEX, CTM, IOBS, File Block, File Lists, Define/Attach calling sequences, Transfer to Program Start, Program, Secondary Object Time Subroutines, Buffer Pools, Program Initialization and Loading Routines, Primary Object Time Subroutines, and area available for customer usage.](images/page-081.png)
*General layout of core storage at execution time (page 03.03.01).*

Note: The core addresses shown above are approximate.

<!-- 03.03.02 | PDF 82 -->
**[03.03.02]**

The program elements of the chart are described as follows:

File Block — this is a 12-word File Control Block for each file required by the program.

File Lists — these are generated for each buffer pool, showing the group structure and the files assigned to the pool.

Define and Attach Calling Sequences — each buffer pool must be defined by a reference to the IOCS subroutine, DEFINE. Files are attached to this pool by reference to the ATTACH subroutine. These calling sequences are generated by the Loader and are the first instructions executed.

Transfer to Program Start — the instruction following the last ATTACH calling sequence is a transfer to the start point of the program.

Secondary and Primary Subroutines — three types of subroutines are used, Secondary, Primary, and Fixed.

Secondary subroutines — such subroutines, if called by the object program, are treated as program sections and are loaded following the end of the program in core storage.

Primary subroutines — certain object time subroutines are expected to have a large number of references in the object program. To avoid placing all instructions containing such references in the 2TEXT#​ file, primary subroutines, which are required to have a fixed length not modified by the loading process, are assigned core storage locations at the upper end of memory. This assignment is made at the time the first reference to the subroutine is encountered.

Fixed subroutines — all program references to points in IOEX, CTM and IOBS are defined by fixed subroutines, each of which has an assigned origin. These fixed

<!-- 03.03.03 | PDF 83 -->
**[03.03.03]**

subroutines are nothing more than BSS "maps" of the corresponding communication regions.

Notes —

1. \#  — 2TEXT is a file generated by the loader during the first reading of program text, including subroutines. In this file are placed all instructions containing references which cannot be defined until the first text pass is complete (e.g., references to secondary subroutines, references to control break sections in a program not yet loaded).

#### B. Printed Messages

1. Off-line on SYSOU1

   a) Error messages
   b) The file list if the FILES option was selected
   c) A storage map of the program, subroutines and buffers ready for program execution, if the LOGIC option was selected.

2. On-line Printer

   A file list is printed showing input/output unit assignments and the tape mounting instructions for the operator.

<!-- conversion notes:
- PDF p.73 and PDF p.81 had no legible section-code header in the OCR draft (jmap.json listed them as null); both were read directly from the page image and normalized to 03.02.02 and 03.03.01 respectively, matching the chunk-specific guidance provided.
- The $LOAD card syntax formula (03.02.01/03.02.02, PDF pp.72-73) prints the option-group keyword as "MIMIMUM" both in the syntax box and in the first line of its definition paragraph, while the same keyword is spelled correctly "MINIMUM" elsewhere on the same page (bracket list at start of item 2, and later "the MINIMUM IOCS will be made available"). This is reproduced verbatim as printed since it recurs identically across two independent transcriptions (OCR and manual image inspection), consistent with Golden Rule 1 (preserve source text/spelling exactly).
- On PDF p.72, the printed text for the closing lines of the MINIMUM/BASIC/LABELS/IOEX definition ("...BASIC iOCS wiil be avaiiabie. ...the fuii (LABELS) iOCS wiil be made avaiiabie if iabeis are to be handled.") shows a localized print/scan degradation (l→i substitution) not seen elsewhere on the page, including in the immediately preceding sentence which prints "will be made available" correctly. This has been corrected to the clearly intended reading ("will be available", "full", "labels", "IOCS") per Golden Rule 3 (never emit garbled text).
- The $LOAD card syntax box (PDF p.72) uses a single spanning bracket enclosing the four IOCS-level option keywords (MIMIMUM/BASIC/LABELS/IOEX) in the original typeset layout; this is rendered here with an opening "[" before the first keyword and closing "]" after the last, on separate lines, to approximate the spanning bracket in fixed-width text.
- The core-storage layout chart (03.03.01, PDF p.81) is reproduced as a best-effort Markdown table plus the embedded page image, per spec guidance for diagrams that cannot be fully captured in a simple table.
- The footnote marker "#" attached to "2TEXT" on PDF p.82, and its corresponding note on PDF p.83, are preserved and rendered as a "Notes —" block per convention.
- No pages in this chunk were blank; no pages were left as image-only transcriptions (only the core-storage chart on PDF p.81 also received an image embed, in addition to full text transcription).
-->
