#!/bin/sh
# Probes the three library compiles that fail on the CT system tape:
# EXPERR, BCDERR and SYSCOL (M7-7 in docs/design/m7-diff.md). Each probe
# deck is one of the three with a change to the cards that M7-7 names.
# Usage: ct_probe.sh KIT [colag]   (KIT holds archive/, s709-2.4.4/, utils/
# and the CTSYS1.BIN that ct_tape.sh writes)
# It works in KIT/run/probe/, keeps probe.job and probe.lst, and prints one
# line for each deck: its name and the result line of its compile.
# With "colag" it compiles five decks with the COLAG option, which prints
# every internal text buffer, into colag.job and colag.lst instead.
set -e
kit=$(cd "$1" && pwd) here=$(cd "$(dirname "$0")" && pwd)
mode=${2:-probe}
ct=$kit/archive/CT/ct.job
mkdir -p "$kit/run/probe"
cd "$kit/run/probe"

# deck SRC NEW EDIT: the $ID card and the X4 deck SRC, renamed NEW on its
# $CMPLE card. EDIT is an awk statement run on each card, with s set to the
# sequence number in columns 73 to 80; "next" drops the card.
deck() {
  awk -v src="$1" -v new="$2" '
    substr($0, 73, 8) == "X4000090" { on = 1; next }
    substr($0, 73, 8) == "X5000010" { exit }
    !on { next }
    /^\$ID/ { id = $0; next }
    /^\$CMPLE/ { nm = substr($0, 8, 6); sub(/ +$/, "", nm); keep = nm == src
                 if (keep) { print id
                   $0 = substr($0, 1, 7) sprintf("%-6s", new) substr($0, 14) } }
    !keep { next }
    { s = substr($0, 73, 8) }
    '"$3"'
    { print }' "$ct"
}
# colag SEQ: an edit that adds COLAG to the options of the $CMPLE card
# with sequence number SEQ. The options end at the first blank, so the
# edit takes six of the blanks after them and no column moves.
colag() {
  echo "s == \"$1\" { sub(/LIST,DICT,SUB      /, \"LIST,DICT,SUB,COLAG\") }"
}
if [ "$mode" = colag ]; then
{
  echo '$EXECUTE       CT'
  # E0 holds a clean BCI card (statement 30) and the failing one (32).
  deck EXPERR E0 "$(colag 15700020)"
  # E1: both BCI cards hold the clean text; it compiles clean.
  deck EXPERR E1 "$(colag 15700020)"'
  s == "15700410" { sub(/ERROR IN EXPONENTIAL AT/, "EXPONENTIAL OVERFLOW AT") }'
  deck BCDERR B0 "$(colag 26300020)"
  # B5 compiles clean.
  deck BCDERR B5 "$(colag 26300020)"'
  s == "26300300" { sub(/CHARACTER/, "XXXXXXXXX") }'
  # KAPUT compiled clean in X4 and holds nine BCI 1 cards.
  deck KAPUT K0 "$(colag 26600020)"
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >colag.job
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" colag.job colag.lst "$kit/CTSYS1.BIN"
grep -E 'NO ERRORS WERE DETECTED|SEVERITY LIMIT WAS' colag.lst || true
exit
fi
{
  echo '$EXECUTE       CT'
  # EXPERR fails at statement 32, card 15700410, BCI 4,ERROR IN EXPONENTIAL AT.
  deck EXPERR E0 ''
  deck EXPERR E1 's == "15700410" { sub(/ERROR IN EXPONENTIAL AT/, "EXPONENTIAL OVERFLOW AT") }'
  deck EXPERR E2 's == "15700410" { next }'
  deck EXPERR E3 's == "15700420" || s == "15700430" { next }'
  deck EXPERR E4 's == "15700410" { sub(/ERROR/, "XXXXX") }'
  deck EXPERR E5 's == "15700410" { sub(/ IN /, " XX ") }'
  # BCDERR fails at statement 24, card 26300300, BCI 3,NUMERIC CHARACTER.
  deck BCDERR B0 ''
  deck BCDERR B1 's == "26300300" { sub(/NUMERIC CHARACTER/, "NUMBER OF BUFFERS") }'
  deck BCDERR B2 's == "26300300" { next }'
  deck BCDERR B3 's == "26300320" { next }'
  deck BCDERR B4 's == "26300300" { sub(/NUMERIC/, "XXXXXXX") }'
  deck BCDERR B5 's == "26300300" { sub(/CHARACTER/, "XXXXXXXXX") }'
  # SYSCOL fails at statement 68, its ENTER COMMERCIAL TRANSLATOR card.
  # Cards 16100090 to 16100720 are its table of 64 words.
  deck SYSCOL S0 ''
  deck SYSCOL S1 's >= "16100410" && s <= "16100720" { next }'
  deck SYSCOL S2 's >= "16100090" && s <= "16100400" { next }'
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >probe.job
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" probe.job probe.lst "$kit/CTSYS1.BIN"
grep '^\$CMPLE' probe.job | cut -c8-13 >names.txt
grep -E 'NO ERRORS WERE DETECTED|SEVERITY LIMIT WAS' probe.lst >results.txt || true
paste -d' ' names.txt results.txt
