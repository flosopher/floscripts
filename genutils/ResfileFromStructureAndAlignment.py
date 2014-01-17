#!/usr/bin/python

import sys
import os
from math import sqrt

def usage():
    print """put in structure with -s, put in alignment with -a, get corresponding resfile to stdout.
    Strategy: read in structure, read in 2 way alignment, the sequence of residues in the alignment needs to be like in the structure. go through the residues in the structure, assert that the residue in the alignment is the same, throw out the corresponding residue
    """



#depending on where the file came from, the sequences start at different columns
ALIGNMENT_LINEOFFSET = 9


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



def get_coordinates(struct):

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = {}
    #all_coordinates['residue_offset'] = 0
    cur_coordinates = {}
    cur_res = 0
    all_cat_remarks = []
    for line in struct_lines:

        if( line[0:6] == 'REMARK' and ( line[17:25] == 'TEMPLATE') or (line[16:24] == 'TEMPLATE') ):
            all_cat_remarks.append( line[20:].replace("\n","") )

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates[cur_res] = cur_coordinates
 
        if atom_reading_flag:
            cols = line.split()
            if cur_res != int(line[22:26]):
                if cur_res != 0:
                    all_coordinates[cur_res] = cur_coordinates
                else:
                    firstres = int(line[22:26])
                    #print "MEEP1 %s" % firstres
                    #if firstres != 1:
                        #all_coordinates['residue_offset'] = firstres - 1
                        #print "MEEP2 %s" % hack_struct_offset
                cur_res = int(line[22:26])
                #print "MEEP cur_res is %s" % cur_res
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
                cur_coordinates['coords'] = {}
            if not ((line[13] == 'H') or ( len(cols[2]) == 4 and line[12] == 'H' ) ):
                cur_coordinates['coords'][cols[2]] = (float(line[30:38]), float(line[38:46]), float(line[46:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
    #all_coordinates['catinfo'] = all_cat_remarks
    #print all_coordinates['catinfo']
    if (atom_reading_flag == 1) and not all_coordinates.has_key(cur_res):
        all_coordinates[cur_res] = cur_coordinates
    return all_coordinates



def read_clustal_format_alignment(filename, offset_template, offset_alignseq):

    filename = filename.replace("\n","")
    file_handle = open(filename,'r')
    file_lines = file_handle.readlines()
    file_handle.close()

    #the alignment will be a list of 3mer tuples:
    #position in the list corresponds to position in template sequence
    #tuple[0] is template aa
    #tuple[1] is aligned aa
    #tuple[2] is residue number of aligned aa
    alignment = []


    #note: in a clustal alignment, the 'template' sequence is
    #in the uneven lines, starting at 3 (i.e. 2 in 0 based counting)
    line_count = 2
    for i in range (offset_template):
        alignment.append( ('-', '-', 0))

    aligned_rescounter = 0 + offset_alignseq

    while line_count < len( file_lines ):
        template_str = (file_lines[ line_count][ALIGNMENT_LINEOFFSET:]).replace('\n','')
        aligned_str = (file_lines[ line_count + 1][ALIGNMENT_LINEOFFSET:]).replace('\n','')

        len_tstr = len( template_str )
        if len_tstr != len( aligned_str):
            print "Error in alignment file: Difference in line length in line "+str( line_count +1)
            print 'hack'
            print template_str
            print 'hack'
            print aligned_str
            print 'hack'
            sys.exit()

        for i in range( len_tstr):
            template_char = template_str[i]
            aligned_char = aligned_str[i]

            if aligned_char != '-':
                aligned_rescounter = aligned_rescounter + 1
            if template_char == '-':
                continue
            alignment.append( (template_char, aligned_char, aligned_rescounter ) )

        line_count = line_count + 3

    return alignment
    

#for res1_num in coords1:
 


CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''
template = ''
alignfile = ''
seq_offset_alignfile_template = 0
seq_offset_alignfile_alignseq = 0
chain_char = 'A'


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-a':
        alignfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-offset_alignfile_template':
        seq_offset_alignfile_template = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-offset_alignfile_alignseq':
        seq_offset_alignfile_alignseq = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-chain':
        chain_char = CommandArgs[CommandArgs.index(arg)+1]



struct_coords = get_coordinates(sing_struct)
alignment = read_clustal_format_alignment( alignfile, seq_offset_alignfile_template, seq_offset_alignfile_alignseq )
outstring = "NATAA \n\nstart\n"

print "got alignment of size"+ str( len( alignment) )
print alignment

print "and struct dictionary"
print struct_coords.keys()

for resi in struct_coords.keys():
    print resi
    if AA3LetTo1Let( struct_coords[resi]['type'] ) != alignment[resi-1][0]:
        print "Error: residue "+str( resi ) + " is " + struct_coords[resi]['type'] + " in template but " + alignment[resi-1][0] + " in alignment, alinged res is "+ str(  alignment[resi-1][2] )
        print "Surrounding alignment: " + alignment[resi-2][0] + alignment[resi-1][0] + alignment[resi][0] 
        sys.exit()
        
    #outstring = outstring + str( alignment[resi-1][2] ) + " " + chain_char + " PIKAA " + alignment[resi-1][1] +"\n"
    outstring = outstring + str( resi ) + " " + chain_char + " PIKAA " + alignment[resi-1][1] +"\n"

outf = open("tha_resfile", 'w')
outf.write(outstring)
outf.close()
