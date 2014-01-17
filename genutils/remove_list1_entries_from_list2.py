#!/usr/bin/python

import sys



CommandArgs = sys.argv[1:]
list1_file = CommandArgs[0]
list2_file = CommandArgs[1]

print 'List 1 is ' + list1_file + ', list2 is ' + list2_file +'.'


f1 = open(list1_file, 'r')
list1 = f1.readlines()
f1.close()

unique_l1_entries = {}

for l1_entry in list1:
    entry = l1_entry.replace("\n","")
    if not unique_l1_entries.has_key( entry ):
        unique_l1_entries[entry] = 1

print 'there were ' + str( len( unique_l1_entries ) ) + ' entries in list 1.'

f2 = open(list2_file, 'r')
list2 = f2.readlines()
f2.close()

outlist = []

for l2_entry in list2:
    entry = l2_entry.replace("\n","")
    if not unique_l1_entries.has_key( entry ):
        outlist.append( l2_entry )

print "there are " + str( len(outlist) ) + " entries in list 2 that were not in list 1"

outf = open( "difflist",'w')
for entry in outlist:
    outf.write( entry )

outf.close()
