#!/usr/bin/perl


# script to manually generate a resfile containing mutations specified in the input to this script
# 
#
# Florian Richter, Baker lab, 05/2007
#


use strict;


#function: spPad(InpString,len) adds spaces to the beginning of the input string until the desired length is reached
sub spPad {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString=" ".$InpString;
    }
    return $InpString;
}

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -numres <x> -pos <residue1lettername><position>\n";
  printf STDERR "usage: example -numres 150 -pos Y110 -pos S52 will place a TYR at position 110 and a Ser at position 52 in a protein containing 150 residues\n";
  printf STDERR "\n";
  exit 1;
}
my $ChangeCounter = 0;
my @PosList = ();
my $NumRes = -1;

if($#ARGV < 1){&usage; exit 1;} 

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-pos'){
	$PosList[$ChangeCounter][0]= (substr($ARGV[$ii+1],1))/1;
	$PosList[$ChangeCounter][1]= substr($ARGV[$ii+1],0,1);
	$ChangeCounter++;	
    }
    if ($ARGV[$ii] eq '-numres'){$NumRes = $ARGV[$ii+1];} 
    if ($ARGV[$ii] eq '-help'){&usage; exit 1;} 

}

if($NumRes == -1){&usage; exit 1;} 

#first sort the poslist
my @SortPosList = ();
if($ChangeCounter > 0 ){ @SortPosList = sort {$a->[0] <=> $b->[0] } @PosList;}


if($ChangeCounter > 0 ){
    if($SortPosList[$#SortPosList][0] > $NumRes){printf STDERR "Error, one mutation given not in range.\n"; exit 1;}
}


my @OutputLines = (" This file specifies which residues will be varied\n","\n"," Column   2:  Chain\n"," Column   4-7:  sequential residue number\n"," Column   9-12:  pdb residue number\n"," Column  14-18: id  (described below)\n"," Column  20-40: amino acids to be used\n","\n"," NATAA  => use native amino acid\n"," ALLAA  => all amino acids\n"," NATRO  => native amino acid and rotamer\n"," PIKAA  => select inividual amino acids\n"," POLAR  => polar amino acids\n"," APOLA  => apolar amino acids\n","\n"," The following demo lines are in the proper format\n","\n"," A    1    3 NATAA\n"," A    2    4 ALLAA\n"," A    3    6 NATAA\n"," A    4    7 NATAA\n"," B    5    1 PIKAA  DFLM\n"," B    6    2 PIKAA  HIL\n"," B    7    3 POLAR\n"," -------------------------------------------------\n"," start\n");

foreach my $item (@OutputLines){
    printf STDOUT $item;
}

for(my $ii = 1; $ii <= $NumRes; $ii++){
    
    if($ii == $SortPosList[0][0]){
	if($SortPosList[0][1] eq 'X') {printf STDOUT " A %s %s ALLAA   \n",&spPad($SortPosList[0][0],4),&spPad($SortPosList[0][0],4);}
	else {
	    printf STDOUT " A %s %s PIKAA  %s\n",&spPad($SortPosList[0][0],4),&spPad($SortPosList[0][0],4),$SortPosList[0][1];
	}
	shift(@SortPosList);
    }
    else{printf STDOUT " A %s %s NATRO   \n",&spPad($ii,4),&spPad($ii,4);}
}


