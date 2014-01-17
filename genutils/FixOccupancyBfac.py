#!/usr/bin/python/

import sys

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

script_fail = 0

for arg in CommandArgs:
    if arg == '-s':
        sing_struct = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        list_mode = 1;
        list_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-only_report':
        report_problems = 1

if list_mode:
    #if not list_file:
    #    print 'E
    listf = open(list_file,'r') || script_fail = 1
    if script_fail:
        print 'Error: could not find file %s' % list_file
        sys.exit()

    file_list = listf.readlines()
    listf.close()

else:
    file_list.append(sing_struct)



#input read in, now process files


for struct in file_list:

    struct = struct.replace("\n","")
    struct_file = open(struct,'r')
    struct_lines = struct_file.readlines()
    struct_file.close

    for line in struct_lines:
        cur_record = line[0:6]
        if (cur_record == 'ATOM  ') || (cur_record == 'HETATM'):
            occupancy = float(line[55:60])
            b_factor = float(line[60:66])
            if occupancy == 0.00:
                if only_report:
                    print 'Atom %s, %s of residue %s has 0 occupancy' % (line[7:11],line[13:16],line[17:26])
                else:
                    line[55:60] = ' 1.00'
            
                if b_factor > 99.99:
                    if only_report:
                        print 'Atom %s, %s of residue %s has b factor > 100' % (line[7:11],line[13:16],line[17:26])
                    else:
                        line[61:66] = ' 99.00'



                
