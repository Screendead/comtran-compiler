#!/bin/sh
# Probes the three library compiles that fail on the CT system tape:
# EXPERR, BCDERR and SYSCOL (M7-7 in docs/design/m7-diff.md). Each probe
# deck is one of the three with a change to the cards that M7-7 names.
# Usage: ct_probe.sh KIT [colag|label|syscol|pad]   (KIT holds archive/, s709-2.4.4/,
# utils/ and the CTSYS1.BIN that ct_tape.sh writes)
# It works in KIT/run/probe/, keeps probe.job and probe.lst, and prints one
# line for each deck: its name and the result line of its compile.
# With "colag" it compiles five decks with the COLAG option, which prints
# every internal text buffer, into colag.job and colag.lst instead.
# With "label" it compiles three decks with COLAG, each with a label on
# the BCI cards that have none, into label.job and label.lst instead.
# With "syscol" it compiles six variants of SYSCOL, each with a change to
# the references of its table, into syscol.job and syscol.lst instead.
# With "pad" it compiles four variants of SYSCOL that move its ENTER
# COMMERCIAL TRANSLATOR card with BSS 0 cards, into pad.job and pad.lst.
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
# label SEQ NAME: an edit that puts the label NAME in columns 1 to 6 of
# the card with sequence number SEQ. The card had no label.
label() {
  echo "s == \"$1\" { \$0 = sprintf(\"%-6s\", \"$2\") substr(\$0, 7) }"
}
if [ "$mode" = label ]; then
{
  echo '$EXECUTE       CT'
  # Each deck gives a label to the BCI cards that have none, and prints
  # its internal text with COLAG.
  deck EXPERR E6 "$(colag 15700020)
  $(label 15700390 XLB30)
  $(label 15700410 XLB32)"
  deck BCDERR B6 "$(colag 26300020)
  $(label 26300300 XLB24)"
  deck KAPUT K1 "$(colag 26600020)
  $(label 26600520 XLB43)
  $(label 26600540 XLB45)
  $(label 26600560 XLB47)"
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >label.job
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" label.job label.lst "$kit/CTSYS1.BIN"
grep -E 'NO ERRORS WERE DETECTED|SEVERITY LIMIT WAS' label.lst || true
exit
fi
# table EXPR: an edit that applies the sub() of EXPR to columns 1 to 72
# of each card of the SYSCOL table, 16100090 to 16100720, and pads them
# with blanks, so the sequence number stays in columns 73 to 80.
table() {
  echo "s >= \"16100090\" && s <= \"16100720\" { t = substr(\$0, 1, 72); $1
    \$0 = sprintf(\"%-72s\", t) substr(\$0, 73) }"
}
if [ "$mode" = pad ]; then
pad='sprintf("%-72s", "       BSS     0") s'
{
  echo '$EXECUTE       CT'
  # S0 fails at statement 68, its ENTER COMMERCIAL TRANSLATOR card.
  deck SYSCOL S0 ''
  # S8: S0 and one BSS 0 card before the table; the ENTER card is 69.
  deck SYSCOL S8 's == "16100080" { print; print sprintf("%-72s", \
    "       BSS     0") "16100081"; next }'
  # S9: S2, with a BSS 0 card for each of the 32 cards it drops; the
  # ENTER card is 68, with 32 table words.
  deck SYSCOL S9 's >= "16100090" && s <= "16100400" { print '"$pad"'; next }'
  # S10: S5, with a BSS 0 card for the card it drops; the ENTER card is
  # 68, with 63 table words.
  deck SYSCOL S10 's == "16100720" { print '"$pad"'; next }'
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >pad.job
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" pad.job pad.lst "$kit/CTSYS1.BIN"
grep '^\$CMPLE' pad.job | cut -c8-13 >names.txt
grep -E 'NO ERRORS WERE DETECTED|SEVERITY LIMIT WAS' pad.lst >results.txt || true
paste -d' ' names.txt results.txt
exit
fi
if [ "$mode" = syscol ]; then
{
  echo '$EXECUTE       CT'
  # S0 fails at statement 68. Its table makes 64 references to SYSCOL.
  deck SYSCOL S0 ''
  # S3: no table word names a symbol; each address is 0.
  deck SYSCOL S3 "$(table 'sub(/SYSCOL,,/, "0,,", t)')"
  # S4: the first 56 table words, 56 references.
  deck SYSCOL S4 's >= "16100650" && s <= "16100720" { next }'
  # S5: the first 63 table words, 63 references.
  deck SYSCOL S5 's == "16100720" { next }'
  # S6: 64 table words; the second half names SYSCO2, a second label of
  # the same location, so each symbol has 32 references.
  deck SYSCOL S6 's == "16100080" { print; print sprintf("%-72s", \
    "SYSCO2 BSS     0") "16100081"; next }
  '"$(table 'if (s >= "16100410") sub(/SYSCOL,,/, "SYSCO2,,", t)')"
  # S7: 65 table words, a copy of the first word at the end.
  deck SYSCOL S7 's == "16100720" { print; print sprintf("%-72s", \
    "       FVE     SYSCOL,,8192") "16100721"; next }'
  echo '$IBSYS'
  echo '$ENDFILE       SYSPP1'
} >syscol.job
LIMIT=300 sh "$here/run_ibsys.sh" "$kit" syscol.job syscol.lst "$kit/CTSYS1.BIN"
grep '^\$CMPLE' syscol.job | cut -c8-13 >names.txt
grep -E 'NO ERRORS WERE DETECTED|SEVERITY LIMIT WAS' syscol.lst >results.txt || true
paste -d' ' names.txt results.txt
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
