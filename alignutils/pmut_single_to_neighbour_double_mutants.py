#!/usr/bin/python

import sys
import re
import math

sys.path.insert(0,'/Users/flo/floscripts/genutils/')
from SequenceProfile import SequenceProfile, create_subprofile

def usage():

    print """
Script to read in a single mutants file in pmut_scan format, a pdb to go along with it,
and then create double mutants out of all single mutants that are within cutoff

"""
    sys.exit()



mutfile = ''
pdbfile = ''
cutoff_sq = 100.0
num_files_to_write = 4

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
    #print "getting neighbors of %s, pdbfile has %s residues" % (mutpos, tot_res )

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
                    


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-mutfile':
        mutfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-pdb':
        pdbfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-dist_cutoff':
        cutoff_sq = float( CommandArgs[CommandArgs.index(arg)+1] ) * float( CommandArgs[CommandArgs.index(arg)+1] )

if mutfile == '':
    print "Error: need to specify mutations file with option -mutfile"
    sys.exit()


if (pdbfile == ''):
    print "specify pdb filee."
    sys.exit()

pdb_coords = get_coordinates(pdbfile)

mutf_handle = open( mutfile, 'r')
mutf_lines = mutf_handle.readlines()
mutf_handle.close()

num_single_muts = len( mutf_lines )
outlines = []

for res_i in range( num_single_muts ):

    iline_items = mutf_lines[res_i].split()
    seqpos1 = int( iline_items[2] )

    neighbor_list =  get_residue_neighbors( pdb_coords, cutoff_sq, seqpos1 )
    ineighbor_dict = {}

    for nb in neighbor_list:
        ineighbor_dict[nb] =1

    for res_j in range ( res_i + 1, num_single_muts ):

        jline_items = mutf_lines[res_j].split()
        seqpos2 = int( jline_items[2] )

        if seqpos1 == seqpos2:
            continue

        if ineighbor_dict.has_key( seqpos2 ):
            outlines.append( mutf_lines[res_i].replace("\n"," ") + mutf_lines[res_j])
            

num_doubles = len( outlines )
lines_per_file = int( num_doubles / num_files_to_write )
tot_line_counter = 0

file_counter  = 1
print "Writing %s double muts to %s files with %s double muts each" % (num_doubles, num_files_to_write, lines_per_file)

while( file_counter <= num_files_to_write ):
    fname = "nbdoublemuts_" + str( file_counter ) +".txt"
    outstring = ''
    this_target = file_counter * lines_per_file
    while( tot_line_counter < this_target ):
        outstring = outstring + outlines[ tot_line_counter ]
        tot_line_counter = tot_line_counter + 1

    if file_counter == num_files_to_write:
        while( tot_line_counter < num_doubles ):
            outstring = outstring + outlines[ tot_line_counter ]
            tot_line_counter = tot_line_counter + 1    

    fhandle = open( fname, 'w')
    fhandle.write(outstring)
    fhandle.close()

    file_counter = file_counter + 1
    

