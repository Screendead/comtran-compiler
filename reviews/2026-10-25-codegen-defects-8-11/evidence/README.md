# Evidence

- `today-fca3157.json`: `tools/probe.dart` run in a checkout of fca3157
  (origin/master). Gives each probe's source, procedure words from START,
  the pool's base words, any refusal, and the field values after a run on
  the machine assembly.
- `handle-8eb359a.json`: the same probes on the prototype branch at 8eb359a.
  Its `lib/` is that of f9505bf; the third commit adds a test only.
- `prototype-fca3157..8eb359a.diff`: the prototype's full diff (three commits).
- `golden-cited-words.txt`: the lines of `test/goldens/90.05-payroll.code`
  at fca3157 that the record cites: the DO FOR step (00702-00721), the chain
  parks (00621-00626), the comparand prologue and the subscript store
  (01404-01432), the subscripted MOVE source (01445-01451) and the pool
  bases (01741-01743).
- `sample-table-bytes.txt`: `tools/bytes.dart` run on the prototype branch
  (whose data map is master's): the word and byte of RATE, INSPREM and
  RETPREM in the sample's TABLE.ITEM. The first RATE line is MASTER's.
