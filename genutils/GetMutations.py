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


template_coords = get_coordinates(template)



outstring = ""
pymutstring = "select mutations, resi "

for struct in FileList:

    struct_coords = get_coordinates(struct)
    num_mutations = 0
    mutstring = ""

    for res in template_coords:
        if not struct_coords.has_key(res):
            print "Error: %s doesn't have the similar residues as template, missing reside no. %s \n" % (struct,res)
            sys.exit()
        if template_coords[res]['type'] != struct_coords[res]['type']:
            #print 'hihi %s %s' %(template_coords[res]['type'], struct_coords[res]['type'])
            mutstring = mutstring + " " + AA3LetTo1Let(template_coords[res]['type']) + str(res) + AA3LetTo1Let(struct_coords[res]['type'])
            num_mutations = num_mutations + 1
            pymutstring = pymutstring + str(res) + "+"

    #print mutstring
    outstring = outstring + struct + " %s mutations: " % num_mutations + mutstring + "\n"
    #print outstring


if outfile == "":
    print outstring
    print pymutstring

else:
    outf = open(outfile,'w')
    outf.write(outstring)
    outf.close()
