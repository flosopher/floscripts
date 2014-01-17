#!/usr/bin/python

#script that will do an 'hg status' command in the current workdir,
#collect the results, and copy every file that has status 'M' or 'A' to a
#specified target directory

import sys
import re
import os

CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    #usage()
    sys.exit()

target_host = 'dig1'
target_dir = '/scratch/USERS/flo/'

for arg in CommandArgs:
   if arg == '-host':
       target_host = CommandArgs[CommandArgs.index(arg)+1]

target_loc = target_host + ':' + target_dir

def get_mod_files():

    mod_files = []
    status_reply = os.popen("hg status")
    status_lines = (status_reply.read()).split('\n')
    for line in status_lines:
        tokens = line.split()
	#print tokens
        num_tokens = len( tokens )
	if num_tokens == 0:
		continue
        if (tokens[0] == 'M') or (tokens[0] == 'A'):
            mod_files.append( tokens[ num_tokens - 1] )

    return mod_files


files_to_copy = get_mod_files()

for file in files_to_copy:
	if file == "src/apps.src.settings":
		continue
	if file == "src/pilot_apps.src.settings.all":
		continue
	target = target_loc + file
	copycmd = "scp %s %s" %(file, target )
	os.popen(copycmd )
	#print "about to execute %s" % copycmd

print "Copied all files"

#CommandArgs = sys.argv[1:]

#for arg in CommandArgs:
#    if arg == '-l':
#        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        

#if ( not Listfile):
#     print 'Error, please supply name of the listfile '
#     sys.exit()

#inlist = open(Listfile,'r')
#FileList = inlist.readlines()
#inlist.close()

#build up the list of digs
#dig_list = []
#for i in range(32):
#    dig_list.append( "dig"+str(i+1) )
    

#dig_loads = get_host_loads( dig_list )

#for dig in dig_loads:
 #   job_capacity = (DIG_CAPACITY - (dig[1] -1.00) ) / 100
  #  job_capacity = int(job_capacity )
  #  print "%s has load %.2f and can accept %s more jobs"% (dig[0], dig[1], job_capacity )
