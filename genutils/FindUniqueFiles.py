#!/usr/bin/python

#translates rosetta++ resfile to mini resfile

import sys
import re
import os


FileList = []
Listfile = ''
resfile = ''
single_file = ''
inform_mode = 0
match_name_compare = 0
print_unique = 1
emptystring=""


#function to compare two files string by string, fuck python for not providing a simple system call routine
def files_differ_slow(fileAname, fileBname):
    inA = open(fileAname,'r')
    FileA = inA.readlines()
    inA.close()

    inB = open(fileBname,'r')
    FileB = inB.readlines()
    inB.close()

    if len(FileA) != len(FileB):
        return 1

    for linecount in range( len(FileA) ):
        if FileA[linecount] != FileB[linecount]:
            return 1

    return 0

def different_by_match_name(fileAname, fileBname):
    if fileAname[0:10] != fileBname[0:10]:
        return 1
    else:
        return 0


def files_differ(fileAname, fileBname):
    if match_name_compare == 1:
        if different_by_match_name(fileAname, fileBname) == 1:
            return 1
    
    pdiff=os.popen("cmp %s %s"%(fileAname,fileBname) )
    diffstring = pdiff.read()
    if diffstring != emptystring:
        return 1
    else:
        return 0


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-inform':
        inform_mode = 1
    if arg == '-name_compare':
        match_name_compare = 1
    if arg == '-r':
        print_unique = 0

        

if ( not Listfile):
     print 'Error, please supply name of the listfile '
     sys.exit()

inlist = open(Listfile,'r')
FileList = inlist.readlines()
inlist.close()


unique_dict = {} #dictionary that has all the files as keys and true if they are unique / false otherwise as value


for ii in range( len(FileList) ):

    if not unique_dict.has_key( FileList[ii] ):
        unique_dict[ FileList[ii] ] = 1

    if unique_dict[ FileList[ii] ] == 1:
        for kk in range( len(FileList) - ii -1 ):
                              
            if files_differ( FileList[ii].replace("\n",""),FileList[ii+kk+1].replace("\n","") ) == 0:
                unique_dict[ FileList[ii+kk+1] ] = 0
                if inform_mode == 1:
                    print "%s identical to %s" %(FileList[ii].replace("\n",""),FileList[ii+kk+1].replace("\n",""))


#print "The unique files are: "
for ufile in FileList:
    if unique_dict[ ufile ] == 1:
        print "%s" %ufile.replace("\n","")
