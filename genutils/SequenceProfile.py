#!/usr/bin/python


#class to generate sequence profiles for positions of interest
#can be instantiated from a list fo structures or from an alignment

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

    def __init__(self, res_input, external_template, wt_sequence = ''):
        self.wt_pos = []
        self.num_sequences = 0
        self.mutations = {}
        self.external_template = external_template

        if wt_sequence == '':
            for res in res_input:
                self.wt_pos.append( AA3LetTo1Let(res_input[res]['type']) )
        else:
            seq_length = len( wt_sequence )
            for i in range( seq_length ):
                self.wt_pos.append( wt_sequence[i] )
                self.num_sequences = 1

    def get_wt_res( self, pos ):
        return self.wt_pos[pos]
    
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


    def add_sequence( self, seq_to_add ):
        this_length = len( seq_to_add )
        if  this_length != len( self.wt_pos ):
            print "Error: input sequence and wt sequence doen't have the same length."
            sys.exit()

        self.num_sequences = self.num_sequences + 1
        for i in range( this_length ):
            this_res = seq_to_add[i]

            if this_res != self.wt_pos[ i ]:

                if not self.mutations.has_key( i ):
                    self.mutations[ i ] = {}
                    self.mutations[i][self.wt_pos[i]] = self.num_sequences - 1

                if not self.mutations[i].has_key( this_res ):
                    self.mutations[i][this_res] = 0

                self.mutations[i][this_res] = self.mutations[i][this_res] + 1 
                                      
            elif self.mutations.has_key( i ):
                self.mutations[i][this_res] = self.mutations[i][this_res] + 1


    def get_observed_res_for_position(self, pos):
        to_return = []
        if not self.mutations.has_key(pos):
            to_return.append( self.wt_pos[pos] )
            return to_return
        
        for res in self.mutations[pos]:
            if self.mutations[pos][res] != 0:
                to_return.append( res )
        return to_return

    def get_string_for_position( self, pos ):

        to_return = ''
        #print "getting string for pos %s, there are %s sequences" % (pos, self.num_sequences)
        if self.mutations.has_key( pos ):

            # if( self.external_template ):
            #  to_return = to_return + self.wt_pos[pos] + str(pos+1) + ": "
            #else:
            #    to_return = to_return + str(pos+1) + ": "

            residues = self.get_observed_res_for_position( pos )

            to_return = to_return + self.get_string_for_position_and_res( pos, residues )

        else:
            if( self.external_template ):
                to_return =  self.wt_pos[pos] + str(pos+1) + ": 1.00 " + self.wt_pos[pos]
            else:
                to_return = str(pos+1) + ": 1.00 " + self.wt_pos[pos]

        return to_return


    def get_string_for_position_and_res( self, pos, residues ):
        to_return = ''

        if( self.external_template ):
            to_return = to_return + self.wt_pos[pos] + str(pos+1) + ": "
        else:
            to_return = to_return + str(pos+1) + ": "

        if not self.mutations.has_key( pos ):
            for res in residues:
                freq = 0.000
                if res == self.wt_pos[pos]:
                    freq = 1.000
                to_return = to_return + "%.2f " % freq + res + ",  "
            return to_return

        for res in residues:
            #print "MEEP pos %s and res %s" % (pos, res )
            freq = 0.000
            if self.mutations[pos].has_key( res ):
                freq = float(self.mutations[ pos ][res]) / float( self.num_sequences )
            to_return = to_return + "%.2f " % freq + res + ",  "

        return to_return
    
    def get_frequency_for_res_at_position( self, pos, residue):

        freq = 0.000
        if not self.mutations.has_key( pos ):
            if res == self.wt_pos[pos]:
                freq = 1.0000

        else:
            if self.mutations[pos].has_key( residue ):
                freq = float(self.mutations[ pos ][residue]) / float( self.num_sequences )

        return freq


    def get_outstring( self ):

        outstring = ""
        for i in range( len( self.wt_pos ) ):
            
            if self.mutations.has_key( i ):
                outstring = outstring + self.get_string_for_position( i ) + "\n"

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

#creates a sequence profile containing only sequences
#that contain mut_aa at mut_position
def create_subprofile( mut_position, mut_aa, alignment ):
    #print "Creating subprofile of sequences containing %s at %s " % (mut_aa, mut_position)
    empty_dict = {}
    first_seq = -1
    al_length = len( alignment )
    for i in range( al_length):
        if alignment[i][mut_position] == mut_aa:
            first_seq = i
            break
    if first_seq == -1:
        print "Error, %s was not observed in alignment at %s " % (mut_aa, mut_position)
        sys.exit()

    to_return = SequenceProfile( empty_dict, 1, alignment[first_seq] )
    seq_counter = first_seq+1

    while seq_counter < al_length:
        if alignment[seq_counter][mut_position] == mut_aa:
            to_return.add_sequence( alignment[seq_counter] )
        seq_counter = seq_counter + 1
    print "Creating subprofile of %s sequences containing %s at %s " % ( to_return.num_sequences, mut_aa, mut_position+1)
    return to_return
