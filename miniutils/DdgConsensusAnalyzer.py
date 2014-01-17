#!/usr/bin/python


import sys
import re
import math

#function that returns takes a list of values and returns
#a tuple containing average and standard deviation
def ave_and_sd(values):
    num_values = len( values )
    ave = 0
    for value in values:
        ave = ave + value
    ave = ave / num_values

    SDsum = 0
    for value in values:
        element = value - ave
        SDsum = SDsum + (element * element)

    SD = math.sqrt(SDsum/num_values)

    return (ave,SD)

  

#class that saves the ddG and position conservation for
#every mutation a structure has, and can then be
#queried for how many forbidden mutations the structure
#has with certain cutoffs
class StructureMutations:

    def __init__(self, name, file_lines):
        self.mutations = []
        self.name = str(name)
        #print name

        for line in file_lines:
            tokens = line.split()
            if len(tokens) < 13:
                continue
            #print tokens
            if tokens[0] == "protocols.filters.ConservedPosMutationFilter:":
                if tokens[6] == "ala_ddg" and tokens[11] == "conservation":
                    self.mutations.append( [float(tokens[8]),float(tokens[12])] )
        #print "read lines with %s mutations" % len( self.mutations)


    def num_forbidden_mutations( self, ddg_cutoff, conserv_cutoff ):
        to_return = 0
        #print "getting queried with ddg of %.2f and conserv of %.2f" % ( ddg_cutoff, conserv_cutoff)
        #print self.mutations
        for mut in self.mutations:
            #print "ha"
            #print mut
            #print mut[0]
            #print mut[1]
            if (mut[0] > ddg_cutoff) and (mut[1] > conserv_cutoff ):
                to_return = to_return + 1

        return to_return

    def name( self ):
        return self.name

    def average_and_sd_mut_ddg( self ):
        ddgs = []
        for mut in self.mutations:
            ddgs.append( mut[0] )
        return ave_and_sd(ddgs)

    def average_and_sd_mut_conserv(self):
        conservs = []
        for mut in self.mutations:
            conservs.append( mut[1] )
        return ave_and_sd( conservs )


FileList = []
FileList2 = []
Listfile = ''
Listfile2 = ''
outfile = ""
listmode = 0

ddg_low = -2.0
ddg_high = 12.0
ddg_stepsize = 0.25

conserve_low = 0.0
conserve_high = 1.0
conserve_stepsize = 0.05
num_combos = 0

heatmapanal = 1
perdesign_avg_anal = 0

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
        listmode = 1
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-noheatmap':
        heatmapanal = 0
    elif arg == '-avg_per_design':
        perdesign_avg_anal = 1
    elif arg == '-l2':
        Listfile2 = CommandArgs[CommandArgs.index(arg)+1]


if not Listfile:
     print 'Error, please supply name of the listfile, the resfile and the template'
     sys.exit()

inlist = open(Listfile,'r')
FileList = inlist.readlines()
inlist.close()

if outfile == ' ':
    outfile = Listfile + '.ana'
    print "Checking structures for %s structures in %s to template %s" % (len(FileList), Listfile, template)


outstring = ""
structure_mutations = []

structure_mutations2 = []

for struct in FileList:

    infile = open(struct.replace("\n",""),'r')
    inlines = infile.readlines()
    infile.close
    structure_mutations.append( StructureMutations( struct.replace("\n",""), inlines) )
 
    #print mutstring
num_structs = len( structure_mutations )

if Listfile2 != "":
    inlist2 = open(Listfile2,'r')
    list2 = inlist2.readlines()
    inlist2.close()
    for struct in list2:
        infile = open(struct.replace("\n",""),'r')
        inlines = infile.readlines()
        infile.close
        structure_mutations2.append( StructureMutations(struct.replace("\n",""),inlines) )
    

if perdesign_avg_anal == 1:
    outstring = outstring + "name                  avg_ddg      sd_ddg         avg_conserv       sd_conserv \n"
    for struct in structure_mutations:
        ddg_ave = struct.average_and_sd_mut_ddg()
        conserv_ave = struct.average_and_sd_mut_conserv()
        outstring = outstring + struct.name + "          %.2f          %.2f             %.2f            %.2f\n" % ( ddg_ave[0], ddg_ave[1], conserv_ave[0],conserv_ave[1] )

ddg_cut = ddg_low
while ddg_cut <= ddg_high:

    conserve_cut = conserve_low

    while conserve_cut <= conserve_high:

        mutvalues = []
        for structmut in structure_mutations:
            mutvalues.append( float( structmut.num_forbidden_mutations(ddg_cut, conserve_cut) ) )
        ave_sd = ave_and_sd(mutvalues)

        num_combos = num_combos + 1
        ident = "combo_%s    " % num_combos
        if heatmapanal:
            outstring = outstring + ident + "%.2f      %.2f       %.2f     %.2f\n" % (ddg_cut, conserve_cut, ave_sd[0], ave_sd[1])

        conserve_cut = conserve_cut + conserve_stepsize

    outstring = outstring + "\n" #if the output is to be used to generate a gnuplot heatmap this line needs to be active
    ddg_cut = ddg_cut + ddg_stepsize
        
    #print outstring


if outfile == "":
    print outstring
    #print pymutstring

else:
    outf = open(outfile,'w')
    outf.write(outstring)
    outf.close()
