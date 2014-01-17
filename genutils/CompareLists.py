#!/usr/bin/python

#script to read in two lists and determine which elements are in
#both lists, or alternatively substract list2 from list1

import sys
import os



ListfileList1 = []
ListfileList2 = []
mode = ""

list1 = []
#list1_dict = {}
list2 = []
list2_dict = {}

#convenience for matching/scaffold related stuff
ScaffoldDir = "/lab/shared/scaffolds/"
def get_scaffold_dir( pdb_code ):
    subcode = pdb_code[1:3]
    return ScaffoldDir + subcode + "/" + pdb_code + "/"


CommandArgs = sys.argv[1:]


for arg in CommandArgs:
    if arg == '-l1':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind - 1 ):
            if( (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ListfileList1.append (CommandArgs[arg_ind + i +1 ] )
    if arg == '-l2':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind - 1 ):
            if( (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ListfileList2.append (CommandArgs[arg_ind + i +1 ] )
    if arg == '-mode':
        mode = str( CommandArgs[ CommandArgs.index(arg) + 1 ] )

if (mode != "union") and (mode != "substract") :
    print "Error, mode nees to be either 'union' or 'substract'. Supplied value was '%s'" % mode
    sys.exit()


#now process the file lists
for list in ListfileList1:
    #print "processing list %s" % list
    listfile = open(list,'r')
    files = listfile.readlines()
    listfile.close
    for file in files:
        list1.append( file.replace("\n","") )

for list in ListfileList2:
    #print "processing list %s" % list
    listfile = open(list,'r')
    files = listfile.readlines()
    listfile.close
    for file in files:
        list2.append( file.replace("\n","") )
        list2_dict[ file.replace("\n","") ] = 1

curdir = os.getcwd()

outlist = []

if mode == "union":
    for element in list1:
        if list2_dict.has_key( element ):
            outlist.append( element )
elif mode == "substract":
    for element in list1:
        if not list2_dict.has_key( element ):
            outlist.append( element )

outstring = ""
for element in outlist:
    outstring = outstring + str( element ) + "\n"

print outstring

