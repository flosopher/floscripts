#!/usr/bin/python

import sys
import os

def usage():
    print """Script to read in a file and delete all the lines from it that don't have the same number of columns as the first line."""
  

CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()

infile = ''

for arg in CommandArgs:
    if arg == '-f':
        infile = CommandArgs[CommandArgs.index(arg)+1]


inf = open( infile , 'r')
inlines = inf.readlines()
inf.close()

outstring = ''
num_columns = len( inlines[0].split() )

counter = 0
failcounter = 0
for line in inlines:
    counter = counter + 1
    if( len( line.split() ) == num_columns ):
        outstring = outstring + line
    else:
        failcounter = failcounter + 1
        #print "line %s does not have the same number of columns." % counter

print '%s lines did not have the required %s columns.' %(failcounter, num_columns)
nfile = open(infile,'w')
nfile.write(outstring)
nfile.close
