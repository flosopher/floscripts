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
        return 'unknown'






def get_coordinates(struct):

    struct = struct.replace("\n","")
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


class SequenceProfile:

    def __init__(self, res_input):
        self.wt_pos = []
        self.num_sequences = 0
        self.mutations = {}

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
                if not self.mutations[ i ].has_key( this_res ):
                    self.mutations[i][this_res] = 0

                self.mutations[ i ][this_res] = self.mutations[i][this_res] + 1


    def get_outstring( self ):

        outstring = ""
        for i in range( len( self.wt_pos ) ):
            if self.mutations.has_key( i ):
                outstring = outstring + self.wt_pos[i] + str(i+1) + ": "
                for res in self.mutations[ i ]:
                    
                    freq = float(self.mutations[ i ][res]) / float( self.num_sequences )
                    #outstring = outstring + str( freq ) + " " + res + ",  "
                    outstring = outstring + "%.2f " % freq + res + ",  "

                outstring = outstring + "\n"

        if outstring == "":
            outstring = "no mutations found"

        return outstring



FileList = []
Listfile = ''
template = ''
outfile = ""
Singlefile = ''
listmode = 0

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-s':
        Singlefile = CommandArgs[CommandArgs.index(arg)+1]



if ( (not Listfile and not Singlefile) or (not template) ):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
elif(listmode):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()
    if outfile == ' ':
        outfile = Listfile + '.ana'
    print "Checking structures for %s structures in %s to template %s" % (len(FileList), Listfile, template)

else:
    FileList.append(Singlefile)

template_coords = {}

if template != '':
    template_coords = get_coordinates(template)

seq_prof = SequenceProfile( template_coords )

outstring = ""
pymutstring = "select mutations, resi "

for struct in FileList:

    struct_coords = get_coordinates(struct)

    seq_prof.add_struct( struct_coords )
 
    #print mutstring

outstring = seq_prof.get_outstring()
    #print outstring


if outfile == "":
    print outstring
    #print pymutstring

else:
    outf = open(outfile,'w')
    outf.write(outstring)
    outf.close()
