#!/bin/sh
# Builds CTSYS2.BIN: the CT system tape CTSYS1.BIN with the CT subroutine
# library in CT files 5 and 6 (M7-7 in docs/design/m7-diff.md).
# Usage: ct_library.sh KIT   (KIT holds archive/, s709-2.4.4/, utils/ and
# the CTSYS1.BIN of ct_tape.sh). It works in KIT/run/lib/ and writes
# KIT/CTSYS2.BIN. Each job's listing stays there: x4.lst, subup.lst, map.lst.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
ct=$kit/archive/CT/ct.job
mkdir -p "$kit/run/lib"
cd "$kit/run/lib"
rm -f ./*.bin

# 1. Seed: file 5 gets SRDLOC and an empty dictionary, which SUBUP must read.
dart run "$here/ct_lib.dart" seed "$kit/CTSYS1.BIN" seed.bin

# The 40 library routines in subroutine-number order: number, name, type,
# and fixed origin, from the comment cards 00300110 to 00300890 of ct.job.
awk 'substr($0, 73, 5) == "00300" &&
  /^\* +[0-9]+  [0-9A-Z]+ +(FIXED|PRIMARY|SECONDARY)/ { print $2, $3, $4, $5 }' \
  "$ct" >table.txt
[ "$(wc -l <table.txt)" -eq 40 ]

# 2. Step X4 of ct.job: CT compiles the 40 decks, in table order, because
# SUBUP reads them from SYSUT4 in the order of its *INSERT cards.
deck() { # the $ID card, the $CMPLE card and the source of routine $1
  awk -v want="$1" 'NR >= 55729 && NR <= 61616 {
    if (/^\$ID/) { id = $0; next }
    if (/^\$CMPLE/) { cur = $2; if (cur == want) print id }
    if (cur == want) print }' "$ct"
}
{
  echo '$EXECUTE       CT'
  while read -r _ name _ _; do deck "$name"; done <table.txt
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >x4.job
LIMIT=600 sh "$here/run_ibsys.sh" "$kit" x4.job x4.lst "$PWD/seed.bin"
mv syspp1.bin x4.pp.bin

# 3. SUBUP inserts the 40 compiled decks and writes the new library, two
# files, to SYSUT2. A blank type is secondary; SUBUP refuses SECONDARY.
{
  echo '$EXECUTE       CT'
  echo '$SUBUP         MAP,40'
  while read -r _ name type org; do
    case $type in
    FIXED) t=",$org" ;;
    PRIMARY) t=,PRIMARY ;;
    *) t= ;;
    esac
    echo "TAPE  *INSERT  SR($name)$t"
  done <table.txt
} >subup.job
ln -sf x4.pp.bin sysut4.bin
sh "$here/run_ibsys.sh" "$kit" subup.job subup.lst "$PWD/seed.bin"
mv sysut2.bin library.bin

# 4. Splice the library into files 5 and 6.
dart run "$here/ct_lib.dart" splice seed.bin library.bin "$kit/CTSYS2.BIN"

# 5. Check: SUBUP with no changes prints the dictionary map of the new tape.
printf '%s\n' '$EXECUTE       CT' '$SUBUP         MAP' >map.job
sh "$here/run_ibsys.sh" "$kit" map.job map.lst "$kit/CTSYS2.BIN"
