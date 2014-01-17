#!/usr/bin/python


#sets up a directory tree as specified by the -queue option and writes a corresponding condor file
#can also write the paths file

import sys
import os
import re


Listfile = ''
projname = ''
startstruct = ''
nstruct = 1
projname = 'default'
queue = 1
make_dirs = 0
make_path_file = 0
arg_choices = []
flagsfile = ''
num_startstruct = 0
listmode = 0
startstructs = []
#get the path we're in
cur_path = os.path.abspath('./')


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
#    if arg == '-proj':
#	proj = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-s':
        startstruct = CommandArgs[CommandArgs.index(arg)+1]
	num_startstruct = 1
	startstucts.append( startsruct )
    elif arg == '-l':
	Listfile = CommandArgs[CommandArgs.index(arg)+1]
	listmode = 1
    elif arg == '-nstruct':
        nstruct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-make_dirs':
        make_dirs = 1
    elif arg == '-make_path':
        make_path_file = 1
    elif arg == '-proj':
        projname = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-flags':
	flagsfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-q':
	queue = int( CommandArgs[CommandArgs.index(arg)+1] )

if ( ( (not startstruct) and not listmode) or (not queue)):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()

#if( not startstruct):
#   startstruct = projname + ".pdb"


if listmode == 1:
    listf = open(Listfile,'r')
    startstructs = listf.readlines()
    listf.close()
 

num_structs = len( startstructs ) #.length()

if( num_structs >= queue ):
    #print "ARRGH"
    structs_per_queue = int (num_structs / queue)

    overhang = num_structs % queue
    
    queue_structlist = []
    structcounter = 0

    for i in range( queue ):
        structs_this_queue = []
        for j in range( structs_per_queue ):
            structs_this_queue.append( startstructs[ structcounter ].replace("\n","" ) )
            structcounter = structcounter + 1
        queue_structlist.append( structs_this_queue )

    if( structcounter != structs_per_queue * queue ):
        print "arrgh, structcouner not right, is %s" % structcounter
        sys.exit()

    print "about to process overhang of %s" % str(overhang)
    for i in range (overhang):
        queue_structlist[ i ].append( startstructs[ structcounter ].replace("\n","" ) )
        structcounter = structcounter + 1

    #we're done with processing the list 

    if( make_dirs ):
        
        syd_reply = os.popen("ssh syd \"mkdir /work/flo/files/startstruct/%s \"" % projname)
        
        syd_reply = os.popen("ssh syd \"mkdir /work/flo/projects/%s \"" % projname)
        
        
        for i in range( queue ):
            this_dir = projname + "_" + str(i)
            syd_reply = os.popen("ssh syd \"mkdir /work/flo/files/startstruct/%s/%s \"" %(projname,this_dir) )
            
            syd_reply = os.popen("ssh syd \"mkdir /work/flo/projects/%s/%s \"" %(projname,this_dir) )

            for j in range( len( queue_structlist[ i ] ) ):

                #print "trying to scp"
                #print "scp %s syd:/work/flo/files/startstruct/%s/%s/" %(queue_structlist[ i ][j], projname,this_dir)
                #print "done"
                syd_reply = os.popen("scp %s syd:/work/flo/files/startstruct/%s/%s/" %(queue_structlist[ i ][j], projname,this_dir) )
                

            listname = this_dir + ".list"
            syd_reply = os.popen("ssh syd \"ls /work/flo/files/startstruct/%s/%s/* > /work/flo/files/startstruct/%s/%s  \""%(projname,this_dir,projname,listname ) )
                                     
            
else:
    print "fuck this"

#arg_choices.append("""Arguments   = @/work/flo/files/flags -nstruct %s -s /work1/flo/files/%s -cstfile /work/flo/files/Est_hNN_d2n_zero.cst -database /scratch/USERS/davis/minirosetta_database/""" %(str(nstruct),startstruct) )
sydlist = "/work/flo/files/startstruct/"+projname+"/"+projname+"_$(Process).list"
outname = projname + "_$(Process)"

#arg_choices.append("""Arguments   = %s -nstruct %s -s %s -out:suffix _$(Process) -database /scratch/USERS/flo/minidb/""" %(flagsfile, str(nstruct),startstruct) )

arg_choices.append("""Arguments   = %s -nstruct %s -l %s -out:file::o %s -database /scratch/USERS/flo/minidb/""" %(flagsfile, str(nstruct),sydlist, outname) )

#arg_choices[1] = """Arguments   = -pose1 -backrub_mc -fa_input -nstruct 1 -s _apo.pdb -find_disulf -resfile /1h2j_brub.resfile -bb_min -series 01 -ntrials 10000 -protein ha -chain A -mc_temp 0.6 -nstruct 1 -paths /paths.txt""" #% (startstruct)

#now build the directory tree
#if make_dirs:
#    if not os.path.isdir('./'+'output'+'/'):
#        os.mkdir('./'+'output'+'/')
#        for i in range(int(queue)):
#            os.mkdir('./'+'output'+'/'+'out'+str(i)+'/')
#    else:
#        print 'Warning, a directory tree already seems to exist, better leave it intact ...'

#now print the condor file
rundir = "work/flo/projects/"+projname+"/"+projname+"_$(Process)/"
condfilename = projname+'.condor'
condorfile = open(condfilename, 'w')
condstring = """

Executable = /work/flo/bin/EnzdesFixBB.linuxiccrelease
universe = vanilla

Error = %sError
Log = %sLog


Initialdir = %s
%s
Output = %s_$(Process).out
queue %s

""" %(rundir,rundir,rundir,arg_choices[0],projname,queue) 

condorfile.write(condstring)
condorfile.close()

if( make_dirs ):
    #print "copying condor file %s" % condfilename
    syd_reply = os.popen("scp %s syd:/work/flo/projects/%s/ " %(condfilename, projname) )
