#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import re
from math import sqrt

#function to calculate the squared distance between two atoms, expects two tuples or two lists as input
#the first three elements of the two inputs are used
def sq_distance(coord1, coord2):
    return ( ((coord2[0] - coord1[0]) ** 2) + ((coord2[1] - coord1[1]) ** 2) + ((coord2[2] - coord1[2]) ** 2) )

#function to calculate the RMSD between two coordinate dictionaries. the dictionaries need to be in format
# residue key: {atom key: coords(tuple)
def RMSD_dictcoords(template_coords,struct_coords):

    total_sqdist = 0
    total_atoms = 0
    for residue_key in template_coords.keys():
        if not struct_coords.has_key(residue_key): return (-1,residue_key)

        for atom_key in template_coords[residue_key].keys():
            if not struct_coords[residue_key].has_key(atom_key): return (-2,residue_key,atom_key)
            
            #print sq_distance(template_coords[residue_key][atom_key],struct_coords[residue_key][atom_key])
            total_sqdist = total_sqdist + sq_distance(template_coords[residue_key][atom_key],
                                                      struct_coords[residue_key][atom_key])
            total_atoms = total_atoms + 1

    return sqrt(total_sqdist/total_atoms)
            

    

#print 'ey yo, first python script'

FileList = []
Listfile = ''
template = ''
resfile = ''
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



CommandArgs = sys.argv[1:]
print CommandArgs

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-resfile':
        resfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-all_atom':
        ca_only = 0

if ( (not Listfile) or (not template) or (not resfile)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
else:
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    print "Calculating RMSDs for %s structures in %s to template %s" % (len(FileList), Listfile, template)

#now read in resfile to determine the residues that moved

resf_match = re.compile(r"start",re.I)
resf = open(resfile,'r')
resf_line = resf.readline()

while not resf_match.search(resf_line):  #get rid of comments
    resf_line = resf.readline()

while resf_line:
    if resf_line[18:19] == 'B':
        rub_residues.append(int(resf_line[9:12]))
    resf_line = resf.readline()
resf.close()
print rub_residues

#then read in template

template_coords = get_coordinates(template)
#print template_coords

score_rms_list = []
#now process structures
for struct in FileList:

   struct = struct.replace("\n","")
   struct_file = open(struct,'r')
   cur_line = struct_file.readline()
   while cur_line[0:4] != 'ATOM':
       if cur_line[0:6] == 'REMARK':
           cols = cur_line.split()
           if cols[2] == 'SCORE':
               cur_score = cols[3]
       cur_line = struct_file.readline()

   struct_file.close()

   struct_coords = get_coordinates(struct)
   #print struct_coords

   struct_rmsd = RMSD_dictcoords(template_coords,struct_coords)
   #print 'hiarr %s \n' %struct_rmsd
   if isinstance(struct_rmsd,tuple):
       if struct_rmsd[0] == -1:
           print 'Warning: %s doesn\'t have the correct number of residues, problem at %s \n' %(struct,struct_rmsd[1])
           struct_rmsd = -1
       elif struct_rmsd[0] == -2:
           print 'Warnig: %s doesn\'t have correct number of atoms in residue %s, problem at %s \n' %(struct,struct_rmsd[1],struct_rmsd[2])
           struct_rmsd = -1

   score_rms_list.append((struct,cur_score,struct_rmsd))


score_rms_list.sort(lambda x,y:cmp(x[1],y[1]))  #sort list by second element (score)
#print score_rms_list

for entry in score_rms_list:
    print "%s    %-10s  %.3f" % (entry[0],entry[1],entry[2])

print 'well, we made it to the end'
