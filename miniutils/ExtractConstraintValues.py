#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import os
import re


    

#print 'ey yo, first python script'

FileList = []
Listfile = ''
template = ''
grepfile = ''
ca_only = 1
rub_residues = []

def get_coordinates(struct):

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()

    all_coordinates = {}
    cur_coordinates = {}
    cur_res = 0
    for line in struct_lines:
        if line[0:4] == 'ATOM':
            cols = line.split()
            if cur_res != int(cols[4]): 
                if cur_res in rub_residues:
                    all_coordinates[cur_res] = cur_coordinates
                cur_res = int(cols[4])
                cur_coordinates = {}
            if cur_res in rub_residues:
                if cols[2] == 'CA':
                    cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
                elif (not ca_only) and line[13:14] != 'H':
                    cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))

    return all_coordinates

startstruct = ''

CommandArgs = sys.argv[1:]
print CommandArgs

for arg in CommandArgs:
    if arg == '-s':
        startstruct = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-grepfile':
        grepfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-all_atom':
        ca_only = 0

if ( (not Listfile) and (not startstruct)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
elif not startstruct:
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    
else:
    FileList.append(startstruct)

#now read in resfile to determine the residues that moved




#now process structures
for struct in FileList:

    catres1 = 0
    
    score_block_reading_flag = 0;
    labels_read_in = 0;
    fields_to_keep = []
    outstrings = []

    struct = struct.replace("\n","")
    #outstrings.append(struct)
    struct_file = open(struct,'r')
    cur_line = struct_file.readline()
  
    while cur_line:
        
        if cur_line[0:26] == '#BEGIN_POSE_ENERGIES_TABLE':
            score_block_reading_flag = 1;

        if cur_line[0:24] == '#END_POSE_ENERGIES_TABLE':
            score_block_reading_flag = 0;

        if score_block_reading_flag:
            linearray = cur_line.split();
            residue_has_cst_e = 0
            

            if linearray[0] == 'label':
                for field in linearray:
                    if field == 'atom_pair_constraint':
                        fields_to_keep.append(linearray.index(field) )
                    elif field == 'angle_constraint':
                        fields_to_keep.append(linearray.index(field) )
                    elif field == 'dihedral_constraint':
                        fields_to_keep.append(linearray.index(field) )
                labels_read_in = 1
                outstr = struct
                for ind in fields_to_keep:
                    outstr = outstr + " " + linearray[ind] + " "
                outstrings.append(outstr)
                cur_line = struct_file.readline()
                continue

            for ind in fields_to_keep:
                if linearray[ind] != "0": 
                    residue_has_cst_e = 1
              
            if residue_has_cst_e:
                outstr = linearray[0]
                for ind in fields_to_keep:
                    outstr = outstr + " " + linearray[ind] + " "
                outstrings.append(outstr)
            
        cur_line = struct_file.readline()

    struct_file.close()

print "Data for: "
for line in outstrings:
    print line
print "--------------------"
  
#print score_rms_list
