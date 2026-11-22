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
# The compiler drops the text of a BCI card with a count and no label, so
# each of the twelve such cards gets the label XLBn in columns 1 to 6, n
# its statement number (Jack's call, issue #236). SYSCOL gets one label,
# XL009, on its first table card: unchanged, its text ends 1 word past a
# block, and IOEX drops that two-word record as noise (M7-7, issue #248).
# Sequence number, label:
labels='15700390 XLB30 15700410 XLB32 26300300 XLB24 26600520 XLB43
  26600540 XLB45 26600560 XLB47 29100300 XLB24 29100320 XLB26
  29400300 XLB16 29700280 XLB15 29700290 XLB16 29700300 XLB17
  16100090 XL009'
deck() { # the $ID card, the $CMPLE card and the source of routine $1
  awk -v want="$1" -v labels="$(echo $labels)" 'BEGIN {
    n = split(labels, f, " ")
    for (i = 1; i < n; i += 2) name[f[i]] = f[i + 1] }
  NR >= 55729 && NR <= 61616 {
    if (/^\$ID/) { id = $0; next }
    if (/^\$CMPLE/) { cur = $2; if (cur == want) print id }
    s = substr($0, 73, 8)
    if (s in name) {
      if (substr($0, 1, 6) != "      ") exit 1
      $0 = sprintf("%-6s", name[s]) substr($0, 7)
    }
    if (cur == want) print }' "$ct"
}
{
  echo '$EXECUTE       CT'
  while read -r _ name _ _; do deck "$name"; done <table.txt
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >x4.job
[ "$(grep -c '^XLB' x4.job)" -eq 12 ]
[ "$(grep -c '^XL009' x4.job)" -eq 1 ]
LIMIT=600 sh "$here/run_ibsys.sh" "$kit" x4.job x4.lst "$PWD/seed.bin"
mv syspp1.bin x4.pp.bin

# 3. SUBUP inserts the 40 compiled decks and writes the new library, two
# files, to SYSUT2. A blank type is secondary; SUBUP refuses SECONDARY.
# The scan of a type overwrites the TAPE indicator before SUBUP reads the
# *CTEXT card (SU020870, SU013900, SU021950), so a typed deck takes its
# *CTEXT card from the reader and the rest from SYSUT4. Thus the reader
# gets a *CTEXT card after each typed *INSERT card, SYSUT4 loses that
# deck's *CTEXT card, and the card count is 40 plus one for each.
# SUBUP tests a *CTEND card on SYSUT4 with a mask that accepts EVD, not
# END (SU023100, SU023160), so each *CTEND card gets EVD in columns 10 to 12.
typed=$(awk '$3 != "SECONDARY" { print NR }' table.txt)
{
  echo '$EXECUTE       CT'
  echo "\$SUBUP         MAP,$((40 + $(echo "$typed" | wc -l)))"
  while read -r _ name type org; do
    case $type in
    FIXED) t=",$org" ;;
    PRIMARY) t=,PRIMARY ;;
    *) t= ;;
    esac
    echo "TAPE  *INSERT  SR($name)$t"
    [ -z "$t" ] || echo '      *CTEXT'
  done <table.txt
} >subup.job
[ "$(grep -c '^      \*CTEXT' subup.job)" -eq 8 ]
dart run "$here/ctext_drop.dart" x4.pp.bin sysut4.bin $typed | tee drop.txt
grep -qx '40 \*CTEND cards rewritten' drop.txt
# SUBUP writes SYSUT2 from the start; the X4 job can leave a longer tape there.
rm -f sysut2.bin
sh "$here/run_ibsys.sh" "$kit" subup.job subup.lst "$PWD/seed.bin"
# run_ibsys.sh returns 0 when a job fails, so check the listing.
if grep -q 'NOT COMPLETED' subup.lst; then
  echo 'SUBUP failed: see subup.lst' >&2
  exit 1
fi
mv sysut2.bin library.bin

# 4. Splice the library into files 5 and 6.
dart run "$here/ct_lib.dart" splice seed.bin library.bin "$kit/CTSYS2.BIN"

# 5. Check: SUBUP with no changes prints the dictionary map of the new tape.
printf '%s\n' '$EXECUTE       CT' '$SUBUP         MAP' >map.job
sh "$here/run_ibsys.sh" "$kit" map.job map.lst "$kit/CTSYS2.BIN"
