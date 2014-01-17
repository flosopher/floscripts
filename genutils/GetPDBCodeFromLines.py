#!/usr/bin/python

#script to read in a file and for every line, spit out the 4 characters
#after the specified -char_position

import sys
import os



InfileList = []

charpos = -1


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
            InfileList.append (CommandArgs[arg_ind + i +1 ] )
    if arg == '-char_position':
        charpos = int( CommandArgs[ CommandArgs.index(arg) + 1 ] )

if charpos == -1:
    print "Error, illegal -char_position specified, or not specified at all?"

end_char = charpos + 4
outlist = []
#now process the file lists
for infile in InfileList:
    #print "processing list %s" % list
    listfile = open(infile,'r')
    lines = listfile.readlines()
    listfile.close
    for line in lines:
        outlist.append( line[charpos:end_char] )

outstring = ""
for element in outlist:
    outstring = outstring + str( element ) + "\n"

print outstring

