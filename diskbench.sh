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

echo "starting test on"
echo $TARGET"/fiotest.tmp"
echo "==============================="


fio --loops=5 --size=100m --filename=$TARGET/fiotest.tmp --stonewall --ioengine=libaio --direct=1 \
  --name=Seqread --bs=32m --rw=read \
  --name=Seqwrite --bs=32m --rw=write \
  --name=4kQD32read --bs=4k --iodepth=32 --rw=randread \
  --name=4kQD32write --bs=4k --iodepth=32 --rw=randwrite
rm -f $TARGET/fiotest.tmp
