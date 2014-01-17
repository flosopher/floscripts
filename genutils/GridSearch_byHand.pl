#!/usr/bin/env perl

use Math::Complex;
use Math::Trig;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   give an input file and the number of the central grid atom and the script will generate a grid around these coordinates fulfilling some constraints !!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage




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


#general grid parameters
my @GridCenter = ();
my $GridSize = 9;
my $GridSpacing = 0.1;


sub distance {             #function to determine the distance between two atoms
    
    my $Xdist = $_[0] - $_[3];
    my $Ydist = $_[1] - $_[4];
    my $Zdist = $_[2] - $_[5];

    my $dist = $Xdist * $Xdist;
    $dist += $Ydist * $Ydist;
    $dist += $Zdist * $Zdist;

    $dist = sqrt($dist);
    return $dist;
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
    my $rad_angle = acos($vect1_2_dot_product/($CentAtToAt1_Vect_length * $CentAtToAt3_Vect_length));

    my $deg_angle = $rad_angle * 57.295779513;
    
    if ($_[9] == 1) {return $rad_angle; }
    else { return $deg_angle; }

		 

}


my $infile;
my $CenterAtNo;

#if($#ARGV < 1) {&usage();}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } 
  else {
      $infile = shift(@ARGV);
      $CenterAtNo = shift(@ARGV);
  }
}



#if( (! defined $GridCenter[0]) && (! defined $GridCenter[1]) && (! defined $GridCenter[2]) ) { &usage(); exit 1;}

#read infile
my @OwatCoords = (-0.041, -2.351, -0.526);
my @OlgCoords = (-0.152, -0.228, 0.247);
my @OwatCarbCoords =  (0.824, -1.204, 0.897);
my @OlgCarbCoords = (0.676, -1.692, 0.569);
my @OlgCarb2Coords = (0.349, 0.751, -0.466);
@GridCenter = (0.75, -1.5, 0.6);


#open(INF,$infile);
#my $infileline;

#while($infileline=<INF>){
#    chomp;
#    my @linearray = split(' ',$infileline);
#    if ($linearray[1] == 9  ) {
#	$OlgCoords[0] = $linearray[5];
#	$OlgCoords[1] = $linearray[6];
#	$OlgCoords[2] = $linearray[7];
#    }
#    elsif($linearray[1] == 6  ) {
#	$OwatCoords[0] = $linearray[5];
#	$OwatCoords[1] = $linearray[6];
#	$OwatCoords[2] = $linearray[7];
#    }
#    elsif($linearray[1] == $CenterAtNo  ) {
#	$GridCenter[0] = $linearray[5];
#	$GridCenter[1] = $linearray[6];
#	$GridCenter[2] = $linearray[7];
#    }
#
#}
#    close INF;

my $NumGridPoints = ($GridSize / $GridSpacing) * ($GridSize / $GridSpacing) * ($GridSize / $GridSpacing);

printf STDERR "Grid Center is at x = %s, y = %s, z = %s.\n",$GridCenter[0],$GridCenter[1],$GridCenter[2];
printf STDERR "GridSize is %s, GridSpacing is %s; %s Grid Points will be evaluated.\n",$GridSize,$GridSpacing,$NumGridPoints;

my $GridXLowerBound = $GridCenter[0] - ($GridSize / 2 );
my $GridXUpperBound = $GridCenter[0] + ($GridSize / 2 );

my $GridYLowerBound = $GridCenter[1] - ($GridSize / 2 );
my $GridYUpperBound = $GridCenter[1] + ($GridSize / 2 );

my $GridZLowerBound = $GridCenter[2] - ($GridSize / 2 );
my $GridZUpperBound = $GridCenter[2] + ($GridSize / 2 );

printf STDERR "Input file read in,grid bounds are (%s,%s) for x, (%s,%s) for y, (%s,%s) for z.\n",$GridXLowerBound,$GridXUpperBound,$GridYLowerBound,$GridYUpperBound,$GridZLowerBound,$GridZUpperBound;


#coordinates read, now calculate grid points that fulfill constraints
my @AllowedPoints = ();
my $numpoints = 0;

for(my $xx = $GridXLowerBound;$xx <= $GridXUpperBound; $xx += $GridSpacing) {
    
    for(my $yy = $GridYLowerBound; $yy <= $GridYUpperBound; $yy += $GridSpacing) {

	for(my $zz = $GridZLowerBound; $zz <= $GridZUpperBound; $zz += $GridSpacing) {

	    my $CurOwatDist = &distance($xx, $yy, $zz, $OwatCoords[0], $OwatCoords[1], $OwatCoords[2]);
	  #  if($CurOwatDist <= 1.65 && $CurOwatDist >= 1.35 ) {
	    #if($CurOwatDist => 0.1) { #line to exclude distance


		my $CurOlgDist = &distance($xx, $yy, $zz, $OlgCoords[0], $OlgCoords[1], $OlgCoords[2]);
		if($CurOlgDist <= 1.9 && $CurOlgDist >= 1.4 ) {
	        #if($CurOlgDist => 0.1 ) { #line to exclude distance

		    my $CurOwatAng = &angle_3points($OwatCarbCoords[0], $OwatCarbCoords[1], $OwatCarbCoords[2], $OwatCoords[0], $OwatCoords[1], $OwatCoords[2], $xx, $yy, $zz);
		#    if($CurOwatAng <= 120 && $CurOwatAng >= 100 ) {

			my $CurOlgAng = &angle_3points($OlgCarbCoords[0], $OlgCarbCoords[1], $OlgCarbCoords[2], $OlgCoords[0], $OlgCoords[1], $OlgCoords[2], $xx, $yy, $zz);
		        my $CurOlgAng2 = &angle_3points($OlgCarb2Coords[0], $OlgCarb2Coords[1], $OlgCarb2Coords[2], $OlgCoords[0], $OlgCoords[1], $OlgCoords[2], $xx, $yy, $zz);
			if($CurOlgAng <= 120 && $CurOlgAng >= 90 ) {
			    if($CurOlgAng2 <= 125 && $CurOlgAng2 >= 100 ) {

			     my $CurPoint = {};
			     $CurPoint->{xcoord} = $xx;
			     $CurPoint->{ycoord} = $yy;
			     $CurPoint->{zcoord} = $zz;

			 

#	    if($xx == -3.224 && $yy == -5.242 && $zz == -3.558) {
#		printf STDERR " $CurOwatDist $CurOwatAng $CurOlgDist $CurOlgAng \n";}
			     
			     push(@AllowedPoints,$CurPoint)
		#	     }
			     }
		     }
		# }
	    }
	    #debugblock
	    #debugblock end
	    $numpoints++;
	    if ($numpoints % ($NumGridPoints / 20)  == 0) { printf STDERR "%s points generated, x = %.4f...\n",$numpoints, $xx;}
	}
    }
}

#allowed points have been determined, now output

printf STDOUT "HEADER  grid points that fullfill constraints \n";
printf STDOUT "HEADER  as set in script GridSearchWithConstraints.pl\n";

my $pointnum = 9;


open(COORFILE,'mod_tsoh_sup.pdb');
while(my $fileline = <COORFILE>) {
    printf STDOUT "$fileline";
}
close COORFILE;

foreach my $point (@AllowedPoints ) {

    printf STDOUT "HETATM%s  gp  GRD X   3     ",&spPad($pointnum,5); 
    my $CurXCoord = sprintf("%.3f", $point->{xcoord});
    my $CurYCoord = sprintf("%.3f",$point->{ycoord});
    my $CurZCoord = sprintf("%.3f",$point->{zcoord});

    #printf STDOUT "%.3f %.3f %.3f",&spPad($CurXCoord,7),&spPad($CurYCoord,7),&spPad($CurZCoord,7);
    printf STDOUT "%s %s %s",&spPad($CurXCoord,7),&spPad($CurYCoord,7),&spPad($CurZCoord,7);
    printf STDOUT"  1.00 10.00            X\n";
    $pointnum++;
}

#open(COORFILE,'mod_tslg_sup.pdb');
#while(my $fileline = <COORFILE>) {
 #   printf STDOUT "$fileline";
#}
#close COORFILE;
