#!/usr/bin/python

#convenience script to run the remodel benchmark
#onto the digs

import sys
import re
import os
import time
import random
import socket

min_free_dig_slots = 10 
ScafFileList = []
ListfileList = []
enzdes_executable = "/work/flo/rosetta/mini/bin/EnzdesFixBB.linuxiccrelease"
wait_interval = 600
total_nstruct = 20
nstruct_per_run = 20

DIG_CAPACITY = 800.0 #current digs have 8 nodes



def get_host_loads( hostlist ):

    host_loads = []
    for host in hostlist:

        #first we need to try whether the host is actually online
        test_reply = os.popen("ssh %s \"echo yomama\" " % host )
        teststr = test_reply.read()[0:6]
        if( teststr != "yomama" ):
                print "host %s aint echoing yomama, prolly offline, skipping \n " % host
                continue
            
        totcpu = 0.0
        host_reply = os.popen("ssh %s \"ps aux\"" % host )
 
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

        for string in process_strings:
            #print string
            cols = string.split()
            totcpu = totcpu + float( cols[ cpu_col ] )

        host_loads.append( (host, totcpu) )

    return host_loads


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
    if arg == '-total_nstruct':
        total_nstruct = int( CommandArgs[ CommandArgs.index(arg) + 1 ] )
    if arg == '-nstruct_per_run':
        nstruct_per_run = int( CommandArgs[ CommandArgs.index(arg) + 1 ] )
    if arg == '-min_free_dig_slots':
        min_free_dig_slots = int( CommandArgs[ CommandArgs.index(arg) + 1 ] )


#now process the file lists
for list in ListfileList:
    print "processing list %s" % list
    listfile = open(list,'r')
    files = listfile.readlines()
    listfile.close
    for file in files:
        ScafFileList.append( file.replace("\n","") )


#build up the match command lines
num_match_jobs = len( ScafFileList )
filestring = ""
curdir = os.getcwd()
jobs_per_struct = int( total_nstruct / nstruct_per_run )
print "%s runs will be started for every structure." % jobs_per_struct
#cmd_lines will be list of tuples
#tuple[0] = cmdline, tuple[1] = workdir in which it will be executed
cmd_lines = []
for file in ScafFileList:
    filestring = filestring + file  + ", "
    prefix = (file.split('.'))[0]
    prefix = (prefix.split('\n'))[0]
    curscafdir = curdir + "/"+prefix+"/"
    for job in range( jobs_per_struct ):
        outcode = "-out:suffix _DE"+str(job +1 )
        logfile = prefix+"_"+str(job+1)+"_rembenchmark.log"
        cmd_lines.append( (enzdes_executable +" @/work/flo/rem_benchmark/remsecmatch_general.flags @"+curscafdir+prefix+"_sys.flags "+ outcode +" > "+logfile , curscafdir ) ) 

    #we will also make the directories here
    #os.popen("mkdir %s" % prefix)
 

print "Remodel benchmark will be launched for the following %s scaffolds: " % num_match_jobs
print filestring
  

#if ( not Listfile):
#     print 'Error, please supply name of the listfile '
#     sys.exit()

#inlist = open(Listfile,'r')
#FileList = inlist.readlines()
#inlist.close()

#build up the list of digs
dig_list = []
for i in range(64):
    if i == 26:
        continue
    dig_list.append( "dig"+str(i+1) )

submit_iteration = 0

while( len( cmd_lines ) > 0 ):

    submit_iteration = submit_iteration + 1
    num_match_jobs = len( cmd_lines )
    print "getting host loads..."
    dig_loads = get_host_loads( dig_list )
    dig_submit_list = []
    tmp_list = []

   #check how many jobs in total we can submit
    totjobs = 0
    max_capacity = 0
    compile_dig = ''

    for dig in dig_loads:
        job_capacity = int( (DIG_CAPACITY - (dig[1] -1.00) ) / 100 )
        if job_capacity > max_capacity:
            max_capacity = job_capacity
            compile_dig = dig[0]
        for job in range( job_capacity ):
            tmp_list.append( dig[0] )
        totjobs = totjobs + job_capacity 
        #print "%s has load %.2f and can accept %s more jobs"% (dig[0], dig[1], job_capacity )

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

    num_submit_jobs = min( num_match_jobs, max_submit_jobs )

     #now submit all the jobs
    if( num_match_jobs > max_submit_jobs ):
        print "Warning, requested to submit %s match jobs, but currently there is only dig capacity for %s." % (num_match_jobs, num_submit_jobs) 

    overhang_cmd_lines = []
    digcounter = 0
    for mjob in range( num_match_jobs ):
        if mjob >= num_submit_jobs:
            overhang_cmd_lines.append( cmd_lines[mjob] )
            continue

        #now we're finally ready to submit the job
        print "submitting job with cmdline " + cmd_lines[mjob][0] + "   to dig " + dig_submit_list[digcounter] + " in directory " + cmd_lines[mjob][1]
        os.popen("ssh %s \"cd %s; nohup nice +19 %s & \" & " %(dig_submit_list[digcounter], cmd_lines[mjob][1],cmd_lines[mjob][0] ) )
        digcounter = digcounter + 1

    cmd_lines = overhang_cmd_lines

    if( len( cmd_lines ) > 0 ):
        print "In submit iteration %s, %s jobs remain to be submitted. Waiting for %s seconds until next try...\n" %( submit_iteration, len( cmd_lines ), wait_interval )
        time.sleep( wait_interval )
    
        

