#!/bin/sh
# Runs one IBSYS job under s709 and keeps every tape it writes.
# Usage: run_ibsys.sh KIT JOB LISTING [SYSLB1.BIN]
# KIT is the folder that holds the built s709-2.4.4 and utils trees.
# Run it in a work folder: the tapes stay there as sysut1.bin, sysut2.bin,
# syspp1.bin and so on. Put an input SYSUT2 tape at sysut2.bin first.
# s709 aborts on long file names, so every file it opens is linked here.
set -e
kit=$1 job=$2 lst=$3 lb1=${4:-$1/s709-2.4.4/ASYS1.BIN}
s=$kit/s709-2.4.4
PATH=$s:$kit/utils:$PATH
ln -sf "$s/ibsys.cmd" ibsys.cmd
ln -sf "$lb1" syslb1.bin
ln -sf "$s/ASYS8.BIN" syslb2.bin
gendate >sysin.txt
cat "$job" "$s/eof.dat" "$s/ibsys.ctl" >>sysin.txt
txt2bcd sysin
txt2bcd "$s/ibsys.ctl" reader.bcd 80 80
bcd2cbn reader
taskpolicy -c utility -d utility \
  s709 -cibsys.cmd -m7094 r=reader p=print u=punch \
  a1r=syslb1.bin a2r=syslb2.bin a3=sysin.bcd a4=sysou1.bcd \
  a5=sysut1.bin a6=sysut3.bin a7=sysut2.bin a8=syspp1.bin \
  a9=sysut4.bin a10=sysck2.bin </dev/null >console.txt &
# A job that never ends keeps s709 running, so stop it after LIMIT seconds
# (60 if unset).
pid=$! n=0
while kill -0 $pid 2>/dev/null; do
  n=$((n + 1))
  if [ $n -gt "${LIMIT:-60}" ]; then kill $pid; echo "s709 stopped after $n s" >&2; fi
  sleep 1
done
bcd2txt -p sysou1.bcd "$lst"
