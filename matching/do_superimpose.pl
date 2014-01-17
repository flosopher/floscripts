#!/usr/bin/perl

use strict;

open (A, "$ARGV[0]"); #assumption: A is list file of matches
open (B, "$ARGV[1]"); #assumption: B is list file of ensemble members
my @lig = <B>;

while (<A>){
    chomp ($_);

    my @temptarget = readpipe "grep 'HETATM' $_";
    my $sanitytest = scalar @temptarget;
    if($sanitytest < 10 ){printf STDERR "$_ is corrupted\n"; next;}

    my @name1 = split(/.pdb/, $_);
#@direc = split(/match_/,$_);
    system "mkdir $name1[0]";
    
    for (my $j=0;$j<=$#lig;$j++){
	my @name2 = split (/.pdb/,$lig[$j]);
	my @more_spl = split (/\//,$name2[0]); #all directories are being split away
	my $name3 = $more_spl[$#more_spl];  #assumption: probably name3 is the number of the ensemble member

	my $name = $name1[0]."_".$name3.".pdb";  #assumption: create new name for match that contains the ensemble member
	system "rm -f $name $name*gz";
	chomp($lig[$j]);
#print $lig[$j];

	system "/arc/flo/scripts/matching/superimpose.pl $_ $lig[$j] $name";  #??? what is $_ in this context? must still be match file that will serve as target
#system "gzip $name";
	system "mv $name $name1[0]/";
	my $PathString = $name1[0].'/'.$name;
	system "echo $PathString >> ${ARGV[2]}_${ARGV[3]}_SubMatchPaths.txt";  #keep track of where everything is
    }
}
close A;
close B;

