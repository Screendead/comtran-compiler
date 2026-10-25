  questions part company here for the first time.

  **The severity finding.** [J 90.04.02]: "The Severity Codes (values)
  are numbered 1 through 5 ... An error severity code of 1 does not
  prevent the running of the object program immediately after
  compilation. Any code above 1 does prevent running ... An error
  severity code of 5 causes the compiler to stop compiling."
  [J 02.01.01]: "If the severity code is 5, a deck will not be
  produced." [J 02.01.02] makes execution conditional on no error above
  severity 1 and on no undefined symbol in the generated code.
  [J 90.04.01] prints CODE 0 against every message "because the value
  may vary", so no printed value survives.

  The verbatim deck draws twelve message kinds: 166, 108, 101, 9, 19,
  21, 175, 110, 81, 80, 206, and our own 906. None of the twelve is
  worded as a stop, a deletion or a repair. J holds that vocabulary and
  uses it elsewhere: 2,00 "-RUN- DELETED.", 25,00 "OPERATION IGNORED",
  171,00 "SENTENCE DELETED FROM TEXT." Our severities are D7.5's, and
  they run 1 to 4 and never 5. So `test/goldens/f-payroll.listing`
  closes SEVERITY LIMIT WAS NOT REACHED, and the driver goes on to code
  generation. There the refusal `a GET record on 0 input files (no
  sample instance)` stops it.

  Under J's letter, then, the 1962 processor compiled the 1960 deck as
  punched, punched an object deck, and refused to run it. No evidence
  describes what that deck held. It held a GET on a record bound to no
  file, 26 undefined names, and a GRAND.TOTAL left empty because COPY
  was deferred. The severities that could change this are unattested
  (Open Question 65).

  **The one question for Jack.** Does "compile" in his rule mean the
  diagnostic listing, or the object deck?

  - *For the listing.* The listing is the artifact our corpus
    reproduces and a golden pins, and chunk 2a already delivered it
    whole. The object deck is unreachable: no evidence describes the
    code for a GET bound to no file, and inventing it breaks D0.4.
  - *For the object deck.* To compile in 1962 was to punch a deck.
    [J 02.01.01] ties deck production to the severity code alone, and
    our severities allow it. A compiler that stops short of the deck
    has not compiled. On this reading the refusal marks a gap in our
    recovery and not a property of the program.

  **Recommendation.** Keep the refusal for the verbatim deck, and
  relabel it. The honest label is "1962 punched a deck whose content no
  evidence describes", not "1962 refused". Take the listing as the
  deliverable of that deck. The applied deck is where chunk 2b works,
  so nothing in the repository waits on the answer. The question is
  Jack's call under his rule, and the review record on branch
  `review/2026-09-14-m6s2-rule` carries it to him.

  **Chunk 2b's design list.** Each item is a recorded decision under
  D0.4, with no listing oracle behind it:

  - the external-decimal fetch, SYS)181 or SYS)182 with SYS)184;
  - the external-decimal store, SYS)180 with SYS)186, 187 or 188;
  - `FILE record IN file`;
  - a comparison whose sides are expressions;
  - a product of a product;
  - the SYS)190 bypass steps, with the page-158 notes measured at build
    time;
  - the 11-character table stride, which carries codegen defect 7 with
    it (`docs/HANDOVER.md`);
  - `STOP n` at run time: the halt and the resume (Open Question 69).
  - a numeric comparison of unequal scales, added 2026-10-25 by the
    fetch decision below.

  **Decided 2026-10-24: `FILE record IN file`. A design decision
  under D0.4; Jack can overturn it.** This is the third item of the
  list above, and the first item done. The generator now compiles the
  IN form to the call of plain FILE, with the named file in the file
  word:

  ```
  TSX    IOC)9,4
  PZE    file,,0
  IOST   record,,length
  ```

  A located record takes the LXA and SXA pair ahead of the call, the
  same as plain FILE. No listing shows the IN form. The decision rests
  on four facts:

  - The 1962 sample attests the IOC)9 call of plain FILE, and its file
    word names one file.
  - [J 02.07.08] b gives the IN form "a means of filing a record in a
    specific file". The form names that one file, so the call names
    it.
  - PRIMARY does not change the call. [J 02.06.07] binds PRIMARY to
    the plain form: "The 'FILE record.name' command will file records
    belonging to more than one output file only in those files where
    PRIMARY has been specified".
  - The record can sit on several output files. The plain form still
    refuses that case, because no sample attests the order of its
    calls. The IN form makes one call, so it has no order.

  [J 02.07.08] 2 a asks that the record be "associated in the
  Environment Description" with the named file. Where it is not, the
  front end prints message 195,00. The generator then refuses the
  shape `FILE record IN a file that is not an output file of the
  record`. No evidence shows what code the 1962 processor made for it.
  The same refusal covers an IN form that names an input file. The
  front end then prints message 22,00, also at severity 3.

  This refusal falls under the question for Jack above. The message
  says "CANNOT FILE RECORD 'NAME.2' IN THIS FILE". Our severity for it
  is 3 (D7.5), and [J 90.04.01] prints no value. At severity 3 the 1962
  processor punched a deck and did not run it ([J 90.04.02]). The case
  is the verbatim deck's case: a listing exists, and no evidence
  describes the deck. His answer decides both refusals.

  The tests:
