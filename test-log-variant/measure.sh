#!/bin/bash

N_EXEC=10
SUM=0

for i in $(seq 1 $N_EXEC); do
  echo -n "$i..."
  T=$(/usr/bin/time -p ./bench 2>&1  | grep real | cut -d' ' -f2)
  echo " done in $T"
  SUM=$(echo $SUM + $T | bc)
done

AVG=$(echo "scale=2; $SUM / $N_EXEC" | bc)
echo
echo "AVG is $AVG"
