#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys


FileList = []
Listfile = ''
SingleFile = ''
outext = 'SplitOut_'
splitstring = " "


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-f':
        SingleFile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-out':
        outext = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-split_string':
        splitstring = CommandArgs[CommandArgs.index(arg)+1]


if( splitstring == " "):
    print "Error, please supply what string to split the files on depending on. Use option -split_string"
    sys.exit()


if ( (not Listfile) and (not SingleFile) ) :
     print 'Error, please supply name of the listfile, or of a single file'
     sys.exit()
elif (not SingleFile):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()

else :
    FileList.append( SingleFile );

#now read in resfile to determine the residues that moved



outstring = ''

for file in FileList:

    filename = file.replace("\n","")
    file_h = open(filename,'r')
    file_lines = file_h.readlines()
    file_h.close()

    num_splits = 0

    to_output = []

    for line in file_lines:

        line_cols = line.split()

        for col in line_cols:
            #print col+ " hi "

            if col == splitstring:
                #print "meep "+line
                #print "to_output has length "+ str( len(to_output ) )
                if len( to_output ) > 0:
                    num_splits = num_splits + 1
                    outf = open( outext + str( num_splits )+".txt", 'w')
                    outstring = ""
                    for outline in to_output:
                        outstring = outstring+outline
                    #print "writing.. "
                    outf.write( outstring )
                    
                    outf.close()
                to_output = []
                break

        to_output.append( line )
