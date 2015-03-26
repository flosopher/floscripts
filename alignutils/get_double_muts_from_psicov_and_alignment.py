#!/usr/bin/python

import sys

sys.path.insert(0,'/Users/flo/floscripts/genutils/')
from SequenceProfile import SequenceProfile, create_subprofile

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

	    for each alternative res1 at anchor seqpos      	    
	    	
		create sub alignment1 w/ residue in question at seqpos
		
		for each alternative res2 at other seqpos
		    create sub alignment2
                    check if alternative res2 is observed at higher
		    frequency in subalignment1 (what factor higher?)
                    check if altres1 is observed at higher frequency
                    in subalignment2
    """
    sys.exit()

#little helper class to store double mutants
#can write its own output string
class DoubleMutant:

    def __init__(self, pos1, pos2, wtres1, wtres2, mutres1, mutres2, all_freq_wt1, all_freq_wt2, all_freq_mut1, all_freq_mut2, sub1wt_freq_wt2, sub1mut_freq_mut2, sub2wt_freq_wt1, sub2mut_freq_mut1 ):

        self.pos1 = pos1
        self.pos2 = pos2

        self.wtres1 = wtres1
        self.wtres2 = wtres2

        self.mutres1 = mutres1
        self.mutres2 = mutres2

        self.all_freq_wt1 = all_freq_wt1
        self.all_freq_wt2 = all_freq_wt2

        self.all_freq_mut1 = all_freq_mut1
        self.all_freq_mut2 = all_freq_mut2 

        self.sub1wt_freq_wt2 = sub1wt_freq_wt2
        self.sub1mut_freq_mut2 = sub1mut_freq_mut2

        self.sub2wt_freq_wt1 = sub2wt_freq_wt1
        self.sub2mut_freq_mut1 = sub2mut_freq_mut1

    def write_output_string( self ):
        outstring = "DoubleMutant " + self.wtres1 + str(self.pos1) + self.mutres1 + "," + self.wtres2 + str(self.pos2) + self.mutres2

        outstring = outstring + "\nwt1_freq=%.3f, mut1_freq=%.3f, wt2_freq=%.3f, mut2_freq=%.3f, sub1wt_freq_wt2=%.3f, sub1mut_freq_mut2=%.3f, sub2wt_freq_wt1=%.3f, sub2mut_freq_mut1=%.3f \n\n" % ( self.all_freq_wt1, self.all_freq_mut1, self.all_freq_wt2, self.all_freq_mut2, self.sub1wt_freq_wt2, self.sub1mut_freq_mut2, self.sub2wt_freq_wt1, self.sub2mut_freq_mut1  )

        return outstring



alignfile = ''
psicov_file = ''
min_freq = 0.2 #this is in terms of wildtype
freq_factor = 1.5
empty_dict = {}

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-a':
        alignfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-psi_out':
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

double_mutants = []

for psi_line in psicov_lines:
    line_items = psi_line.split()
    seqpos1 = int( line_items[0] ) -1
    seqpos2 = int( line_items[1] ) -1

    #print psi_line

    if seqpos2 < seqpos1:   #make sure ordering is correct
        seqpos1 = seqpos2
        seqpos2 = int( psi_line[0] )

    pos1_alternates = all_seq_prof.get_observed_res_for_position( seqpos1 )
    pos2_alternates = all_seq_prof.get_observed_res_for_position( seqpos2 )
    #print pos1_alternates
    if (len( pos1_alternates ) < 2) or ( len( pos2_alternates ) < 2):
        continue

    pos1_wt = all_seq_prof.get_wt_res( seqpos1 )
    pos2_wt = all_seq_prof.get_wt_res( seqpos2 )
    print "checking line %s with seqpos1 %s (%s) and seqpos2 %s (%s)" % (psi_line, seqpos1+1,pos1_wt, seqpos2+1, pos2_wt)

    wtfreq1 = all_seq_prof.get_frequency_for_res_at_position( seqpos1, pos1_wt)
    wtfreq2 = all_seq_prof.get_frequency_for_res_at_position( seqpos2, pos2_wt)

    wt1_subprofile = create_subprofile( seqpos1, pos1_wt, alf_lines )
    wt2_subprofile = create_subprofile( seqpos2, pos2_wt, alf_lines )

    print pos1_alternates

    #we create the subprofiles for residue2 here to get better performance
    alt2_subprofs = {}
    relevant_pos2_alternates = []
    for altres2 in pos2_alternates:
        if altres2 == '-':
                continue

        alt2freq = all_seq_prof.get_frequency_for_res_at_position( seqpos2, altres2 )

        if wtfreq2 * min_freq > alt2freq : #make sure altres2 is observed at all
                continue

        relevant_pos2_alternates.append( altres2 )
        alt2_subprofs[altres2] = create_subprofile( seqpos2, altres2, alf_lines )

    if len(relevant_pos2_alternates) < 2:
        continue

        
    for altres1 in pos1_alternates:
        if altres1 == '-':
            continue

        alt1freq = all_seq_prof.get_frequency_for_res_at_position( seqpos1, altres1 )
 
        if wtfreq1 * min_freq > alt1freq : #make sure altres1 is observed at all
            continue

        print "res1 %s at pos %s has freq %.3f, checking ..." % (altres1, seqpos1+1, alt1freq )

        #wt1_subprofile = create_subprofile( seqpos1, pos1_wt, alf_lines )
        alt1_subprofile = create_subprofile( seqpos1, altres1, alf_lines )

        for altres2 in relevant_pos2_alternates:

            alt2freq = all_seq_prof.get_frequency_for_res_at_position( seqpos2, altres2 )

            print "res2 %s at pos %s has freq %.3f, checking ..." % (altres2, seqpos2+1, alt2freq )

            #wt2_subprofile = create_subprofile( seqpos2, pos2_wt, alf_lines )
            #alt2_subprofile = create_subprofile( seqpos2, altres2, alf_lines )


            #now the decision whether altres1 and altres2 
            #could be a good double mutant
            sub1wt_freq_wt2 = wt1_subprofile.get_frequency_for_res_at_position( seqpos2, pos2_wt )
            sub1mut_freq_mut2 = alt1_subprofile.get_frequency_for_res_at_position( seqpos2, altres2)

            sub2wt_freq_wt1 = wt2_subprofile.get_frequency_for_res_at_position( seqpos1, pos1_wt )
            sub2mut_freq_mut1 = alt2_subprofs[altres2].get_frequency_for_res_at_position( seqpos1, altres1)

            if (sub1mut_freq_mut2 > (sub1wt_freq_wt2 * freq_factor) ) and (sub2mut_freq_mut1  > (sub2wt_freq_wt1  * freq_factor) ):

                print "creating double mutant!"

                double_mutants.append( DoubleMutant( seqpos1 +1, seqpos2+1, pos1_wt, pos2_wt, altres1, altres2, wtfreq1, wtfreq2, alt1freq, alt2freq, sub1wt_freq_wt2, sub1mut_freq_mut2, sub2wt_freq_wt1,  sub2mut_freq_mut1 ) )


outstring = "A total of %s potential double mutants:\n" % len( double_mutants )
for doubles in double_mutants:
    outstring = outstring + doubles.write_output_string()

print outstring
