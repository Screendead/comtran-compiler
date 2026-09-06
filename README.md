# COMTRAN Compiler

[![Archived in Software Heritage](https://archive.softwareheritage.org/badge/origin/https://github.com/Screendead/comtran-compiler/)](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Screendead/comtran-compiler)

**COMTRAN was IBM's business programming language before COBOL existed. No
compiler for it survives, and no machine-readable source. This project
reconstructs the language from the two manuals that are left, and builds a
compiler from that reconstruction.**

On 18 October 1961, IBM's field-test compiler ran a payroll program and printed
the listing below. This repository compiles the same program today and
reproduces that page byte for byte.

![The first page of the 1961 compilation listing: the heading COMPILATION OF
SAMPLE PROBLEM, the line DATE 10/18/61 TIME 2.45, and the numbered data
description entries beginning with MASTER](docs/images/90.05-listing-page-1.png)

*IBM J28-6169-1, Appendix 90.05, PDF page 192 — a crop of the page scan held in
this repository.*

```
                                    COMPILATION OF SAMPLE PROBLEM

        DATE 10/18/61   TIME  2.45   ACCOUNT                    ID. CT PUBLICATIONS        PAGE   1


        *COMPILE LIST                                   CT PUBLICATIONS
  CTC

                                *DATA
                   1,00   71175 MASTER           1RECORD      L
                   2,00   71177   DAT            2
                   3,00             EMPLOYEE.NUM 3
                          71200              BER
                   4,00   71201       DEPARTMENT 4             AA
                   5,00   71202       EMPLOYEE   4             AAAA
                   6,00   71203     NAME         3             A(15)
```

That is our output, not a transcription — the first sixteen lines of
[the full listing](test/goldens/90.05-payroll.listing), which runs to 229
numbered statements. A test compares it against the printed page and fails on
a single wrong byte. You can read the whole thing here without installing
anything.

**In a hurry?** The recovered language is
[`docs/definition/`](docs/definition/README.md). The method behind it is
[`docs/reconstruction-method.md`](docs/reconstruction-method.md). To build or
contribute, [`CONTRIBUTING.md`](CONTRIBUTING.md). Longer routes for each kind
of reader are [at the bottom](#where-to-start).

## What COMTRAN was

Commercial Translator was IBM's business data-processing language of the
immediate pre-COBOL era. A June 1960 *General Information Manual* (F28-8043)
defined it. A field-test compiler for the IBM 709/7090 implemented it, and a
January 1962 *Preliminary Reference Manual* (J28-6169-1) documents that
compiler.

A programmer wrote a COMTRAN program on card forms in three portions:
Procedure, Data Description, and Environment. Procedure statements are
English-like imperative sentences — `MOVE`, `SET`, `GET`, `FILE`, `DO`,
`GO TO … WHEN …` — over period-joined compound names such as
`END.OF.MASTERS`. Data descriptions are pictorial. File handling is
tape-oriented. If that sounds like COBOL, that is no accident: Commercial
Translator counts, beside FLOW-MATIC, as one of the principal inputs to COBOL.

Then it vanished. The language it fed into replaced it, the machines that ran
it were scrapped, and what reached us is two manuals and one compiled sample
program.

## What this project has built

Two things, in order. First the language: a structured, fully cited definition
recovered from the manuals under strict evidence rules. That part is complete
and verified. Then the compiler, which is partly built.

Today the card reader, the lexer, the listing, the parsers for all three
divisions, the job-stream driver, and the Data Description semantic layer all
work. Code generation fills every word of the object program and prints the
whole object listing of the 1962 sample byte for byte; the deck writer punches the
object deck and the loader cards, our loader reads them back, and the machine
assembly executes what comes out. A program that touches no file now compiles
and runs to its `STOP RUN`. [`docs/HANDOVER.md`](docs/HANDOVER.md) holds the live
state and the next task.

To see it run, with the Dart SDK installed:

```sh
dart pub get
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd
dart run comtran:comtranc test/fixtures/90.05-payroll-job.ctd --run
```

The input is the manual's own payroll program, re-keyed as a punch-level card
deck — 293 cards, every column measured from the page scans, plus one
reconstructed `*FINISH` card. The output is the listing above, numbered 1,00 to
229,00 exactly as the 1962 compile numbered it, with zero diagnostics.

`--run` loads the punched deck into the emulator and starts it. The payroll
program gets as far as reading its first record and stops there, because the
tape I/O runtime is the next milestone. The goal is to carry it past that
point: run the sample to the end and reproduce the printed report it produced
in 1961.

## How we know, and what we don't

Both questions matter, and the second one more.

Parallel extraction over both manuals built the definition. Adversarial
verification then checked it: every verbatim quote character for character,
every numeric limit and citation re-derived, and every disputed reading settled
at 400–600 dpi against the page scans. Later passes mined the generated-code
appendix ([J 90.02]), the compiled sample listing ([J 90.05]), and external
period sources — the 709/7090 IOCS manual C28-6100-2, and the IBM 705 and 1401
references — to settle questions the manuals delegate to the machine.

Where the sources are silent, this project decides, and says so. Every such
choice is labelled a judgment call rather than a fact. Some things are simply
not recoverable: the per-message severity codes, for instance, are our design
decision and are marked as such wherever they appear.

**The honest limit is this.** Everything here rests on a single scanned copy of
each manual, read and corrected by one person. Internal checks can show that
our artifacts agree with each other. They cannot show that the reading was
right. Only a second, independently scanned copy could do that, and finding one
is open work — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

[`docs/reconstruction-method.md`](docs/reconstruction-method.md) states the
method in full — how conflicts are resolved, when inference is allowed, what
the method cannot do, and how far large language models did the work. It is
written so that someone recovering a different extinct language could follow
it.

## Where to start

**If you came for the history**, read [what COMTRAN was](#what-comtran-was)
above, then
[`docs/reconstruction-method.md`](docs/reconstruction-method.md) for how a
language gets recovered from paper. The two manuals themselves are here, in
Markdown and as page scans: [`comtran-manuals/`](comtran-manuals/README.md).

**If you are a researcher or an archivist**, the reconstruction is
[`docs/definition/`](docs/definition/README.md) — a cited definition of the
language, with a catalog of every place the two manuals disagree and every
ambiguity the sources leave open. Section 10 of the method document lists what
this project cannot establish on its own. [`CONTRIBUTING.md`](CONTRIBUTING.md)
says what outside help would change that, and finding a second scan of either
manual is top of the list. `CITATION.cff` records how to cite the work,
including its Software Heritage identifier.

**If you build compilers**, [`CONTRIBUTING.md`](CONTRIBUTING.md) has the setup
and the house rules, and [`docs/design/`](docs/design/README.md) holds the
design records — `decisions.md` is the slate everything else builds on. The
pipeline runs cards → lexer → parser → data → codegen → emulator, under
`lib/src/`. Two rules will surprise you: a golden test compares the listing to
the 1962 page byte for byte, and code that no test asserts on and no run
reaches is not allowed in the repository.

## Ground rules

- **J28-6169 outranks F28-8043** wherever they diverge. F is the 1960 design;
  J is the implemented 1962 language.
- The manual conversions are ground truth and read-only. When a transcription
  is doubted, the page scan decides.
- The definition holds language facts only. Compiler architecture and design
  decisions live in `docs/design/`.

The definition's
[Sources and authority](docs/definition/README.md#sources-and-authority)
section is the one home for the first two rules. It states the F/J rule in
full, the fidelity conventions, and the citation style. Read it there; no other
document repeats the detail.

## License

The code and the documents written for this project are copyright © 2026 Jack
Lusher, and licensed under the GNU General Public License, version 3 only. A
later version of that license does not apply. `CITATION.cff` records the same
choice as `GPL-3.0-only`; change the two together. The full text is in
[LICENSE](LICENSE).

The license does not cover the IBM material. `comtran-manuals/` holds page
scans and conversions of two IBM publications from 1960–1962: F28-8043 and
J28-6169-1. Those works belong to IBM, and this repository includes them for
preservation and scholarship. The same applies to material transcribed from
them: the 90.05 sample deck and mirror in `test/fixtures/`, the golden listing
in `test/goldens/`, and the page crop shown above.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 90.02]: comtran-manuals/J28-6169/90.02-generated-code.md#appendix-9002
[J 90.05]: comtran-manuals/J28-6169/90.05-sample-program.md#appendix-9005
