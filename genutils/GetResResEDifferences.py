#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import os
import re

def usage():
    print """run with -f1 <file one> -f2 <file two>, where both files contain output from a ScoreCutoffFilter
    residue pair interaction log. Reads in the two files, substracts the energies in f2 from f1, and sorts by
    either ascending or descending values before output.
"""

token_titles = {}

def setup_token_titles( title_string ):
    token_titles.clear()
    
    tokens = title_string.split()
    for i in range( len(tokens)):
        token_titles[ tokens[i] ] = i


    
class ResResE:

    def __init__(self, init_string, token_titles):
        tokens = init_string.split()
        self.name = tokens[1][1:] + "_" + tokens[2][1:]
        self.values = [0] * len( tokens )
        self.values[0] = 'DiffResResE'
        self.values[1] = tokens[1]
        self.values[2] = tokens[2]
        
        for i in range (len( tokens ) - 3):
            try:
                i_float = float( tokens[i+3] )
                self.values[i+3] = i_float
            except ValueError:
                print "Error: non float value encountered where it shouldn't be"
                sys.exit()

    def substract_other_ResResE( self, other ):
        for i in range (len( self.values ) - 3):
            self.values[ i+3 ] = self.values[i+3] - other.values[i+3]

    def negate( self ):
        for i in range (len( self.values ) - 3):
            self.values[ i+3 ] = self.values[i+3] * (-1.0)

    def get_name(self):
        return self.name

    def get_value( self, label ):
        return self.values[ token_titles[ label ] ]

    def get_outstring(self):
        to_return = ''
        #to_return = self.name
        for val in self.values:
            to_return = to_return  + str( val ) + "  "
        return to_return +'\n'
        


def ResE_dict_from_file( filename ):
    file = open(filename, 'r')
    content = file.readlines()
    file.close()
    first_resE_line_seen = 0

    to_return = {}
    
    for line in content:
        if line[0:7] == 'ResResE':
            line = line.replace('\n','')
            if not first_resE_line_seen:
                first_resE_line_seen = 1
                if len( token_titles.keys() ) == 0:
                    setup_token_titles( line )
            else:
                if line[11:18] == 'nonzero':
                    continue
                this_record = ResResE( line, token_titles )
                totval = this_record.get_value( 'total' )
                if isinstance( totval, float ):
                    if totval != 0.0:
                        to_return[ this_record.get_name() ] = this_record
                else:
                    print "Error: total value column is not a float, offending line reads: "
                    print line
                    sys.exit()
    return to_return


filename_1 = ''
filename_2 = ''
significance_cutoff = 0.4

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-f1':
        filename_1 = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-f2':
        filename_2 = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-cutoff':
        significance_cutoff = float( CommandArgs[CommandArgs.index(arg)+1] )

if ( (not filename_1) or (not filename_2)):
     print 'Error, please supply name of the two files'
     usage()
     sys.exit()

file1_dict = ResE_dict_from_file( filename_1 )
file2_dict = ResE_dict_from_file( filename_2 )

#building up list of differences
sorted_list = []

for record in file2_dict.keys():
    if file1_dict.has_key( record ):
        sorted_list.append( file1_dict[ record ] )
        sorted_list[ len( sorted_list ) - 1].substract_other_ResResE( file2_dict[ record ] )
   
    else:
        sorted_list.append( file2_dict[ record ] )
        sorted_list[ len( sorted_list ) - 1].negate()

for record in file1_dict.keys():
    if not file2_dict.has_key( record ):
            sorted_list.append( file1_dict[ record ] )

#building up difference list done, now we just gotta sort
sorted_list = sorted( sorted_list, key = lambda ResResE: ResResE.get_value('total') )        


#we will also count which residues show the biggest differences
per_residue_diff_dict = {}
per_residue_abs_diff_dict = {}

for item in sorted_list:
    key1 = (item.get_value('Res1'))[1:]
    key2 =  (item.get_value('Res2'))[1:]
    
    if not per_residue_diff_dict.has_key( key1 ):
        per_residue_diff_dict[ key1 ] = item.get_value('total')
    else:
         per_residue_diff_dict[ key1 ] =  per_residue_diff_dict[ key1 ] + item.get_value('total')
    if not per_residue_diff_dict.has_key( key2 ):
        per_residue_diff_dict[ key2 ] = item.get_value('total')
    else:
         per_residue_diff_dict[ key2 ] =  per_residue_diff_dict[ key2 ] + item.get_value('total')

    if not per_residue_abs_diff_dict.has_key( key1 ):
        per_residue_abs_diff_dict[ key1 ] = abs( item.get_value('total') )
    else:
         per_residue_abs_diff_dict[ key1 ] =  per_residue_abs_diff_dict[ key1 ] + abs( item.get_value('total') )
    if not per_residue_abs_diff_dict.has_key( key2 ):
        per_residue_abs_diff_dict[ key2 ] = abs( item.get_value('total') )
    else:
        per_residue_abs_diff_dict[ key2 ] =  per_residue_abs_diff_dict[ key2 ] + abs( item.get_value('total') )

import operator
per_residue_sorted_list =  sorted(per_residue_diff_dict.iteritems(), key=operator.itemgetter(1) )
per_residue_abs_sorted_list = sorted(per_residue_abs_diff_dict.iteritems(), key=operator.itemgetter(1) )
per_residue_abs_sorted_list.reverse()

#print per_residue_sorted_list
#print per_residue_abs_sorted_list
#done counting per residue differences

output = ''
for item in sorted_list:
    if abs( item.get_value( 'total') ) >= significance_cutoff:
        output = output + item.get_outstring()

for item in per_residue_sorted_list:
    if abs( item[1]) > 0.0:
        output = output + 'ResidueDeltaScore      ' + str( item[0] ) + '  %.2f' % item[1] + '\n'

for item in per_residue_abs_sorted_list:
    if item[1] >  0.0:
        output = output + 'ResidueAbsDeltaScore   ' + str( item[0] ) + '  %.2f' % item[1] + '\n'


print output
#print score_rms_list
