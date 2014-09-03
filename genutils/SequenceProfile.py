#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import re

def AA3LetTo1Let(aa):

    if aa == 'ALA':
        return 'A'
    elif aa == 'CYS':
        return 'C'
    elif aa == 'ASP':
        return 'D'
    elif aa == 'GLU':
        return 'E'
    elif aa == 'PHE':
        return 'F'
    elif aa == 'GLY':
        return 'G'
    elif aa == 'HIS':
        return 'H'
    elif aa == 'ILE':
        return 'I'
    elif aa == 'LYS':
        return 'K'
    elif aa == 'LEU':
        return 'L'
    elif aa == 'MET':
        return 'M'
    elif aa == 'ASN':
        return 'N'
    elif aa == 'PRO':
        return 'P'
    elif aa == 'GLN':
        return 'Q'
    elif aa == 'ARG':
        return 'R'
    elif aa == 'SER':
        return 'S'
    elif aa == 'THR':
        return 'T'
    elif aa == 'VAL':
        return 'V'
    elif aa == 'TRP':
        return 'W'
    elif aa == 'TYR':
        return 'Y'
    else:
    	print "hack dunno "+aa
        return 'unknown'



class SequenceProfile:

    def __init__(self, res_input, external_template):
        self.wt_pos = []
        self.num_sequences = 0
        self.mutations = {}
        self.external_template = external_template

        for res in res_input:
            self.wt_pos.append( AA3LetTo1Let(res_input[res]['type']) )


    def add_struct( self, res_coords ):

        if len( res_coords ) != len( self.wt_pos ):
            print "Error: input structure and wt structure doesn't have the same size"
            sys.exit()
        i = -1
        self.num_sequences = self.num_sequences + 1
        for res in res_coords:

            i = i + 1
            this_res = AA3LetTo1Let(res_coords[res]['type'])

            if this_res != self.wt_pos[ i ]:

                if not self.mutations.has_key( i ):
                    self.mutations[ i ] = {}
                    self.mutations[i][self.wt_pos[i]] = self.num_sequences - 1
                if not self.mutations[ i ].has_key( this_res ):
                    self.mutations[i][this_res] = 0

                self.mutations[ i ][this_res] = self.mutations[i][this_res] + 1

            elif self.mutations.has_key( i ):
                self.mutations[i][self.wt_pos[i]] = self.mutations[i][self.wt_pos[i]] + 1

    def get_outstring( self ):

        outstring = ""
        for i in range( len( self.wt_pos ) ):
            if self.mutations.has_key( i ):
                if( self.external_template ):
                    outstring = outstring + self.wt_pos[i] + str(i+1) + ": "
                else:
                    outstring = outstring + str(i+1) + ": "

                for res in self.mutations[ i ]:
                    if( self.mutations[i][res] == 0 ):
                        continue
                    freq = float(self.mutations[ i ][res]) / float( self.num_sequences )
                    #outstring = outstring + str( freq ) + " " + res + ",  "
                    outstring = outstring + "%.2f " % freq + res + ",  "

                outstring = outstring + "\n"

        if outstring == "":
            outstring = "no mutations found"

        return outstring

    def get_pymutstring( self ):
        pymutstring = "select mutations, resi "
        mutlist = []
        for mut in self.mutations.keys():
            mutlist.append( mut )

        mutlist.sort()
        for item in mutlist:
            pymutstring = pymutstring + "%s+" % (item + 1)

        return pymutstring

