#!/bin/sh
# Runs step X4 of the archive's CT/ct.job on the CT system tape: the 1963
# processor compiles the 40 decks of its own runtime library (M7-7 in
# docs/design/m7-diff.md).
# Usage: ct_library.sh KIT   (KIT holds archive/, s709-2.4.4/, utils/ and
# the CTSYS1.BIN that ct_tape.sh writes)
# It works in KIT/run/library/ and keeps x4.lst, the compile listing, and
# x4.pp.bin, the punch tape of the 40 relative binary decks.
# X4 starts at its $EXECUTE CT card; the $PAUSE before it asks an operator
# for a new output reel, and a simulator run has none to mount.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
ct=$kit/archive/CT/ct.job
mkdir -p "$kit/run/library"
cd "$kit/run/library"
{ awk 'substr($0, 73, 8) == "X4000090" { on = 1 }
       substr($0, 73, 8) == "X5000010" { exit }
       on' "$ct"
  echo '$IBSYS'; echo '$ENDFILE       SYSPP1'; } >x4.job
TIMEOUT=${TIMEOUT:-600} \
  sh "$here/run_ibsys.sh" "$kit" x4.job x4.lst "$kit/CTSYS1.BIN"
mv syspp1.bin x4.pp.bin
echo "compiles:  $(grep -c '^\$CMPLE' x4.job)"
echo "no errors: $(grep -c 'NO ERRORS WERE DETECTED' x4.lst || true)"
echo "decks:     $(grep -c 'THE LAST LOADER CONTROL CARD PUNCHED IS' x4.lst || true)"
