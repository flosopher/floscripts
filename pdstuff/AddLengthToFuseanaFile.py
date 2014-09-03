#!/usr/bin/python

#script that will do an 'hg status' command in the current workdir,
#collect the results, and copy every file that has status 'M' or 'A' to a
#specified target directory

import sys
import re
import os

CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    #usage()
    sys.exit()

nstart = 0
cstart = 0
filename = ""

for arg in CommandArgs:
    if arg == '-nstart':
        nstart = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-cstart':
        cstart = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-file':
        filename = CommandArgs[CommandArgs.index(arg)+1]


inf = open(filename)
lines = inf.readlines()
inf.close()

outstring = ""

for line in lines:
    tokens = line.split()
    if tokens[0][0:5] != "scanr":
        #outstring = outstring + append( line )
	outstring = outstring + line
        continue
    length_nums = tokens[1].split('_')
    n_num = int( length_nums[0] )
    c_num = int( length_nums[1] )

    length = (n_num - nstart) + (cstart - c_num)

    #newstring = line
    #newstring[12:13] = str( length ) + "_"
    newstring = line[0:13] + str( length ) + " " + line[13:]
    #new_string = tokens[0] + " " + str( length) + " "
    #i = 1
    #while i < len( tokens):
    #    new_string = new_string + tokens[i]
    #    i = i + 1

    outstring = outstring + newstring 

outf = open(filename, 'w')
outf.write( outstring )
outf.close()

 
