#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import re
from math import sqrt

def add_spaces(string, newlen, dir = 0):
    if len(string) > newlen:
        return string

    fill = newlen - len(string)
    if dir == 0:
        for i in range(fill):
            string = string + ' '

    else:
        for i in range(fill):
            string = ' ' + string

    return string



#funtion to return whether a certain atom is a hydrogen or not
def is_hydrogen(atom_string):
    checkstring = atom_string[0:2]
    if atom_string[0:1] == 'H':
        return 1
    elif checkstring == '1H':
        return 1
    elif checkstring == '2H':
        return 1
    elif checkstring == '3H':
        return 1
    else:
        return 0

#function to calculate the squared distance between two atoms, expects two tuples or two lists as input
#the first three elements of the two inputs are used
def sq_distance(coord1, coord2):
    return ( ((coord2[0] - coord1[0]) ** 2) + ((coord2[1] - coord1[1]) ** 2) + ((coord2[2] - coord1[2]) ** 2) )





def get_coordinates(struct, hetatms = 0): #hetatms meaning: 0 only ATOM is read, 1 both ATOM and HETATM are read, 2 only HETATM is read

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0
    hetatm_reading_flag = 0

    all_coordinates = {}
    cur_coordinates = {}
    cur_res = 0
    for line in struct_lines:

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM' and ( hetatms == 0 or hetatms == 1):
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            all_coordinates[cur_res] = cur_coordinates
            atom_reading_flag = 0

        if (line[0:6] == 'HETATM') and (hetatm_reading_flag == 0) and (hetatms == 1 or hetatms == 2):
            hetatm_reading_flag = 1
        if (hetatm_reading_flag == 1 ) and line[0:6] != 'HETATM':
            all_coordinates[cur_res] = cur_coordinates
            hetatm_reading_flag = 0


 
        if atom_reading_flag or hetatm_reading_flag:
            cols = line.split()
            if cur_res != int(line[23:26]): 
                if cur_res != 0:
                    all_coordinates[cur_res] = cur_coordinates
                cur_res = int(line[23:26])
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
            cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))

    return all_coordinates



def calculate_center_of_mass( coordinates ):     #not a real physical COM calculation, all atoms except H are treated as having the same mass

    no_atoms = 0
    mass_center = 0.0, 0.0, 0.0

    for atom_key in coordinates.keys():
        if not isinstance(coordinates[atom_key],tuple):  #make sure we only process atoms in the dict 
            continue
        if is_hydrogen(atom_key):    #disregard protons
            continue

        no_atoms = no_atoms + 1;
        cur_atom_coords = coordinates[atom_key]
        #print cur_atom_coords
        #print mass_center

        wtfX = mass_center[0] + cur_atom_coords[0]
        wtfY = mass_center[1] + cur_atom_coords[1]
        wtfZ = mass_center[2] + cur_atom_coords[2]
        mass_center = wtfX, wtfY, wtfZ

    mass_center = (mass_center[0] / no_atoms ), (mass_center[1] / no_atoms), (mass_center[2] / no_atoms)
 
    return mass_center


def rigid_body_translate( coordinates, trans_vect ):

    for atom_key in coordinates.keys():
        if not isinstance(coordinates[atom_key],tuple):  #make sure we only process atoms in the dict 
            continue
        coordinates[atom_key] = (coordinates[atom_key][0] + trans_vect[0]), (coordinates[atom_key][1] + trans_vect[1]), (coordinates[atom_key][2] + trans_vect[2])



CommandArgs = sys.argv[1:]
template = ''
molecule = ''
outfile = 'default_trans.pdb'

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-m':
        molecule = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]

template_coords = get_coordinates(template,2) #only hetatm coords

to_translate_coords = get_coordinates(molecule,2)
to_translate_res =  to_translate_coords[ to_translate_coords.keys()[0] ]

translate_template = {}

#figure out which hetatm residue to use:
if len (template_coords.keys() ) > 1:
    no_het_residues = len( template_coords.keys() )
    print "template %s has %s HETATM residues, using the one that has the most atoms" %(template,no_het_residues)
    max_atoms = 0
    best_key = ''
    for res_key in template_coords.keys():
        if len( template_coords[res_key] ) > max_atoms:
            max_atoms = len( template_coords[res_key] ) 
            best_key = res_key
    translate_template = template_coords[best_key]
elif len(template_coords.keys() ) == 0:
    print "Error, template %s has no heteroatoms, exiting... " % template
    sys.exit()
else:
    translate_template = template_coords[ template_coords.keys()[0] ]

trans_target_com = calculate_center_of_mass( translate_template )

to_translate_com = calculate_center_of_mass( to_translate_res )

translation = (trans_target_com[0] - to_translate_com[0]), (trans_target_com[1] - to_translate_com[1]), (trans_target_com[2] - to_translate_com[2]) 


rigid_body_translate( to_translate_res, translation)

#now we have to write out everything
outf_template = open(molecule, 'r')
outf_template_lines = outf_template.readlines()
outf_template.close()

outstring = ""

for line in outf_template_lines:

    newline = line
    if line[0:4] == 'ATOM':
        print "stopping, ATOM lines in file to translate"
        sys.exit()

    if line[0:6] == 'HETATM':
        cols = line.split()
        if cols[3] != to_translate_res['type']:
            #print "ignoring and splitting out atoms for residue %s%s !!!" %(cols[3],cols[5] )
            print "something impossible just happened!"
            sys.exit()
    
        #print "%.3f" % to_translate_res[ cols[2] ][0]
        curX = add_spaces( "%.3f" % to_translate_res[ cols[2] ][0],8,1)
        curY = add_spaces( "%.3f" % to_translate_res[ cols[2] ][1],8,1)
        curZ = add_spaces( "%.3f" % to_translate_res[ cols[2] ][2],8,1)

        newline = line[:30] + curX + curY + curZ + line[54:]

    outstring = outstring + newline

outf = open(outfile,'w')
outf.write(outstring)
outf.close()

