#!/usr/bin/python

#script to read in a structure and write a resfile based on it.

import sys
import os
from math import sqrt

def usage():
    print "run with -s <pdb> or -l list"

def AA3LetTo1Let(aa):

    if aa == 'ALA':
        return 'A'
    elif aa == 'CYS':
        return 'C'
    elif aa == 'ASP':
        return 'D'
    elif aa == 'GLU':
        return 'E'
    elif aa == 'PHE':
        return 'F'
    elif aa == 'GLY':
        return 'G'
    elif aa == 'HIS':
        return 'H'
    elif aa == 'ILE':
        return 'I'
    elif aa == 'LYS':
        return 'K'
    elif aa == 'LEU':
        return 'L'
    elif aa == 'MET':
        return 'M'
    elif aa == 'ASN':
        return 'N'
    elif aa == 'PRO':
        return 'P'
    elif aa == 'GLN':
        return 'Q'
    elif aa == 'ARG':
        return 'R'
    elif aa == 'SER':
        return 'S'
    elif aa == 'THR':
        return 'T'
    elif aa == 'VAL':
        return 'V'
    elif aa == 'TRP':
        return 'W'
    elif aa == 'TYR':
        return 'Y'
    else:
        return 'unknown'


ignore_hydrogens = 1

def get_coordinates(struct):

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = {}
    all_coordinates['residue_offset'] = 0
    cur_coordinates = {}
    cur_res = 0
    all_cat_remarks = []
    for line in struct_lines:

        if( line[0:6] == 'REMARK' and ( line[17:25] == 'TEMPLATE') or (line[16:24] == 'TEMPLATE') ):
            all_cat_remarks.append( line[20:].replace("\n","") )

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates[cur_res] = cur_coordinates
 
        if atom_reading_flag:
            cols = line.split()
            if cur_res != int(line[22:26]):
                if cur_res != 0:
                    all_coordinates[cur_res] = cur_coordinates
                else:
                    firstres = int(line[22:26])
                    #print "MEEP1 %s" % firstres
                    if firstres != 1:
                        all_coordinates['residue_offset'] = firstres - 1
                        #print "MEEP2 %s" % hack_struct_offset
                cur_res = int(line[22:26])
                #print "MEEP cur_res is %s" % cur_res
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
                cur_coordinates['coords'] = {}
            if (not ignore_hydrogens) or not ((line[13] == 'H') or ( len(cols[2]) == 4 and line[12] == 'H' ) ):
                cur_coordinates['coords'][cols[2]] = (float(line[30:38]), float(line[38:46]), float(line[46:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
    #all_coordinates['catinfo'] = all_cat_remarks
    #print all_coordinates['catinfo']
    if (atom_reading_flag == 1) and not all_coordinates.has_key(cur_res):
        all_coordinates[cur_res] = cur_coordinates
    return all_coordinates


CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]

if list_mode:
 
    if not os.path.exists(list_file):
        print 'Error: could not find file %s' % list_file
        sys.exit()

    else:
        listf = open(list_file,'r')
        file_list = listf.readlines()
        listf.close()

else:
    file_list.append(sing_struct)


for struct in file_list:

    struct_coords = get_coordinates(struct)
    resf_name = "resfile_" + struct.replace("\n","")
    resf_string = "start\n"

    for res in struct_coords:
        if res == 'residue_offset':
            continue
        res_record = struct_coords[res]
        resf_string = resf_string + str(res) +" "+res_record['chain']+" PIKAA " + AA3LetTo1Let( res_record['type'] ) +"\n"

    resfile = open( resf_name, 'w')
    resfile.write(resf_string)
    resfile.close()
        

