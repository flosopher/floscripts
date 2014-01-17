#!/usr/bin/python


#my first python script:)
#reads in a list of pdb files and spits out the unique sequences

import sys
import re
import time


ADD_PDB_SUFFIX = 0

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
        return 'unknown'






def get_coordinates(struct):

    struct = struct.replace("\n","")
    if ADD_PDB_SUFFIX == 1:
        struct = struct + ".pdb"
    
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close()
    atom_reading_flag = 0

    all_coordinates = {}
    cur_coordinates = {}
    cur_res = 0
    for line in struct_lines:

        if (atom_reading_flag == 0) and line[0:4] == 'ATOM':
            atom_reading_flag = 1
        if (atom_reading_flag == 1 ) and line[0:4] != 'ATOM':
            atom_reading_flag = 0
            all_coordinates[cur_res] = cur_coordinates
 
        if atom_reading_flag:
            cols = line.split()
            if cur_res != int(line[23:26]): 
                if cur_res != 0:
                    all_coordinates[cur_res] = cur_coordinates
                cur_res = int(line[23:26])
                cur_coordinates = {}
                cur_coordinates['type'] = cols[3]
                cur_coordinates['chain'] = line[21:22]
                cur_coordinates['active'] = 1  #keep track of whether we count this residue
            cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))
           #     elif (not ca_only) and line[13:14] != 'H':
           #         cur_coordinates[cols[2]] = (float(line[31:38]), float(line[39:46]), float(line[47:54]))

    return all_coordinates

def get_sequence( res_coords ):
    sequence = []
    curpos = 1
    for res in res_coords:
        if ( res - curpos ) != 1:   #to make sure we don't have gaps
            for i in range( res - curpos ):
                sequence.append("X")
        sequence.append(  AA3LetTo1Let(res_coords[res]['type']) )
        curpos = res

    return sequence


class UniqueSequenceCounter:

    def __init__(self):
        self.mut_pos = {}
        self.num_sequences = 0
        self.sequences = []
        self.seq_length = 0



    def add_struct( self, res_coords, name ):

        this_len = len( res_coords )
        if self.num_sequences == 0:
            self.seq_length = this_len

        if this_len != self.seq_length :
            print "Error: structures don't all have same length"
            sys.exit()
        self.num_sequences = self.num_sequences + 1
        #print "adding struct %s " % self.num_sequences
        this_sequence = get_sequence( res_coords )
        this_seq_unique = 1

        for seq in self.sequences:
            #print "starting seq compare"
            seqs_differ = 0
            for i in range (self.seq_length):
                if seq[0][i] != this_sequence[i]:
                    #print "for seq %s, at position %s, template has %s while new seq has %s" % (self.num_sequences, i, seq[0][i], this_sequence[i] )
                    seqs_differ = 1
                    if not self.mut_pos.has_key( i + 1 ):  #mutation at this position observed the first time
                        self.mut_pos[ i+1 ] = 1;

            if seqs_differ == 0:
                seq[1] = seq[1] + 1   #how often this sequence was observed
                #print "sequence %s is not unique" % self.num_sequences 
                this_seq_unique = 0
                break

        if this_seq_unique == 1:
            self.sequences.append( [this_sequence,1,name] )



    def get_outstring( self ):

        outstring = "%s unique sequences were observed among a total of %s sequences.\n" % (len(self.sequences), self.num_sequences)
        allmutpos = self.mut_pos.keys()
        allmutpos.sort()
        for seq in self.sequences:
            for pos in allmutpos:
                outstring = outstring + seq[0][pos - 1] + str( pos ) + ", "
            outstring = outstring + "     %s counts, first observed %s \n" % (seq[1],seq[2])
        return outstring

    def get_unique_filenames( self ):
        to_return = []
        for seq in self.sequences:
            to_return.append( seq[2] )

        return to_return


FileList = []
Listfile = ''
outfile = ""
listmode = 0
output_unique_filenames = 0

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-output_filenames':
        output_unique_filenames = 1
    elif arg == '-add_pdb_suffix':
        ADD_PDB_SUFFIX = 1



if not Listfile:
     print 'Error, please supply name of the listfile'
     sys.exit()

inlist = open(Listfile,'r')
FileList = inlist.readlines()
inlist.close()
if outfile == ' ':
    outfile = Listfile + '.ana'

if not output_unique_filenames:
    print "Checking structures for %s structures in %s." % (len(FileList), Listfile)


seqs = UniqueSequenceCounter()

outstring = ""
report_interval = 5
time_last_report = time.clock()
#pymutstring = "select mutations, resi "

for struct in FileList:
    cur_time = time.clock()

    if ( cur_time - time_last_report ) > report_interval:
        print "A total of %s structures with %s unique sequences checked so far..." % ( seqs.num_sequences, len(seqs.sequences) )
        time_last_report = cur_time

    struct_coords = get_coordinates(struct)

    seqs.add_struct( struct_coords, struct.replace('\n','' ) )
 
    #print mutstring
outstring = ""

if output_unique_filenames:
    unique_list = seqs.get_unique_filenames()
    for file in unique_list:
        outstring = outstring + file + "\n"
else:
    outstring = seqs.get_outstring()
    #print outstring


if outfile == "":
    #in this case we have to remove the last \n character
    outlength = len( outstring )
    if outstring[outlength-1:outlength] == '\n':
        outstring = outstring[:outlength-1] 
    print outstring
    #print pymutstring

else:
    outf = open(outfile,'w')
    outf.write(outstring)
    outf.close()
