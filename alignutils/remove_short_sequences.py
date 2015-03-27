#!/usr/bin/python

import sys

def usage():
	print """ Script to read in an alignment and remove all the sequences
	that are shorter than a user-specified lenght.

	Example:
	specifying length 26 on the following input file

	FLHPVGGSFGHPDYFLGSQFELGRSGSSEQEAAAGHAG
	FLHPVGGR-----YILGSQFEIADDAAEQVRA------
	FMYHLKV-SRSRSLFMGSQFRL----------------
	LLEPISNKLDSRRLALGAQFELARHELEEFKEEPVQEN

	leads to

	FLHPVGGSFGHPDYFLGSQFELGRSGSSEQEAAAGHAG
	FLHPVGGR-----YILGSQFEIADDAAEQVRA------
	LLEPISNKLDSRRLALGAQFELARHELEEFKEEPVQEN

	usage:
	remove_short_sequences.py -alignment <filename> -length <integer>

	"""
	sys.exit()



#function to determine the length of a given sequence
#returns the position of the first character that is not a -

def get_sequence_length( sequence ):
	#get rid of /n characters first
	#sequence.replace('\n','')
	if sequence[len(sequence)-1] == '\n':
		sequence = sequence[:-1]

	counter = len(sequence)
	#print sequence

	while counter > 0:
		#print counter
		#print sequence[counter-1]
		if sequence[counter-1] != '-':
			return counter
		counter = counter - 1

	return -1



aln_filename = ''
min_length = -1


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-alignment':
        aln_filename = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-length':
        min_length = int( CommandArgs[CommandArgs.index(arg)+1] )


if (aln_filename == '') or (min_length < 1):
	usage()


alnfile = open(aln_filename,'r' )

#read all sequences into a list data structure
#->read up on python list and directory data types

all_sequences = alnfile.readlines()
alnfile.close()

output_sequences = []

#print all_sequences

for sequence in all_sequences:
	this_length = get_sequence_length( sequence )
	#print sequence
	#print "has a length of "
	#print this_length

	if this_length >= min_length:
		#print "appending"
		output_sequences.append(sequence)


newfilename = 'min_' + str(min_length) + aln_filename

print str( len(output_sequences)) + " sequences have a minimum length of " + str(min_length)

fileoutstring = ""
for outseq in output_sequences:
	fileoutstring = fileoutstring + outseq
outfile = open(newfilename,'w')
outfile.write(fileoutstring)
outfile.close()

