#!/usr/bin/python

import sys
import re

def reverse_complement( sequence ):
    rev_comp_list = []
    length = len( sequence )
    for i in range( length ):
        cur_char = sequence[length - i -1]
        #print "at i=%s, char to check is %s"%(i, cur_char)
        if( cur_char == 'A' ):
            rev_comp_list.append('T')
        elif( cur_char == 'C' ):
            rev_comp_list.append('G')
        elif( cur_char == 'G' ):
            rev_comp_list.append('C')
        elif( cur_char == 'T' ):
            rev_comp_list.append('A')
        else:
            print "Error: When making reverse_complement, Sequence contained a '"+cur_char+"' character at position %s, quitting..."%(i+1)
            sys.exit()
    #print "rev complemnt: %s of length %s got turned into"%(sequence, length)
    #print rev_comp_list
    return "".join( rev_comp_list )
