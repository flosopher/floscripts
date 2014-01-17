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


class brub_output_line:

    def __init__(self,structname, score = -100000000):
        self.name = structname
        self.score = score #score is later used to sort a list consisting of instances of this class
        

    def set_output(self, score, rmsd_ca, maxrms_res_ca, maxrms_ca, minrms_res_ca, minrms_ca, rmsd_all,  maxrms_res_all, maxrms_all, minrms_res_all, minrms_all, rmsd_cata):
        self.scorestring = add_spaces(self.name, 35)
        self.scorestring = self.scorestring + add_spaces(score,8,1)
        self.scorestring = self.scorestring + add_spaces(rmsd_ca,10,1)
        self.scorestring = self.scorestring + add_spaces(rmsd_all,10,1)
        self.scorestring = self.scorestring + add_spaces(rmsd_cata,10,1)
        self.scorestring = self.scorestring + add_spaces(maxrms_res_ca,15,1)
        self.scorestring = self.scorestring + ' ' + add_spaces(maxrms_ca,8)
        self.scorestring = self.scorestring + add_spaces(minrms_res_ca,15,1)
        self.scorestring = self.scorestring + ' ' + add_spaces(minrms_ca,8) 
        self.scorestring = self.scorestring + add_spaces(maxrms_res_all,15,1)
        self.scorestring = self.scorestring + ' ' + add_spaces(maxrms_all,8)
        self.scorestring = self.scorestring + add_spaces(minrms_res_all,15,1)
        self.scorestring = self.scorestring + ' ' + minrms_all+'\n'

    def write_output(self, outfilehandle = ' '):
        if outfilehandle == ' ':
            print self.scorestring
        else:
            outfilehandle.write(self.scorestring)


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

#function to calculate the RMSD between two coordinate dictionaries. the dictionaries need to be in format
# residue key: {atom key: coords(tuple)
def RMSD_dictcoords(template_coords,struct_coords,ca_only = 0):

    total_sqdist = 0
    total_atoms = 0
    maxms_res = ''
    maxms = -1
    minms_res =''
    minms = 1000
    #print template_coords.keys()
    for residue_key in template_coords.keys():
        if not struct_coords.has_key(residue_key): return (-1,residue_key)
        #print residue_key
        if template_coords[residue_key]['active'] == 1:
            temp_total_sqdist = total_sqdist
            temp_total_atoms = total_atoms
            for atom_key in template_coords[residue_key].keys():
                if is_hydrogen(atom_key) or (ca_only and atom_key != 'CA'):
                    continue
                if not isinstance(template_coords[residue_key][atom_key],tuple):
                    continue
                if not struct_coords[residue_key].has_key(atom_key): return (-2,residue_key,atom_key)
            
            #print sq_distance(template_coords[residue_key][atom_key],struct_coords[residue_key][atom_key])
                #print 'using %s from %s, ca only is %s' % (residue_key, atom_key, ca_only)
                total_sqdist = total_sqdist + sq_distance(template_coords[residue_key][atom_key],
                                                      struct_coords[residue_key][atom_key])
                total_atoms = total_atoms + 1

            sqdist_this_res = (total_sqdist - temp_total_sqdist) / ( total_atoms - temp_total_atoms)
            if sqdist_this_res > maxms:
                maxms = sqdist_this_res
                maxms_res = template_coords[residue_key]['type']+str(residue_key)
            if sqdist_this_res < minms:
                minms = sqdist_this_res
                minms_res = template_coords[residue_key]['type']+str(residue_key)

            
    to_return = (sqrt(total_sqdist/total_atoms), maxms_res, sqrt(maxms), minms_res, sqrt(minms) )


    return to_return
            

    

#print 'ey yo, first python script'


def get_coordinates(struct):

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = {}
    cur_coordinates = {}
    cur_res = 0
    for line in struct_lines:

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates[cur_res] = cur_coordinates
 
        if atom_reading_flag:
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


FileList = []
Listfile = ''
template = ''
resfile = ''
ca_only = 1
outfile = ' '
rub_residues = []
norub_residues = []

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-resfile':
        resfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-all_atom':
        ca_only = 0
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]


if ( (not Listfile) or (not template) or (not resfile)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
else:
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    if outfile == ' ':
        outfile = Listfile + '.ana'
    print "Calculating RMSDs for %s structures in %s to template %s" % (len(FileList), Listfile, template)

#now read in resfile to determine the residues that moved

resf_match = re.compile(r"start",re.I)
resf = open(resfile,'r')
resf_line = resf.readline()

while not resf_match.search(resf_line):  #get rid of comments
    resf_line = resf.readline()
resf_line = resf.readline() #get past start line

while resf_line:
    #cur_res = int(resf_line[9:12]):
    if resf_line[18:19] == 'B':
        rub_residues.append(int(resf_line[9:12]))
    elif len(resf_line) > 10 and resf_line[17:18] != ' ':
        norub_residues.append(int(resf_line[9:12]))
    resf_line = resf.readline()

resf.close()
print rub_residues

#then read in template, and turn off nonbackrubbing residues, and also determine catalytic residues

template_coords = get_coordinates(template)

cat_res = {}
catresf = open(template,'r')
catres_linearray = (catresf.readline()).split()

while catres_linearray[0] != 'ATOM':
    if catres_linearray[0] == 'REMARK' and catres_linearray[2] == 'TEMPLATE':
        cat_res[int(catres_linearray[10])] = 1

    catres_linearray = (catresf.readline()).split()
catresf.close()
print "Catalytic residues are: "
for key in cat_res:
    print key


#prepare output
output_lines = []
output_title = brub_output_line('Structure')
output_title.set_output('score', 'rmsd_ca', 'maxrms_res_ca', 'rms', 'minrms_res_ca', 'rms', 'rmsd_all',  'maxrms_res_all', 'rms', 'minrms_res_all', 'rms', 'cat_rmsd')
output_lines.append(output_title)

for res in norub_residues:
    #print res
    #print template_coords[res]
    template_coords[res]['active'] = 0;

#print template_coords

#score_rms_list = []
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
   output_line = brub_output_line(struct,float(cur_score) )

   struct_coords = get_coordinates(struct)


   #now calculate all atom rmsd for cat residues
   template_cat_coords = {}
   struct_cat_coords = {}
   for key in cat_res:
       template_cat_coords[key] = template_coords[key]
       struct_cat_coords[key] = struct_coords[key]
   structure_cat_rmsd_all = RMSD_dictcoords(template_cat_coords,struct_cat_coords,0)

   for res in norub_residues:
       struct_coords[res]['active'] = 0
   #print struct_coords
#to_return = (sqrt(total_sqdist/total_atoms), maxms_res, sqrt(maxms), minms_res, sqrt(minms) )
   structure_rmsd_ca = RMSD_dictcoords(template_coords,struct_coords,1)
   structure_rmsd_all = RMSD_dictcoords(template_coords,struct_coords,0)


#   output_line.set_output(cur_score,str(structure_rmsd_ca[0]),structure_rmsd_ca[1],str(structure_rmsd_ca[2]),structure_rmsd_ca[3],str(structure_rmsd_ca[4]),str(structure_rmsd_all[0]),structure_rmsd_all[1],str(structure_rmsd_all[2]),structure_rmsd_all[3],str(structure_rmsd_all[4]))

   output_line.set_output(cur_score,'%.2f' % structure_rmsd_ca[0],structure_rmsd_ca[1], '%.2f' % structure_rmsd_ca[2],structure_rmsd_ca[3],'%.2f' % structure_rmsd_ca[4], '%.2f' % structure_rmsd_all[0],structure_rmsd_all[1], '%.2f' % structure_rmsd_all[2],structure_rmsd_all[3], '%.2f' % structure_rmsd_all[4], '%.2f' % structure_cat_rmsd_all[0])

   output_lines.append(output_line)
   #print 'hiarr %s \n' %struct_rmsd
   if isinstance(structure_rmsd_ca,tuple):
       if structure_rmsd_ca[0] == -1:
           print 'Warning: %s doesn\'t have the correct number of residues, problem at %s \n' %(struct,structure_rmsd_ca[1])
           struct_rmsd = -1
       elif structure_rmsd_ca[0] == -2:
           print 'Warnig: %s doesn\'t have correct number of atoms in residue %s, problem at %s \n' %(struct,structure_rmsd_ca[1],structure_rmsd_ca[2])
           struct_rmsd = -1
       else:
           struct_rmsd = structure_rmsd_ca[0]
   else:
       struct_rmsd = structure_rmsd_ca

   #score_rms_list.append((struct,cur_score,struct_rmsd))


#score_rms_list.sort(lambda x,y:cmp(x[1],y[1]))  #sort list by second element (score)
#print score_rms_list
output_lines.sort(lambda x,y:cmp(x.score,y.score))

#for entry in score_rms_list:
#    print "%s    %-10s  %.3f" % (entry[0],entry[1],entry[2])

print 'well, we made it to the end'

outf = open(outfile,'w')
for line in output_lines:
    line.write_output(outf)

outf.close()
