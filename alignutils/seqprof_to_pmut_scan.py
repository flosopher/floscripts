#!/usr/bin/python

import sys

def usage():
    print """Script to read in a seqprof file and turn it into a file that the pmut scan protocol can understand.

    example

    L139: 0.8519 -,  0.1194 L,
    T140: 0.8533 -,   0.0905 T,
    G141: 0.0183 A, 0.0869 G,  0.8575 -,
    E142:  0.0360 E, 0.0360 G,  0.8865 -,  0.0079 L,   0.0077 Q,

    becomes

    A G 141 A
    A E 142 G
    A E 142 L
    A E 142 Q
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

