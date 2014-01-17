#!/usr/bin/perl

use strict;


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

my $design;
my $mode;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $mode = shift(@ARGV);
    }
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


my $COXcoord;
my $COYcoord;
my $COZcoord;


#printf STDERR "Starting script for ${design}\n";


#to be able to compare the distances between C and proton abstracting residue, the C coordinates have to be read in


my $CurDist;
my $ShortDist = 100;
my $CloseAtomName;
my $CloseAtomRes;
my $CloseAtomResNr;
my $pdbcheck = -1;


#printf STDERR "%f %f %f \n", $COXcoord, $COYcoord, $COZcoord;

#printf STDERR "Reading Product_score file ..\n";

open(INF1,"/work/flo/edesign/designs/kemp/${design}_stTS.pdb") || die "Can't open file\n";
my @dumpbuffer = split(' ',<INF1>);
while($dumpbuffer[0] ne "ATOM") {
    @dumpbuffer = split(' ',<INF1>);
}
my @chaintestarray = split(' ',<INF1>);
#printf STDOUT "%s\n", $chaintestarray[4];
if($chaintestarray[4] eq "A" or $chaintestarray[4] eq "B" or $chaintestarray[4] eq "C" or $chaintestarray[4] eq "L") { $pdbcheck = 0;}
#printf STDOUT "%s\n", $pdbcheck;

#to be able to compare the distances between C and proton abstracting residue, the C coordinates have to be read in

my $tempcoofileline= readpipe "grep HETATM /work/flo/edesign/designs/kemp/${design}_stTS.pdb | grep COO";
my @cooarray=split(' ', $tempcoofileline);
$COXcoord = $cooarray[6 + $pdbcheck];
$COYcoord = $cooarray[7 + $pdbcheck];
$COZcoord = $cooarray[8 + $pdbcheck];


while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  
  
  #the atom closest to the C atom has to be found
  if ($inline =~ /^ATOM/ ) {   

      my @linearray = split(' ', $inline);

      my $AtomChar = substr($linearray[2],0,1);

      if ( $linearray[3] eq "GLU" or $linearray[3] eq "ASP" or $linearray[3] eq "HIS") {    #make sure only base residues evaluated, some designs make this necessary
	  #printf STDERR "evaluating %s %f \n", $linearray[3], $linearray[5];
	  if ( $AtomChar ne "H" and $AtomChar ne "1" and $AtomChar ne "2" and $AtomChar ne "3"){  #make sure that only hetatms are compared
	  
      
	      $CurDist = &distance($COXcoord, $COYcoord, $COZcoord, $linearray[6 + $pdbcheck], $linearray[7 + $pdbcheck], $linearray[8 + $pdbcheck]);
      
	      if ($CurDist < $ShortDist) {
		  $ShortDist = $CurDist;
		  $CloseAtomName = $linearray[2];
		  $CloseAtomRes = $linearray[3];
		  $CloseAtomResNr = $linearray[5 + $pdbcheck];
		  #printf STDERR "atom found...\n";
	      }
	  }
  }
    
  }

#the atom should have been found

}

#printf STDERR "%s %f %s %.2f \n", $CloseAtomRes, $CloseAtomResNr, $CloseAtomName, $ShortDist;
if ($ShortDist == 100) {printf STDERR "Error: Base atom not identified\n %f\n", $ShortDist; exit 1;}
 

if($mode eq "cmd") {
    printf STDOUT "Arguments = sp 1pro _ -dock -use_input_sc -ligand -dock_mcm -nstruct 1500 -dock_pert 3.0 3.0 75 -ex1 -ex1aro -ex2 -output_input_pdb -l %slist.list -fa_input -fa_output -read_all_chains -try_both_his_tautomers -flo_exclude -fhid 6 -fresid %s -fatom %s\n", ${design},$CloseAtomResNr,$CloseAtomName;
}

else {

    if ($CloseAtomRes eq "ASP") {
	if($CloseAtomName eq "OD1") {
	    printf STDOUT "%s %s OD1 CG OD2", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "OD2") {
	    printf STDOUT "%s %s OD2 CG OD1", $CloseAtomRes, $CloseAtomResNr;
	}

    }

    if ($CloseAtomRes eq "GLU") {
	if($CloseAtomName eq "OE1") {
	    printf STDOUT "%s %s OE1 CD OE2", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "OE2") {
	    printf STDOUT "%s %s OE2 CD OE1", $CloseAtomRes, $CloseAtomResNr;
	}

    }

    if ($CloseAtomRes eq "HIS") {
	if($CloseAtomName eq "ND1") {
	    printf STDOUT "%s %s ND1 CG CE1", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "NE2") {
	    printf STDOUT "%s %s NE2 CD2 CE1", $CloseAtomRes, $CloseAtomResNr;
	}

    }
}
