#!/usr/bin/python

import sys
import os
from math import sqrt

def usage():
    print """Script to read in a pdb file (or list thereof) and calculate the RMSD to a starting structure. Additionally, an enzdes loops file can be given to specify over which residues to calculate the RMSD. Further, the REMARK blocks for catalytc residues are checked for whether they're at the same position in each structure."""
  
#hack_struct_offset = 0
#MAX_CATRES = 2

def get_coordinates(struct):

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = {}
    all_coordinates['residue_offset'] = 0
    cur_coordinates = {}
    cur_res = 0
    all_cat_remarks = []
    for line in struct_lines:

        #BAD HACK, skip chain B
        if line[21:22] == 'B':
            continue
        if( line[0:6] == 'REMARK' and ( line[17:25] == 'TEMPLATE') or (line[16:24] == 'TEMPLATE') ):
            all_cat_remarks.append( line[20:].replace("\n","") )

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates[cur_res] = cur_coordinates
 
        if atom_reading_flag:
            cols = line.split()
            if cur_res != int(line[23:26]): 
                if cur_res != 0:
                    all_coordinates[cur_res] = cur_coordinates
                else:
                    firstres = int(line[23:26])
                    #print "MEEP1 %s" % firstres
                    if firstres != 1:
                        all_coordinates['residue_offset'] = firstres - 1
                        #print "MEEP2 %s" % hack_struct_offset
                cur_res = int(line[23:26])
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
            cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
    all_coordinates['catinfo'] = all_cat_remarks
    #print all_coordinates['catinfo']
    return all_coordinates

#function to calculate the squared distance between two atoms, expects two tuples or two lists as input
#the first three elements of the two inputs are used
def sq_distance(coord1, coord2):
    return ( ((coord2[0] - coord1[0]) ** 2) + ((coord2[1] - coord1[1]) ** 2) + ((coord2[2] - coord1[2]) ** 2) )


def get_CA_rmsd( coords1, coords2, residue_subset ):

    tot_dist_sq = 0;
    count = 0
    #print residue_subset
    for res in residue_subset:
        count = count + 1
        res1 = coords1[res]
        res2 = coords2[res]
        res1ca = res1['CA']
        res2ca = res2['CA']
        #print res1ca
        #print res2ca
        #print "mpf"
        tot_dist_sq = tot_dist_sq + sq_distance( res1ca, res2ca )
        #print "totdistsq " + str( tot_dist_sq )

    av_dist_sq = tot_dist_sq / count
    #print "count " + str( count )
    #print av_dist_sq
    return sqrt( av_dist_sq )

def read_enzdes_loopsfile( filename ):
    filename = filename.replace("\n","")
    file = open(filename,'r')
    loopf_lines = file.readlines()
    file.close()

    to_return = [0, 0]
    for line in loopf_lines:
        tokens = line.split()
        if len( tokens ) == 0:
            continue
        if tokens[0] == 'start':
            to_return[0] = int( tokens[1] )
        elif tokens[0] == 'stop':
            to_return[1] = int( tokens[1] )
    if to_return[0] == 0:
        print "Error: no start tag in found in loopfile " + filename
        sys.exit()
    if to_return[1] == 0:
       print "Error: no stop tag in found in loopfile " + filename
       sys.exit()

    return to_return


class StructData:

    def __init__(self, template_coords, loop_interval ):
        self.loopres = []
        self.coords = template_coords
        for i in range ( loop_interval[1] - loop_interval[0] +1 ):
            self.loopres.append( loop_interval[0] + i )
        #print self.loopres
        self.numcatres = len( template_coords['catinfo'])
        self.loopcatres = []
        for i in range( self.numcatres ):
            self.loopcatres.append( 0 )
            #print "hack"
        #print self.loopcatres
        #print template_coords['catinfo']
        for line in template_coords['catinfo']:
            #print line
            #self.numcatres = self.numcatres+1
            tokens = line.split()
            this_catres = int( tokens[8] )
            this_catid = int( tokens[9] )
            #print this_catid
            #print this_catres
            #print loop_interval[0]
            #print loop_interval[1]
            if( (this_catres >= loop_interval[0] ) and ( this_catres <= loop_interval[1] ) ):
                #print 'meep'
                self.loopcatres[ this_catid -1 ] = this_catres
        #print self.loopcatres

    def get_outtitles( self ):
        outlist = ['#name','success','tot_rmsd']
        for i in self.loopcatres:
            if i != 0:
                #print i
                outlist.append( 'catres_' + str( i ) + '_seqpos' )
                outlist.append( 'catres_' + str( i ) + '_rms' )
                outlist.append( 'catres_' + str( i ) + '_same_seqpos' )

        return outlist
        
                                       

class StructResult:
                    
    def __init__(self, coords, template_struct_data, name ):
        self.name = name
        self.loop_rmsd = get_CA_rmsd( template_struct_data.coords, coords, template_struct_data.loopres )
        catinfo = coords['catinfo']
        self.success = 0
        self.loopcatres_data = []
        self.numloopcatres = 0

        if len(catinfo ) == template_struct_data.numcatres:
            self.success = 1
            for line in catinfo:
                tokens = line.split()
                catres_id = int( tokens[9] )
                #print catres_id
                if template_struct_data.loopcatres[ catres_id -1 ] != 0:
                    catres_info = []
                    catres_info.append( int( tokens[8] ) )
                    #print catres_info
                    catrmsd = get_CA_rmsd( template_struct_data.coords, coords, catres_info )
                    same_catres = 1
                    if( catres_info[0] != template_struct_data.loopcatres[ catres_id -1 ] ):
                        same_catres = 0
                    catres_info.append( catrmsd )
                    catres_info.append( same_catres )
                    self.loopcatres_data.append( catres_info )
        else:
            self.numloopcatres = template_struct_data.numcatres - len( catinfo) 

    def get_outlist( self ):
        outlist = [ self.name,self.success,"%.2f" % self.loop_rmsd ]
        if self.success == 1:
            for i in self.loopcatres_data:
                outlist.append( i[0] )
                outlist.append( "%.2f" % i[1] )
                outlist.append( i[2] )
        else:
            for i in range(self.numloopcatres):
                outlist.append( 0 )
                outlist.append( 0 )
                outlist.append( 0 )

        return outlist
            
                    

CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''
template = ''
loop_file = ''


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-loopfile':
        loop_file = CommandArgs[CommandArgs.index(arg)+1]

  


if list_mode:
 
    if not os.path.exists(list_file):
        print 'Error: could not find file %s' % list_file
        sys.exit()

    else:
        listf = open(list_file,'r')
        file_list = listf.readlines()
        listf.close()

else:
    file_list.append(sing_struct)


template_coords = get_coordinates(template)
#print template_coords['catinfo']

loop_interval = read_enzdes_loopsfile( loop_file )
#print "loop interval is "
#print loop_interval
#print "hack offset is %s" % hack_struct_offset
if template_coords['residue_offset'] != 0:
    loop_interval[0] = loop_interval[0] + template_coords['residue_offset']
    loop_interval[1] = loop_interval[1] + template_coords['residue_offset']

#print loop_interval
    
template_data = StructData( template_coords, loop_interval )

outlists = []
outlists.append( template_data.get_outtitles() )

for struct in file_list:

    struct_coords = get_coordinates(struct)
    result = StructResult( struct_coords, template_data, struct.replace('\n','') )
    outlists.append( result.get_outlist() )

outstring = ""
for list in outlists:
    for el in list:
        outstring = outstring + str( el ) +" "
    outstring = outstring + '\n'

print outstring


                
