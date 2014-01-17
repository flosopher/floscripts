#!/usr/bin/perl

#script to read in two files and substract the column values in file2 from the one in file1. note the first column serves as the name 
#specifier of the line, i.e. it is used to identify corresponding lines
#


use strict;



#function: Padsp(InpString,len) adds spaces to the end of the input string until the desired length is reached
sub Padsp {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString=$InpString." ";
    }
    return $InpString;
}


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
  printf STDERR "usage: -f1 <file1> -f2 <file2 that is to be substracted from file1> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $File1 = -1;
my $File2 = -1;
my @DataList1 = ();
my @DataList2 = ();
my @DataMatrix1 = ();
my @DataMatrix2 = ();

my @ResultList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-f1'){$File1 = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-f2'){$File2 = $ARGV[$ii+1];}
}


my $NumList1 = 0;
my $NumList2 = 0;

open(INLIST, $File1) || die "Could not open $File1\n";
@DataList1 = <INLIST>;
close INLIST;
open(OUTLIST, $File2) || die "Could not open $File2\n";
@DataList2 = <OUTLIST>;
close OUTLIST;


$NumList1 = scalar @DataList1;
$NumList2 = scalar @DataList2;
my $NumStructsNotFound = 0;
my $NumComments1 = 0;
my $NumComments2 = 0;

my $longest = 0;

printf STDERR "%s lines in input list, %s lines in output list\n",$NumList1,$NumList2;

for (my $i = 0; $i < $NumList1; $i++) {
    if(substr($DataList1[$i],0,1) eq '#') {$NumComments1++; }
    else{
	my @tmparray = split(' ',$DataList1[$i]);
	#$tmparray[0] = substr($tmparray[0],0,-9);   #take away .pdb and rosetta code
	if(length $tmparray[0] > $longest) {$longest = length $tmparray[0];}
	push(@{$DataMatrix1[$i - $NumComments1]},@tmparray);
    }
}


for (my $i = 0; $i < $NumList2; $i++) {
    if(substr($DataList2[$i],0,1) eq '#') {$NumComments2++; }
    else{
	my @tmparray = split(' ',$DataList2[$i]);
	#$tmparray[0] = substr($tmparray[0],0,-9);   #take away .pdb and rosetta code
	push(@{$DataMatrix2[$i - $NumComments2]},@tmparray);
    }
}




for(my $ii = 0; $ii < $NumList1 - $NumComments1; $ii++){

    #my $LineFound = 0;

    for(my $jj = 0; $jj < $NumList2 - $NumComments2; $jj++){

#	if($LineFound

	if($DataMatrix1[$ii][0] eq $DataMatrix2[$jj][0]) { #we found the corresponding entry

	    my @tmpresultarray = ();
	    $tmpresultarray[0] = &Padsp($DataMatrix1[$ii][0],$longest);  #copy name
	    
	    for(my $kk = 1; $kk <= $#{@DataMatrix1[$ii]}; $kk++) {
		$tmpresultarray[$kk] = &spPad(sprintf("%.2f",$DataMatrix1[$ii][$kk] - $DataMatrix2[$jj][$kk]),6);
	    }
	    $ResultList[$ii] = join('  ',@tmpresultarray);
	    $ResultList[$ii] = $ResultList[$ii]."\n";

	    #$LineFound = 1;
	    last; #break loop
	}
    }
}

foreach my $item (@ResultList) {
    printf STDOUT $item;
}
#printf STDERR "A total of %s structures were not found in the output list.\n",$NumStructsNotFound;
    

