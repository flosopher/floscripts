#!/usr/bin/python/

import sys
import os

def usage():
    print """Script to read in a list of silentfiles and concatenate them together so the structures are uniquely named.
Only one reference pose is kept. 
"""


def read_file_to_commentless_linelist( filehandle ):
    
    return_lines = []
    line = filehandle.readline()
    while( line ):
        
        commentpos = line.find('#')
        if commentpos != -1:
            if line[commentpos-1:commentpos] != "\\":
                print "splitting out comment %s" % line[commentpos:]
                line = line[0:commentpos]

        if len(line) > 0 :
            return_lines.append(line)

        line = filehandle.readline()

    return return_lines


def add_zeros(string, newlen, dir = 1):
    if len(string) > newlen:
        return string

    fill = newlen - len(string)
    if dir == 0:
        for i in range(fill):
            string = string + '0'

    else:
        for i in range(fill):
            string = '0' + string

    return string




def change_pose_tag_number( pose_tag, offset):

    pose_num = int(pose_tag[-4:] )
    pose_should_num = pose_num + offset
    newnum = add_zeros( str(pose_should_num), 4 )
    
    newtag = pose_tag[0:-4] + newnum
    return newtag



CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []

list_file = ''

script_fail = 0
outfile = "tmp.out"

for arg in CommandArgs:
   if arg == '-ptm':
        ptm_file = CommandArgs[CommandArgs.index(arg)+1]
   elif arg == '-l':
       list_file = CommandArgs[CommandArgs.index(arg)+1]
   elif arg == '-o':
       outfile = CommandArgs[CommandArgs.index(arg)+1]



#if not list_file:
#    print 'E
if not os.path.exists(list_file):
    print 'Error, no list file found \n'
    sys.exit()

listf = open(list_file,'r')
file_list = listf.readlines()
listf.close()


#input read in, now process files
outlines = []
firstfile = 1
refpose_name = ""
number_poses = 0
outstring = ""

for struct in file_list:

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close
 
    pose_block = 0
    cur_end_pose_tag = ""
    first_struct = 1
    refpose_block = 0

    additional_ref_block = 0

    cur_start_pose_tag = ""
    cur_file_no_lines = len(struct_lines)
    incomplete_poses = 0

    single_pose_string = ""

    print "Silent file %s has %s lines." %(struct, len(struct_lines) )
    
    for i in range(cur_file_no_lines):
        line = struct_lines[i]
        #cur_index = struct_lines.index(line)
        cur_fields = line.split()

        newline = line

        #if( (i % 1000) == 0):
        #    print "line %s" %str(i)

        if( (cur_fields[0] == "SCORES") and refpose_block == 0 and additional_ref_block == 0):
            if pose_block != 1:
                print "omg, everything is fucked in a score block \n"
                sys.exit()
            cur_fields[1] = change_pose_tag_number( cur_fields[1], number_poses - incomplete_poses )
            if cur_fields[1] != cur_start_pose_tag:
                print "omg, everything is fucked in score tag, %s isn't equal to %s \n" %(cur_fields[1],cur_start_pose_tag)
                sys.exit()
            newline = " ".join( cur_fields)
            newline = newline + "\n"
 

        if( cur_fields[0] == "POSE_TAG"):
            if pose_block == 1:
                print "file %s corrupted, missing END_POSE_TAG around line %s, will not consider this pose \n" %(struct,str(i))
                single_pose_string = ""
                incomplete_poses = incomplete_poses + 1
                first_struct = 0
            pose_block = 1
            outstring = outstring + single_pose_string
            single_pose_string = ""
            if( cur_fields[1][0:5] == "%REF%" ): #means we are in a ref block
                if first_struct == 1:  #this means this is the reference pose
                    cur_refpose_name = cur_fields[1]
                    if firstfile == 1:
                        refpose_name = cur_refpose_name
                        print "refpose found: %s  " % refpose_name
                    elif refpose_name != cur_refpose_name:
                        print "files corrupted, ref poses not the same \n"
                        sys.exit()
                    first_struct = 0
                    refpose_block = 1
                else:
                    additional_ref_block = 1
            else:
                cur_start_pose_tag = change_pose_tag_number( cur_fields[1], number_poses - incomplete_poses )
                newline = cur_fields[0] + " " + cur_start_pose_tag + "\n"

        if( cur_fields[0] == "END_POSE_TAG" ):
            first_struct = 0
            if pose_block == 0:
                print "file corrupted, missing BEGIN_POSE_TAG somewhere, i.e. line %s \n" %str(i)
                sys.exit()
            pose_block = 0;

            if firstfile and (additional_ref_block != 1):
                #outlines.append(line)
                #outstring = outstring + newline
                single_pose_string = single_pose_string + newline
            elif( (refpose_block != 1) and (additional_ref_block != 1) ):
                new_pose_tag = change_pose_tag_number( cur_fields[1], number_poses - incomplete_poses )
                newline = cur_fields[0] + " " + new_pose_tag + "\n"
                if new_pose_tag != cur_start_pose_tag:
                    print "omg, everything is fucked \n"
                    sys.exit()
                #outlines.append(newline)
                #outstring = outstring + newline
                single_pose_string = single_pose_string + newline
            refpose_block = 0
            additional_ref_block = 0
            cur_end_pose_tag = cur_fields[1]
        else:
            if( additional_ref_block != 1):
                if firstfile:
                #outlines.append(newline)
                    #outstring = outstring + newline
                    single_pose_string = single_pose_string + newline
                elif refpose_block != 1:
                #outlines.append(newline)
                    #outstring = outstring + newline
                    single_pose_string = single_pose_string + newline
     

    outstring = outstring + single_pose_string
    firstfile = 0
    last_pose_num = int(cur_end_pose_tag[-4:] )
    number_poses = number_poses + last_pose_num - incomplete_poses
   

#done with new file, now we have to add it all into one string
#outstring = "hoh"
#for line in outlines:
#    outstring = outstring + line

newfile = open(outfile,'w')
newfile.write(outstring)
newfile.close

#print outstring
 

                
