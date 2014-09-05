#!/usr/bin/python

import sys
import re

sys.path.insert(0,'../genutils/')
from SequenceProfile import SequenceProfile


alignfile = ''
relevant_pos_string = ''
mutpos = 0
mutchar = ''
mutstring = ''
empty_dict = {}

#creates a sequence profile containing only sequences
#that contain mut_aa at mut_position
def create_subprofile( mut_position, mut_aa, alignment ):
    #print "Creating subprofile of sequences containing %s at %s " % (mut_aa, mut_position)
    first_seq = -1
    al_length = len( alignment )
    for i in range( al_length):
        if alignment[i][mut_position] == mut_aa:
            first_seq = i
            break
    if first_seq == -1:
        print "Error, %s was not observed in alignment at %s " % (mut_aa, mut_position)
        sys.exit()

    to_return = SequenceProfile( empty_dict, 1, alignment[first_seq] )
    seq_counter = first_seq+1

    while seq_counter < al_length:
        if alignment[seq_counter][mut_position] == mut_aa:
            to_return.add_sequence( alignment[seq_counter] )
        seq_counter = seq_counter + 1
    print "Creating subprofile of %s sequences containing %s at %s " % ( to_return.num_sequences, mut_aa, mut_position)
    return to_return


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-a':
        alignfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-pos':
        relevant_pos_string = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-mutation':
        mutstring = CommandArgs[CommandArgs.index(arg)+1]
        mutchar = mutstring[0:1]
        mutpos = int( mutstring[1:] )

if alignfile == '':
    print "Error: need to specify alignment file with option -a"
    sys.exit()


if relevant_pos_string == '':
    print "Error: need to specify positions of interest with e.g. -pos 1,2,3"
    sys.exit()

relevant_pos = relevant_pos_string.split(',')


alf_handle = open(alignfile, 'r')
alf_lines = alf_handle.readlines()
alf_handle.close()


all_seq_prof = SequenceProfile( empty_dict, 1, alf_lines[0] )

for i in range( len( alf_lines ) - 1 ):
    all_seq_prof.add_sequence( alf_lines[i+1] )

outstring = ''

#print "relevant pos are"
#print relevant_pos
sub_seq_prof = 0
if mutpos > 0:
    sub_seq_prof = create_subprofile( mutpos-1, mutchar, alf_lines )

    
for pos in relevant_pos:
    if mutpos == 0:
        outstring = outstring + all_seq_prof.get_string_for_position( int(pos) - 1 ) + '\n'
    else:
        outstring = outstring + "All: " + all_seq_prof.get_string_for_position( int(pos) - 1 ) + '\n'+mutstring+": " + sub_seq_prof.get_string_for_position( int(pos) - 1 ) + '\n\n'
        

print outstring
    
