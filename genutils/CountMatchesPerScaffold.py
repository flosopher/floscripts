#!/usr/bin/python
import sys
import os


ScafFileList = []
ListfileList = []

helpstring = """Script that will find all matches in the current directory and all subdirectories (using the find command), then split out the scaffold, and count how many matches there are for each scaffold.
"""

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

scafdict = {};

sys_reply = os.popen("find . -name \"UM*_1.pdb\"")
allumfiles = (sys_reply.read() ).split('\n')
totcount = 0

for file in allumfiles:
    if file == "":
        continue
    #print file
    #print "aheh"
    dirs = file.split('/')
    #print dirs
    fname = dirs[ len(dirs) - 1]
    #print fname
    if fname[0:2] != "UM":
        print fname
        print "Error: apparently there are matches that don't start with 'UM', script can't deal with this."
        sys.exit()
    scafname = (fname.split('_'))[3]
    if not scafdict.has_key( scafname ):
        scafdict[scafname] = 1
    else:
        scafdict[scafname] = scafdict[scafname] + 1

outstring = ""
for key in scafdict.keys():
    num_this_scaf = scafdict[key]
    totcount = totcount + num_this_scaf
    outstring = outstring + key + " has %s matches.\n" % num_this_scaf

outstring = outstring + "A total of %s matches in %s scaffolds were counted." % ( totcount, len( scafdict ) )

print outstring
