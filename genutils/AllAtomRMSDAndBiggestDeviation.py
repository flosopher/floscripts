#!/usr/bin/python

import sys
import os
from math import sqrt

def usage():
    print "run with -t <pdb1> -s <pdb2> to get a list of all atom deviations observed"

ignore_hydrogens = 1
ca_only = 0
account_hnq_flip = 0
output_cutoff = 0.009

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


#function to calculate the squared distance between two atoms, expects two tuples or two lists as input
#the first three elements of the two inputs are used
def sq_distance(coord1, coord2):
    return ( ((coord2[0] - coord1[0]) ** 2) + ((coord2[1] - coord1[1]) ** 2) + ((coord2[2] - coord1[2]) ** 2) )


#function that returns an list of the square distances between atoms in two structures
#the list is ordered by ascending distances sq
def atom_atom_sq_distances( coords1, coords2 ):
    to_return = []
    #print coords1
    for res1_num in coords1:
        if not coords2.has_key(res1_num):
            return "coords 2 does not have key %s" % res1_num
        res2 = coords2[res1_num]
        res1 = coords1[res1_num]
        if res1_num == 'residue_offset':
            continue
        #print res1_num
        #print res1
        #print res1['coords'].keys()
        for atom in res1['coords'].keys():
            if (ca_only == 1 ) and (atom != 'CA'):
                continue
            if not res2['coords'].has_key(atom):
                return "coords2 res with key %s does not have atom %s" % (res1_num, atom)
            atomstring = res1['chain'] + "_" + res1['type'] + "_" + str(res1_num) + "_" + atom
            sqdist = sq_distance( res1['coords'][atom], res2['coords'][atom] )

            if account_hnq_flip:
                other_sqdist = sqdist + 1.0
                if res1['type'] == 'HIS':
                    if atom == 'ND1':
                        other_sqdist = sq_distance( res1['coords']['ND1'], res2['coords']['CD2'] )
                    elif atom == 'CD2':
                        other_sqdist = sq_distance( res1['coords']['CD2'], res2['coords']['ND1'] )
                    elif atom == 'NE2':
                        other_sqdist = sq_distance( res1['coords']['NE2'], res2['coords']['CE1'] )
                    elif atom == 'CE1':
                        other_sqdist = sq_distance( res1['coords']['CE1'], res2['coords']['NE2'] )

                elif res1['type'] == 'GLN':
                    if atom == 'NE2':
                        other_sqdist = sq_distance( res1['coords']['NE2'], res2['coords']['OE1'] )
                    elif atom == 'OE1':
                        other_sqdist = sq_distance( res1['coords']['OE1'], res2['coords']['NE2'] )

                elif res1['type'] == 'ASN':
                    if atom == 'ND2':
                        other_sqdist = sq_distance( res1['coords']['ND2'], res2['coords']['OD1'] )
                    elif atom == 'OD1':
                        other_sqdist = sq_distance( res1['coords']['OD1'], res2['coords']['ND2'] )

                        
                if other_sqdist < sqdist:
                    sqdist = other_sqdist

            to_return.append( (atomstring, sqdist  ) )
    #to_return.append( ("hack", 5.0))
    #to_return.sort()
    #return to_return
    return sorted (to_return, key=lambda element: element[1], reverse=True)


CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''
template = ''


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-account_hnq_flip':
        account_hnq_flip = 1
    elif arg == '-output_cutoff':
        tmp = float ( CommandArgs[CommandArgs.index(arg)+1] )
        output_cutoff =  tmp * tmp
    elif arg == '-ca_only':
        ca_only = 1

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


template_coords = get_coordinates(template)
outstring = ""

for struct in file_list:

    struct_coords = get_coordinates(struct)
    if len( struct_coords ) != len( template_coords ):
        print "%s Error, template and struct seem to have different number of residues" % struct.replace("\n","")
        sys.exit()
    distlist = atom_atom_sq_distances( template_coords, struct_coords )
    #print "distlist is type %s" % type(distlist)
    if type(distlist) == type(""):
        print "%s Error " % struct.replace("\n","") + distlist
        sys.exit()
    tmpstring = ""


    totsqdist = 0
    for result in distlist:
        #print result
        totsqdist = totsqdist + result[1]
        if( result[1] > output_cutoff ):
            tmpstring = tmpstring + struct.replace("\n","") + " " + result[0] + " " + str( sqrt( result[1] )) + "\n"
    allrmsd = sqrt( totsqdist / len( distlist ) )
    #original line allrmsd = sqrt( totsqdist ) / len( distlist )
    outstring = outstring + "Results for struct %s: overall rmsd is %.3f \n" % (struct,allrmsd) + tmpstring


print outstring

