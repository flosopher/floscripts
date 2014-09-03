#!/usr/bin/python


import sys
import os
import re
import copy

from ResResE_util import ResResE, ResE_dict_from_file, token_titles, setup_token_titles


    
def usage():
    print """run with -f <logfile> -c1 <chain of interest, one chair> -c2 <interacting chains, can be multiple chars>, where the logfile contains output from a ScoreCutoffFilter
    residue pair interaction log. For every residue in chain -c1, it sums up the interactions with the other chains and outputs a list
"""


 

class SingleResCollector:

    def __init__(self, res_string,  resrese_init):
        self.res_string = str( res_string ),
        self.values = (resrese_init.get_all_values())[:]
        self.first_float = 3

    def add_other_resrese( self, resrese ):
        if( len( resrese.values ) != len( self.values ) ):
            print "error when adding other resrese to singlerescollector. value lists have different lengths"
            sys.exit()

        for i in range( len( self.values ) - self.first_float):
            self.values[ i+self.first_float ] += resrese.get_all_values()[ i+self.first_float ]

    def get_value( self, label ):
        return self.values[ token_titles[ label ] ]

    def get_outstring( self ):
        to_return = str( self.res_string )
        #print "preparing outstring for %s" % to_return
        #print self.values
        for i in range( len( self.values ) - self.first_float):
            #print self.values[ i+self.first_float ]
            to_return = to_return + "   " + str( self.values[ i+self.first_float ])
        return to_return + "\n"


filename = ''
chain_of_interest = ''
other_chains = {}

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-f':
        filename = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-c1':
        chain_of_interest = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-c2':
        other_string = CommandArgs[CommandArgs.index(arg)+1]
        other_string_len = len( other_string )
        for i in range(other_string_len):
            other_chains[ other_string[i:i+1] ] = 1

if ( (not filename) or (not chain_of_interest) or( len(other_chains) == 0 ) ):
     print 'Error, please supply name of the logfile, the chain of interest, and the corresponding chains'
     usage()
     sys.exit()

file_dict = ResE_dict_from_file( filename )
collector_dict = {}

def get_chain_from_res_tag( res_tag ):
    return res_tag[2:3]

for item in file_dict.iteritems():
    #1. figure out if one of the residues is on the chain we're intersted in
    #print value
    res1_tag = item[1].get_value( "Res1")
    res2_tag = item[1].get_value( "Res2")
    chain_res1 = get_chain_from_res_tag( res1_tag  )
    chain_res2 = get_chain_from_res_tag( res2_tag  )
    res1_num = int( res1_tag[3:] )
    res2_num = int( res2_tag[3:] )

    if ((chain_res1 == chain_of_interest) and other_chains.has_key( chain_res2 )):
        if not collector_dict.has_key( res1_num ):
            collector_dict[ res1_num ] = SingleResCollector( res1_tag, item[1] )
        else:
            collector_dict[ res1_num ].add_other_resrese( item[1] )
    elif (chain_res1 == chain_of_interest) and (not collector_dict.has_key( res1_num ) ):
        tmprese = copy.deepcopy( item[1] )
        tmprese.nullify()
        collector_dict[ res1_num ] = SingleResCollector( res1_tag, tmprese );

    elif ((chain_res2 == chain_of_interest) and other_chains.has_key( chain_res1 )):
        if not collector_dict.has_key( res2_num ):
            collector_dict[ res2_num ] = SingleResCollector( res2_tag, item[1] )
        else:
            collector_dict[ res2_num ].add_other_resrese( item[1] )

    elif (chain_res2 == chain_of_interest) and (not collector_dict.has_key( res2_num ) ):
        tmprese = copy.deepcopy( item[1] )
        tmprese.nullify()
        collector_dict[ res2_num ] = SingleResCollector( res2_tag, tmprese )


    
#now output
total_outstring = ""
for record in collector_dict.iteritems():
    total_outstring += record[1].get_outstring()
print total_outstring
#print score_rms_list
