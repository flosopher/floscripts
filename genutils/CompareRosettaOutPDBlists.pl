#!/usr/bin/perl

#script to check whether for all files in list, there is a corresponding file in a second list. in the first list,
#the last 4 characters are chopped off the string, in the second list the last 8 are chopped off.
#all files that are not-found in the second list are put out


use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -o <listfile of output structures> -l <listfile of inputstructures> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $InListFile = -1;
my $OutListFile = -1;
my @InStructList = ();
my @OutStructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-o'){$OutListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$InListFile = $ARGV[$ii+1];}
    
}


my $NumInStruct = 0;
my $NumOutStruct = 0;

open(INLIST, $InListFile) || die "Could not open $InListFile\n";
@InStructList = <INLIST>;
close INLIST;
open(OUTLIST, $OutListFile) || die "Could not open $OutListFile\n";
@OutStructList = <OUTLIST>;
close OUTLIST;


$NumInStruct = scalar @InStructList;
$NumOutStruct = scalar @OutStructList;
my $NumStructsNotFound = 0;
printf STDERR "%s lines in input list, %s lines in output list\n",$NumInStruct,$NumOutStruct;

for(my $ii = 0; $ii < $NumInStruct; $ii++){
    
    my $CheckString;
    my $kk = 0;
    my $CurStructNotFound = 1;
    chomp($InStructList[$ii]);
    #printf STDERR "%s \n",substr($StructList[$ii],-4,4);
    #printf STDERR "%s \n",substr($StructList[$ii],0,-4);
    if(substr($InStructList[$ii],-4,4) eq '.pdb'){$CheckString = substr($InStructList[$ii],0,-4);}
    else {$CheckString = $InStructList[$ii];}

    while ($CurStructNotFound && ( $kk < $NumOutStruct)){
	chomp($OutStructList[$kk]);
	my $CompareString = substr($OutStructList[$kk],0,-9); #have to take away rosetta generated output code
	#printf STDOUT "compare string is %s, check string is %s\n",$CompareString, $CheckString;
	if($CheckString eq $CompareString) { $CurStructNotFound = 0;}
	$kk++;
    }


    if( $CurStructNotFound ){printf STDOUT $InStructList[$ii]."\n"; $NumStructsNotFound++;}
    
}
printf STDERR "A total of %s structures were not found in the output list.\n",$NumStructsNotFound;
    

