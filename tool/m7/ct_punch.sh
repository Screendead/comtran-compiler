#!/bin/sh
# Assembles the FAP steps of the archive's CT/ct.job under IBSYS, one job
# per step, and keeps each punch tape as <step>.pp.bin in the current folder.
# Usage: ct_punch.sh KIT   (KIT holds archive/, s709-2.4.4/ and utils/)
# Set ONLY=1 to rerun steps x5 and basic alone.
# Step x5 leaves out the first assembly, SRDLOC (cards SDL00010 to
# SDL00360): IBSFAP punches it and then never returns to IBSYS.
# Step basic is X2 again without the cards that IO000140 to IO000180 name;
# it gives the BASIC record.
set -e
kit=$1 ct=$1/archive/CT/ct.job here=$(dirname "$0")
step() { # name first last
  { echo '$EXECUTE       IBSFAP'
    awk -v a="$2" -v b="$3" -v basic="$4" 'NR>=a && NR<=b {
      s = substr($0, 73, 8)
      if (basic && ((s >= "IO001150" && s <= "IO001160") || s == "IO046000" ||
          (s >= "IO046310" && s <= "IO047490"))) next
      print }' "$ct"
    echo '$IBSYS'; echo '$ENDFILE       SYSPP1'; } >"$1.job"
  sh "$here/run_ibsys.sh" "$kit" "$1.job" "$1.lst"
  mv syspp1.bin "$1.pp.bin"
}
[ -n "$ONLY" ] || step x1 11 918
[ -n "$ONLY" ] || step x2 923 5675
[ -n "$ONLY" ] || step x3 5680 55719
step x5 61658 66676
step basic 923 5675 1
