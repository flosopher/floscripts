#!/bin/bash

# report which whips have a given process name running

# could use sequential (seq) instead.

#numbers="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26"
numbers=" 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32"

for c in $numbers
do

  wname="dig$c"


  echo "ps on dig : $wname"
  ssh $wname "ps uwx | grep $1 | grep -v grep"

done
