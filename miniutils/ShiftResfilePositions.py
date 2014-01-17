#!/usr/bin/python

#translates rosetta++ resfile to mini resfile

import sys
import re


FileList = []
Listfile = ''
resfile_in = ''
listmode = 0;

insertion_string = "NOTAA  EDKR"


class ResfileRecord:

    def __init__( self, line):
        tokens = line.split()
        self.pos = int( tokens[0] )
        self.chain = tokens[1]
        self.rest = tokens[1] + ' '
        for i in range( len( tokens ) - 2 ):
            self.rest = self.rest + tokens [ i + 2] + '  '

        self.line = line.replace("\n","")



class ResfileChange:

    def __init__( self, chain, position, change ):
        self.chain = chain
        self.pos = position
        self.change = change
        self.last_change_below = 1

    def change_resfile_record( self, resfile_record ):
        #print "about to change resfile record with line "+resfile_record.line+"and position"+str( resfile_record.pos )

        new_resfile_records = []

        if self.chain != resfile_record.chain:
            #print "not chain"
            new_resfile_records.append( resfile_record )

        elif self.pos > resfile_record.pos :
            #print "below event"
            new_resfile_records.append( resfile_record )

        elif self.pos == resfile_record.pos and self.change > 0:
            new_resfile_records.append( resfile_record )
                

        elif self.change < 0:
            if resfile_record.pos > (self.pos - change ):
                newpos = resfile_record.pos + change;
                newstring = newpos + " " + resfile_recored.rest
                new_resfile_records.append( ResfileRecord( newstring) )

        else:
            if self.last_change_below == 1 and self.pos != resfile_record.pos:
                self.last_change_below = 0
                for i in range( change ):
                    new_record = " " + (str) (self.pos + i + 1 ) + " " + self.chain + " " + insertion_string
                    new_resfile_records.append( ResfileRecord(new_record) )
                    
            newpos = resfile_record.pos + change
            newstring =  " " + str( newpos) + " " + resfile_record.rest
            new_resfile_records.append( ResfileRecord( newstring) )


        return new_resfile_records


CommandArgs = sys.argv[1:]

resfile_changes = []

for arg in CommandArgs:
    if arg == '-f':
        resfile_in = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        listmode = 1
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-change':
        chain = CommandArgs[CommandArgs.index(arg)+1]
        position = int( CommandArgs[CommandArgs.index(arg)+2] )
        change = int( CommandArgs[CommandArgs.index(arg)+3] )
        resfile_changes.append( ResfileChange( chain, position, change ) )
 
if ( (not Listfile) and (not resfile_in)):
     print 'Error, please supply name of the listfile or a single resfile'
     sys.exit()

if len( resfile_changes ) < 1:
    print 'Error, no resfile changes were specified'
    sys.exit()

if len( resfile_changes ) > 1:
    print 'Error, more than one resfile change specified, script can\'t handle this yet.'
    sys.exit()

if(listmode):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
else:
    FileList.append(resfile_in)

#now read in resfile to determine the residues that moved

resf_match = re.compile(r"start",re.I)


#then read in template

#now process structures
for rfile in FileList:

   rfile = rfile.replace("\n","")
   resf = open(rfile,'r')

   res_info = []  #will save every line
   res_behaviours = {}  #will keep count of how many residues do what
   default = 'NATRO'  #defaul behaviour for mini resfile
   default_count = 0

   new_lines = [] #the translated resfile

   resf_line = resf.readline()

   while not resf_match.search(resf_line):  #get rid of comments
       resf_line = resf.readline()
       new_lines.append( resf_line.replace("\n","") )

   resf_line = resf.readline()   #read one more line to get rid of start tag
   #new_lines.append( resf_line )

   while resf_line:

       cur_record = ResfileRecord( resf_line )

       translated_recs = resfile_changes[0].change_resfile_record( cur_record )

       #print "DEBUG"
       #print translated_recs
       #print "DONE"

       for rec in translated_recs:
           new_lines.append( rec.line  )
           

       resf_line = resf.readline()

   resf.close()

   #now print out the new file
   for line in new_lines:
       print line

   #now determine the default behaviour
   #for behav in res_behaviours.keys():
   #    if res_behaviours[behav] > default_count:
   #        default_count = res_behaviours[behav]
   #        default = behav

   #rint '#default behaviour \n%s \n' % default
   #print 'start'

   #for res in res_info:
   #    if res[13:18] != default:
   #        print '%s %s %s' %(res[3:7],res[1:2],res[13:])


