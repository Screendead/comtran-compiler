#!/bin/sh
# Builds CTSYS3.BIN: CTSYS2.BIN with an IBSYS nucleus that has four tapes on
# channel C and four on channel D (M7-11 in docs/design/m7-diff.md).
# Usage: ct_units.sh KIT   (KIT holds archive/, s709-2.4.4/, utils/ and the
# CTSYS2.BIN of ct_library.sh). It works in KIT/run/units/ and writes
# KIT/CTSYS3.BIN. It keeps nuc.job, nuc.lst (the assembly) and edit.lst (the
# editor map).
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$kit/run/units"
cd "$kit/run/units"
rm -f ./*.bin

# 1. The nucleus of ASYS1.BIN is IBSYS/ibsys.map. Four cards change, found by
# their sequence numbers: CHC1 and CHD1 give four tapes to channels C and D,
# and CHCAT and CHDAT mark those tapes attached. A bit is 1 for a device that
# is not attached, from the left: reader, punch, printer, tapes 1 to 10.
# ibsys2.map adds channel B, and ibsys3.map channels C and D, the same way.
awk 'BEGIN {
    new["IBB01720"] = "CHC1   EQU     4"
    new["IBB01770"] = "CHCAT  BOOL    16077"
    new["IBB02290"] = "CHD1   EQU     4"
    new["IBB02340"] = "CHDAT  BOOL    16077" }
  { s = substr($0, 73, 8) }
  s in new { printf "%-72s%s\n", new[s], substr($0, 73); n++; next }
  { print }
  END { if (n != 4) exit 1 }' "$kit/archive/IBSYS/ibsys.map" >nuc.job
printf '$IBSYS\n$ENDFILE       SYSPP1\n' >>nuc.job

# 2. IBJOB assembles the nucleus with IBMAP and punches it to SYSPP1.
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" nuc.job nuc.lst "$kit/CTSYS2.BIN"
[ -s syspp1.bin ] || { echo "ct_units.sh: no nucleus deck punched" >&2; exit 1; }
mv syspp1.bin sysut2.bin

# 3. The editor replaces the IBSYS record from SYSUT2 and copies the rest of
# the tape. It writes its own name table into the new record (VV151D of
# EDITOR/editor.map), so CT stays in the table.
printf '%s\n' '$JOB           CT UNITS' '$IBEDT' \
  '      *EDIT    MAP                                    CT UNITS' \
  'TAPE  *REPLACE IBSYS' >edit.job
sh "$here/run_ibsys.sh" "$kit" edit.job edit.lst "$kit/CTSYS2.BIN"
cp sysut1.bin "$kit/CTSYS3.BIN"
