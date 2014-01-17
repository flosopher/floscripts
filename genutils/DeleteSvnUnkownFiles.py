#!/usr/bin/python

#script that will do an 'svn status' command in the current workdir,
#collect the results, and delete every file that has status '?' to a

import sys
import re
import os




def get_unknown_files():

    mod_files = []
    status_reply = os.popen("svn status")
    status_lines = (status_reply.read()).split('\n')
    for line in status_lines:
        tokens = line.split()
	#print tokens
        num_tokens = len( tokens )
	if num_tokens == 0:
		continue
        if (tokens[0] == '?'):
            mod_files.append( tokens[ num_tokens - 1] )

    return mod_files


files_to_delete = get_unknown_files()

for file in files_to_delete:
	if file == "src/apps.src.settings.few":
		continue
	if file == "src/pilot_apps.src.settings.few":
		continue
	delcmd = "rm -fr %s" %(file)
	os.popen(delcmd )
	#print "about to execute %s" % copycmd


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
