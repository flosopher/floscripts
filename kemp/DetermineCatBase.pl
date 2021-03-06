#!/usr/bin/env perl


use Math::Complex;
use strict;     # vars must be declared before usage

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl design atomnumber of hetatm\n";
  printf STDERR "\n";
  exit 1;
}

sub distance {             #function to determine the distance between two atoms

    my $Xdist = $_[0] - $_[3];
    my $Ydist = $_[1] - $_[4];
    my $Zdist = $_[2] - $_[5];

    my $SqXdist = $Xdist * $Xdist;
    my $SqYdist = $Ydist * $Ydist;
    my $SqZdist = $Zdist * $Zdist;

    my $dist = sqrt($SqXdist + $SqYdist + $SqZdist);
    return $dist;
}



my $infile;
my $QueryAtom;
my $QAXcoord;
my $QAYcoord;
my $QAZcoord;
my $mode;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $infile = shift(@ARGV);
    $QueryAtom = shift(@ARGV);
    $mode = shift (@ARGV);
  }
}

&usage() if (! defined $infile);

printf STDERR "Starting program...\n";
printf STDERR "Query Atom is %s\n", $QueryAtom;

#first get the coordinates of the atom of interest

my $QAreached = 1;
my $QAname;
my $infil = substr($infile, 0, - 4);
open(INF2, "${infil}_fra.pdb") || die "Can't open $infile\n";

while (<INF2>) {
    chomp;
    my $template_line=$_;
    my @temparray = split(' ',$template_line);

    #printf STDERR "%s %s\n",$temparray[0],$temparray[1];

    if ($temparray[0] eq "HETATM") {
	#printf STDERR "Examining HETATM record %s\n",$temparray[1];

	if ($temparray[1] eq $QueryAtom) {
	    $QAXcoord = $temparray[6];
	    $QAYcoord = $temparray[7];
	    $QAZcoord = $temparray[8];
	    $QAname = $temparray[2];
	    $QAreached = 0;
	}
    }

}
close (INF2);

if ( $QAreached == 1){
    printf STDERR "Error: Query atom not found in file\n";
    exit 1;
}

my $CloseAtomName;
my $CloseAtomRes;
my $CloseAtomResNr;


my $CurAtomXCoord;
my $CurAtomYCoord;
my $CurAtomZCoord;
my $CurAtomID;
my $CurDist;
my $ShortDist = 100;
my $AtomChar;	

printf STDERR "Query Atom found: %s\n Xcoord is %.2f" , $QAname, $QAXcoord;

open(INF1,"$infile") || die "Can't open file $infile\n";
#my $start_reading=0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
    if ( $inline =~ /^ATOM / ) {
      my @linearray = split(' ', $inline);

      $AtomChar = substr($linearray[2],0,1);

      if ( $AtomChar ne "H" and $AtomChar ne "1" and $AtomChar ne "2" and $AtomChar ne "3"){  #make sure that only hetatms are compared
	  
      
      $CurDist = &distance($QAXcoord, $QAYcoord, $QAZcoord, $linearray[6], $linearray[7], $linearray[8]);
      
      if ($CurDist < $ShortDist) {
	  $ShortDist = $CurDist;
	  $CloseAtomName = $linearray[2];
	  $CloseAtomRes = $linearray[3];
	  $CloseAtomResNr = $linearray[5];

      }

  }
  }
   
} 

close(INF1);

#printf STDOUT "Closest Atom: %s %s %s, Distance is %f\n", $CloseAtomRes, $CloseAtomResNr, $CloseAtomName, $ShortDist;


#my @slist = ( sort { $b->{Ediff} <=> $a->{Ediff} } @enediffs );   # array is being sorted 

#foreach my $f ( @slist ) {
#    printf STDOUT "%s %f\n", $f->{resid}, $f->{Ediff};
#}

if (!$mode){
system "grep HEADER ".$infil.".pdb > ".$infil."_stTS.pdb";
system "echo REMARK BACKBONE TEMPLATE A $CloseAtomRes   $CloseAtomResNr MATCH MOTIF B $CloseAtomRes     3  2 >> ".$infil."_stTS.pdb";
system "grep ATOM ".$infil.".pdb >> ".$infil."_stTS.pdb";
system "echo TER >> ${infil}_stTS.pdb";
system "grep HETATM  ${infil}_fra.pdb >> ${infil}_stTS.pdb";
system "echo END >> ${infil}_stTS.pdb";
}

if ($mode == "prod") {
system "grep HEADER ".$infil.".pdb > ".$infil."_prod.pdb";
system "echo REMARK BACKBONE TEMPLATE A $CloseAtomRes   $CloseAtomResNr MATCH MOTIF B $CloseAtomRes     3  2 >> ".$infil."_prod.pdb";
system "grep ATOM ".$infil.".pdb >> ".$infil."_prod.pdb";
system "echo TER >> ${infil}_prod.pdb";
system "grep HETATM  ${infil}_fra.pdb >> ${infil}_prod.pdb";
system "echo END >> ${infil}_prod.pdb";


}
	
	
	

printf STDERR "Done!\n";


#while ( ($Kbuf, $Vbuf) = each %Ediffs) {
#    printf STDOUT  "%s %f\n", $Kbuf,$Vbuf;
#}

#sub hashValueDescendingNum {
#    $Ediffs{$b} <=> $Ediffs{$a};
#} 
 
#foreach $key (sort hashValueDescendingNum (keys(%Ediffs))) {
#    printf STDOUT "\t\t %f \t\t %s\n", $Ediffs{$key}, $key;
#}




