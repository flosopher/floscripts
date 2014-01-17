#!/usr/bin/python/

import sys
import os

def add_spaces(string, newlen, dir = 0):
    if len(string) > newlen:
        return string

    fill = newlen - len(string)
    if dir == 0:
        for i in range(fill):
            string = string + ' '

    else:
        for i in range(fill):
            string = ' ' + string

    return string


def usage():
    print 'Script to read in a pdb file (or list thereof), make sure no atom has an occupancy of 0,',
    print 'and no b-factor is bigger than 100. Occupancy gets set to 1.00, B-factors get set to 99'
    print 'usage: -s <single struct> or -l <list>, optional -only_report reports offending lines without changing file'


def read_file_to_commentless_linelist( filehandle ):
    
    return_lines = []
    line = filehandle.readline()
    while( line ):
        
        commentpos = line.find('#')
        if commentpos != -1:
            if line[commentpos-1:commentpos] != "\\":
                #print "splitting out comment %s" % line[commentpos:]
                line = line[0:commentpos]

        if len(line) > 0 :
            return_lines.append(line)

        line = filehandle.readline()

    return return_lines


def fix_remark_header( line, ptm, block_offset, lchain ):
    linelist = line.split()
    newstring = line
    if linelist[0] != "REMARK":
        print "wtf? wtf?!? \n"
        sys.exit()

    if (linelist[1] == "BACKBONE"):
        new_cst = int( linelist[11] ) + block_offset 
        newstring = "REMARK BACKBONE TEMPLATE " + lchain + " " + ptm.newname + "    0 MATCH MOTIF A "+linelist[9] + add_spaces( linelist[10], 6, 1 ) + "  " + str( new_cst ) + "\n"

    return newstring
   
class LigPtmData:

    def __init__(self, file_inp):
        atommap_flag = 0;
        self.atom_dict = {}
        for line in file_inp:
            linearray = line.split()
            if linearray[0] == 'NAME':
                self.oldname = linearray[1]
                self.newname = linearray[2]

            if linearray[0] == "ATOM_MAP_START":
                atommap_flag = 1
                continue

            if linearray[0] == "ATOM_MAP_END":
                atommap_flag = 0

            if atommap_flag == 1:
                if len( linearray[1] ) < 4:
                    linearray[1] = " " + linearray[1]
                if len( linearray[1] ) < 4:
                    linearray[1] = linearray[1] + " "
                self.atom_dict[ int( linearray[0] ) ] = linearray[1]




CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''
ptm_file = ''
only_report = 0
new_chain = ' '
cst_block_offset = 0

script_fail = 0
fix_vatoms = 0


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    if arg == '-ptm':
        ptm_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-put_chain':
        new_chain = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-only_report':
        report_problems = 1
    elif arg == '-fix_v':
        fix_vatoms = 1
    elif arg == '-cst_offset':
        cst_block_offset = int( CommandArgs[CommandArgs.index(arg)+1] )


if list_mode:
    #if not list_file:
    #    print 'E
    if not os.path.exists(list_file):
        print 'Error, no list file found \n'
        sys.exit()

    listf = open(list_file,'r')
    file_list = listf.readlines()
    listf.close()

else:
    file_list.append(sing_struct)

ptmf = open(ptm_file,'r')
ptm_lines = read_file_to_commentless_linelist(ptmf)
ptmf.close()

lig_ptm = LigPtmData( ptm_lines )

#input read in, now process files


for struct in file_list:

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close

    lig_read_flag = 0
    lig_encountered = 0
    first_lig_atom = 0
    lig_atoms = 0
    structout_string = ""
    lig_resnr = ""
    
    for line in struct_lines:
        cur_index = struct_lines.index(line)
        cur_record = line[0:6]
        print_this_line = 1

        if( cur_record == "REMARK" ):
            struct_lines[cur_index] = fix_remark_header( line, lig_ptm, cst_block_offset, new_chain )

        if( cur_record != 'HETATM'):
            if( ( line[0:4] == "ATOM" ) and ( new_chain != ' ') and (line[21:22] == " ") ):    #means we want to put in a new chain
                struct_lines[cur_index] = line[:21] + "A" + line[22:]

            structout_string = structout_string + struct_lines[cur_index]
            continue
      
        linearray = line.split()
        #print linearray

        if (cur_record == 'HETATM' and (lig_read_flag == 0) ):
            if lig_encountered == 1:
                print "fuck that \n"
                print line
                sys.exit()

            if line[17:20] == lig_ptm.oldname:
                lig_read_flag = 1
                lig_encountered = 1
                #print "huh" + linearray[1] + "  "
                first_lig_atom = int(linearray[1]) 
                lig_resnr = line[22:26]

        if (cur_record == 'HETATM' and (lig_read_flag == 1) ):
            if ( (line[17:20] != lig_ptm.oldname) and (line[12:13] != "V") ):
                lig_read_flag = 0

        if( lig_read_flag == 1 ):
            #atom number should be first_lig_atm - lig_atoms
            #print "huh" + str(first_lig_atom + lig_atoms)
            if( int(linearray[1]) != ( first_lig_atom + lig_atoms) ):
                print 'Error, ligand numbering is fucked. \n'
                sys.exit()

            lig_atoms = lig_atoms + 1
            if( lig_ptm.atom_dict[lig_atoms] == "REMOVE" ):
                print_this_line = 0
            struct_lines[cur_index] = line[:12] + lig_ptm.atom_dict[lig_atoms] + " " + lig_ptm.newname + " " + new_chain + line[22:]
            #print struct_lines[cur_index]

            if( fix_vatoms == 1 and line[12:13] == "V" ):
                templine = struct_lines[cur_index]
                struct_lines[cur_index] = templine[0:22] + lig_resnr + "    " + templine[30:66] + "           X\n"
                

        if( print_this_line == 1):
            structout_string = structout_string + struct_lines[cur_index]
 
    os.remove(struct)
    newfile = open(struct,'w')
    newfile.write(structout_string)
    newfile.close


                
