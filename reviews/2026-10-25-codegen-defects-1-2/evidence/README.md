# Evidence

- `today-ace4ee0.json`: `tools/probe.dart` run in a checkout of ace4ee0.
  Gives each probe's source, procedure words, refusal and field values after
  a run on the machine assembly.
- `align-0223ddf.json`: the same probes on the prototype branch at 0223ddf.
- `prototype-ace4ee0..0223ddf.diff`: the prototype's full diff.
- `today-sites-ace4ee0.dart.txt`: the code at the defect sites on ace4ee0,
  from `lib/src/codegen/procedure.dart` lines 2150-2162, 2275-2310,
  2655-2690, 2724-2734 and 2964-2985.
- `golden-attested-words.txt`: lines from `test/goldens/90.05-payroll.code`
  at ace4ee0 that hold the multiply, divide and exchange words the
  prototype uses.
- `corpus-pairs.md`: an inspection of every MOVE and ADD pair in the 1960
  payroll decks, showing that no pair has unequal scales.
