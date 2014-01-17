#!/usr/bin/python


#sets up a directory tree as specified by the -queue option and writes a corresponding condor file
#can also write the paths file

import sys
import os
import re
import time

exec_binary = '/work/flo/bin/EnzdesFixBB.linuxiccrelease'
Listfile = ''
projname = ''
startstruct = ''
nstruct = 1
projname = 'default'
outsuffix = '_DE$(Process)'
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
queue_specified = 0
scorefile_name_equals_structname = 0

usage_string = """
This script can be used to setup a run on syd. Evoking this script will cause all the specified input files to be copied to syd into a directory structure determined and created by this script. Further, run directories will be created on syd, and a condor file will be written. Ideally, all the user has to do after calling this script is to condor_submit the condor file
Necessary inputs
-proj the name of the project. 
-l <list of files> all structures that are supposed to run. the files must be listed under the correct path.
-q <number of jobs to queue> the total number of jobs that will be queued on syd
-nstruct <number nstruct> how many structures EACH of the queued jobs produces
-flags <flagsfile> flagsfile for the job
-make_dirs this will invoke the actual creation of the directories. if this option is not active, the script will only write the condorfile.

Note: this script expects to find directory ~<username>/files/startstruct/ on syd.

"""

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
#    if arg == '-proj':
#	proj = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-s':
        startstruct = CommandArgs[CommandArgs.index(arg)+1]
	num_startstruct = 1
	startstructs.append( startstruct )
    elif arg == '-l':
	Listfile = CommandArgs[CommandArgs.index(arg)+1]
	listmode = 1
    elif arg == '-nstruct':
        nstruct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-make_dirs':
        make_dirs = 1
    elif arg == '-make_path':
        make_path_file = 1
    elif arg == '-sfesn':
         scorefile_name_equals_structname = 1
    elif arg == '-proj':
        projname = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-flags':
	flagsfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-q':
	queue = int( CommandArgs[CommandArgs.index(arg)+1] )
        queue_specified = 1
    elif arg == '-outsuffix':
        outsuffix = str( CommandArgs[CommandArgs.index(arg)+1] ) + '$(Process)'
    elif arg == '-exec':
        exec_binary = str( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-help' or arg == '-h':
	print usage_string
        sys.exit()


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

if not queue_specified:
    queue = num_structs

#fundamentally different if the number of structs to process is more than the number of
#jobs to run
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
            #we want to wait here a little while,
            #files get lost sometimes
            time.sleep(0.5)
            syd_reply = os.popen("ssh syd \"ls /work/flo/files/startstruct/%s/%s/* > /work/flo/files/startstruct/%s/%s  \""%(projname,this_dir,projname,listname ) )


                                                
    #arg_choices.append("""Arguments   = @/work/flo/files/flags -nstruct %s -s /work1/flo/files/%s -cstfile /work/flo/files/Est_hNN_d2n_zero.cst -database /scratch/USERS/davis/minirosetta_database/""" %(str(nstruct),startstruct) )
    sydlist = "/work/flo/files/startstruct/"+projname+"/"+projname+"_$(Process).list"
    outname = projname + "_$(Process)"

    #arg_choices.append("""Arguments   = %s -nstruct %s -s %s -out:suffix _$(Process) -database /scratch/USERS/flo/minidb/""" %(flagsfile, str(nstruct),startstruct) )

    arg_choices.append("""Arguments   = @/work/flo/projects/%s/%s -nstruct %s -l %s -out:file::o %s.out -database /scratch/USERS/flo/minidb/ -out:suffix %s""" %(projname,flagsfile, str(nstruct),sydlist, outname, outsuffix ) )

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
    rundir = "/work/flo/projects/"+projname+"/"+projname+"_$(Process)/"
    condfilename = projname+'.condor'
    condorfile = open(condfilename, 'w')
    condstring = """

    Executable = %s
    universe = vanilla
    
    Error = %sError_$(Process)
    Log = %sLog_$(Process)


    Initialdir = %s
    %s
    Output = %s_$(Process).log
    queue %s

    """ %(exec_binary, rundir,rundir,rundir,arg_choices[0],projname,queue) 

    condorfile.write(condstring)
    condorfile.close()

    if( make_dirs ):
        #print "copying condor file %s" % condfilename
        syd_reply = os.popen("scp %s syd:/work/flo/projects/%s/ " %(condfilename, projname) )
        syd_reply = os.popen("scp %s syd:/work/flo/projects/%s/" %( flagsfile,projname ) )


 #if the number of jobs to run is higher than the number of structures to process,
 #everything changes
else:
    #first, every startstruct gets it's own directory
    #we're done with processing the list 

    if( make_dirs ):
        
        syd_reply = os.popen("ssh syd \"mkdir /work/flo/files/startstruct/%s \"" % projname)
        
        syd_reply = os.popen("ssh syd \"mkdir /work/flo/projects/%s \"" % projname)

        #copy the flagsfile
        syd_reply = os.popen("scp %s syd:/work/flo/projects/%s/" %( flagsfile,projname ) )
        
        #copy all the startstucts
        for i in range( num_structs ):
            this_dir = projname + "_" + str(i)
            syd_reply = os.popen("ssh syd \"mkdir /work/flo/files/startstruct/%s/%s \"" %(projname,this_dir) )
            syd_reply = os.popen("scp %s syd:/work/flo/files/startstruct/%s/%s/" %( startstructs[i].replace("\n","" ), projname,this_dir) )


    #prepare the run files and directories
    outtag = projname + "_$(Process)"
    scorefilename = outtag
    
    
    condfilename = projname+'.condor'
    condstrings = ""

    queue_per_struct = queue / num_structs
    overhang = queue % num_structs
    flagpath = "/work/flo/projects/%s/%s" %( projname, flagsfile )
        
    for i in range ( num_structs ):

        this_dir = projname + "_" + str(i)

        struct_path =  (startstructs[ i ].replace("\n","" )).split("/")
        struct_name = struct_path[ len( struct_path ) - 1 ]
        struct_this_i = "/work/flo/files/startstruct/%s/%s/%s"%(projname, this_dir, struct_name )
        if scorefile_name_equals_structname:
            scorefilename = struct_name.replace(".pdb","") + "_"+ outtag
        
        rundir = "/work/flo/projects/%s/%s/" %(projname,outtag)

        arguments = "Arguments = @%s -nstruct %s -s %s -out:file::o %s.out -database /scratch/USERS/flo/minidb/ -out:suffix %s "%(flagpath, str(nstruct), struct_this_i, scorefilename, outsuffix)

        this_queue = queue_per_struct
        
        if( i < overhang ):
            this_queue = this_queue + 1
        
        string_to_add = "Initialdir = " + rundir + "\n" + arguments + "\nOutput = " + outtag + ".log\nqueue %s"%(this_queue) + "\n"
        condstrings = condstrings + "\n\n" + string_to_add


    #make all the outdirecotyr
    if( make_dirs ):
        for i in range ( queue ):
            syd_reply = os.popen("ssh syd \"mkdir /work/flo/projects/%s/%s \"" %(projname,projname + "_" + str(i)) )


    #now output the condor file
    condorfile_string = """
Executable = %s
universe = vanilla

Error = /work/flo/projects/%s/%s/Error_%s
Log = /work/flo/projects/%s/%s/condor_log_%s

    """%(exec_binary, projname,outtag,outtag,projname,outtag,outtag) + condstrings

    condorfile = open(condfilename, 'w')
    condorfile.write(condorfile_string)
    condorfile.close()
    
   
