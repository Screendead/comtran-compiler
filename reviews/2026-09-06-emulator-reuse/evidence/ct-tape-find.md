# The Commercial Translator on Pitts' IBSYS recovery

Excerpts I pulled myself from `ibsys.tar.gz`, downloaded 2026-09-06 from
`https://www.cozx.com/dpitts/tarballs/ibm709x/ibsys.tar.gz` (9,829,802 bytes,
HTTP 200). The tarball is not redistributed here; these are the passages the
record argues from.

## Provenance, from the distribution's own readme

    These directories contain the source of the IBSYS operating system and
    several subsystems. The files were gleaned from the IBSYS tapes from
    Paul Pierce's web site (www.piercefuller.com/oldibm-shadow/709x.html).
    
    The subdirectories are:
    
       9PAC		- Report generator and data file maintenance
       CT		- Commercial Translator
       EDITOR	- System Editor
       FORTRAN	- FORTRAN II
       IBCBC	- COBOL
       IBFTC	- FORTRAN IV
       IBJOB	- IBJOB monitor
       IBMAP	- MAP assembler
       IBSYS	- IBSYS nucleus
       IOCS		- IOCS (I/O Control System)
       misc		- Things that go someplace
       RESTART	- RESTART 
       SORT		- SORT/MERGE 
       UTILS	- DISK Utilities

## The CT directory

    CT/Makefile      205 bytes
    CT/ct.job    5398204 bytes   66684 lines   FAP source
    CT/ct.lst    7747434 bytes   74625 lines   assembly listing, with octal
    CT/ct.obj     927369 bytes   11449 lines   object

## The monitor header, ct.job lines 12-16

           ABS                                                              CT000020
           COUNT   857                                                      CT000030
    *  709/7090 COMMERCIAL TRANSLATOR MONITOR (VERSION 5)  07/15/63         CT000040
    *                                                                       CT000050
           SPACE   1                                                        CT000060

## The forty object-time subroutine decks

Each is introduced by a `$CMPLE` card and headed
`7090 COMM. TRAN. (OBJECT SUBROUTINE) VERSION 5      JULY 15, 1963`.
The deck names, in file order:

    IOBSMP IOEXMP CTMCOM IBMAP PRGINT UNITAS INREAD 2CELLS EXPERR 
    EXPDBL FPTRP SYSADJ SYSCOL SYSCOM SYSSXY SYSSDX SYSDIV SYSMPX 
    EXPSNG OPEN1 OPEN2 CLOSE1 CLOSE2 STPPRT MOVPAK NJJJNJ MOVFLT PATTRN 
    EOBERR BCDBIN BCDERR GETVLM UNXEOF KAPUT HOLBCD WRTEOB BCDHOL BLERR 
    TRAPEM SRMOVE

## MOVPAK, ct.job lines 57878-57905

    $CMPLE MOVPAK  LIST,DICT,SUB                          CT0500   07/15/63 17900020
                   ENTER CRYPT                                              17900030
    * 7090 COMM. TRAN. (OBJECT SUBROUTINE) VERSION 5      JULY 15, 1963     17900040
    *                                                                       17900050
    *                 THIS SUBROUTINE IS EMPLOYED TO                        17900060
    *              MOVE FIELDS FROM ONE LOCATION TO                         17900070
    *              ANOTHER                                                  17900080
    *                                                                       17900090
           SYS     179                 MOVPAK                               17900100
    MOVPAK SXA     SAVE2,2                                                  17900110
           AXT     2,2                                                      17900120
           TRA     *+4                                                      17900130
           SYS     180                 MVPAK1                               17900140
    MVPAK1 STO     SAVACC                                                   17900150
           SXA     SAVE2,2                                                  17900160
           AXT     1,2                                                      17900170
           SXA     SAVE1,1                                                  17900180
    MVP100 CLA     1,4                                                      17900190
           TPL     MVP101              TRA UNLESS BL OR PI                  17900200
           STP     *+3                                                      17900210
           PDC     0,1                                                      17900220
           CAL*    1,4                                                      17900230
           NOP     MVP101                                                   17900240
           TZE     SYS)294             BL ERR IF ZERO                       17900250
           ACL     0,1                                                      17900260
           PDX     0,1                                                      17900270
           TXL     *+2,1,5                                                  17900280
           ACL     BYTCON                                                   17900290

## The same code assembled, ct.lst

    64417: 13505   0634 00 2 13611     9  MOVPAK SXA     SAVE2,2                                                  17900110

Location 13505, instruction word `0634 00 2 13611`. Opcode 0634 is SXA, tag 2,
address 13611. 3,351 lines in this region of the listing carry a location and
an octal instruction word.

## SYS) cross-references

    31877:       VFD     O6/23,30/BLERR      SYS)294 (BL NOT LOADED ERR)          CD089290
    57541:*              CT SUBROUTINE SYS)175                                    17500080
    57636:*              CT SUBROUTINE SYS)177                                    17700060
    57837:*              CT SUBROUTINE SYS)178                                    17800050
    59516:MOVOVF EQU     SYS)130                                                  25100120
    59517:MOVERR EQU     SYS)131                                                  25100130

Occurrences in ct.job of each SYS) cell our generated code calls:

    SYS)130  2
    SYS)131  2
    SYS)132  4
    SYS)133  4
    SYS)162  1
    SYS)177  5
    SYS)178  4
    SYS)180  2
    SYS)182  1
    SYS)265  2
    SYS)267  1
    SYS)294  8

## Instructions the library uses that our 43-opcode core does not implement

Counted over the object-subroutine region of ct.job (lines 55800 to end),
matching a mnemonic in operand position.

    floating point   FAD 31   FMP 11   FDP 7   FSB 2   FRN 3
    trapping/halts   TTR 8    TOV 3    ETM 2   LTM 2   HTR 1
    channel I/O      IORT 13  IOCP 10  TCH 9   IORP 3  IOCT 2   RDS 1
    other, common    TIX 151  XEC 109  STA 106 SXD 88  STZ 70   ZET 64
                     TZE 55   STL 43   LFT 42  XCL 41  LXD 38   PAC 37
                     RIL 33   TNX 31   TNZ 30  MTW 27  PDC 25   LLS 23
                     PXD 21   TMI 15

The first three groups are the three families `docs/design/emulator.md`
section 8 puts out of scope. Channel I/O is what decision D0.7 exists to
avoid.

## What I did not do

I read headers, the deck table, the SYS)/IOC) cross-references and MOVPAK's
opening. I read no routine's logic through, compared no routine against
J28-6169's documented contract, assembled nothing, and ran nothing. The
version is 5 of 07/15/63; our target is J28-6169-1 of January 1962.
