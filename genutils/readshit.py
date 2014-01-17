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



CommandArgs = sys.argv[1:]
print CommandArgs

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-grepfile':
        grepfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-all_atom':
        ca_only = 0

if ( (not Listfile) or (not grepfile)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
else:
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    

#now read in resfile to determine the residues that moved




#now process structures
for struct in FileList:

    catres1 = 0

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    cur_line = struct_file.readline()
    while cur_line[0:4] != 'ATOM':
        cols = cur_line.split()
        if cols[0] == 'REMARK' and cols[1] == 'BACKBONE' and cols[2] == 'TEMPLATE' and cols[11] == '1':
            catres1 = cols[10]
            #print 'catres one determined to be %s' % catres1
        cur_line = struct_file.readline()

    while cur_line:
        if cur_line[0:4] == 'woll':
            cols = cur_line.split()
            if (cols[2] == catres1 and (cols[3] == 'ND1' or cols[3] == 'NE2')):
                cmd = 'grep %s %s' % (struct,grepfile)
                #print cmd
                os.system(cmd)
        cur_line = struct_file.readline()

    struct_file.close()

  
#print score_rms_list
