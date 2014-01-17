#!/usr/bin/python

import sys
import re


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
listmode = 0

CommandArgs = sys.argv[1:]

seen_lengths = {}

for arg in CommandArgs:
    if arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    #elif arg == '-out':
    #    outfile = CommandArgs[CommandArgs.index(arg)+1]
    #elif arg == '-s':
    #    Singlefile = CommandArgs[CommandArgs.index(arg)+1]



if ( not Listfile):
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()
elif(listmode):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()

num_structs = len( FileList )
print "starting to process " + Listfile + " containing " + str( num_structs ) + " structures."

counter = 0
num_per_report = num_structs / 10
if( num_per_report == 0 ):
    num_per_report = num_structs

for struct in FileList:

    counter = counter + 1

    struct_coords = get_coordinates(struct)

    len_this_struct = len( struct_coords )

    if not seen_lengths.has_key( len_this_struct ):
        new_list = []
        new_list.append( struct  )
        seen_lengths[ len_this_struct ] = new_list

    else:
        seen_lengths[ len_this_struct ].append( struct )

    if( counter % num_per_report == 0 ):
        print "process " + str( counter ) + " so far."

     
#done, now write out the lists

for length in seen_lengths:
     this_name = Listfile + "_" + str( length )
     outf = open(this_name,'w')
     for struct in seen_lengths[length]:
         outf.write( struct )
     outf.close()
     

#if outfile == "":
#    print outstring
#    print pymutstring

#else:
#    outf = open(outfile,'w')
#    outf.write(outstring)
#    outf.close()
