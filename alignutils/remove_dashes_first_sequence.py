#!/usr/bin/python

import sys

def usage():
    print """Script to read in a file where each line represents a sequence, and each line needs to have the same number of characters. Dashes in the first line/sequence are removed. Characters in other sequence that were in the place of first sequence dashes are also removed.

    Example:

    MSDF--GHY-TYR
    MSE--KAHF--YK
    ----DG-H-R---
    MTEFWAGNFFSYK

    becomes

    MSDFGHYTYR
    MSE-AHF-YK
    -----H----
    MTEFGNFSYK
    """
    sys.exit()




filename = 'cas9_al_ines_onlyseq.txt'

infile = open( filename, 'r')

flines = infile.readlines()

infile.close()


outlines = []
seq_length = len( flines[0] )

active_chars = [] #list of bools to keep track of the positions that are dashes in the first sequence
cur_outstring = ''

for i in range( seq_length ):
    if flines[0][i] == '-':
        active_chars.append( 0 )
    else:
        cur_outstring = cur_outstring + flines[0][i]
        active_chars.append( 1 )

outlines.append( cur_outstring )
cur_outstring = ''

seq_counter = 1
while seq_counter < len( flines ):
    cur_length = len( flines[seq_counter] )
    if cur_length != seq_length:
        print "Error. Sequence %s has unequal number of characters, ignoring." % seq_counter + 1
        continue
    for i in range( seq_length ):
        if active_chars[i] == 1:
            cur_outstring = cur_outstring + flines[seq_counter][i]

    outlines.append( cur_outstring )
    cur_outstring = ''

    seq_counter = seq_counter + 1


outstring = ''
for line in outlines:
    outstring = outstring+line

print outstring

