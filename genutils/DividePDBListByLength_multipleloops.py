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


def read_loop_file( loop_file ):
    filehandle = open( loop_file, 'r')
    filelines = filehandle.readlines()
    filehandle.close()

    loops = []
    in_loop_block = 0
    cur_loop_start = 0
    cur_loop_end = 0

    for line in filelines:
        tokens = line.split()
        if len( tokens ) < 1:
            continue
        #print tokens[0]
        if tokens[0] == 'LOOP_BEGIN':
            in_loop_block = 1
            cur_loop_start = 0
            cur_loop_end = 0
        elif tokens[0] == 'LOOP_END':
            in_loop_block = 0
            if (cur_loop_end == 0 ) or ( cur_loop_start == 0 ):
                print "Wrong format loop file. either start or stop not specified for one of the loops."
                sys.exit()
            loops.append( (cur_loop_start,cur_loop_end) )
        elif tokens[0] == 'start':
            if in_loop_block:
                cur_loop_start = int(tokens[1])
        elif tokens[0] == 'stop':
            if in_loop_block:
                cur_loop_end = int(tokens[1])

    return loops

#function to calculate the squared distance between two atoms, expects two tuples or two lists as input
#the first three elements of the two inputs are used
def sq_distance(coord1, coord2):
    return ( ((coord2[0] - coord1[0]) ** 2) + ((coord2[1] - coord1[1]) ** 2) + ((coord2[2] - coord1[2]) ** 2) )


FileList = []
Listfile = ''
template = ''
outfile = ""
listmode = 0
loop_file = ''

CommandArgs = sys.argv[1:]

seen_lengths = {}

for arg in CommandArgs:
    if arg == '-t':
        template = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    elif arg == '-loopfile':
        loop_file = CommandArgs[CommandArgs.index(arg)+1]
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

template_coords = get_coordinates(template)
len_template = len( template_coords )

#loops is a list of tuples
loops = read_loop_file( loop_file )
print "Loops file was read, loops gotten were:"
print loops
num_loops = len(loops)
midpoints = []

for i in range( num_loops - 1 ):
    midpoints.append( int( (loops[i+1][0] - loops[i][1])/2 ) + loops[i][1] )

midpoints.append( int( loops[num_loops - 1][1] ) + 3 )

print "Midpoints used are:"
print midpoints

num_structs = len( FileList )
print "starting to process " + Listfile + " containing " + str( num_structs ) + " structures."

counter = 0
num_per_report = num_structs / 10
if( num_per_report == 0 ):
    num_per_report = num_structs


for struct in FileList:

    counter = counter + 1
    #print struct
    struct_coords = get_coordinates(struct)

    len_this_struct = len( struct_coords )

    lengths_this_struct = []
    tot_change_this_struct = 0

    for i in range ( num_loops ):
        #print template_coords[ 117]
        midpoint_coords =  template_coords[midpoints[i]]['CA']
        #print midpoint_coords
        orig_len_this_loop = loops[i][1] - loops[i][0] + 1
        res_counter = loops[i][0] + tot_change_this_struct
        while res_counter < len_this_struct:
            diff_this_ca = sq_distance( midpoint_coords , struct_coords[res_counter]['CA']  )
            if diff_this_ca < 4:
                break
            res_counter = res_counter + 1

        len_diff_this_loop = ( res_counter - midpoints[i] ) - tot_change_this_struct
        tot_change_this_struct = tot_change_this_struct + len_diff_this_loop
        lengths_this_struct.append( orig_len_this_loop + len_diff_this_loop )
        #print "for loop %s, midpoint is at %s, len_diff_this_loop is " % (str(i), str(res_counter), str(len_diff_this_loop) )
        #print i
        #print res_counter
        #print len_diff_this_loop

    #lists are unhashable, so we'll build a string based on loop lengths
    hash_str = 'h_'
    for element in lengths_this_struct:
        hash_str = hash_str + str( element ) + '_'
    if not seen_lengths.has_key( hash_str ):
        new_list = []
        new_list.append( struct  )
        seen_lengths[ hash_str ] = new_list

    else:
        seen_lengths[ hash_str ].append( struct )

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
