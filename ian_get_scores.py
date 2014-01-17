#!/usr/bin/python
# for f in *.out; do echo $f; ./get_scores.py < $f > ${f:0:9}_suffix.tab; done
import sys

struct = sys.argv[1]
struct = struct.replace("\n","")
struct_file = open(struct,'r')
struct_lines = struct_file.readlines()
struct_file.close

first = True
for line in struct_lines:
    if not line.startswith("SCORES "): continue
    if "is_reference_pose 1" in line: continue # skip ref. structures
    f = line.rstrip().split()
    if first:
        first = False
        i = 0
        while i < len(f):
            print f[i],
            i += 2
        print
    i = 1
    while i < len(f):
        print f[i],
        i += 2
    print
    
