#!/usr/bin/python

#translates rosetta++ resfile to mini resfile

import sys
import re
import os


FileList = []
Listfile = ''
resfile = ''
single_file = ''

DIG_CAPACITY = 2000.0 #current digs have 20 nodes



def get_host_loads( hostlist ):

    host_loads = []
    for host in hostlist:

        totcpu = 0.0
        host_reply = os.popen("ssh %s \"ps aux\"" % host )
        #reply_string = host_reply.read()

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
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        

#if ( not Listfile):
#     print 'Error, please supply name of the listfile '
#     sys.exit()

#inlist = open(Listfile,'r')
#FileList = inlist.readlines()
#inlist.close()

#build up the list of digs
dig_list = []
for i in range(26):
    if i == 7:
        continue
    dig_list.append( "dig"+str(i+1) )
    

dig_loads = get_host_loads( dig_list )

for dig in dig_loads:
    job_capacity = (DIG_CAPACITY - (dig[1] -1.00) ) / 100
    job_capacity = int(job_capacity )
    print "%s has load %.2f and can accept %s more jobs"% (dig[0], dig[1], job_capacity )
