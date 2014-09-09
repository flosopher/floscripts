#!/usr/bin/python

import sys
import re
import math

sys.path.insert(0,'../genutils/')
from SequenceProfile import SequenceProfile


alignfile = ''
relevant_pos_string = ''
mutpos = 0
mutchar = ''
mutstring = ''
empty_dict = {}
pdbfile = ''
cutoff_sq = 100.0

def get_ca_ca_dist_sq( res1, res2):
    res1ca = res1['CA']
    res2ca = res2['CA']
    return ((res2ca[0] - res1ca[0]) * (res2ca[0] - res1ca[0])) + ((res2ca[1] - res1ca[1]) * (res2ca[1] - res1ca[1])) + ((res2ca[2] - res1ca[2]) * (res2ca[2] - res1ca[2]))

def get_coordinates(struct):

    struct = struct.replace("\n","")
    
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = []
    cur_coordinates = {}
    cur_res = 0
    for line in struct_lines:

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates.append( cur_coordinates )
 
        if atom_reading_flag:
            cols = line.split()
            if cur_res != int(line[23:26]): 
                if cur_res != 0:
                    all_coordinates.append( cur_coordinates )
                cur_res = int(line[23:26])
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
                cur_coordinates['pdbnum'] =  int( line[22:26] )
            cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))

    return all_coordinates

def get_residue_neighbors( coords, cutoff_sq, mutpos ):
    to_return = []
    tot_res = len(coords)
    i_counter = 0
    print "getting neighbors of %s, pdbfile has %s residues" % (mutpos, tot_res )

    while i_counter < tot_res:
        
        i_is_mutpos = 0
        if coords[i_counter]['pdbnum'] == mutpos:
            i_is_mutpos = 1
            to_return.append( mutpos )

        j_counter = i_counter + 1
        while j_counter < tot_res:
            if (coords[i_counter]['pdbnum'] == mutpos) or (coords[j_counter]['pdbnum'] == mutpos):
                #print "Checking distance between %s and %s.." % (coords[i_counter]['pdbnum'], coords[j_counter]['pdbnum'])
                if( get_ca_ca_dist_sq( coords[i_counter], coords[j_counter]) ) <= cutoff_sq:
                    if i_is_mutpos:
                        to_return.append( coords[j_counter]['pdbnum'] )
                    else:
                        to_return.append( coords[i_counter]['pdbnum'] )

            j_counter = j_counter + 1
        i_counter = i_counter + 1
    return to_return
                    
        
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
    print "Creating subprofile of %s sequences containing %s at %s " % ( to_return.num_sequences, mut_aa, mut_position+1)
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
    elif arg == '-pdb':
        pdbfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-dist_cutoff':
        cutoff_sq = float( CommandArgs[CommandArgs.index(arg)+1] ) * float( CommandArgs[CommandArgs.index(arg)+1] )

if alignfile == '':
    print "Error: need to specify alignment file with option -a"
    sys.exit()


if (relevant_pos_string == '') and (pdbfile == ''):
    print "Error: need to specify positions of interest with e.g. -pos 1,2,3, or a pdbfile with -pdb"
    sys.exit()

if (relevant_pos_string != '') and (pdbfile != ''):
    print "Error: both relevant positions and a pdb file were specified. only 1 is possible."
    sys.exit()


relevant_pos = []

if(relevant_pos_string != ''):
            relevant_pos = relevant_pos_string.split(',')

elif( pdbfile != '' ):
    if mutstring == '':
        print "ARRRRRGHHH"
        sys.exit()
    coords = get_coordinates(pdbfile)
    relevant_pos = get_residue_neighbors( coords, cutoff_sq, mutpos )
    print "The following %s residues are neighbors of %s at %.2f cutoff: " %(len(relevant_pos), mutpos, math.sqrt( cutoff_sq))
    neighbor_string = ""
    for pos in relevant_pos:
       neighbor_string = neighbor_string + str( pos ) + "+"
    print neighbor_string
    
alf_handle = open(alignfile, 'r')
alf_lines = alf_handle.readlines()
alf_handle.close()


all_seq_prof = SequenceProfile( empty_dict, 1, alf_lines[0] )

for i in range( len( alf_lines ) - 1 ):
    all_seq_prof.add_sequence( alf_lines[i+1] )

outstring = ''

#print "relevant pos are"
#print relevant_pos
wt_sub_seq_prof = 0
mut_sub_seq_prof = 0
wtstring_mutpos = all_seq_prof.get_wt_res( mutpos-1) + str( mutpos ) 

if mutpos > 0:
    wt_sub_seq_prof = create_subprofile( mutpos-1, all_seq_prof.get_wt_res( mutpos-1), alf_lines )
    mut_sub_seq_prof = create_subprofile( mutpos-1, mutchar, alf_lines )

    
for pos in relevant_pos:
    if mutpos == 0:
        outstring = outstring + all_seq_prof.get_string_for_position( int(pos) - 1 ) + '\n'
    else:
        relevant_res = all_seq_prof.get_observed_res_for_position( int(pos) - 1 )
        #print "relevant res for pos %s are:" % pos
        #print relevant_res
        outstring = outstring + "All:  " + all_seq_prof.get_string_for_position( int(pos) - 1 ) + '\n'+ wtstring_mutpos+": " + wt_sub_seq_prof.get_string_for_position_and_res( (int(pos) - 1), relevant_res ) + '\n' + mutstring+": " + mut_sub_seq_prof.get_string_for_position_and_res( (int(pos) - 1), relevant_res ) + '\n\n'
        

print outstring
    
