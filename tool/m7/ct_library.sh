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
# DECKS="EXPERR SYSCOL" keeps only the $ID and $CMPLE decks of those names,
# and NAME=x4a names the outputs x4a.job, x4a.lst and x4a.pp.bin.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
ct=$kit/archive/CT/ct.job
mkdir -p "$kit/run/library"
cd "$kit/run/library"
n=${NAME:-x4}
{ awk -v decks=" $DECKS " 'BEGIN { keep = 1 }
    substr($0, 73, 8) == "X4000090" { on = 1 }
    substr($0, 73, 8) == "X5000010" { exit }
    !on { next }
    /^\$ID/ { id = $0; next }
    /^\$CMPLE/ { nm = substr($0, 8, 6); sub(/ +$/, "", nm)
                 keep = decks == "  " || index(decks, " " nm " ") > 0
                 if (keep) print id }
    keep' "$ct"
  echo '$IBSYS'; echo '$ENDFILE       SYSPP1'; } >"$n.job"
TIMEOUT=${TIMEOUT:-600} \
  sh "$here/run_ibsys.sh" "$kit" "$n.job" "$n.lst" "$kit/CTSYS1.BIN"
mv syspp1.bin "$n.pp.bin"
echo "compiles:  $(grep -c '^\$CMPLE' "$n.job")"
echo "no errors: $(grep -c 'NO ERRORS WERE DETECTED' "$n.lst" || true)"
echo "decks:     $(grep -c 'THE LAST LOADER CONTROL CARD PUNCHED IS' "$n.lst" || true)"
