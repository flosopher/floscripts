#!/usr/bin/python

import sys
import os
from math import sqrt

def usage():
    print "run with -l <pdblist>  to replace all SE atom names in MET residues with SD"

dry_run = 0




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
    elif arg == '-dry_run':
        dry_run = 1

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

affected_files = []

for struct in file_list:

    fname = struct.replace("\n","")
    struct_file = open(fname,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    this_struct_affected = 0

    for i in range( len( struct_lines ) ):
        if struct_lines[i][0:4] == 'ATOM':
            if struct_lines[i][17:20] == 'MET':
                if (struct_lines[i][12:14] == 'SE') or (struct_lines[i][13:15] == 'SE'):
                    this_struct_affected = 1
                    struct_lines[i] = struct_lines[i][:12] + ' SD' + struct_lines[i][15:]
            
    
    if this_struct_affected:
        affected_files.append( struct )

    if this_struct_affected and not dry_run:
        filestring = ""
        for line in struct_lines:
            filestring = filestring + line
        os.popen("rm %s" % fname)
        new_file = open(fname,'w')
        new_file.write(filestring )
        new_file.close()

outstring = ""
for file in affected_files:
    outstring = outstring + file

print outstring

