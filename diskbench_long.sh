#!/bin/bash

#This script will measure bandwidth of the selected disk using fio
#It will not use cache, the results represent a slower result than real world performance for writing to storage with large amount of cache.

if [ -f /usr/bin/fio ]; then #Dependency check
    :
else
    echo "This script requires fio to run, please make sure it is installed."
    exit
fi

echo "What drive do you want to test? (Default: $HOME on /dev/$(df $HOME | grep /dev | cut -d/ -f3 | cut -d" " -f1) )"
echo "Only directory paths (e.g. /home/user/) are valid targets."
read TARGET

if [ -z $TARGET ]; then
    TARGET=$HOME
elif [ -d $TARGET ]; then
    :
else
    echo -e "\033[1;31mError: $TARGET is not a valid path.\033[0m"
    exit
fi

echo "starting test on"
echo $TARGET"/fiotest.tmp"
echo "==============================="

QSIZE=32m
LOOPS=2
SIZESEQ=32g
SIZE4k=64m

fio --loops=$LOOPS --size=$SIZESEQ --filename="$TARGET/fiomark.tmp" --stonewall --ioengine=libaio --direct=1 --output-format=json \
  --name=SeqQ32T1read --bs=$QSIZE --iodepth=32 --rw=read \
  --name=SeqQ32T1write --bs=$QSIZE --iodepth=32 --rw=write \
  > "$TARGET/fiomark.txt"
  
SEQ32R="$(($(cat "$TARGET/fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark.txt" | grep -A15 '"name" : "SeqQ32T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
SEQ32W="$(($(cat "$TARGET/fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark.txt" | grep -A80 '"name" : "SeqQ32T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"

echo -e "
Results:
\033[1;36m
Sequential Q32T1 Read: $SEQ32R
Sequential Q32T1 Write: $SEQ32W
\033[0m" | sed 's:-e::g'


fio --loops=$LOOPS --size=$SIZE4k --filename="$TARGET/fiomark-4k.tmp" --stonewall --ioengine=libaio --direct=1 --output-format=json \
  --name=4kQ1T1read --bs=4k --iodepth=1 --numjobs=1 --rw=randread \
  --name=4kQ1T1write --bs=4k --iodepth=1 --numjobs=1 --rw=randwrite \
  --name=4kQ32T1read --bs=4k --iodepth=32 --numjobs=1 --rw=randread \
  --name=4kQ32T1write --bs=4k --iodepth=32 --numjobs=1 --rw=randwrite \
  --name=4kQ8T8read --bs=4k --iodepth=8 --numjobs=8 --rw=randread \
  --name=4kQ8T8write --bs=4k --iodepth=8 --numjobs=8 --rw=randwrite \
  > "$TARGET/fiomark-4k.txt"

FKR="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ1T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ1T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FKW="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ1T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ1T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK32R="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ32T1read"' | grep bw | grep -v '_' | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ32T1read"' | grep -m1 iops | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK32W="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ32T1write"' | grep bw | grep -v '_' | sed 2\!d | cut -d: -f2 | sed s:,::g)/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ32T1write"' | grep iops | sed '7!d' | cut -d: -f2 | cut -d. -f1 | sed 's: ::g') IOPS]"
FK8R="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ8T8read"' | grep bw | grep -v '_' | sed 's/        "bw" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }')/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A15 '"name" : "4kQ8T8read"' | grep iops | sed 's/        "iops" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }' | cut -d. -f1) IOPS]"
FK8W="$(($(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ8T8write"' | grep bw | sed 's/        "bw" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }')/1000))MB/s [   $(cat "$TARGET/fiomark-4k.txt" | grep -A80 '"name" : "4kQ8T8write"' | grep '"iops" '| sed 's/        "iops" : //g' | sed 's:,::g' | awk '{ SUM += $1} END { print SUM }' | cut -d. -f1) IOPS]"

echo -e "\033[1;35m
4KB Q8T8 Read: $FK8R
4KB Q8T8 Write: $FK8W
\033[1;33m
4KB Q32T1 Read: $FK32R
4KB Q32T1 Write: $FK32W
\033[0;36m
4KB Q1T1 Read: $FKR
4KB Q1T1 Write: $FKW
\033[0m
" | sed 's:-e::g'

echo "Would you like to save these results? [Y/N]"
read REPLY
if [ "$REPLY" = "N" ] || [ "$REPLY" = "n" ]; then
    REPLY=""
else
    DRIVESIZE=$(df -h $TARGET | cut -d ' ' -f3 | tail -n 1)
    echo "Saving at $HOME/$DRIVE$(date +%F%I%M%S).txt"

	echo "
* MB/s = 1,000,000 bytes/s
* KB = 1000 bytes, KiB = 1024 bytes

   Sequential Read (Q= 32,T= 1)  :   $SEQ32R
  Sequential Write (Q= 32,T= 1)  :   $SEQ32W
  Random Read 4KiB (Q=  8,T= 8)  :   $FK8R
 Random Write 4KiB (Q=  8,T= 8)  :   $FK8W
  Random Read 4KiB (Q= 32,T= 1)  :   $FK32R
 Random Write 4KiB (Q= 32,T= 1)  :   $FK32W
  Random Read 4KiB (Q=  1,T= 1)  :   $FKR
 Random Write 4KiB (Q=  1,T= 1)  :   $FKW

  Test : $(echo $SIZE | rev | cut -c 2- | rev) MiB [$DRIVEMODEL, $DRIVE $DRIVEPERCENT ($(echo $DRIVEUSED | rev | cut -c 2- | rev)/$(echo $DRIVESIZE | rev | cut -c 2- | rev) GiB] (x$LOOPS)  [Interval=0 sec]
  Date : $(date +%F | sed 's:-:/:g') $(date +%T)
	OS : $(uname -srm)
	  " > "$HOME/$DRIVE$(date +%F%I%M%S).txt"
fi

rm -f $TARGET/fiotest.tmp
rm "$TARGET/fiomark.txt" "$TARGET/fiomark-4k.txt" 2>/dev/null
rm "$TARGET/fiomark.tmp" "$TARGET/fiomark-4k.tmp" 2>/dev/null
