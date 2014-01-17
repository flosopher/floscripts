#!/usr/bin/python


#sets up a directory tree as specified by the -queue option and writes a corresponding condor file
#can also write the paths file

import sys
import os
import re


Listfile = ''
startstruct = ''
nstruct = 1
projname = 'default'
queue = 1
make_dirs = 0
make_path_file = 0
arg_choices = []

#get the path we're in
cur_path = os.path.abspath('./')


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-s':
        startstruct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-nstruct':
        nstruct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-q':
        queue = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-make_dirs':
        make_dirs = 1
    elif arg == '-make_path':
        make_path_file = 1
    elif arg == '-proj':
        projname = CommandArgs[CommandArgs.index(arg)+1]


if ( (not startstruct) or (not queue)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()



arg_choices.append("""Arguments   = -pose1 -backrub_mc -fa_input -s %s_apo.pdb -find_disulf -resfile %s/%s_brub.resfile -bb_min -series 01 -ntrials 10000 -protein %s -chain A -mc_temp 0.6 -nstruct %s -paths %s/paths.txt""" % (startstruct, cur_path, startstruct, startstruct, str(nstruct), cur_path) )

#arg_choices[1] = """Arguments   = -pose1 -backrub_mc -fa_input -nstruct 1 -s _apo.pdb -find_disulf -resfile /1h2j_brub.resfile -bb_min -series 01 -ntrials 10000 -protein ha -chain A -mc_temp 0.6 -nstruct 1 -paths /paths.txt""" #% (startstruct)

#now build the directory tree
if make_dirs:
    if not os.path.isdir('./'+'output'+'/'):
        os.mkdir('./'+'output'+'/')
        for i in range(int(queue)):
            os.mkdir('./'+'output'+'/'+'out'+str(i)+'/')
    else:
        print 'Warning, a directory tree already seems to exist, better leave it intact ...'

#now print the condor file
condfilename = projname+'.condor'
condorfile = open(condfilename, 'w')
condstring = """

Executable = /work1/flo/bin/rosetta.intel
universe = vanilla

Error = %s/Error
Log = %s/Log


Initialdir = %s/output/out$(Process)
%s
Output = %s_%s_$(Process).out
queue %s

""" %(cur_path,cur_path,cur_path,arg_choices[0],projname,startstruct,queue) 

condorfile.write(condstring)
condorfile.close()

#and, if requested, print the paths_file
if make_path_file:
    pathfile = open('paths.txt', 'w')

    pathfile.write("""Rosetta Input/Output Paths (order essential)
path is first '/', './',or  '../' to next whitespace, must end with '/'
INPUT PATHS:
pdb1                            %s/
pdb1                            %s/
alternate data files            ./
fragments                       %s/
structure dssp,ssa (dat,jones)  %s/
sequence fasta,dat,jones        %s/
constraints                     %s/
starting structure              %s/
data files                      /scratch/ROSETTA/rosetta_database/
OUTPUTS PATHS:
movie                           ./
pdb path                        ./
score                           ./
status                          ./
user                            ./
FRAGMENTS: (use '*****' in place of pdb name and chain)
2                               number of valid fragment files
3                               frag file 1 size
aa*****03_05.200_v1_3           name
9                               frag file 2 size
aa*****09_05.200_v1_3           name
-------------------------------------------------------------------------
CVS information:
$Revision: 1.1 $
$Date: 2004/05/13 02:43:41 $
$Author: rohl $
-------------------------------------------------------------------------
""" % (cur_path,cur_path,cur_path,cur_path,cur_path,cur_path,cur_path)
)

    pathfile.close()


