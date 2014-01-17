#!/usr/bin/python

#convenience script to distribute runs onto the digs
#without pissing off people (hopefully)
#sample commandline nohup ~/laptop_bkup/scripts/genutils/RunTonsOfJobsOnDigs.py -jobtype relaxscaf -checkpoint -min_free_dig_slots 140 -l torelaxbatch7.txt > batch7log1.txt &

import sys
import re
import os
import time
import random
import socket




min_free_dig_slots = 10 
wait_interval = 200
ScafFileList = []
ListfileList = []

jobtype = ""
checkpoint = 0
default_rundir = os.getcwd()

DIG_CAPACITY = 2000.0 #new digs have 20 nodes

def get_dig_capacity( dig ):
    return DIG_CAPACITY
#    dignum = int ( dig[3:] )
#    #print "asking for capacity of %s, num is %s" % (dig, dignum)
#    if( dignum < 21 ):
#        return NEW_DIG_CAPACITY
#    else:
#        return OLD_DIG_CAPACITY

#convenience for matching/scaffold related stuff
ScaffoldDir = "/lab/shared/scaffolds/"
def get_scaffold_dir( pdb_code ):
    subcode = pdb_code[1:3]
    return ScaffoldDir + subcode + "/" + pdb_code + "/"


#returns list of tuples, where tuple[1]=host, tuple[2]=load as added percentage over all cpus
def get_host_loads( hostlist ):

    host_loads = []
    for host in hostlist:

        #first we need to try whether the host is actually online
        test_reply = os.popen("ssh %s \"echo yomama\" < /dev/null" % host )
        teststr = test_reply.read()[0:6]
        if( teststr != "yomama" ):
                print "host %s aint echoing yomama, prolly offline, skipping \n " % host
                continue
            
        totcpu = 0.0
        host_reply = os.popen("ssh %s \"ps aux\" < /dev/null" % host )
 
        process_strings = (host_reply.read() ).split('\n')
        cpu_col = -1

        title_cols = process_strings[0].split()
        title_len = len(title_cols)

        for i in range( title_len ):
            if title_cols[i] == "%CPU":
                cpu_col = i

        process_strings.pop(0)

        #apparently the last line that's returned is messed up
        if( len( process_strings[ len( process_strings ) - 1 ].split() ) < 2 ):
            process_strings.pop( len( process_strings ) - 1 )

        if cpu_col == (-1):
            print "Error, for host %s, no column seems to contain the cpu loads" % host
            sys.exit()

        #print "For host %s, cpu info is in col %s " % ( host, cpu_col )
        num_real_jobs = 0
        for string in process_strings:
            #print string
            cols = string.split()
            load_this_proc =  float( cols[ cpu_col ] )
            #tmp hack to deal with TMalign jobs
            if cols[10] == "/work/sonya/bin/TMalign":
                load_this_proc = 100.0
                #print "fuuuck"
            totcpu = totcpu + load_this_proc
            if load_this_proc > 5.0:
                num_real_jobs = num_real_jobs + 1

        real_job_load = num_real_jobs * 100.0
        hostload = max(real_job_load, totcpu )
        #print "host %s has totcpu %.3f and %s real jobs, load counts as %.3f" % (host, totcpu, num_real_jobs, hostload)
        host_loads.append( (host, hostload) )

    return host_loads


CommandArgs = sys.argv[1:]

#abstract base class.
#all child classes should implement the get_cmd_lines
#method, which returns a list of tuples, where tuple[1]=commandline, tuple[2]=execute directory of commandline
class CommandLineGenerator:

    def __init__(self):
        #nothing happening here
        x = 1

    def get_cmd_lines(self):
        print "Error. Unimplemented base class method get_cmd_lines called"
        sys.exit()

#CommandLine generator that sets stuff up for generating pssms
class MakePSSMsCLG( CommandLineGenerator ):
    def __init__(self,pdblist):
        self.pdblist_ = pdblist

    def get_cmd_lines(self):

        cmdlist = []
        for pdb in self.pdblist_:
            this_rundir = get_scaffold_dir( pdb )
            this_cmd = "/work/flo/designs/wholepdbscafstuff/make_pssm_file.csh %s > /dev/null" %pdb
            cmdlist.append( (this_cmd, this_rundir) )

        return cmdlist

class ScafRelaxCLG( CommandLineGenerator):
    def __init__(self, pdblist):
        self.pdblist_ = pdblist

    def get_cmd_lines(self):
        cmdlist = []
        for pdb in self.pdblist_:
            this_rundir = get_scaffold_dir( pdb )
            this_cmd = "/work/flo/designs/wholepdbscafstuff/relax/cstrelax_scaf.csh %s > /dev/null" %pdb
            cmdlist.append( (this_cmd, this_rundir) )

        return cmdlist

class AlaScanCLG( CommandLineGenerator ):
    def __init__(self, pdblist):
        self.pdblist_ = pdblist

    def get_cmd_lines(self):
        cmdlist = []
        for pdb in self.pdblist_:
            this_rundir = get_scaffold_dir( pdb )
            this_cmd = "/work/flo/designs/wholepdbscafstuff/aladdg/do_ala_scan.csh %s > /dev/null" %pdb
            cmdlist.append( (this_cmd, this_rundir) )

        return cmdlist


class MakeFragmentsCLG( CommandLineGenerator ):
    def __init__( self, pdblist ):
        self.pdblist_ = pdblist

    def get_cmd_lines(self):
        cmdlist = []
        for pdb in self.pdblist_:
            this_cmd = "/work/flo/designs/esterase/ech13/hisrem/glideresults/topredict/runa-d/fragfiles/create_fragfile.csh %s >& /dev/null" %pdb
            cmdlist.append( (this_cmd, default_rundir) )
        return cmdlist

#CommandLine generator that generates command lines from a checkpoint file
class CheckpointCLG(CommandLineGenerator):
    def __init__(self,chkfile):
        self.checkpoint_file_ = chkfile.replace("\n","")

    def get_cmd_lines(self):
        infile = open(self.checkpoint_file_,'r')
        filecontents = infile.readlines()
        infile.close()

        listsize = len(filecontents)

        i = 0
        cmdlist = []
        while i < listsize:
            cmdlist.append( (filecontents[i].replace("\n",""), filecontents[i+1].replace("\n","") ) )
            i = i + 2

        return cmdlist


for arg in CommandArgs:
    if arg == '-l':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind - 1 ):
            if( (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ListfileList.append (CommandArgs[arg_ind + i +1 ] )
    elif arg == '-s':
        arg_ind = CommandArgs.index(arg)
        for i in range( len( CommandArgs ) - arg_ind -1 ):
            if(  (CommandArgs[arg_ind + i + 1])[0:1] == '-' ):
                break
            ScafFileList.append(CommandArgs[arg_ind + i + 1] )
    elif arg == '-cstfile':
        cstfile = CommandArgs[ CommandArgs.index(arg) + 1 ]
    elif arg == '-checkpoint':
        checkpoint = 1
    elif arg == '-min_free_dig_slots':
        min_free_dig_slots = int( CommandArgs[ CommandArgs.index(arg) + 1 ] )
    elif arg == '-bump_tolerance':
        bump_tolerance = float( CommandArgs[ CommandArgs.index(arg) + 1 ] )
    elif arg == '-jobtype':
        jobtype = CommandArgs[ CommandArgs.index(arg) + 1 ]
    elif arg == '-rundir':
        default_rundir = CommandArgs[ CommandArgs.index(arg) + 1 ]




#now process the file lists
for list in ListfileList:
    print "processing list %s" % list
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
#tuple[0] = cmdline, tuple[1] = workdir in which it will be executed
checkpointfilename = "chkfile_" + jobtype + "_" +str(num_orig_jobs)+".flochkfile"

clg = CommandLineGenerator()

if (checkpoint == 1 ) and os.path.exists(checkpointfilename):
    print "Checkpoint file found, getting commandlines from file %s" % checkpointfilename
    clg = CheckpointCLG(checkpointfilename)

elif( jobtype == "makepssm" ):
    clg = MakePSSMsCLG( ScafFileList )

elif (jobtype == "relaxscaf" ):
    clg = ScafRelaxCLG( ScafFileList )

elif ( jobtype == "alascan" ):
    clg = AlaScanCLG( ScafFileList )

elif (jobtype == "fragments"):
    clg = MakeFragmentsCLG( ScafFileList )

else:
    print "Illegal jobtype specified, exiting.."
    sys.exit

cmd_lines = clg.get_cmd_lines()

#remove checkpoint file to not confuse any eventual later runs of this script
#no wait, probably better to not remove it at this point
#if checkpoint == 1:
#    if os.path.exists(checkpointfilename):
#        os.remove(checkpointfilename)

print "A total of %s jobs will be launched" % len( cmd_lines )

#if ( not Listfile):
#     print 'Error, please supply name of the listfile '
#     sys.exit()

#inlist = open(Listfile,'r')
#FileList = inlist.readlines()
#inlist.close()

#build up the list of digs
dig_list = []
for i in range(26):
    dig_list.append( "dig"+str(i+1) )

dig_list.reverse()  #hopefully we'll piss off less people by submitting to higher digs

submit_iteration = 0

while( len( cmd_lines ) > 0 ):

    submit_iteration = submit_iteration + 1
    num_total_jobs = len( cmd_lines )
    print "getting host loads..."
    dig_loads = get_host_loads( dig_list )
    dig_submit_list = []
    tmp_list = []

   #check how many jobs in total we can submit
    totjobs = 0
    max_capacity = 0
    compile_dig = ''

    for dig in dig_loads:
        job_capacity = int( (get_dig_capacity( dig[0] ) - (dig[1] -1.00) ) / 100 )
	if job_capacity < 0:
		job_capacity = 0
        if job_capacity > max_capacity:
            max_capacity = job_capacity
            compile_dig = dig[0]
        for job in range( job_capacity ):
            tmp_list.append( dig[0] )
        totjobs = totjobs + job_capacity 
        print "%s has load %.2f and can accept %s more jobs"% (dig[0], dig[1], job_capacity )

    print "%s has max capacity of %s, no jobs will be submitted so people can keep compiling." %(compile_dig, max_capacity )
    totjobs = totjobs - max_capacity
    for dig in tmp_list:
        if dig != compile_dig:
            dig_submit_list.append( dig )

    #now we could shuffle the dig submit list, bc match jobs might need high memory
    #we therefore don't want to submit all our match jobs to the same machine
    #akshully match jobs turn out to not need that much memory, so let's not shuffle
    #in hopes of pissing off less people
    #random.shuffle( dig_submit_list )
    max_submit_jobs = int(totjobs - min_free_dig_slots)
    if( max_submit_jobs < 0 ):
        max_submit_jobs = 0
    print "There are a total of %s free job slots available on the digs, script will submit up to %s jobs." %(totjobs, max_submit_jobs )

    num_submit_jobs = min( num_total_jobs, max_submit_jobs )

     #now submit all the jobs
    if( num_total_jobs > max_submit_jobs ):
        print "Warning, requested to submit %s match jobs, but currently there is only dig capacity for %s." % (num_total_jobs, num_submit_jobs) 

    overhang_cmd_lines = []
    digcounter = 0
    for mjob in range( num_total_jobs ):
        if mjob >= num_submit_jobs:
            overhang_cmd_lines.append( cmd_lines[mjob] )
            continue

        #now we're finally ready to submit the job
        print "submitting job with cmdline " + cmd_lines[mjob][0] + "   to dig " + dig_submit_list[digcounter] + " in directory " + cmd_lines[mjob][1]
        os.popen("ssh %s \"cd %s; nohup nice +19 %s & \" & " %(dig_submit_list[digcounter], cmd_lines[mjob][1],cmd_lines[mjob][0] ) )
        digcounter = digcounter + 1

    cmd_lines = overhang_cmd_lines
    #if we're checkpointing, write the remaining commandlines to a file
    if checkpoint == 1:
        newcheckpointstring = ""
	print "Writing checkpoint file containing %s commandlines at the end of submit iteration %s..." % (len(cmd_lines), submit_iteration)
        for cmd in cmd_lines:
            newcheckpointstring = newcheckpointstring + cmd[0] + "\n" + cmd[1] + "\n"
        if os.path.exists(checkpointfilename):
            os.remove(checkpointfilename)
        outfile = open(checkpointfilename,'w')
        outfile.write(newcheckpointstring)
        outfile.close()
        
    if( len( cmd_lines ) > 0 ):
        print "In submit iteration %s, %s jobs remain to be submitted. Waiting for %s seconds until next try...\n" %( submit_iteration, len( cmd_lines ), wait_interval )
        time.sleep( wait_interval )
    #in case we're done, remove checkpoint file
    else:
        if os.path.exists(checkpointfilename):
            os.remove(checkpointfilename)
    
        

