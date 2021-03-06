#!/usr/bin/perl

use strict;

if ($#ARGV<2){
print "USAGE: superimpose.pl <target> <probe> <output>\n";
exit(0);
}

my @het_probe;
if(-e $ARGV[1]){
    @het_probe = `grep 'HETATM' $ARGV[1]`; # used to be @het_probe = `grep 'HETATM' $ARGV[1]`, without the check for existence
}

my @old = @het_probe;

for (my $i=0;$i<=$#het_probe;$i++){
    $het_probe[$i] =~ s/LG1/EST/g;       #substituting ligand name
    $het_probe[$i] =~ s/  3   /900   /g; #substituting ligand residue number
}

system "rm -f to_superimpose";
open (G,">>to_superimpose");
print G $het_probe[0].$het_probe[1].$het_probe[9].$het_probe[18].$het_probe[19].$het_probe[22].$het_probe[23];
print G @old;
close G;
#system "~wollacott/py_scripts/tools/Superimpose.py -p to_superimpose -t $ARGV[0] -s 'resi=900' -o tmp.out";  #superposition happens
system "grep 'HETATM' $ARGV[0] > temptarget";
system "~/scripts/matching/FloSuperimpMols.pl to_superimpose temptarget 1 5 6 > tmp.out";
#------- let's hope this works
system "grep 'LG1' tmp.out > tmplg.pdb"; #
system "grep -v 'HETATM' $ARGV[0] | grep -v 'END' > tmp_cat.pdb";  #everything but HETATM and END lines of original match into one file
system "cat tmp_cat.pdb tmplg.pdb > $ARGV[2]";   #creating name file with original match -hetatm and superimposed lig
system "grep 'HETATM ' $ARGV[0] | grep ' V' >> $ARGV[2]"; #adding the virtual atoms to final file
#system "rm -f tmp* to_superimpose";
