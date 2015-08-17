#!/usr/bin/python

import sys

def usage():
    print """Script to do stuff on a blast table

    """
    sys.exit()


max_q_start = 150
min_q_end = 400

class BlastAlignData:

    def __init__(self, raw_line ):

        self.raw_line = raw_line
        items = raw_line.split()
        
        self.a_query = items[0]
        self.a_subject = items[1]
        self.a_length = int( items[3] )
        self.a_identity = float( items[2] )
        self.q_start = int( items[6] )
        self.q_end = int(items[7])
        self.s_start = int(items[8])
        self.s_end = int(items[9])

    def a_length(self):
        return self.a_length

    def q_start(self):
        return self.q_start

    def q_end( self ):
        return self.q_end

    def raw_line(self):
        return self.raw_line

        

filename = 'phosphodiesterase_tblastn.table'



infile = open( filename, 'r')

flines = infile.readlines()

infile.close()

align_list = []

#read blast align file into list of instances of BlastAlign Data
for line in flines:

    line_items = line.split()
    if len(line_items) == 12:
        ba_data = BlastAlignData( line )
        if( ba_data.q_start < max_q_start ) and ( ba_data.q_end < min_q_end ):
            align_list.append( ba_data )
    #print line_items

#everything read in, now sort
#sorted_list = sorted( align_list, key=a_length() )
sorted_list = sorted( align_list, key=lambda x: x.a_length, reverse=True )


#spit out sorted list
outlines = []

for items in sorted_list:
    outlines.append( items.raw_line )


outstring = ''
for line in outlines:
    outstring = outstring+line

print outstring

