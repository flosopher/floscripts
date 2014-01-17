#!/usr/bin/perl

#script to change the chirality of all the molecules in a pdb file

#written by flo, nov 2007


use Math::Complex;

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
  printf STDERR "usage:  -l <listfile of structures> or -s <struct> -axis <axis to negate> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 1) {&usage(); exit 1}


my $ListOption = 0;
my $ScafStruct = -1;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();
my $NegAxis = 'z';
my $CharOffset = 0;

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-axis'){$NegAxis = $ARGV[$ii+1];}
}


if( ($NegAxis ne 'x') && ($NegAxis ne 'y') && ($NegAxis ne 'z')){
    printf STDERR "Error: please give either x, y, or z as the axis to negate.\n";
    exit 1;
}
elsif($NegAxis eq 'x') { $CharOffset = 30; }
elsif($NegAxis eq 'y') { $CharOffset = 38; }
elsif($NegAxis eq 'z') { $CharOffset = 46; }



my $NumStruct = 0;

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    #$Scaf = substr($ListFile,0,4);
    printf STDERR "Changing non-catalytic sidechain coordiantes for list of structures $ListFile containing $NumStruct structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Changing non-catalytic sidechain coordinates for single structure $SingStruct ..\n";
    $ListFile = $SingStruct;
}


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
    open(STRUCT,$CurStruct) || die "Could not open $CurStruct.\n";
    my @CurFile = <STRUCT>;
    close STRUCT;

     my $NumFileLines = scalar @CurFile;

     for(my $ii = 0; $ii < $NumFileLines; $ii++){
	my $inline = $CurFile[$ii];

	if( ($inline =~ /^ATOM/) || ($inline =~ /^HETATM/)) { 
	    my $ChangeCoordinate = substr($inline,$CharOffset,8)/1; 
	    $ChangeCoordinate = $ChangeCoordinate * (-1);
	    substr($inline,$CharOffset,8) = &spPad(sprintf("%.3f",$ChangeCoordinate),8);
	    }
	printf STDOUT $inline;
    }
}



