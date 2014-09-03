#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import re
from SequenceProfile import SequenceProfile

ADD_PDB_SUFFIX = 0

def get_coordinates(struct):

    struct = struct.replace("\n","")
    if ADD_PDB_SUFFIX == 1:
        struct = struct + ".pdb"
    
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
outfile = ""
Singlefile = ''
listmode = 0
external_template = 1

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-s':
        Singlefile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-add_pdb_suffix':
        ADD_PDB_SUFFIX = 1

if( Listfile and not template ):
    hurz = 2

elif( (not Listfile and not Singlefile) or (not template) ):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()


if(listmode):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    if( not template ):
        template = FileList[0].replace("\n","")
        external_template = 0
    if outfile == ' ':
        outfile = Listfile + '.ana'
    print "Checking structures for %s structures in %s to template %s" % (len(FileList), Listfile, template)

else:
    FileList.append(Singlefile)

template_coords = {}

if template != '':
    template_coords = get_coordinates(template)

seq_prof = SequenceProfile( template_coords, external_template )

outstring = ""

for struct in FileList:

    struct_coords = get_coordinates(struct)

    seq_prof.add_struct( struct_coords )
 
    #print mutstring

outstring = seq_prof.get_outstring()
pymutstring =  seq_prof.get_pymutstring()
    #print outstring


if outfile == "":
    print outstring
    print pymutstring

else:
    outf = open(outfile,'w')
    outf.write(outstring)
    outf.close()
