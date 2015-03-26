#!/usr/bin/python

import sys

def usage():
    print """
Script to read in a psicov outfile and an alignment and try
to get suggestions for some double mutants out of it

pseudocode
read in psicov file, read in sequence alignment

go through psicov file line by line. 

   for each interaction:

       pick one anchor seqpos, i.e. the earlier one in sequence
    
   	    for both seqpos in interaction, make a list of alternative
	    residues occuring at minfreq in alignment

	    for each alternative res at anchor seqpos      	    
	    	
		create sub alignment w/ residue in question at seqpos
		
		for each alternative res at other seqpos
		    check if alternative res is observed at higher
		    frequency in subalignment (what factor higher?)
    """
    sys.exit()

#little helper class to store double mutants
#can write its own output string
class DoubleMutant:

    def __init__(self, pos1, pos2, wtres1, wtres2, mutres1, mutres2, allfreq_mut1, allfreq_mut2, freqfac1, freqfac2 ):

        self.pos1 = pos1
        self.pos2 = pos2
        self.wtres1 = wtres1
        self.wtres2 = wtres2
        self.mutres1 = mutres1
        self.mutres2 = mutres2
        self.allfreq_mut1 = allfreq_mut1 #frequency (in terms of wt)of mutres1 in overall alignment
        self.allfreg_mut2 = allfreq_mut2 #like above for mutres2
        self.freqfac1 = freqfac1
        self.freqfac2 = freqfac2

    def write_output_string( self ):
        print 'stubbed out'



alignfile = ''
psicov_file = ''
min_freq = 0.2 #this is in terms of wildtype
freq_factor = 3.0
empty_dict = {}

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-a':
        alignfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-psi_out:'
        psicov_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-min_freq':
        min_freq = float( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-freq_factor':
        freq_factor = float( CommandArgs[CommandArgs.index(arg)+1] ) 


if alignfile == '':
    print "Error: need to specify alignment file with option -a"
    sys.exit()

if psicov_file == '':
    print "Error: need to specify psicov out file with option -psi_out"
    sys.exit()

# get sequence profile
alf_handle = open(alignfile, 'r')
alf_lines = alf_handle.readlines()
alf_handle.close()
all_seq_prof = SequenceProfile( empty_dict, 1, alf_lines[0] )
for i in range( len( alf_lines ) - 1 ):
    all_seq_prof.add_sequence( alf_lines[i+1] )

#get psicov stuff
psicov_handle = open(psicov_file, 'r')
psicov_lines = psicov_handle.readlines()
psicov_handle.close()

for psi_line in psicov_lines:
    seqpos1 = psi_line[0]
    seqpos2 = psi_line[1]

    if seqpos2 < seqpos1:   #make sure ordering is correct
        seqpos1 = seqpos2
        seqpos2 = psi_line[0]

    pos1_alternates = all_seq_prof.get_observed_res_for_position(self, seqpos1)
    pos2_alternates = all_seq_prof.get_observed_res_for_position(self, seqpos2)
    if (len( pos1_alternates ) < 2) or ( len( pos2_alternates ) ):
        continue

    pos1_wt = all_seq_prof.get_wt_res( seqpos1 )
    pos2_wt = all_seq_prof.get_wt_res( seqpos2 )

    wtfreq1 = 
    wtfreq2 = 
