# The evidence directory

These three files are the working reports M5 stage 2 was designed from. They are
left exactly as their authors wrote them, on 2026-09-12. They carry absolute
scratch-directory paths, agent-to-agent phrasing, and the line numbers the
repository held at the time. Nothing here was tidied for a reader. The record
cites them for what they said when the work was done.

## `s2-manual-get.md`

The two COMTRAN manuals on GET, read with the language definition and the
decision slate. It gives the IOC)8 calling sequence from J 90.02 and what the
entry does. It covers the `*FILE` and `*SPEC` loader cards, the sample's data
description, and every GET in the sample's PROCEDURE division. Later sections
hold F28-8043 on buffering, end of file, the record-length check, and the D6
decision family. A final part lists the gaps the manuals do not answer.

## `s2-runtime-codegen.md`

The repository side: the runtime, the generator, the goldens and the tests. It
gives the dispatch rule, the parameter helpers and the resume rule. It shows what
IOC)8 does today, the stage-1 file model, and the GET emission. It lists every
I/O site in the golden object listing, and where the two input records live. It
ends with the test support, M4-15 in full, and the `comtranc --run` driver path.

## `s2-iocs-read.md`

The published 7090 IOCS manual, C28-6100-2, on locate-style reading of a blocked
tape file. It quotes the READ routine in full, then buffering, end of file, and
the File Control Block layout. It adds the glossary entries and the READ rows of
the abnormal-conditions table. It opens with a correction to earlier project
notes about page numbers. It closes with what the manual leaves unsaid about
locate-mode reading. The manual is an external period source. It is not the
sealed archive of D0.9.
