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



pdb_chain = 'A'
filename = 'seqprof_hel_interface_minal.txt'

outlines = []

infile = open( filename, 'r')

flines = infile.readlines()

infile.close()

for line in flines:

    line_items = line.split()
    if len(line_items) < 2:
        continue
    #print line_items

    wt_res = line_items[0][0:1]
    resnum = line_items[0][1:]
    resnum = resnum[:len(resnum)-1]
    num_alternative_res = ( len(line_items) - 1) / 2

    #line formats for reference
    #E142:  0.0360 E, 0.0360 G,  0.8865 -,  0.0079 L,   0.0077 Q,
    # A E 142 L
    for i in range( num_alternative_res ):
        this_res = line_items[2*i + 2][0:1]
        if (this_res != wt_res) and (this_res != '-'):
            this_outline = pdb_chain + ' ' + wt_res + ' ' + resnum + ' ' + this_res
            outlines.append( this_outline )


outstring = ''
for line in outlines:
    outstring = outstring+line + '\n'

print outstring

