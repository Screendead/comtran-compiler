#!/bin/sh
# Builds CTSYS1.BIN, an IBSYS system tape that holds the 1963 Commercial
# Translator, from the archive's CT/ct.job (M7-6 in docs/design/m7-diff.md).
# Usage: ct_tape.sh KIT   (KIT holds archive/, s709-2.4.4/ and utils/)
# It works in KIT/run/ and writes KIT/CTSYS1.BIN.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$kit/run/punch" "$kit/run/edit"
cd "$kit/run/punch"
sh "$here/ct_punch.sh" "$kit"
# The editor reads SYSUT2 straight through, so the programs go on it in the
# order of the ten CT files: CT, BASIC, CTB to CTE, IOCS, LOAD, IOBB, IOBM,
# NOBS, SUBUP, MAIN.
dart run "$here/punch_split.dart" x1.pp.bin basic.pp.bin x3.pp.bin \
  x2.pp.bin x5.pp.bin -o ../edit/sysut2.bin \
  0:0 1:0 2:0 2:1 2:2 2:3 2:4 3:0 2:5 3:1 3:2 3:3 4:0 4:1
cd ../edit
sh "$here/run_ibsys.sh" "$kit" "$here/ct_edit.job" edit.lst
cp sysut1.bin "$kit/CTSYS1.BIN"
