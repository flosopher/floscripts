#!/usr/bin/perl


# script to read in all the files from a design run and delete those that have sequences that occur multiple times
# if a sequence occurs multiple times, the file with the lowest bk_tot is kept
# the script has to be called from a directory that contains the design files as well as a file that contains all the sequences 
# in fasta format
#
# Florian Richter, Baker lab, 06/2007
#


use strict;


## function: zPad(num,len) 
## pads the input number with leading zeros
## to return a string of the desired length
sub zPad {
    my $num=shift;
    my $newlen=shift;

    my $origlen=length($num);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$num="0".$num;
    }
    return $num;
}

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: totally easy \n";
  printf STDERR "\n";
  exit 1;
}

my @enzyme = ();
my $numenzymes = 0;

if($#ARGV== -1) {&usage();}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $enzyme[$numenzymes] = shift(@ARGV);
    $numenzymes++;
    }
}

my $weightfactor = 15;

for(my $i = 0; $i < $numenzymes; $i++){
    chdir("/work/flo/recap/oldruns/aug07_wlig1_5/$enzyme[${i}]/workruns/");

    for(my $m=1; $m <= 50; $m++) {
	my $string_m = &zPad($m,4);
	system "mv $enzyme[${i}]_des_wl${weightfactor}_${string_m}_0001.pdb $enzyme[${i}]_des_${string_m}.pdb";
	if($m < 31 ) { system "mv $enzyme[${i}]_des_useisc_wl${weightfactor}_${string_m}_0001.pdb $enzyme[${i}]_des_useisc_${string_m}.pdb";}
    }
}


		
	






