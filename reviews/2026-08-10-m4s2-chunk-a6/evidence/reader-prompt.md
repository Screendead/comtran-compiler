  const dir = `${SCRATCH}/page-${page.pdf}`
  return `You are a blind reader of one printed page. Your only source of truth is the image file
${REPO}/comtran-manuals/J28-6169/images/page-${page.pdf}.png

That page is one page of a 1962 IBM compiler's object listing: rows of a fixed-pitch line
printer, in six fields, under a page head. Your job is to read what the ink says and to
measure how the page is laid out, so that a separate comparison can hold a transcription
made by somebody else to account. You never see that transcription.

HARD BAN. Do not open, read, grep, list, diff, or git-log any of these, and do not read any
file that quotes them:
  - ${REPO}/test/fixtures/90.05-object-listing.target
  - ${REPO}/test/fixtures/90.05-object-listing-notes.md
  - ${REPO}/tool/object_listing_target_source.dart
  - ${REPO}/tool/generate_object_listing_target.dart
  - ${REPO}/comtran-manuals/J28-6169/90.05-sample-program.md
  - ${REPO}/docs/design/m4-codegen.md and ${REPO}/docs/design/m1-front-end.md
  - anything under ${REPO}/test/goldens/
  - any other page scan than your own
A reading that came from a transcription is worthless here, because the transcription is the
thing under test. If you catch yourself about to consult one, stop, and say so in your
contamination report. Reading ${REPO}/comtran-manuals/J28-6169/02-compiler.md for what a
field means is allowed; reading anything that prints this page's values is not.

WORK ONLY INSIDE ${dir}
It is yours alone. Three readers run at this moment, one per page. In the last chunk two
readers shared one directory, both wrote a working file under the same name, and one reader's
rotation of its own scan silently overwrote the other's. Never write a file outside your
directory, and never read one another reader wrote.

TOOLING. python3 has PIL and numpy. It does not have scipy. Write your scripts into your own
directory and run them there.

METHOD, in this order.

1. Count before you transcribe. Model the page body as a frame of line slots at one pitch,
   with the page head as slot 0. Report how many empty slots sit between the head and the
   first content line, how many content lines print, which slot the last content line sits
   in, and whether any slot inside the body is empty. Record a blank as a value, not as an
   absence: a sweep that counts only the rows that carry text loses a row and never notices.
   Prove an empty slot by sweeping it for ink at several thresholds, and say which thresholds.

2. Fit this page's own grid. Deskew first. Then fit the character advance and the origin over
   the whole printed width, roughly print columns 0 to 90, from intensity-weighted ink
   centroids. Fit centroids, never glyph left edges: a 3 starts further right inside its cell
   than a 0 does, and a left-edge fit carries that shape bias into the origin by more than a
   pixel. Do not fit the advance on the twelve-digit machine-word field alone. That short
   baseline is a trap with a measured price: on an earlier page it gave 9.4545 px against that
   page's true 9.296 px, which is more than ten cells of drift by column 67. Report the
   advance, the origin, the deskew angle, the line pitch, how many centroids you fitted, and
   the residual.

3. Remove the form rules by the margin test, not by a run-length filter. A filter that deletes
   an image row whose longest horizontal ink run reaches 25 px deletes the solid rules and
   misses every dashed one, because the dashes print about 6 px. Both kinds print ink in the
   left and the right margin, where no text prints, and both span far more of the page width
   than the widest line of text. That is the test that catches both. Expect the rules to cross
   the text, which can leave a content line as few as 5 clean image rows, so read doubtful
   cells from a crop rather than from the whole-row bitmap.

4. Transcribe every content line, in print order, as six fields: LOC, OCTAL, CNTRL, then
   either a label or a +n offset, then the mnemonic, then the operand. Some lines print only
   some of the six. Give the measured print column of each field you find, and say whether an
   offset is left- or right-justified in its field if this page can tell.

5. Report every glyph you were not certain of, name the alternative you rejected, and give the
   evidence that decided it. If the ink genuinely does not choose, say so and give both
   readings rather than picking one silently. Report any mark you judged to be a speck rather
   than a character, with the measurement that decided it and the reading you would fall back
   to. This chain prints B and 8 as nearly the same shape, and it drops the right stroke of
   some 0 glyphs; both have caught earlier readers.

6. Run self-checks and report the result of each. A line that prints its machine word twice
   must agree digit for digit. The location sequence must run unbroken, with correct octal
   carries. Each mnemonic must agree with the opcode prefix of its own octal word. An address
   that names a label must resolve to that label's own location. A tag or a decrement must
   agree with the word that carries it. Report the first and the last LOC on the page.

An invented example of the record shape. These values are made up, they are not on your page,
and you must not expect to find them:
  slot 07 | LOC 07777 | OCTAL 0 77777 0 77777 | CNTRL 99999 | +99 | XYZ | ZZZ)999,9,9

DELIVERABLES, both written before you return:
  ${dir}/transcription.txt  one record per content line, in print order, in the shape above,
                            with a slot number on every line, including the empty slots.
  ${dir}/report.md          the geometry, the slot count, the rule measurement, every doubtful
                            glyph, every rejected speck, every self-check, and your method
                            notes for a later reader.

Then return the structured result. Report honestly: an unread cell that you say you could not
read costs one cell, and an unread cell that you guess costs the whole page its standing.`
