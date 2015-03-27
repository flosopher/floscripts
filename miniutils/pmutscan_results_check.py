#!/usr/bin/python

import sys

def usage():
    print """
    Script to clean up pmut_scan protocol results. When calculating double mutants, this protocol
    also writes out combinations where the score increase is entirely due to one of the 2 mutants,
    i.e. the single mutant would make more sense.
    This script reads in one file with single mutant outputs, one file with double mutant outputs,
    looks at every single mutant and it's score, and then throws out every double mutant where one
    of the two mutants has a higher score as a single mutant than the corresponding double

    example,
    single muts
    protocols.pmut_scan.PointMutScanDriver: A-H102F   A-H102F      -1.345     -203.68

    double muts
    protocols.pmut_scan.PointMutScanDriver: A-H102F,A-V149I   A-H102F,A-V149I      -0.968     -210.11

    leads to the double mutant being thrown out

    usage
    pmutscan_results_check.py -smutfile <single muts file> -dmutfile <double muts file>
    
    """
    sys.exit()



#pdb_chain = 'A'
#filename = 'seqprof_hel_interface_minal.txt'

smutfname = 'singlemuts_out.txt'
dmutfname = 'doublemuts_out.txt'

#put some commandline arguments in here

s_infile = open( smutfname, 'r')
smut_lines = s_infile.readlines()
s_infile.close()

d_infile = open( dmutfname, 'r')
dmut_lines = d_infile.readlines()
d_infile.close()

#if this variable is true, also discard double mutants whose score
#is not better than the combined singles
check_singles_sum = 1



#simple dictionary, key=string (e.g. A-G17D), value = dG , (e.g. -0.385)
single_mutants = {}

#first process single mutants
for sline in smut_lines:
    line_items = sline.split()
    
    #quick check if we have a relevant line
    #print line_items
    if line_items[0] != 'protocols.pmut_scan.PointMutScanDriver:':
        continue
    if len( line_items ) != 5:
        continue

    single_mutants[ line_items[1] ] = float( line_items[3] )


#done, now look at doubles
outlines = []
for dline in dmut_lines:
    line_items = dline.split()
    if line_items[0] != 'protocols.pmut_scan.PointMutScanDriver:':
        continue
    if len( line_items ) != 5:
        continue

    muts = (line_items[1]).split(',')
    smut1 = muts[0]
    smut2 = muts[1]

    muts_dg = float( line_items[3] )

    if single_mutants.has_key( smut1 ):
        if single_mutants[ smut1 ] < muts_dg:
            print "Single mutant %s has dG of %.2f, double mutant %s has dG of %.2f, discarding double." % (smut1, single_mutants[ smut1 ], line_items[1], muts_dg )
            continue

    if single_mutants.has_key( smut2 ):
        if single_mutants[ smut2 ] < muts_dg:
            print "Single mutant %s has dG of %.2f, double mutant %s has dG of %.2f, discarding double." % (smut2, single_mutants[ smut2 ], line_items[1], muts_dg )
            continue

        if ( check_singles_sum == 1) and single_mutants.has_key( smut1 ):
            singles_sum = single_mutants[ smut1 ] + single_mutants[ smut2 ]
            if singles_sum < muts_dg:
                print "Single mutants %s and %s have a dG sum of %.2f + %.2f = %.2f, but double mutant only has dG of %.2f, discarding double." % (smut1, smut2, single_mutants[ smut1 ], single_mutants[ smut2 ], singles_sum, muts_dg )
                continue

    outlines.append( dline )
   
outstring = ''
for outl in outlines:
    outstring = outstring + outl
print outstring

