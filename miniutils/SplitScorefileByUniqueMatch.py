#!/usr/bin/python/

import sys
import os

def add_spaces(string, newlen, dir = 0):
    if len(string) > newlen:
        return string

    fill = newlen - len(string)
    if dir == 0:
        for i in range(fill):
            string = string + ' '

    else:
        for i in range(fill):
            string = ' ' + string

    return string


def usage():
    print 'Script to read in an enzdes generated scorefile, divide the entries by unique match, and write all entries for a particular unique match to a separate file',
    print 'Usage: SplitScoreFileByUniqueMatch.py -s <scorefile>'


def read_file_to_commentless_linelist( filehandle ):
    
    return_lines = []
    line = filehandle.readline()
    while( line ):
        
        commentpos = line.find('#')
        if commentpos != -1:
            if line[commentpos-1:commentpos] != "\\":
                #print "splitting out comment %s" % line[commentpos:]
                line = line[0:commentpos]

        if len(line) > 0 :
            return_lines.append(line)

        line = filehandle.readline()

    return return_lines


CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()

um_dict = {}
scaf_dict = {}
num_different_scafs = 0
num_unique_matches = 0
scorefile = ''
list_file = ''
scaf_column = 3
list_mode = 0
file_list = []


for arg in CommandArgs:
    if arg == '-s':
        scorefile = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-scafcol':
        scaf_column = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]

if list_mode:
    #if not list_file:
    #    print 'E
    if not os.path.exists(list_file):
        print 'Error, no list file found \n'
        sys.exit()

    listf = open(list_file,'r')
    file_list = listf.readlines()
    listf.close()

else:
    file_list.append(scorefile)

title_line = ''

for file in file_list:

    file = file.replace("\n","")
    filehandle = open(file,'r')
    file_lines = filehandle.readlines()
    filehandle.close

    for line in file_lines:

        if title_line == '' and len( um_dict.keys() ) == 0:  #means first file, first line
            title_line = line
            #print "title_line detected to be %s" % title_line
            continue

        line_items = line.split()
        #assuming that match name is the last thing in the line
        struct_name = line_items[ len( line_items ) - 1 ]
        name_items = struct_name.split('_')
        unique_name = name_items[0]+'_'+name_items[1]+'_'+name_items[2]+'_'+name_items[3]+'_'+name_items[4]
        scafname = name_items[3]

        if um_dict.has_key( unique_name ):
            um_dict[ unique_name ].append( line )
        else:
            um_dict[ unique_name ] = []
            um_dict[ unique_name ].append( line )
	    num_unique_matches = num_unique_matches + 1
            #print "new key added to dict: %s. Size is now %s" % (unique_name, len( um_dict.keys() ) )

	if not scaf_dict.has_key( scafname ):
		scaf_dict[ scafname ] = 1
		num_different_scafs = num_different_scafs + 1

print "%s unique matches in %s scaffolds." % (num_unique_matches, num_different_scafs)

for key in um_dict.keys():
    
    splitfile_name = key+"_splitout.txt"
    try:
        os.remove( splitfile_name)
    except os.error:
        pass

    newfile = open(splitfile_name,'w')
    newfile.write(title_line)
    for line in um_dict[ key ]:
        newfile.write( line )
    newfile.close

scaffile = open("splitscafs.txt",'w')
scafstring = ""
for key in scaf_dict.keys():
	scafstring = scafstring + " " + key
scaffile.write(scafstring)
scaffile.close()

                
