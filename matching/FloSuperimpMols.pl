#!/usr/bin/perl

#script to superimpose a probe molecule onto a target molecule. 3 atoms have to be specified, these 3 atoms have to be in the 
#same line in the files of the two molecules


use Math::Complex;
use Math::Trig;


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

#function to calculate angle between three points, the coordinates have 
#to be passed x1,y1,z1,x2,y2,z2,x3,y3,z3, angle around atom 2 will be determined
#
#
sub angle_3points {   

    # CentAt is At2, i.e. the coordinates for Cent At are $_[3,4,5]
    my @CentAtToAt1_Vect = ();
    $CentAtToAt1_Vect[0] = $_[0] - $_[3];
    $CentAtToAt1_Vect[1] = $_[1] - $_[4];
    $CentAtToAt1_Vect[2] = $_[2] - $_[5];

    my @CentAtToAt3_Vect = ();
    $CentAtToAt3_Vect[0] = $_[6] - $_[3];
    $CentAtToAt3_Vect[1] = $_[7] - $_[4];
    $CentAtToAt3_Vect[2] = $_[8] - $_[5];


    my $CentAtToAt1_Vect_length = sqrt( ($CentAtToAt1_Vect[0] * $CentAtToAt1_Vect[0])+( $CentAtToAt1_Vect[1] * $CentAtToAt1_Vect[1]  )+($CentAtToAt1_Vect[2] * $CentAtToAt1_Vect[2]  ) );


    my $CentAtToAt3_Vect_length = sqrt( ($CentAtToAt3_Vect[0] * $CentAtToAt3_Vect[0])+( $CentAtToAt3_Vect[1] * $CentAtToAt3_Vect[1]  )+($CentAtToAt3_Vect[2] * $CentAtToAt3_Vect[2]  ) );

    #printf STDERR "vect1length: %.2f, vect2length: %.2f\n",$vect1_length,$vect2_length;
    my $vect1_2_dot_product = $CentAtToAt1_Vect[0] * $CentAtToAt3_Vect[0]  + $CentAtToAt1_Vect[1]*$CentAtToAt3_Vect[1] +$CentAtToAt1_Vect[2]  * $CentAtToAt3_Vect[2];
    if($CentAtToAt1_Vect_length == 0 || $CentAtToAt3_Vect_length == 0){ return 0;} #guard against bad input
    my $rad_angle = acos($vect1_2_dot_product/($CentAtToAt1_Vect_length * $CentAtToAt3_Vect_length));

    my $deg_angle = $rad_angle * 57.295779513;
    
    if ($_[9] == 1) {return $rad_angle; }
    else { return $deg_angle; }
}


#function to multiply a matrix with a vector. IMPORTANT: the dimensionality of the vector must be supplied to the function as the first, i.e. 0th argument,
#the second argument is the vector, and the third argument the matrix. 
#Naturally, the matrix must have the same number of columns as the vector elements/dimensions
sub MultMatWithVect {

    my @ReturnVect = ();
    my $NumRows = ((scalar @_) - $_[0] - 1) / $_[0];
 
    for(my $row = 0; $row < $NumRows; $row++){
	$ReturnVect[$row] = 0;
	for(my $col = 0; $col < $_[0]; $col++){
	    $ReturnVect[$row] = $ReturnVect[$row] + $_[$col+1] * $_[$_[0] + 1 + ($row * $_[0]) + $col];
	}
    }
    return @ReturnVect;
    
}

#function to multiply two square matrices with each other, the two matrices have to be passed in sequence
sub MultTwoSqMatMat {
    my @ReturnVect = ();
    my $NumElements = (scalar @_) / 2; #elements per matrix
    my $NumRows = sqrt ($NumElements);

    for(my $row = 0; $row < $NumRows; $row++) {
	for(my $col = 0; $col < $NumRows;) {

	    #work in progress

	}
    }
}

#function to normalize a vector
sub NormalizeVector {
    
    my $SqSum = 0;
    my @ReturnVect = @_;
    
    foreach my $element (@ReturnVect) { $SqSum = $SqSum + $element * $element;}
    my $vectlen = sqrt($SqSum);
    if($vectlen == 0){$vectlen = 1; printf STDERR "iarggh $ARGV[5] ;";} #guard against bad input
    foreach my $element (@ReturnVect) { $element = $element/$vectlen;}

    return @ReturnVect;
}

#function to set the length of a given vector, new length has to be the last argument passed to the function
sub SetLengthVector {
    my $SqSum = 0;
    my @ReturnVect = ();
    my $VectSize = (scalar @_) - 1;
    
    for(my $ii = 0; $ii < $VectSize; $ii++){ $SqSum = $SqSum + $_[$ii] * $_[$ii];}
    if($SqSum == 0){$SqSum = 1;} #guard against bad input
    my $lenfactor = $_[$VectSize] / sqrt($SqSum);
    for(my $ii = 0; $ii < $VectSize; $ii++){ $ReturnVect[$ii] = ($_[$ii] * $lenfactor);}

    return @ReturnVect;
}


#funtion to add two vectors
sub AddVectors {
    my $VectSize = (scalar @_) / 2;
    my @ReturnVect = ();

    for(my $element = 0; $element < $VectSize; $element++){
	$ReturnVect[$element] = $_[$element] + $_[$element + $VectSize];
    }
    
    return @ReturnVect;
}

#function to substract two vectors: second vector will be substracted from first given vector
sub SubstractVectors {
    my $VectSize = (scalar @_) / 2;
    my @ReturnVect = ();

    for(my $element = 0; $element < $VectSize; $element++){
	$ReturnVect[$element] = $_[$element] - $_[$element + $VectSize];
    }
    
    return @ReturnVect;
}

sub VectorLength {
    my $SqSum = 0;
        
    foreach my $element (@_) { $SqSum = $SqSum + $element * $element;}
    return sqrt($SqSum);
    
}
 

sub cross_product {

    my @crossprod;
    $crossprod[0] = (($_[1] * $_[5]) - ($_[2] * $_[4]));
    $crossprod[1] = (($_[2] * $_[3]) - ($_[0] * $_[5]));
    $crossprod[2] = (($_[0] * $_[4]) - ($_[1] * $_[3]));

    return @crossprod;
}



sub usage {
  printf STDERR "\n";
  printf STDERR "usage: <probe> <target> <line# at1> <line# at2> <line# at3>\n Note: the three atoms have to be on the same lines in the respective files";
  printf STDERR "\n";
  exit 1;
}

open (PROBEFILE, "$ARGV[0]") || die "Could not open Probefile\n"; 
open (TARGETFILE, "$ARGV[1]")|| die "Could not open Targetfile\n"; #assumption: B is list file of ensemble members
my @Probe = <PROBEFILE>;
my @Target = <TARGETFILE>;

close TARGETFILE;
close PROBEFILE;

if( ((scalar @Probe) < 3)  || ((scalar @Target) < 3) ) {
    printf STDERR "Error: $ARGV[0] or $ARGV[1] do not contain enough atoms to do superposition, aborting....\n";
    exit 1;
}

#first: get the coordinates of the relevant atoms in the target

my @At1Coords = ((substr($Target[$ARGV[2]-1],31,7))/1, (substr($Target[$ARGV[2]-1],39,7))/1, (substr($Target[$ARGV[2]-1],47,7))/1 );
my @At2Coords = ((substr($Target[$ARGV[3]-1],31,7))/1, (substr($Target[$ARGV[3]-1],39,7))/1, (substr($Target[$ARGV[3]-1],47,7))/1 );
my @At3Coords = ((substr($Target[$ARGV[4]-1],31,7))/1, (substr($Target[$ARGV[4]-1],39,7))/1, (substr($Target[$ARGV[4]-1],47,7))/1 );


#next: get the translation vector
my @ProbeAt1Coords = ((substr($Probe[$ARGV[2]-1],31,7))/1,(substr($Probe[$ARGV[2]-1],39,7))/1, (substr($Probe[$ARGV[2]-1],47,7))/1 );
my @ProbeAt2Coords = ((substr($Probe[$ARGV[3]-1],31,7))/1,(substr($Probe[$ARGV[3]-1],39,7))/1, (substr($Probe[$ARGV[3]-1],47,7))/1 );
my @ProbeAt3Coords = ((substr($Probe[$ARGV[4]-1],31,7))/1,(substr($Probe[$ARGV[4]-1],39,7))/1, (substr($Probe[$ARGV[4]-1],47,7))/1 );

#my @TransVect = ( $At1Coords[0] - $ProbeAt1Coords[0], $At1Coords[1] - $ProbeAt1Coords[1], $At1Coords[2] - $ProbeAt1Coords[2] );
my @TransVect = &SubstractVectors(@At1Coords,@ProbeAt1Coords);


#now get the first rotational vector/matrix, which is the cross product between the vectors Target:At1 -> Target:At2 and Probe:At1 -> Probe:At2
#my @TransAt2Coords = ( $ProbeAt2Coords[0] + $TransVect[0], $ProbeAt2Coords[1] + $TransVect[1], $ProbeAt2Coords[2] + $TransVect[2]);

my @TransAt2Coords = &AddVectors(@ProbeAt2Coords,@TransVect);

my @RotVect1 = &cross_product($TransAt2Coords[0] - $At1Coords[0], $TransAt2Coords[1] - $At1Coords[1], $TransAt2Coords[2] - $At1Coords[2],$At2Coords[0] - $At1Coords[0], $At2Coords[1] - $At1Coords[1], $At2Coords[2] - $At1Coords[2]);
@RotVect1 = &NormalizeVector(@RotVect1);

my $RotAng1 = &angle_3points($At2Coords[0],$At2Coords[1],$At2Coords[2],$At1Coords[0],$At1Coords[1],$At1Coords[2],$TransAt2Coords[0],$TransAt2Coords[1],$TransAt2Coords[2],1);

my @RotMat1 = ([cos($RotAng1) + ($RotVect1[0] * $RotVect1[0] * (1 - cos($RotAng1))),$RotVect1[0] * $RotVect1[1] * (1 - cos($RotAng1)) - $RotVect1[2] * sin($RotAng1), $RotVect1[0] * $RotVect1[2] * (1 - cos($RotAng1)) + $RotVect1[1] * sin($RotAng1)],
[$RotVect1[0] * $RotVect1[1] * (1 - cos($RotAng1)) + $RotVect1[2] * sin($RotAng1), cos($RotAng1) + $RotVect1[1] * $RotVect1[1] * (1 - cos($RotAng1)),$RotVect1[1] * $RotVect1[2] * (1 - cos($RotAng1)) - $RotVect1[0] * sin($RotAng1)],
[$RotVect1[0] * $RotVect1[2] * (1 - cos($RotAng1)) - $RotVect1[1] * sin($RotAng1), $RotVect1[1] * $RotVect1[2] * (1 - cos($RotAng1)) + $RotVect1[0] * sin($RotAng1),cos($RotAng1) + $RotVect1[2] * $RotVect1[2] * (1 - cos($RotAng1))]);

#first rotational matrix determined, now get second one.
#the rotation vector is the cross product between transrot at3 - projected at3 and at3 - projected at3, 
#the angle is between the transformed and rotated atom 3 and the probe atom 3
#printf STDERR " %s \n",cos($RotAng1) + ($RotVect1[0] * $RotVect1[0] * (1 - cos($RotAng1))); 
my @TransRotAt3Coords = &AddVectors(@ProbeAt3Coords,@TransVect);
my @At3VectToRot = &SubstractVectors(@TransRotAt3Coords,@At1Coords);
@At3VectToRot = &MultMatWithVect(3,@At3VectToRot, @{$RotMat1[0]},@{$RotMat1[1]},@{$RotMat1[2]});
@TransRotAt3Coords = &AddVectors(@At1Coords,@At3VectToRot);

my @At1At2Vect = &SubstractVectors(@At1Coords,@At2Coords);

#---now determine the angle by which to do the second rotation, takes a little bit of LinAlg----#

my $ProjectionAngle = &angle_3points(@TransRotAt3Coords,@At1Coords,@At2Coords,1);
if($ProjectionAngle > 1.570796327 ) {$ProjectionAngle = 3.141592653 - $ProjectionAngle;}  #angle has to be smaller than 90deg
my $At3At1Dist = &VectorLength(@At3VectToRot);
my $At3PrimeAt1Dist = $At3At1Dist * cos($ProjectionAngle);

my @At3PrimeAt1Vect = &SetLengthVector(@At1At2Vect,$At3PrimeAt1Dist);
my @At3PrimeCoords = (); 

if(&VectorLength(&SubstractVectors(@TransRotAt3Coords,@At2Coords)) < $At3At1Dist){ #if transrot At3 is closer to At2
    @At3PrimeCoords = &SubstractVectors(@At1Coords,@At3PrimeAt1Vect);
}
else{@At3PrimeCoords = &AddVectors(@At1Coords,@At3PrimeAt1Vect);} #transrot At3 was closer to At1

my $RotAng2 = &angle_3points(@TransRotAt3Coords,@At3PrimeCoords,@At3Coords,1);

my @RotVect2 = &cross_product($TransRotAt3Coords[0] - $At3PrimeCoords[0],$TransRotAt3Coords[1] - $At3PrimeCoords[1],$TransRotAt3Coords[2] - $At3PrimeCoords[2],$At3Coords[0] - $At3PrimeCoords[0],$At3Coords[1] - $At3PrimeCoords[1],$At3Coords[2] - $At3PrimeCoords[2]);
@RotVect2 = &NormalizeVector(@RotVect2);


#-------------------------angle determined ------------------

my @RotMat2 = ([cos($RotAng2) + ($RotVect2[0] * $RotVect2[0] * (1 - cos($RotAng2))),$RotVect2[0] * $RotVect2[1] * (1 - cos($RotAng2)) - $RotVect2[2] * sin($RotAng2), $RotVect2[0] * $RotVect2[2] * (1 - cos($RotAng2)) + $RotVect2[1] * sin($RotAng2)],
[$RotVect2[0] * $RotVect2[1] * (1 - cos($RotAng2)) + $RotVect2[2] * sin($RotAng2), cos($RotAng2) + $RotVect2[1] * $RotVect2[1] * (1 - cos($RotAng2)),$RotVect2[1] * $RotVect2[2] * (1 - cos($RotAng2)) - $RotVect2[0] * sin($RotAng2)],
[$RotVect2[0] * $RotVect2[2] * (1 - cos($RotAng2)) - $RotVect2[1] * sin($RotAng2), $RotVect2[1] * $RotVect2[2] * (1 - cos($RotAng2)) + $RotVect2[0] * sin($RotAng2),cos($RotAng2) + $RotVect2[2] * $RotVect2[2] * (1 - cos($RotAng2))]);



#rotational matrices determined, now transform the ligand
my @RotMat = @RotMat1;

#bugfixing
#my @RotMat = ([1,0,0],[0,1,0],[0,0,1]);


my $NumProbeAtoms = scalar @Probe;

for( my $ii = 0; $ii < $NumProbeAtoms; $ii++){
    my @NewAtCoords = ();
   
    #first translation
    $NewAtCoords[0] = (substr($Probe[$ii],31,7))/1 + $TransVect[0];
    $NewAtCoords[1] = (substr($Probe[$ii],39,7))/1 + $TransVect[1];
    $NewAtCoords[2] = (substr($Probe[$ii],47,7))/1 + $TransVect[2];

    #then rotation
   
    my @TmpVectToRot = &SubstractVectors(@NewAtCoords,@At1Coords);
    @TmpVectToRot = &MultMatWithVect(3,@TmpVectToRot, @{$RotMat[0]},@{$RotMat[1]},@{$RotMat[2]});
    @TmpVectToRot = &MultMatWithVect(3,@TmpVectToRot, @{$RotMat2[0]},@{$RotMat2[1]},@{$RotMat2[2]});
    @NewAtCoords = &AddVectors(@At1Coords,@TmpVectToRot);


    #now update coordinates
    substr($Probe[$ii],30,8) = &spPad(sprintf("%.3f",$NewAtCoords[0]),8);
    substr($Probe[$ii],38,8) = &spPad(sprintf("%.3f",$NewAtCoords[1]),8);
    substr($Probe[$ii],46,8) = &spPad(sprintf("%.3f",$NewAtCoords[2]),8);

    #output
    printf STDOUT $Probe[$ii];

}
#printf STDOUT "\n";
#my $TestAt = "HETATM    4 ND1  EST   900      -4.000   0.000   0.000  1.00 50.71";
#             HETATM    4 ND1  EST   900    0.000   -1.0000.0.0000 50.71
#my @RotVectCoords = &AddVectors(@At1Coords,@RotVect1);

#printf STDERR "rotvect coords: %s, %s, %s\n",@RotVectCoords;
#substr($TestAt,30,8) = &spPad(sprintf("%.3f",($At3PrimeCoords[0])),8);
#substr($TestAt,38,8) = &spPad(sprintf("%.3f",($At3PrimeCoords[1])),8);
#substr($TestAt,46,8) = &spPad(sprintf("%.3f",($At3PrimeCoords[2])),8);
#printf STDOUT $TestAt;
