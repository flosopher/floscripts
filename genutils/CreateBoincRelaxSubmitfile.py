#!/usr/bin/python

#convenience script to distribute runs onto the digs
#without pissing off people (hopefully)

import sys
import re
import os
import time
import random
import socket




ScafFileList = []
ListfileList = []

jobtype = ""
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



#now process the file lists
for list in ListfileList:
    #print "processing list %s" % list
    listfile = open(list,'r')
    files = listfile.readlines()
    listfile.close
    for file in files:
        ScafFileList.append( file.replace("\n","") )

#build up the match command lines
num_orig_jobs = len( ScafFileList )
filestring = ""
curdir = os.getcwd()
#cmd_lines will be list of tuples


#print "A total of %s jobs will be launched" % num_orig_jobs



outstring = "application = minirosetta\n"


for struct in ScafFileList:

    subcode = struct[1:3]
    this_dir = get_scaffold_dir( struct ) 
    startpdb = "%s_nohet_1.pdb" % struct
    startpdbpath = this_dir + startpdb
    cstfile = "%s_nohet_1_sc.cst" % struct
    cstfilepath = this_dir + cstfile

    this_string = "name = scrlx_%s_%s_SAVE_ALL_OUT\ndescription = relax of scaffold %s\n" % (subcode, struct, struct)
    this_string = this_string + "inputfiles = %s, %s, /work/nivon/design/for_flo/baseflags, /work/flo/designs/wholepdbscafstuff/relax/relax_sccoordcst_boinc.flags, /work/flo/designs/wholepdbscafstuff/relax/always_constrained_relax_script.zip\n"% (startpdbpath, cstfilepath)
    this_string = this_string + "arguments = @baseflags @relax_sccoordcst_boinc.flags -constraints:cst_fa_file %s -s %s -out:file:silent_struct_type binary -run:write_failures false -fail_on_bad_hbond false -run:protocol relax -silent_gz -in:file:boinc_wu_zip always_constrained_relax_script.zip -mute all\n" %(cstfile, startpdb)
    this_string = this_string + "resultfiles = default.out.gz\nqueue = 1\n\n"

    outstring = outstring + this_string


print outstring



