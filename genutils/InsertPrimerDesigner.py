#!/usr/bin/python

import sys
import re
#from PrimerTMCalculator import TM_Calculator
from ReadDNASeqs import read_dna_seq_from_gb_file
from ReadDNASeqs import GeneticCodeAAConverter
import PrimerTMCalculator

from primer_design_utils import reverse_complement, generate_histogram, num_primer_problems, read_insertion_site_list

#script to read in a DNA sequence, first and last nucleotide between which to design primers,
#number of primers to design, and then automatically design those primers
#Florian Richter, Moeglich Lab, feb 2014 florian.richter.1@hu-berlin.de, 

MIN_Tm = 55.0 #the minimum annealing temp for designed primers
MAX_NON_PROBLEMATIC_TM = 69
MAX_P_LENGTH = 36 #maximum allowed length of the primer
MIN_P_LENGTH = 18
TM_DIFF_PROBLEMATIC_INCREMENT = 5.0

ADD_LINKERS = 1
FWD_LINKER = "CGTAGGGTCGACT"
REV_LINKER = "CGGAAAGGCGGCCGC"

CONVERT_SITE_LIST = 1  #in case a list is read in, it can be converted (i.e. convert a list of amino acid positions to nucleotide positions

tm_calculator = PrimerTMCalculator.TM_Calculator()
codon_mapper = GeneticCodeAAConverter()



#simple function to check whether a certain amino acid is hydrophobic
def is_hydrophobic( aa1let ):
    if aa1let == 'A':
        return 1
    elif aa1let == 'C':
        return 1
    elif aa1let == 'F':
        return 1
    elif aa1let == 'I':
        return 1
    elif aa1let == 'L':
        return 1
    elif aa1let == 'M':
        return 1
    elif aa1let == 'P':
        return 1
    elif aa1let == 'V':
        return 1
    elif aa1let == 'W':
        return 1
    elif aa1let == 'Y':
        return 1

    return 0


def between_two_hydrophobic(seqpos, sequence):
    if is_hydrophobic( codon_mapper.codon2aa( sequence[seqpos-4:seqpos-1] ) ) and is_hydrophobic( codon_mapper.codon2aa( sequence[seqpos-1:seqpos+2] ) ):
        return 1
    else:
        return 0


#simple helper class
class PrimerPair:

    def __init__(self, fwd_primer, rev_primer, num_problems, impossible, site ):
        self.fwd_primer = fwd_primer
        self.rev_primer = rev_primer
        self.impossible = impossible  #should be bool
        self.site = site
        self.num_problems = num_problems
        self.fwd_tm = tm_calculator.calculate_tm( fwd_primer )
        self.rev_tm = tm_calculator.calculate_tm( rev_primer )
        self.lowest_tm = self.fwd_tm
        self.tm_diff = self.rev_tm - self.lowest_tm
        self.totlength = len( self.fwd_primer ) + len( self.rev_primer )
        if self.rev_tm < self.fwd_tm:
            self.lowest_tm = self.rev_tm
            self.tm_diff = self.fwd_tm - self.rev_tm
        #self.num_problems = num_problems + int( self.tm_diff / TM_DIFF_PROBLEMATIC_INCREMENT )
        

    def get_fwd_primer(self):
        return self.fwd_primer

    def get_rev_primer(self):
        return self.rev_primer

    def get_fwd_tm(self):
        return self.fwd_tm

    def get_rev_tm(self):
        return self.rev_tm

    def get_lowest_tm(self):
        return self.lowest_tm

    def get_num_problems(self):
        return self.num_problems

    def set_num_problems(self, probs):
        self.num_problems = probs
        if probs > 9:
            self.impossible = 1

    def is_impossible(self):
        return self.impossible

    def get_tm_difference( self ):
        return self.tm_diff

    def this_site(self):
        return self.site

    def get_totlength(self):
        return self.totlength

    def print_contents(self):
        print "This pair at site %s has fwd primer %s, rev primer %s, %s problems and impossible is %s."%(self.site, self.fwd_primer, self.rev_primer, self.num_problems, self.impossible)


#function to calculate a bunch of statistics on a list containing instances of the above class
def calculate_statistics( primer_pairs ):
    lengths = {}
    melt_temps = []
    melt_diffs = []
    T_increment = 2.5
    cost_per_base = 0.10

    fwd_linker_len = 0
    rev_linker_len = 0

    if ADD_LINKERS == 1:
        fwd_linker_len = len( FWD_LINKER )
        rev_linker_len = len( REV_LINKER )

    tot_length = 0
    for item in primer_pairs:
        len_fwd = len( item.get_fwd_primer() ) + fwd_linker_len
        len_rev = len( item.get_rev_primer() ) + rev_linker_len
        tot_length = tot_length + len_fwd + len_rev

        if not lengths.has_key( len_fwd ):
            lengths[ len_fwd ] = 0
        if not lengths.has_key( len_rev ):
            lengths[ len_rev ] = 0

        lengths[ len_fwd ] = lengths[ len_fwd ] + 1
        lengths[ len_rev ] = lengths[ len_rev ] + 1

        melt_temps.append( item.get_fwd_tm() )
        melt_temps.append( item.get_rev_tm() )
        melt_diffs.append( item.get_tm_difference() )

    

    returnstring = 'Average Length %.2f, total number of bases %s, estimated cost EUR %.2f, distribution:\n' % ( tot_length / (2.0 * len( primer_pairs ) ), tot_length, tot_length * cost_per_base )

    for key in lengths.keys():
        returnstring = returnstring + "%s:  %s\n"%(key, lengths[key] )

    returnstring = returnstring + "\nTm distribution:\n" + generate_histogram( melt_temps, T_increment )

    returnstring = returnstring + "\nTm diff distribution:\n" + generate_histogram( melt_diffs, T_increment )
    return returnstring




    
def design_insertion_primer_pair( site, sequence, consider_tm_diff ):
    fwd_options = []
    rev_options = []

    length = MIN_P_LENGTH
    good_fwd_found = 0
    good_rev_found = 0

    #print "designing pair for site %s" % site

    while length <= MAX_P_LENGTH:
        fwd_candidate = sequence[site -1 : site+length -1 ]
        rev_candidate = reverse_complement( sequence[site -1 -length:site -1] )

        #print "length %s, fwd_candidate is %s, rev_candidate is %s" %(length, fwd_candidate, rev_candidate)
        num_fwd_problems = num_primer_problems( fwd_candidate, MIN_Tm, MAX_NON_PROBLEMATIC_TM )
        if(  num_fwd_problems < 10 ):
            fwd_options.append( [fwd_candidate, num_fwd_problems ] )
            if num_fwd_problems == 0:
                good_fwd_found = 1

        num_rev_problems = num_primer_problems( rev_candidate, MIN_Tm, MAX_NON_PROBLEMATIC_TM )
        if(  num_rev_problems < 10 ):
            rev_options.append( [rev_candidate, num_rev_problems] )
            if num_rev_problems == 0:
                good_rev_found = 1

        if (good_fwd_found == 1 ) and (good_rev_found == 1 ):
            break
        
        length = length + 1

    #go through generated primers and pick best
    if ( len( fwd_options) == 0) or (len( rev_options ) == 0):
        return PrimerPair( "", "",10, 1, site )

    if consider_tm_diff == 1:

        best_primer_pair = PrimerPair( "", "",100, 1, site )
        #best_pair_problems = best_primer_pair.get_num_problems()
        #best_pair_length = best_primer_pair.get_totlength()

        for fwd_option in fwd_options:
            for rev_option in rev_options:
                candidate_pair = PrimerPair( fwd_option[0], rev_option[0], fwd_option[1]+rev_option[1], 0, site )
                tm_diff_probs = int( candidate_pair.get_tm_difference() / TM_DIFF_PROBLEMATIC_INCREMENT )
                candidate_pair.set_num_problems( candidate_pair.get_num_problems() + tm_diff_probs )
                if candidate_pair.get_num_problems() < best_primer_pair.get_num_problems():
                    best_primer_pair = candidate_pair
                elif (candidate_pair.get_num_problems() == best_primer_pair.get_num_problems()) and (candidate_pair.get_totlength() < best_primer_pair.get_totlength() ):
                    best_primer_pair = candidate_pair

        return best_primer_pair

    else:

        best_fwd_option = fwd_options[0]
        best_rev_option = rev_options[0]
    #print "best rev option set to %s with %s problems" % (best_rev_option[0], best_rev_option[1])
        for i in range( len(fwd_options) - 1 ):
            if fwd_options[i+1][1] < best_fwd_option[1]:
                best_fwd_option = fwd_options[i+1]

        for i in range( len(rev_options) - 1 ):
            if rev_options[i+1][1] < best_rev_option[1]:
                best_rev_option = rev_options[i+1]
            #print "switched rev to %s with %s problems" % (best_rev_option[0], best_rev_option[1])
        if (best_fwd_option[1] == 10) or (best_rev_option[1] == 10 ):
            return PrimerPair( best_fwd_option[0], best_rev_option[0],10, 1, site )

        return PrimerPair( best_fwd_option[0], best_rev_option[0], best_fwd_option[1]+best_rev_option[1], 0, site )


def create_insertion_site_list( first_nt, last_nt, num_primers):
    seq_to_cover = last_nt - first_nt
    num_intermediate_sites = num_primers - 1
    spacing = float( seq_to_cover ) / float( num_intermediate_sites )

    print "Sequence to cover is %s, at %s primers this leads to a primer pair every %.2f nucleotides." %(seq_to_cover, num_primers, spacing)
    insertion_site_list = []
    #insertion_site_list.append( first_nt )

    for i in range( num_intermediate_sites ):
        raw_relative_pos = i * spacing
        corrected_relative_pos = ( int(raw_relative_pos / 3 ) * 3 )
        corrected_relative_pos_option2 = corrected_relative_pos + 3
        #print "For site %s, the raw relative pos is %.2f and the corrected rel pos is %.2f"%(i, raw_relative_pos, corrected_relative_pos )
        if( ( float(corrected_relative_pos_option2) - raw_relative_pos ) < ( raw_relative_pos - float(corrected_relative_pos) ) ):
            corrected_relative_pos = corrected_relative_pos_option2
            #print "Correcting for i=%s, new corrected relative pos is %.2f"%(i,corrected_relative_pos)
        
        insertion_site_list.append( first_nt + corrected_relative_pos )

    insertion_site_list.append( last_nt )

    return insertion_site_list

    

#function that'll make sure no insertion sites are between two hydrophobic residues
#note: won't touch last or first residue
def modify_insertion_site_list_according_to_hydrophobicity( list, sequence ):

    first_pos = list[0]
    last_pos = list[ len( list ) - 1 ]
    cur_seq_pos = first_pos + 3
    all_allowed_pos = {}
    all_allowed_pos[first_pos ] = 1
    all_allowed_pos[last_pos ] = 1

    hp_switched_pos = []

    to_return_list = []

    last_pos_change = 0

    #first build a list of which  positions are between two hydrophobic res and which aren't
    while cur_seq_pos < last_pos:
        #print "checking for pos %s" % cur_seq_pos
        if between_two_hydrophobic( cur_seq_pos, sequence  ):
            all_allowed_pos[cur_seq_pos ] = 0
        else:
            all_allowed_pos[cur_seq_pos ] = 1
        cur_seq_pos = cur_seq_pos + 3
            
    for raw_candidate_pos in list:
        candidate_pos = raw_candidate_pos
        lc_shift = 0
        if (last_pos_change < -3) or ( last_pos_change > 3 ):
            lc_shift = (3 * int( (last_pos_change / 2 ) / 3 ) )
            candidate_pos = candidate_pos + lc_shift
            print "at raw_candidate_pos %s, lc_shift set to %s " % (raw_candidate_pos, lc_shift )
        if all_allowed_pos[ candidate_pos ] == 1:
            if( lc_shift != 0 ):
                hp_switched_pos.append( [raw_candidate_pos, candidate_pos] )
            to_return_list.append( candidate_pos )
            last_pos_change = lc_shift
        else:
            good_pos_found = 0
            counter = 3
            while good_pos_found == 0:
                fwd_good = 0
                if(all_allowed_pos[ candidate_pos + counter ] == 1):
                    fwd_good = 1
                rev_good = 0
                if(all_allowed_pos[ candidate_pos - counter ] == 1 ):
                    rev_good = 1
                    
                if( (fwd_good == 1 ) or ( rev_good == 1 ) ):
                    good_pos_found = 1
                else:
                    counter = counter + 3

                if(fwd_good == 1 ):
                    if( rev_good == 1):
                        if last_pos_change < 0:
                            last_pos_change = lc_shift - counter
                            to_return_list.append( candidate_pos - counter )
                            hp_switched_pos.append( [raw_candidate_pos, candidate_pos - counter] )
                        else:
                            last_pos_change = lc_shift + counter
                            to_return_list.append( candidate_pos + counter )
                            hp_switched_pos.append( [raw_candidate_pos, candidate_pos + counter] )
                    else:
                        last_pos_change = lc_shift +  counter
                        to_return_list.append( candidate_pos + counter )
                        hp_switched_pos.append( [raw_candidate_pos, candidate_pos + counter] )
                elif( rev_good == 1 ):
                    last_pos_change = lc_shift - counter
                    to_return_list.append( candidate_pos - counter )
                    hp_switched_pos.append( [raw_candidate_pos, candidate_pos - counter] )

    print "The following positions were switched bc of hydrophobicity reasons:"
    print hp_switched_pos
    return to_return_list
        

def return_plate_well_from_number( number ):
    number_int = int( number )
    row = (number_int / 12) + 1
    column_int = number_int % 12 
    if column_int == 0:
        row = row - 1
        column_int = 12
    column = str( column_int )

    if row == 1:
        return 'A'+ column
    elif row == 2:
        return 'B'+ column
    elif row == 3:
        return 'C'+ column
    elif row == 4:
        return 'D'+ column
    elif row == 5:
        return 'E'+ column
    elif row == 6:
        return 'F'+ column
    elif row == 7:
        return 'G'+ column
    elif row == 8:
        return 'H'+ column

    else:
        print "passed in number %s seems to be bigger than 96" % number
        sys.exit()


seq_filename = ''
first_nt = 0
last_nt = 0
num_primers = 0
sort_by_tm = ''
consider_tm_difference = 0
consider_hydrophobicity = 0
position_file_name =''

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-f':
        filename = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-first_nt':
        first_nt = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-last_nt':
        last_nt = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-num_primers':
        num_primers = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-sort_tm':
        sort_by_tm = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-consider_tm_diff':
        consider_tm_difference = 1
    elif arg == '-consider_hydrophobicity':
        consider_hydrophobicity = 1
    elif arg == '-add_linkers':
        ADD_LINKERS = 1
    elif arg == '-positions':
        position_file_name = CommandArgs[CommandArgs.index(arg)+1]
        print "huurz"
        print position_file_name
        


if( (filename == '') or ( ((first_nt == 0) or (last_nt == 0)  or (num_primers == 0)) and (position_file_name=='') )  ):
     print 'Error, please specify filename, first and last nt or a position file, and number of primers'
     sys.exit()



sequence = read_dna_seq_from_gb_file( filename )
#print "the following sequence was obtained: "
#print sequence
insertion_site_list = []
#first we create a list of where to ideally place the desired number of primers
if position_file_name == '':
    insertion_site_list = create_insertion_site_list( first_nt, last_nt, num_primers)
    if consider_hydrophobicity == 1:
        insertion_site_list = modify_insertion_site_list_according_to_hydrophobicity( insertion_site_list, sequence )
else:
    insertion_site_list = read_insertion_site_list( position_file_name, CONVERT_SITE_LIST )
    print "Read the following positions from disk:"
    print insertion_site_list
        

#sanity check
for i in range( len( insertion_site_list) - 1 ):
    if( (insertion_site_list[i+1] - insertion_site_list[i]) % 3 != 0.0):
        print "insertion_site_list fucked up"
        sys.exit()
        
#print insertion_site_list

#now let's start designing primers
primer_pairs = []
impossible_sites = []
problematic_sites = []
switched_pos = []
hydrophobic_sites = []

for site in insertion_site_list:
    primer_pair = design_insertion_primer_pair( site, sequence, consider_tm_difference )
    #print "At site %s, the following pair was designed.. "%site
    #primer_pair.print_contents()
    num_probs_orig = primer_pair.get_num_problems()
    #print "initial pair has %s problems" %num_probs_orig
    if ((num_probs_orig  == 0) or (position_file_name != '' ) ):
        primer_pairs.append( primer_pair )
        if( num_probs_orig == 0 ):
            problematic_sites.append( site )
        continue

    else:
        next_pair = design_insertion_primer_pair( site + 3, sequence, consider_tm_difference )
        #next_pair.print_contents()
        if( consider_hydrophobicity == 1 ) and between_two_hydrophobic( site + 3, sequence):
            next_pair.set_num_problems( 10 )
        if next_pair.get_num_problems() == 0 :
            switched_pos.append( [site, site+3] )
            primer_pairs.append( next_pair )
            continue
        else:
            prev_pair = design_insertion_primer_pair( site - 3, sequence, consider_tm_difference )
            if( consider_hydrophobicity == 1 ) and between_two_hydrophobic( site - 3, sequence):
                prev_pair.set_num_problems( 10 )
            #prev_pair.print_contents()
            if prev_pair.get_num_problems() == 0 :
                switched_pos.append( [site, site-3] )
                primer_pairs.append( prev_pair )
                continue

            else:
                problematic_sites.append( site )
                if( (primer_pair.is_impossible() == 1 ) and (next_pair.is_impossible() == 1 ) and (prev_pair.is_impossible() == 1 ) ):
                    impossible_sites.append( site )
                    continue
                num_probs_next = next_pair.get_num_problems()
                num_probs_prev = prev_pair.get_num_problems()

                if( ( num_probs_orig <=  num_probs_next) and ( num_probs_orig <= num_probs_prev) ):
                    primer_pairs.append( primer_pair )
                elif( ( num_probs_next <= num_probs_orig) and ( num_probs_next <= num_probs_prev) ):
                    #print "switching primers downward for site %s, original was: "%site
                    #primer_pair.print_contents()
                    #print "next pair is "
                    #next_pair.print_contents()
                    switched_pos.append( [site, site+3] )
                    primer_pairs.append( next_pair )
                else:
                    #print "switching primers upward for site %s, original was: "%site
                    #primer_pair.print_contents()
                    #print "prev pair is "
                    #prev_pair.print_contents()
                    switched_pos.append( [site, site-3] )
                    primer_pairs.append( prev_pair )

print "The following %s sites are problematic: " %len(problematic_sites)
print problematic_sites

print "The following %s sites were switched: " %len(switched_pos)
print switched_pos


print "The following sites are impossible: "
print impossible_sites

print "The following primers were obtained"
stats = calculate_statistics( primer_pairs )
print stats

#also measure the distance between each pair of primers
primer_pair_i = 0
pair_spacings = []
while primer_pair_i < (len( primer_pairs ) - 1):
    pair_spacings.append( primer_pairs[primer_pair_i+1].this_site() - primer_pairs[primer_pair_i].this_site() )
    primer_pair_i = primer_pair_i + 1

spacing_stats = generate_histogram( pair_spacings, 1 )
print "Primer pair spacings are: \n"+spacing_stats


if sort_by_tm == 'lowest':
    primer_pairs = sorted(primer_pairs, key=lambda PrimerPair: PrimerPair.lowest_tm )
elif sort_by_tm == 'diff':
    primer_pairs = sorted(primer_pairs, key=lambda PrimerPair: PrimerPair.tm_diff )

i = 1
fwd_plate_string = ''
rev_plate_string = ''
all_plate_string = ''
plate = -1  #set to -1 so the following loop works out
i_in_plate = 1

for item in primer_pairs:

    #the following line is hacky but necessary to avoid double ordering
    #of the test primers
    #if( item.this_site() == 2302 ) or ( item.this_site() == 1816 ) or ( item.this_site() == 910 ) or ( item.this_site() == 4216 ):
    #    continue
    
    if i % 96 == 1:
        plate = plate + 2
        i_in_plate = 1
        all_plate_string = all_plate_string + fwd_plate_string + rev_plate_string
        fwd_plate_string = ''
        rev_plate_string = ''

    fwd_name = ""
    rev_name = ""
    site_str = str(item.this_site())
    plate_loc = return_plate_well_from_number( i_in_plate )
    if( item.this_site() ) < 1000:
        site_str = "0"+site_str
    if ADD_LINKERS == 0:
        fwd_name = "dCL_s"+site_str+"_gc_fwd"
        rev_name = "dCL_s"+site_str+"_gc_rev"
        fwd_plate_string = fwd_plate_string + "%s %s %s %s %s\n"%(plate, plate_loc, i_in_plate, fwd_name, item.get_fwd_primer())
        rev_plate_string = rev_plate_string + "%s %s %s %s %s\n"%(plate + 1,plate_loc, i_in_plate, rev_name, item.get_rev_primer())
    else:
        fwd_name = "dCL_s"+site_str+"_re_fwd"
        rev_name = "dCL_s"+site_str+"_re_rev"
        fwd_plate_string = fwd_plate_string + "%s %s %s %s %s\n"%(plate, plate_loc, i_in_plate, fwd_name, FWD_LINKER+item.get_fwd_primer())
        rev_plate_string = rev_plate_string + "%s %s %s %s %s\n"%(plate + 1, plate_loc, i_in_plate, rev_name, REV_LINKER+item.get_rev_primer())

         
    print "Pair %s: At site %s, fwd is %s and rev is %s. Fwd_tm=%.2f, Rev_tm=%.2f diff_tm=%.2f."%(i, item.this_site(), item.get_fwd_primer(), item.get_rev_primer(), item.get_fwd_tm(), item.get_rev_tm(), item.get_tm_difference() )
    i = i +1
    i_in_plate = i_in_plate + 1
    
    if( between_two_hydrophobic( item.this_site(), sequence  ) ):
        hydrophobic_sites.append( item.this_site() )

all_plate_string = all_plate_string + fwd_plate_string + rev_plate_string

print "The following %s sites are between two hydrophobic res:"%len(hydrophobic_sites)
hydrophobic_sites.sort()
print hydrophobic_sites

platef = open('primer_plates.txt', 'w')
platef.write( all_plate_string )
platef.close()

