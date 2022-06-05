#!/usr/bin/env bash

set -x

cd /disk-bench

echo "#"
echo "#  Random read/write performance"
echo "#"



fio \
    --randrepeat=1 \
    --ioengine=libaio \
    --direct=1 --gtod_reduce=1 \
    --name=test \
    --filename=test \
    --bs=4k \
    --iodepth=64 \
    --size=4G \
    --readwrite=randrw \
    --rwmixread=75

rm test

echo "#"
echo "# Random read performance"
echo "#"

fio \
    --randrepeat=1 \
    --ioengine=libaio \
    --direct=1 \
    --gtod_reduce=1 \
    --name=test \
    --filename=test \
    --bs=4k \
    --iodepth=64 \
    --size=4G \
    --readwrite=randread

rm test

echo "#"
echo "# Random write performance"
echo "#"

fio \
--randrepeat=1 \
--ioengine=libaio \
--direct=1 \
--gtod_reduce=1 \
--name=test \
--filename=test \
--bs=4k \
--iodepth=64 \
--size=4G \
--readwrite=randwrite

rm test

echo "#"
echo "# Measuring latency with IOPing"
echo "#"
