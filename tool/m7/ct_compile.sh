#!/bin/sh
# Compiles the corpus decks with the 1963 CT processor on CTSYS2.BIN, one
# job per deck (M7-8 in docs/design/m7-diff.md).
# Usage: ct_compile.sh KIT   (KIT holds the s709-2.4.4 and utils trees and
# the CTSYS2.BIN of ct_library.sh). It works in KIT/run/compile/ and keeps,
# for each deck NAME, NAME.job, NAME.lst and the punch tape NAME.pp.bin.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
mkdir -p "$kit/run/compile"
cd "$kit/run/compile"

# The 1962 deck opens with *COMPILE LIST (J 02.01.01). The 1963 compiler
# takes the $CMPLE card in its place: the job name in columns 8 to 13, the
# options from column 16, and an identification in columns 55 to 72
# (CB024100 to CB024160, CB025870). The card keeps LIST and its columns
# 55 to 72, and adds DICT. The rest of the deck goes in unchanged.
compile() { # job name, deck
  (cd "$repo" && dart run comtran:deckconv to-text "test/fixtures/$2.ctd") \
    >"$2.txt"
  head -1 "$2.txt" | grep -q '^      \*COMPILE LIST'
  {
    echo '$EXECUTE       CT'
    echo '$ID'
    head -1 "$2.txt" | awk -v name="$1" \
      '{ c = sprintf("$CMPLE %-6s  %-38s %s", name, "LIST,DICT", substr($0, 55))
        sub(/ +$/, "", c); print c }'
    tail -n +2 "$2.txt"
    echo '$IBSYS'
    echo '$ENDFILE       SYSPP1'
  } >"$2.job"
  rm -f sys*.bin
  LIMIT=120 sh "$here/run_ibsys.sh" "$kit" "$2.job" "$2.lst" "$kit/CTSYS2.BIN"
  mv syspp1.bin "$2.pp.bin"
}
compile SAMPLE 90.05-payroll-job
compile FPAYRL f-payroll
compile FPAYRJ f-payroll-j
