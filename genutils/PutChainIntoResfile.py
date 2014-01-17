#!/usr/bin/python

#translates rosetta++ resfile to mini resfile

import sys
import re
import shutil
import os


FileList = []
Listfile = ''
resfile = ''
single_file = ''
listmode = 0;
chain = ''

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-chain':
        chain = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        listmode = 1
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-s':
        single_file = CommandArgs[CommandArgs.index(arg)+1]

if ( (not Listfile) and (not single_file)):
     print 'Error, please supply name of the listfile or a single resfile'
     sys.exit()

if len(chain) != 1:
    print 'Error, chain can only consist of one character'
    sys.exit()

if(listmode):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
else:
    FileList.append(single_file)

#now read in resfile to determine the residues that moved

resf_match = re.compile(r"start",re.I)


#then read in template

#now process structures
for rfile in FileList:

   rfile = rfile.replace("\n","")
   resf = open(rfile,'r')
   newlines = []

   res_info = []  #will save every line
   res_behaviours = {}  #will keep count of how many residues do what
   default = 'NATAA'  #defaul behaviour for mini resfile
   default_count = 0

   resf_line = resf.readline()
   newlines.append(resf_line)

   while not resf_match.search(resf_line):  #get rid of comments
       resf_line = resf.readline()
       newlines.append(resf_line)
   resf_line = resf.readline()   #read one more line to get rid of start tag
   #newlines.append(resf_line)

   while resf_line:
       if resf_line[1:2] == ' ':
           resf_line = ' ' + chain + resf_line[2:]
       newlines.append(resf_line)
       resf_line = resf.readline()

   resf.close()

   nfile = open('tempres', 'w')
   for line in newlines:
       nfile.write(line)
   nfile.close

   #shutil.move('tempres',rfile)
   os.rename('tempres',rfile)

   

