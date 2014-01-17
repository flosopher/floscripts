#!/usr/bin/python

import sys
import os

def usage():
    print """Script to read in a list of logfiles from a remodel run and determine which secondary struture strings led to successes/failure how many times
"""


CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []

list_file = ''
single_file =''

script_fail = 0
outfile = ""

longest_secstruct = 0


class SecstructStats:

    def __init__(self):
        self.rem_failure = 0
        self.rem_loopsuccess = 0
        self.rem_designsuccess = 0
        self.num_attempts = 0

    def add_attempt(self):
        self.num_attempts = self.num_attempts + 1

    def add_remfailure(self):
        self.rem_failure = self.rem_failure + 1

    def add_remloopsuccess(self):
        self.rem_loopsuccess = self.rem_loopsuccess + 1

    def add_remdesignsuccess(self):
        self.rem_designsuccess = self.rem_designsuccess + 1


secstruct_dict = {}

for arg in CommandArgs:
   if arg == '-l':
       list_file = CommandArgs[CommandArgs.index(arg)+1]
   elif arg == '-o':
       outfile = CommandArgs[CommandArgs.index(arg)+1]
   elif arg == '-f':
       single_file = CommandArgs[CommandArgs.index(arg)+1]



#if not list_file:
#    print 'E
if (not os.path.exists(list_file)) and (not os.path.exists(single_file)):
    print 'Error, no list file found \n'
    sys.exit()

if list_file != '':
    listf = open(list_file,'r')
    file_list = listf.readlines()
    listf.close()

if single_file != '':
    file_list.append( single_file )


#input read in, now process files
outlines = []
firstfile = 1
outstring = ""

total_attempts = 0
total_loopsuccess = 0
total_designsuccess = 0


for file in file_list:

    filen = file.replace("\n","")
    filehandle = open(filen,'r')
    file_lines = filehandle.readlines()
    filehandle.close()
 
    cur_ss = ''
    cur_ss_successful = 0
    for line in file_lines:
        if line[0:7] == "devel.e":
            elements = line.split()
	    elsize = len( elements )
	    if( elsize < 2 ):
		continue
	    #print elements
            if (elements[1] == "New" ) and (elements[2] == "secstruct"):
                if cur_ss != '':
                   if not cur_ss_successful:
                       secstruct_dict[ cur_ss ].add_remfailure()
                if( elsize < 7 ):
			cur_ss = "logfile_fail"
		else:
			cur_ss = elements[9].replace("\n","")
                cur_ss_successful = 0
                total_attempts = total_attempts + 1
                if not cur_ss in secstruct_dict:
                    secstruct_dict[ cur_ss ] = SecstructStats()
                    if len(cur_ss) > longest_secstruct:
                        longest_secstruct = len( cur_ss )
                secstruct_dict[ cur_ss ].add_attempt()

            elif (elements[1] == "Remodel" ) and (elements[6] == "success"):
                if cur_ss != elements[10]:
                    print "Error: secstruct %s does not equal success string %s" %(cur_ss,elements[7])
                    sys.exit()
                secstruct_dict[ cur_ss ].add_remloopsuccess()
                total_loopsuccess = total_loopsuccess + 1
                cur_ss_successful = 1

        elif line[0:13] == "protocols.jd2":
            elements = line.split()
            if len( elements ) < 3:
                continue
            if ( elements[2] == "reported") and (elements[3] == "success"):
                if not cur_ss_successful:
                    print "Error: secstruct %s apparently led to design success %s but wasn't set to successful." %(cur_ss, elements[1])
                    sys.exit()
                secstruct_dict[ cur_ss ].add_remdesignsuccess()
                total_designsuccess = total_designsuccess + 1
     


outstring = outstring + "In %s total attempts, %s remodel successes and %s design successes were achieved.\n The distribution among secondary structure strings is as follows:\n secstruct_string     num_attempts   rem_failures   num_remsuccesses   num_design_successes    remsuccess/attempt    design_success/rem_success\n" %( total_attempts, total_loopsuccess, total_designsuccess)

sscolwidth = longest_secstruct + 8
for key in secstruct_dict.keys():
    keyname = key
    while len(keyname) < sscolwidth:
        keyname = keyname + " "

    loopsuccessrate = float(secstruct_dict[key].rem_loopsuccess) / float(secstruct_dict[ key ].num_attempts)
    designsuccessrate = 0.0
    if( float(secstruct_dict[key].rem_loopsuccess) ) > 0.0:
        designsuccessrate = float( secstruct_dict[key].rem_designsuccess ) / float(secstruct_dict[key].rem_loopsuccess)
    loopsuc = "%.2f" % loopsuccessrate
    designsuc = "%.3f" % designsuccessrate
    outstring = outstring + keyname + "  " + str(secstruct_dict[ key ].num_attempts) + "               " + str(secstruct_dict[key].rem_failure ) + "                " + str( secstruct_dict[key].rem_loopsuccess ) + "               " + str( secstruct_dict[key].rem_designsuccess ) + "                      " + loopsuc + "                     " + designsuc + "\n"
   

#done with new file, now we have to add it all into one string
#outstring = "hoh"
#for line in outlines:
#    outstring = outstring + line

if outfile != "":
    newfile = open(outfile,'w')
    newfile.write(outstring)
    newfile.close
else:
    print outstring

#print outstring
 
