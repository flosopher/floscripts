#!/usr/bin/python

import os
import sys

CommandArgs = sys.argv[1:]
listfile = ""

for arg in CommandArgs:
    if arg == '-l':
    	listfile = CommandArgs[CommandArgs.index(arg)+1]

if( listfile == "" ):
	print "No listfile name given. Use -l <listfile>"
	sys.exit()

listf = open(listfile,'r')
allfiles = listf.readlines()
listf.close()

for file in allfiles:
	file = file.replace("\n","")
	tokens = file.split('_')
	newname = tokens[0]
	for i in range(1,4):
		newname = newname + "_" + tokens[i]
	for i in range(10, len( tokens)):
		newname = newname + "_" + tokens[i]

	#print "old file is %s, new file is %s" %(file, newname)
	os.popen("mv %s %s" % (file, newname) )
