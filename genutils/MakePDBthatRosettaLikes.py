#!/usr/bin/python

import sys
import os

def usage():
    print 'Script to read in a pdb file (or list thereof), make sure no atom has an occupancy of 0,',
    print 'and no b-factor is bigger than 100. Occupancy gets set to 1.00, B-factors get set to 99'
    print 'usage: -s <single struct> or -l <list>, optional -only_report reports offending lines without changing file'




CommandArgs = sys.argv[1:]
if len(CommandArgs) < 2:
    usage()
    sys.exit()


file_list = []
list_mode = 0

list_file = ''
sing_struct = ''
only_report = 0
keep_chains = 1
erase_chains = 0
put_chains = 0


for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-only_report':
        only_report = 1
    elif arg == '-erase_chains':
        erase_chains = 1
        keep_chains = 0
    elif arg == '-put_chains':
        put_chains = 1
        keep_chains = 0
        erase_chains = 0
    


if list_mode:
 
    if not os.path.exists(list_file):
        print 'Error: could not find file %s' % list_file
        sys.exit()

    else:
        listf = open(list_file,'r')
        file_list = listf.readlines()
        listf.close()

else:
    file_list.append(sing_struct)



#input read in, now process files


for struct in file_list:

    struct = struct.replace("\n","")
    if not os.path.exists(struct):
        print 'Error: could absolutely not find file %s' % struct
        continue
    
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close

    renumber_offset = 0
    atom_block_flag = 0
    hetatm_block_flag = 0
    remark_block_flag = 0
    cur_res = 0
    cur_chain = "-"
    first_chain = " "
    residue_gaps = {}
    remark_lines = []
    indices_to_delete = []

    for line in struct_lines:
        cur_index = struct_lines.index(line)
        cur_record = line[0:6]

        if (cur_record == 'TER   ') and (erase_chains == 1):
            #del struct_lines[cur_index]
            indices_to_delete.append(cur_index)
            #print 'blep '
            continue


        #l = string.split(cur_record)
        #if( l[0] == 'TER')

        if (cur_record == 'REMARK'):
            remark_lines.append(cur_index)  #save remark lines for latter processing

        if (cur_record == 'ATOM  ')  and (atom_block_flag == 0 ):
            atom_block_flag = 1
            remark_block_flag = 0
            hetatm_block_flag = 0

        if (cur_record == 'HETATM')  and (hetatm_block_flag == 0 ):
            atom_block_flag = 0
            remark_block_flag = 0
            hetatm_block_flag = 1

        if atom_block_flag and cur_record != 'ATOM  ':
            atom_block_flag = 0
        if hetatm_block_flag and cur_record != 'HETATM':
            hetatm_block_flag = 0
            

        if atom_block_flag or hetatm_block_flag:
            occupancy = float(line[55:60])
            b_factor = float(line[60:66])
            residue = int(line[23:26])
            chain = line[21:22]
            atom_name = line[12:16]    #rosetta peculiarity

            if atom_block_flag:

                #if (cur_res == 0) and residue != 1):  #first line, check if file starts at 1
                #    renumber_offset = residue - 1
                #    print 'In %s the first residue has number %s \n' % (struct,residue)
                
                if (atom_name == ' OXT') and erase_chains:
                    #del struct_lines[cur_index]
                    indices_to_delete.append(cur_index)
                    continue

                if (cur_chain == '-') :
                    cur_chain = chain      #first line, get current chain
                    if not erase_chains:
                        first_chain = chain

                if(chain != cur_chain):    #encountered new chain, have to reset numbering offset
                    cur_chain = chain
                    
                    if residue != 1: #keep chains, start counting at one
                        print '%s chain %s has first residue number %s.' % (struct,chain,residue)
                    
                    if keep_chains:
                        renumber_offset = residue - 1
           
                    else:   #put all into one chain, keep counting after residue of last chain
                        new_first_number_this_chain = cur_res - renumber_offset + 1
                        residue_gaps[residue] = residue - cur_res - 1
                        renumber_offset = residue - new_first_number_this_chain
                        

                    cur_res = residue      #have to put this in here so the residue block below doesn't screw things up
                    
                if cur_res != residue: #encountered new residue, check for correct numbering
                    if residue <= cur_res:
                        print 'WARNING: %s is a fuckin\' mess, goes down in residue numbers at %s\n' % (struct,residue)
                        #continue

                    if residue != (cur_res + 1):
                        residue_gaps[cur_res] = residue - cur_res - 1   #keep track of where the gaps are
                        renumber_offset = renumber_offset + residue_gaps[cur_res]  #update numbering offset
                        print '%s has a gap of %s residues after residue %s' % (struct, residue_gaps[cur_res],cur_res)
                    
                    cur_res = residue

                if not only_report:   #done with checking, now change line
                    if not keep_chains:
                        #print 'bleb %s ha' % first_chain
                        if chain == ' ' and put_chains:
                            line = line[:21] + 'A' + line[22:] #change chain
                        elif erase_chains:
                            line = line[:21] + first_chain + line[22:] #change chain

                    new_residue_num = '%3s' % str(cur_res - renumber_offset)
                    line = line[:23] + new_residue_num + line[26:]


            #print " %s %.2f %.2f " % (line, occupancy, b_factor)
            if occupancy == 0.00:
                if only_report:
                    print 'Atom %s, %s of residue %s has 0 occupancy' % (line[7:11],line[13:16],line[17:26])
                else:
                    line = line[:55] + ' 1.00' + line[60:]
            
            if b_factor > 99.99:
                if only_report:
                    print 'Atom %s, %s of residue %s has b factor > 100' % (line[7:11],line[13:16],line[17:26])
                else:
                    line = line[:60] +  ' 99.00' + line[66:]

        struct_lines[cur_index] = line


    #done with going through lines, now change the cst mode information in the remark block
    for index in remark_lines:
        cur_remark = struct_lines[index]
        if cur_remark[0:24] == 'REMARK BACKBONE TEMPLATE':
            catres_a = int(cur_remark[56:59])
            catres_b = int(cur_remark[32:35])
            for gap_res in residue_gaps.keys():
                if gap_res < catres_a:
                    catres_a = catres_a - residue_gaps[gap_res]
                if (catres_b > 0) and gap_res < catres_b:
                    catres_b = catres_b - residue_gaps[gap_res]

            catres_a = '%3s' % catres_a
            catres_b = '%3s' % catres_b
            struct_lines[index] = cur_remark[:32] + catres_b + cur_remark[35:56] + catres_a + cur_remark[59:]

    #delete any lines we don't need anymore
    indices_to_delete.reverse()   #need to reverse so we don't delete the wrong lines
    print indices_to_delete
    for delindex in indices_to_delete:
        del struct_lines[delindex]

    if not only_report:
        os.remove(struct)
        newfile = open(struct,'w')
        newfile.writelines(struct_lines)
        newfile.close



                
