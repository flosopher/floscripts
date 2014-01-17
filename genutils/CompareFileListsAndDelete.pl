#!/usr/bin/perl

#script to check whether for all files in list, there is a corresponding file in a second list.
#any file that isn't found is deleted. at the end, a check for empty directories and deletion
#is done


use strict;

use File::Find;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -l <listfile of all structures> -o <listfile of structures not to be deleted> \n";
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

printf STDERR "%s lines in input list, %s lines in output list\n",$NumInStruct,$NumOutStruct;

my $NumDeleted = 0;

for(my $ii = 0; $ii < $NumInStruct; $ii++){
    
    my $kk = 0;
    chomp($InStructList[$ii]);
    #printf STDERR "%s \n",substr
    my $CurStructNotFound = 1;
    my @CurInStructArray = split(' ',$InStructList[$ii]);
    my $CurInStruct = $CurInStructArray[0];
    #printf STDERR "\n $CurInStruct ";

    while ($CurStructNotFound && ( $kk < $NumOutStruct)){
	chomp($OutStructList[$kk]);
	my @CurOutStructArray = split(' ',$OutStructList[$kk]);
	my $CurOutStruct = $CurOutStructArray[0];
	#printf STDERR " $CurOutStruct ";

	#printf STDOUT "compare string is %s, check string is %s\n",$CompareString, $CheckString;
	if($CurOutStruct eq $CurInStruct) {
	    #printf STDERR "\n $CurOutStruct \n check \n $CurInStruct \n";
	    $CurStructNotFound = 0;
	}
	$kk++;
    }


    if( $CurStructNotFound ){
	#printf STDOUT $CurInStruct."\n";
	system "rm $CurInStruct \n";
	$NumDeleted++;

    }
    
}
finddepth(sub{rmdir},'.'); #removes empty directories
printf STDERR "A total of %s structures were not found in the output list $OutListFile.\n",$NumDeleted;
    

