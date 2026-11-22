#!/bin/sh
# Compiles and runs the 90.05 job and the applied 1960 payroll deck with the
# 1963 CT processor on CTSYS2.BIN, over our input tapes (M7-11 in
# docs/design/m7-diff.md).
# Usage: ct_run.sh KIT   (KIT holds the s709-2.4.4 and utils trees and the
# CTSYS2.BIN of ct_library.sh). It works in KIT/run/run/ and keeps:
# - units.lst, the unit table of IBSYS ($UNITS);
# - for each job NAME, the folder NAME/ with NAME.job, NAME.lst,
#   console.txt, each tape as UNIT.bin, and each output tape as UNIT.txt.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
mkdir -p "$kit/run/run"
cd "$kit/run/run"
conv() { (cd "$repo" && dart run tool/m7/tape_conv.dart "$@"); }

# 1. The unit table, to read beside a refusal of a unit by the loader.
rm -rf units && mkdir units && cd units
printf '$JOB\n$UNITS\n' >units.job
sh "$here/run_ibsys.sh" "$kit" units.job ../units.lst "$kit/CTSYS2.BIN"
cd ..

# 2. One job a deck: the job of ct_compile.sh with the option RUN, which
# loads and runs the object program after the compile (CE004360 to
# CE004660). Each file of the deck names its unit, for example UNIT1 'D1';
# the tape of that unit mounts there. An input tape is read only. The
# mode is the mode of the file: B binary, C BCD.
run() { # job name, deck, tape folder, inputs, outputs (UNIT:MODE ...)
  rm -rf "$1" && mkdir "$1" && cd "$1"
  (cd "$repo" && dart run comtran:deckconv to-text "test/fixtures/$2.ctd") \
    >deck.txt
  head -1 deck.txt | grep -q '^      \*COMPILE LIST'
  {
    echo '$EXECUTE       CT'
    echo '$ID'
    head -1 deck.txt | awk -v name="$1" \
      '{ c = sprintf("$CMPLE %-6s  %-38s %s", name, "LIST,DICT,RUN", substr($0, 55))
        sub(/ +$/, "", c); print c }'
    tail -n +2 deck.txt
    echo '$IBSYS'
    echo '$ENDFILE       SYSPP1'
  } >"$1.job"
  TAPES=
  for t in $4; do
    u=${t%:*} b=$(echo "${t%:*}" | tr 'A-Z' 'a-z')
    if [ "${t#*:}" = C ]; then bcd=--bcd; else bcd=; fi
    conv to-bin $bcd "$repo/test/fixtures/$3/$u.tap" "$PWD/$b.bin"
    TAPES="$TAPES ${b}r=$b.bin"
  done
  for t in $5; do
    b=$(echo "${t%:*}" | tr 'A-Z' 'a-z')
    TAPES="$TAPES $b=$b.bin"
  done
  TAPES=$TAPES LIMIT=180 sh "$here/run_ibsys.sh" "$kit" "$1.job" "$1.lst" \
    "$kit/CTSYS2.BIN"
  for t in $5; do
    b=$(echo "${t%:*}" | tr 'A-Z' 'a-z')
    [ -s "$b.bin" ] || continue
    if [ "${t#*:}" = C ]; then
      conv list "$PWD/$b.bin" >"$b.txt"
    else
      w=$PWD
      (cd "$repo" && dart run tool/m7/tape_map.dart --words "$w/$b.bin") \
        >"$b.txt"
    fi
  done
  cd ..
}

# The 90.05 files (test/fixtures/90.05-payroll.ct, the FILE cards):
# INPUTMASTER D1 and OUTPUTMASTER C1 are binary, the rest BCD.
run SAMPLE 90.05-payroll-job 90.05-tapes 'D1:B C2:C' 'C1:B D2:C D3:C C3:C D4:C'
# The applied deck: every file is BCD.
run FPAYRJ f-payroll-j f-payroll-tapes 'D1:C C2:C' 'D3:C D2:C D4:C'
