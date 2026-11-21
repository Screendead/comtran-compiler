# M6-11 — The object deck of the 1960 program as keyed

*Recorded 2026-11-21. This file holds entry M6-11 of `m6-acceptance.md`,
which has no room for it. The entry adds no language claims. Each form
below is our own design under D0.4, and Jack can overturn it. No source
shows the code. Evidence exists and is sealed until M7.*

## The ground

Jack ruled on 2026-11-21: "punch the object deck as 1962 did"
(`m6-acceptance.md` M6-9 as amended).

- The 1962 processor withheld the deck at severity 5 only ([J 02.01.01]).
- It did not run a job above severity 1 ([J 90.04.02]).
- The 1960 program as keyed, `test/fixtures/f-payroll.ctd`, compiles at
  severity 4 under our table (D7.5).

So the processor punched a deck for that program and did not run it.
No message of that program names a stop, a deletion or a repair
(M6-9). So the processor wrote code for each statement, and no page
shows that code.

## The entry

- **M6-11. The generator leaves out the words that it cannot write,
  and it keeps every other word of the statement.** The verbatim deck
  reaches shapes that the generator refused. In each one, a statement
  needs a thing that the program does not define. The
  generator invents no field class, no file and no instruction for it.
  It removes the smallest unit that needs the missing thing. The words
  around that unit keep their attested forms. A clause inside the
  statement is a unit of its own, and it compiles as it stands.

  **a. An operand that names no data item is an undefined symbol in
  the text.** The resolver binds the operand to no item and prints a
  message. In the verbatim deck the messages are 26 rows of 108,00 and
  seven rows of 101,00. Any other message that leaves an operand
  unbound takes the same form.

  Each such reference writes one word, in source order:

  ```
  0 00000 0 00000   10000      PZE    name,,0
  ```

  - The word is the address reference of [J 90.02.14], Case 1,
    `PZE LOC,,BYTE`. In that form the generated code names a data item
    and does no operation on it.
  - `name` is the last word of the reference. A symbol holds no blank,
    so the qualifiers do not print.
  - The address and the byte are zero, and their class is constant.
    The symbol has no value, so the loader adds nothing to the word
    ([J 90.03.04]).

  The instructions that read or store an operand depend on its class,
  its scale and its length. An undefined name has none of the three. So
  the unit that holds the operand writes no other word:

  - A comparison of an IF or of a GO TO WHEN writes no compare word and
    no skip vector. The transfer of a GO TO WHEN is a slot of the
    vector, so it goes also. The arms of an IF stay, with the join
    transfer and the two labels.
  - A SET or an ADD writes its address words only.
  - Each target of a MOVE is a clause of its own (M4-14). An unbound
    target loses its own move. An unbound source loses each move of the
    clause.

  The ground is [J 02.01.02]. The program does not run where the compiler
  finds "an undefined symbol in the code which it has generated". D9.13
  reads message 108,00 as that symbol. So the name stays in the text.
  Two other forms lost:

  - *Instructions with a default class.* This form invents a class for
    each name. Each verb then needs forms that no sample attests, such
    as a figurative comparison of a numeric field.
  - *No word.* The text then holds no undefined symbol, against
    [J 02.01.02] and D9.13.

  The symbol bars the run on its own. [J 02.01.02] names two bars, the
  severity and the undefined symbol, and D9.1 makes each a gate of its
  own. `--run` tests both, and each bar that holds prints its line:

  ```
  job 1: not run: maximum severity 4
  job 1: not run: undefined symbol in the generated code
  ```

  D9.1 asks for a test of the second gate at severity 1. No program
  reaches that state. Each message that leaves an operand unbound has
  a severity above 1: 25,00 and 101,00 have 2, 166,00 has 3, and 108,00
  has 4. So the verbatim deck is the test of both gates.

  The form covers the operands of a comparison, a SET, an ADD and a
  MOVE. The verbatim deck reaches no other site, and each other site
  stays as it was:

  - An unbound name keeps its refusal in a subscript, in a truth
    function, below a sign, and as a DO FOR index.
  - A CORRESPONDING clause pairs no field with an unbound operand
    ([J 02.04.04]). It writes no word for that operand.

  **b. A GET or a FILE that has no file writes no call.** The sites:

  | Message | Shape | Statements |
  |---|---|---|
  | 9,00 | GET of a record on no input FILE card | 3, 4, 7 |
  | 19,00 | FILE of a record on no output FILE card | 13, 21, 22, 23 |
  | 21,00 | `FILE record IN name`, and `name` is not a file | 6, 9, 36 |

  Message 10,00, for a record on output FILE cards only, takes the form
  of 9,00.

  - The call of a GET is the stamp, `TSX IOC)8,4`, the file word, the
    exit word and the buffer descriptor (M4-15). The call of a FILE is
    `TSX IOC)9,4`, the file word and the `IOST` word.
  - The file word has no file to name. The record of the GET has no
    buffer locator also, because only a record on an input file is
    located ([J 02.07.05]).
  - A calling sequence that lacks a word is not a call. So the whole
    sequence stays out.
  - The GET keeps its frame: `TRA` to the join, the AT END block under
    its label, and the join. The clause after AT END is an imperative
    statement of its own (D6.6). Nothing enters the block, because the
    exit word went with the call.

  The severity table of D9.2, `lib/src/lexer/severities.dart`, already
  states this loss. For 9,00 it says "all I/O for that record is lost",
  and for 21,00 "the referring statement is lost". Two other forms
  lost:

  - *The call with a zero file word.* This form invents a file number
    that no `*FILE` card defines. For the GET it also invents a
    descriptor for a record that has no buffer.
  - *`name` of the IN form as an undefined symbol.* Message 21,00 is
    not message 108,00. It reports a FILE statement that names no file.
    It does not report a symbol of the generated code.

  The two other faults of the IN form keep their refusal (M6-9, the
  decision of 2026-10-24). Messages 22,00 and 195,00 report them, and no
  deck reaches them.

  **c. COPY leaves no shape.** Message 110,00 defers COPY
  ([J 90.01.03]). `GRAND.TOTAL` has no entry below it and reserves no
  storage. The two CORRESPONDING clauses that name it, in statements 13
  and 23, pair no field with it ([J 02.04.04]). They write no word for it,
  and the generator needed no change.

## The result

- The verbatim deck compiles to 35 cards: `*CTEXT`, 33 text cards and
  `*CTEND`. It has no `*FILE` card, because the program has no FILE
  card.
- The text holds 33 undefined symbols, one for each row of 108,00 and
  101,00.
- `comtranc` prints the listing and exits with status 0, because only
  severity 5 changes the status (D11.2). With `--run` it also prints
  the two lines of item a on the error stream.
- No golden moves. The sample and the applied deck reach none of
  these shapes.
- `test/f_corpus_test.dart` pins the card count, the count of the
  undefined symbols against the message rows, and the refused run. The
  deck is the output of our design, not an oracle.
- `test/codegen_refusal_test.dart` loses the refusals that now compile.
  It gains a FILE record on two output files, which still refuses, and
  an undefined subscript variable.

<!-- manual links; generated by tool/linkify_manual_refs.dart -->

[J 02.01.01]: ../../comtran-manuals/J28-6169/02-compiler.md#0200-introduction
[J 02.01.02]: ../../comtran-manuals/J28-6169/02-compiler.md#a-cmple-card
[J 02.04.04]: ../../comtran-manuals/J28-6169/02-compiler.md#3-move
[J 02.07.05]: ../../comtran-manuals/J28-6169/02-compiler.md#1-factors-affecting-choice-and-use-of-locate-or-transmit-mode
[J 90.01.03]: ../../comtran-manuals/J28-6169/90.01-deferred-features.md#1-language
[J 90.02.14]: ../../comtran-manuals/J28-6169/90.02-generated-code.md#sys-reference-numbers
[J 90.03.04]: ../../comtran-manuals/J28-6169/90.03-object-deck-format.md#1-format
[J 90.04.02]: ../../comtran-manuals/J28-6169/90.04-error-messages.md#a-error-messages
