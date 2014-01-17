#!/usr/bin/python

#script to check whether a file with a given ending is present
#for all scaffolds in an input list

import sys
import os



ScafFileList = []
ListfileList = []

file_ending = ""
checkpoint = 0

#convenience for matching/scaffold related stuff
ScaffoldDir = "/lab/shared/scaffolds/"
def get_scaffold_dir( pdb_code ):
    subcode = pdb_code[1:3]
    return ScaffoldDir + subcode + "/" + pdb_code + "/"


CommandArgs = sys.argv[1:]


for arg in CommandArgs:
    if arg == '-l':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind - 1 ):
            if( (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ListfileList.append (CommandArgs[arg_ind + i +1 ] )
    if arg == '-s':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind -1 ):
            if(  (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ScafFileList.append(CommandArgs[arg_ind + i + 1] )
    if arg == '-file_ending':
        file_ending = CommandArgs[ CommandArgs.index(arg) + 1 ]

if file_ending == "":
    print "Error, need to specify desired file ending with -file_ending"
    sys.exit()


#now process the file lists
for list in ListfileList:
    #print "processing list %s" % list
    listfile = open(list,'r')
    files = listfile.readlines()
    listfile.close
    for file in files:
        ScafFileList.append( file.replace("\n","") )

curdir = os.getcwd()

scafs_not_present = []

for scaf in ScafFileList:
    desired_file = get_scaffold_dir( scaf ) + scaf + file_ending
    #print "looking for %s" % desired_file
    if not os.path.exists( desired_file ):
        #print "doesn't exist"
        scafs_not_present.append( scaf )

num_missing = len( scafs_not_present )
if( num_missing > 0 ):
    outstring = ""
    for scaf in scafs_not_present:
        outstring = outstring + scaf + "\n"

    print "The following %s scaffolds do not have the desired file: \n %s" %(num_missing,outstring)
        

