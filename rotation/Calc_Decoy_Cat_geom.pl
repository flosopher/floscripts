#!/usr/bin/env perl

use Math::Complex;
use Math::Trig;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage


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


sub angle {     #here be the function to determine the angle between two vectors


    my $vect1_length = sqrt(($_[0] * $_[0])+($_[1] * $_[1])+($_[2] * $_[2]));
    my $vect2_length = sqrt(($_[3] * $_[3])+($_[4] * $_[4])+($_[5] * $_[5]));
    #printf STDERR "vect1length: %.2f, vect2length: %.2f\n",$vect1_length,$vect2_length;
    my $vect1_2_dot_product = $_[0] * $_[3] + $_[1] * $_[4] + $_[2] * $_[5];
    my $angle = acos($vect1_2_dot_product/($vect1_length * $vect2_length));

    my $degangle = $angle * 57.295779513;
    
    if ($_[6] == 1) {return $angle; }
    else { return $degangle; }

}



sub torsion {
    
    my $vect1_length = sqrt(($_[0] * $_[0])+($_[1] * $_[1])+($_[2] * $_[2]));
    my $vect_between_length = sqrt(($_[3] * $_[3])+($_[4] * $_[4])+($_[5] * $_[5]));
    my $vect2_length = sqrt(($_[6] * $_[6])+($_[7] * $_[7])+($_[8] * $_[8]));

    my $sin1_bet = sin(&angle($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],1));
    my $sinbet_2 = sin(&angle(-$_[3],-$_[4],-$_[5],$_[6],$_[7],$_[8],1));

    my @normal1 = &cross_product($_[0],$_[1],$_[2],$_[3],$_[4],$_[5]);
     
    $normal1[0] = $normal1[0] / ($vect1_length * $vect_between_length * $sin1_bet);
    $normal1[1] = $normal1[1] / ($vect1_length * $vect_between_length * $sin1_bet);
    $normal1[2] = $normal1[2] / ($vect1_length * $vect_between_length * $sin1_bet);
		  
    
    my @normal2 = &cross_product(-$_[3],-$_[4],-$_[5],$_[6],$_[7],$_[8]);

    #printf STDERR "\n\n";
    #printf STDERR "normal 2 components: %.2f %.2f %.2f \n", $normal2[0],$normal2[1],$normal2[2];
    #printf STDERR "vect2_length: %.2f \n",$vect2_length ;
    #printf STDERR "vectbetween_length: %.2f \n",$vect_between_length ;
    #printf STDERR "sin between 2 vectors: %.6f \n",$sinbet_2;

    $normal2[0] = $normal2[0] / ($vect2_length * $vect_between_length * $sinbet_2);
    $normal2[1] = $normal2[1] / ($vect2_length * $vect_between_length * $sinbet_2);
    $normal2[2] = $normal2[2] / ($vect2_length * $vect_between_length * $sinbet_2);

    #printf STDERR "normal 2 components: %.2f %.2f %.2f \n", $normal2[0],$normal2[1],$normal2[2];

    my $torsion = &angle($normal1[0],$normal1[1],$normal1[2],$normal2[0],$normal2[1],$normal2[2]);

    return $torsion;

}

sub cross_product {

    my @crossprod;
    $crossprod[0] = (($_[1] * $_[5]) - ($_[2] * $_[4]));
    $crossprod[1] = (($_[2] * $_[3]) - ($_[0] * $_[5]));
    $crossprod[2] = (($_[0] * $_[4]) - ($_[1] * $_[3]));

    return @crossprod;
}


my $design = 0;
my $decoy = 0;
my $BaseResNr = 0;
my $BaseResName = 0;
my $BaseAtom1Name = 0;
my $BaseAtom2Name = 0;
my $BaseAtom3Name = 0;
my $BaseAtom1Name_alt = 0;
my $BaseAtom2Name_alt = 0;
my $BaseAtom3Name_alt = 0;


my $DecLigE;
my $DecTotE;
my $start_reading = 0;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $decoy = shift(@ARGV);
    $BaseResName = shift(@ARGV);
    $BaseResNr = shift(@ARGV);
    $BaseAtom1Name = shift(@ARGV);
    $BaseAtom2Name = shift(@ARGV);
    $BaseAtom3Name = shift(@ARGV);
  }
}


if($BaseResName eq "GLU") {
    if($BaseAtom1Name eq "OE1") {
	$BaseAtom1Name_alt = "OE2";
	$BaseAtom2Name_alt = $BaseAtom2Name;
	$BaseAtom3Name_alt = "OE1";
    }
    elsif($BaseAtom1Name eq "OE2") {
	$BaseAtom1Name_alt = "OE1";
	$BaseAtom2Name_alt = $BaseAtom2Name;
	$BaseAtom3Name_alt = "OE2";
    }
}

elsif($BaseResName eq "ASP") {
    if($BaseAtom1Name eq "OD1") {
	$BaseAtom1Name_alt = "OD2";
	$BaseAtom2Name_alt = $BaseAtom2Name;
	$BaseAtom3Name_alt = "OD1";
    }
    elsif($BaseAtom1Name eq "OD2") {
	$BaseAtom1Name_alt = "OD1";
	$BaseAtom2Name_alt = $BaseAtom2Name;
	$BaseAtom3Name_alt = "OD2";
    }
}
elsif($BaseResName eq "HIS") {
    if($BaseAtom1Name eq "ND1") {
	$BaseAtom1Name_alt = "NE2";
	$BaseAtom2Name_alt = "CD2";
	$BaseAtom3Name_alt = "CE1";
    }
    elsif($BaseAtom1Name eq "NE2") {
	$BaseAtom1Name_alt = "ND1";
	$BaseAtom2Name_alt = "CG";
	$BaseAtom3Name_alt = "CE1";
    }
}

else{ printf STDERR "Error: Correct base is not given\n"; exit 1;}



#-----------first, get the coordinates of the two base atoms in the decoy------------#

my @hetbaseatom;
my @carbbaseatom1;
my @carbbaseatom2;

my @hetbaseatom_alt;
my @carbbaseatom1_alt;
my @carbbaseatom2_alt;


my $pdbcheck = -1;

open(INF1,"${decoy}") || die "Can't open file decoy file\n";

my @firstline = split(' ',<INF1>);
if ($firstline[4] eq 'A' or $firstline[4] eq 'B' or $firstline[4] eq 'C' or $firstline[4] eq 'L') {
    $pdbcheck = 0;
}

while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           
  if ($inline =~ /^ATOM/ ) {   

      my @linearray = split(' ', $inline);

      if ( $linearray[5 + $pdbcheck] == $BaseResNr) {
	  if ( $linearray[2] eq $BaseAtom1Name) { @hetbaseatom = @linearray;}
	  if ( $linearray[2] eq $BaseAtom2Name) { @carbbaseatom1 = @linearray;}
	  if ( $linearray[2] eq $BaseAtom3Name) {
	      @carbbaseatom2 = @linearray;
	      if($carbbaseatom2[3] ne $BaseResName) { 
		  printf STDERR "Error: Base Atoms and resname doesn't match.\n";
		  exit(1);
	      }
	  }
	  if ( $linearray[2] eq $BaseAtom1Name_alt) { @hetbaseatom_alt = @linearray;}
	  if ( $linearray[2] eq $BaseAtom2Name_alt) { @carbbaseatom1_alt = @linearray;}
	  if ( $linearray[2] eq $BaseAtom3Name_alt) { @carbbaseatom2_alt = @linearray;}
      
      }

     
  }
  
  elsif ($inline =~ /^CHARGE / ) {
      $start_reading =1;
      #printf STDERR "Setting start_reading true\n";
 } 
  elsif ( $inline =~ /^res aa/ ) {   #ask john how to recognize empty line
     $start_reading = 0;
     close(INF1);
     #printf STDERR "Setting start_reading false\n"
     }

  elsif ( $start_reading) {
      my @linearray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
      if ($linearray[0] eq "bk_tot:"){ $DecTotE = $linearray[1];}
      if ($linearray[0] eq "lig_sum:"){ $DecLigE = $linearray[1];}
  }
}



my @Hposarray;
my @Cposarray;

open(TS_Hfile,"${decoy}_TS_H.pdb") || die "TS H file can't be opened, fuck that\n";
#open(TS_Hfile,"temphetfile") || die "TS H file can't be opened, fuck that\n";
    while(<TS_Hfile>){
	chomp;
	my @linearray = split(' ',$_);
	#if($linearray[1] == 25 and $linearray[2] eq 'Hpol') {@Hposarray = @linearray; $Hposarray[6] = $linearray[5]; $Hposarray[7] = $linearray[6]; $Hposarray[8] = $linearray[7]; }
	
	#elsif($linearray[1] == 5 and $linearray[2] eq 'NH2O') {@Cposarray = @linearray; $Cposarray[6] = $linearray[5]; $Cposarray[7] = $linearray[6]; $Cposarray[8] = $linearray[7]}


	if($linearray[1] == 16 and $linearray[2] eq 'Hpol') {@Hposarray = @linearray;}
	elsif($linearray[1] == 6 and $linearray[2] eq 'COO') {@Cposarray = @linearray;}
    }
close(TS_Hfile);
#printf STDERR "${decoy} %s %.2f %.2f\n", $Cposarray[2], $Cposarray[6], $Hposarray[6];


#system "rm ${decoy}_TS_H.pdb";


#--------------------two sanity checks follow---------------------------#

if($Hposarray[1] != 16) {
    printf STDERR "Fock: H doesn't behave...\n";
    exit 1;
}

if($Cposarray[1] != 6) {
    printf STDERR "Fock: C doesn't behave...\n";
    exit 1;
}

#---------calculate the necessary vectors----------------#


my @C_to_H_vect;

my @H_to_OorN_vect;
my @H_to_OorN_vect_alt;

my @OorN_to_H_vect;
my @OorN_to_H_vect_alt;

my @Base_OorN_to_C1_vect;
my @Base_OorN_to_C1_vect_alt;

my @Base_C1_to_C2_vect;
my @Base_C1_to_C2_vect_alt;


$C_to_H_vect[0] = $Hposarray[6] - $Cposarray[6];
$C_to_H_vect[1] = $Hposarray[7] - $Cposarray[7];
$C_to_H_vect[2] = $Hposarray[8] - $Cposarray[8];

$H_to_OorN_vect[0] = $hetbaseatom[6 + $pdbcheck] - $Hposarray[6];
$H_to_OorN_vect[1] = $hetbaseatom[7 + $pdbcheck] - $Hposarray[7];
$H_to_OorN_vect[2] = $hetbaseatom[8 + $pdbcheck] - $Hposarray[8];
$H_to_OorN_vect_alt[0] = $hetbaseatom_alt[6 + $pdbcheck] - $Hposarray[6];
$H_to_OorN_vect_alt[1] = $hetbaseatom_alt[7 + $pdbcheck] - $Hposarray[7];
$H_to_OorN_vect_alt[2] = $hetbaseatom_alt[8 + $pdbcheck] - $Hposarray[8];

$OorN_to_H_vect[0] = -$H_to_OorN_vect[0];
$OorN_to_H_vect[1] = -$H_to_OorN_vect[1];
$OorN_to_H_vect[2] = -$H_to_OorN_vect[2];
$OorN_to_H_vect_alt[0] = -$H_to_OorN_vect_alt[0];
$OorN_to_H_vect_alt[1] = -$H_to_OorN_vect_alt[1];
$OorN_to_H_vect_alt[2] = -$H_to_OorN_vect_alt[2];


$Base_OorN_to_C1_vect[0] = $carbbaseatom1[6 + $pdbcheck] - $hetbaseatom[6 + $pdbcheck];
$Base_OorN_to_C1_vect[1] = $carbbaseatom1[7 + $pdbcheck] - $hetbaseatom[7 + $pdbcheck];
$Base_OorN_to_C1_vect[2] = $carbbaseatom1[8 + $pdbcheck] - $hetbaseatom[8 + $pdbcheck];
$Base_OorN_to_C1_vect_alt[0] = $carbbaseatom1_alt[6 + $pdbcheck] - $hetbaseatom_alt[6 + $pdbcheck];
$Base_OorN_to_C1_vect_alt[1] = $carbbaseatom1_alt[7 + $pdbcheck] - $hetbaseatom_alt[7 + $pdbcheck];
$Base_OorN_to_C1_vect_alt[2] = $carbbaseatom1_alt[8 + $pdbcheck] - $hetbaseatom_alt[8 + $pdbcheck];


$Base_C1_to_C2_vect[0] = $carbbaseatom2[6 + $pdbcheck] - $carbbaseatom1[6 + $pdbcheck];
$Base_C1_to_C2_vect[1] = $carbbaseatom2[7 + $pdbcheck] - $carbbaseatom1[7 + $pdbcheck];
$Base_C1_to_C2_vect[2] = $carbbaseatom2[8 + $pdbcheck] - $carbbaseatom1[8 + $pdbcheck]; 
$Base_C1_to_C2_vect_alt[0] = $carbbaseatom2_alt[6 + $pdbcheck] - $carbbaseatom1_alt[6 + $pdbcheck];
$Base_C1_to_C2_vect_alt[1] = $carbbaseatom2_alt[7 + $pdbcheck] - $carbbaseatom1_alt[7 + $pdbcheck];
$Base_C1_to_C2_vect_alt[2] = $carbbaseatom2_alt[8 + $pdbcheck] - $carbbaseatom1_alt[8 + $pdbcheck]; 

#--------now, geometry calculations are carried out-------------------#

#printf STDERR "hi ${decoy} %s %s %.2f %.2f\n", $carbbaseatom1[2], $carbbaseatom1[3], $carbbaseatom1[4],$carbbaseatom1[6 + $pdbcheck];

my $C_hetbase_dist = &distance($Cposarray[6], $Cposarray[7], $Cposarray[8], $hetbaseatom[6 + $pdbcheck], $hetbaseatom[7 + $pdbcheck], $hetbaseatom[8 + $pdbcheck]);
my $C_hetbase_dist_alt = &distance($Cposarray[6], $Cposarray[7], $Cposarray[8], $hetbaseatom_alt[6 + $pdbcheck], $hetbaseatom_alt[7 + $pdbcheck], $hetbaseatom_alt[8 + $pdbcheck]);

my $H_hetbase_dist = &distance($Hposarray[6], $Hposarray[7], $Hposarray[8], $hetbaseatom[6 + $pdbcheck], $hetbaseatom[7 + $pdbcheck], $hetbaseatom[8 + $pdbcheck]);
my $H_hetbase_dist_alt = &distance($Hposarray[6], $Hposarray[7], $Hposarray[8], $hetbaseatom_alt[6 + $pdbcheck], $hetbaseatom_alt[7 + $pdbcheck], $hetbaseatom_alt[8 + $pdbcheck]);

my $fucked_up_flag = 0;

if($H_hetbase_dist > $C_hetbase_dist) { $fucked_up_flag = 1;}

#printf STDERR "C dist is %.2f, Hdist is %.2f \n",$C_hetbase_dist, $H_hetbase_dist;

my $C_H_O_angle = &angle(-$C_to_H_vect[0],-$C_to_H_vect[1],-$C_to_H_vect[2],$H_to_OorN_vect[0],$H_to_OorN_vect[1],$H_to_OorN_vect[2]);
my $C_H_O_angle_alt = &angle(-$C_to_H_vect[0],-$C_to_H_vect[1],-$C_to_H_vect[2],$H_to_OorN_vect_alt[0],$H_to_OorN_vect_alt[1],$H_to_OorN_vect_alt[2]);

#printf STDERR "angle 1 calculated: %.2f\n", $C_H_O_angle;

my $H_O_hetcarb1_angle = &angle(-$H_to_OorN_vect[0],-$H_to_OorN_vect[1],-$H_to_OorN_vect[2],$Base_OorN_to_C1_vect[0],$Base_OorN_to_C1_vect[1],$Base_OorN_to_C1_vect[2]);
my $H_O_hetcarb1_angle_alt = &angle(-$H_to_OorN_vect_alt[0],-$H_to_OorN_vect_alt[1],-$H_to_OorN_vect_alt[2],$Base_OorN_to_C1_vect_alt[0],$Base_OorN_to_C1_vect_alt[1],$Base_OorN_to_C1_vect_alt[2]);

#printf STDERR "angle 2 calculated: %.2f\n", $H_O_hetcarb1_angle;

my $torsion_OorN_to_C1 = &torsion($Base_C1_to_C2_vect[0],$Base_C1_to_C2_vect[1],$Base_C1_to_C2_vect[2],-$Base_OorN_to_C1_vect[0],-$Base_OorN_to_C1_vect[1], -$Base_OorN_to_C1_vect[2],$OorN_to_H_vect[0],$OorN_to_H_vect[1],$OorN_to_H_vect[2]);
my $torsion_OorN_to_C1_alt = &torsion($Base_C1_to_C2_vect_alt[0],$Base_C1_to_C2_vect_alt[1],$Base_C1_to_C2_vect_alt[2],-$Base_OorN_to_C1_vect_alt[0],-$Base_OorN_to_C1_vect_alt[1], -$Base_OorN_to_C1_vect_alt[2],$OorN_to_H_vect_alt[0],$OorN_to_H_vect_alt[1],$OorN_to_H_vect_alt[2]);

#printf STDERR "torsion 3 calculated: %.2f...\n",$torsion_OorN_to_C1 ;

#----------now output everything---------------------#


printf STDOUT "${decoy} %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f\n",$DecLigE, $DecTotE, $C_hetbase_dist, $C_H_O_angle, $H_O_hetcarb1_angle,$torsion_OorN_to_C1, $C_hetbase_dist_alt, $C_H_O_angle_alt, $H_O_hetcarb1_angle_alt, $torsion_OorN_to_C1_alt; 
