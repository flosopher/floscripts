#!/usr/bin/python

#translates rosetta++ resfile to mini resfile

import sys
import re


FileList = []
Listfile = ''
resfile = ''
single_file = ''
listmode = 0;

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        listmode = 1
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-s':
        single_file = CommandArgs[CommandArgs.index(arg)+1]

if ( (not Listfile) and (not single_file)):
     print 'Error, please supply name of the listfile or a single resfile'
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

   res_info = []  #will save every line
   res_behaviours = {}  #will keep count of how many residues do what
   default = 'NATAA'  #defaul behaviour for mini resfile
   default_count = 0

   resf_line = resf.readline()

   while not resf_match.search(resf_line):  #get rid of comments
       resf_line = resf.readline()
   resf_line = resf.readline()   #read one more line to get rid of start tag

   while resf_line:
       resf_line = resf_line.replace("\n","")
       res_info.append(resf_line)
       curres_behav = resf_line[13:18]
       if res_behaviours.has_key(curres_behav):
           res_behaviours[curres_behav] = res_behaviours[curres_behav] + 1

       else:
           res_behaviours[curres_behav] = 1

       resf_line = resf.readline()

   resf.close()

   #now determine the default behaviour
   for behav in res_behaviours.keys():
       if res_behaviours[behav] > default_count:
           default_count = res_behaviours[behav]
           default = behav

   print '#default behaviour \n%s \n' % default
   print 'start'

   for res in res_info:
       if res[13:18] != default:
           print '%s %s %s' %(res[3:7],res[1:2],res[13:])


