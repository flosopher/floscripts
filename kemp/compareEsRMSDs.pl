#!/usr/bin/perl 


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



my $design;
my $mode = 0;
my $calc_mode = 0;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $mode = shift(@ARGV);
    $calc_mode = shift(@ARGV);
    }
}
if (!$design) {printf STDERR "Please specify input file\n";
	       exit 1;
	   }

if ($calc_mode) {
    if ($calc_mode eq "COO" ) {
	printf STDERR "Substracting C repulsive energy from ligand energy and base energy...\n";
    }
}

my $CalcAtEnergies = 0;
$CalcAtEnergies = 1;

my $COXcoord;
my $COYcoord;
my $COZcoord;


printf STDERR "Starting script for ${design}\n";


#to be able to compare the distances between C and proton abstracting residue, the C coordinates have to be read in

system "grep HETATM ${design}_prod_score.pdb | grep COO > tempCOOfile";
open(COOFILE,"tempCOOfile") || die "Can't open COO file\n";
my $tempcoofileline=<COOFILE>;
chomp($tempcoofileline);
my @cooarray=split(' ', $tempcoofileline);
$COXcoord = $cooarray[5];
$COYcoord = $cooarray[6];
$COZcoord = $cooarray[7];
printf STDERR "COO coordinates: %f  %f  %f\n",$COXcoord, $COYcoord, $COZcoord;
close (COOFILE);
system "rm tempCOOfile";

my $CurDist;
my $ShortDist = 100;
my $CloseAtomName;
my $CloseAtomRes;
my $CloseAtomResNr;


my $reading_flag=0;
my $resume_reading =0;
my $pdbav_reading_flag =0;

my $BaseE_prodScore ={};
my $NhisE_prodScore ={};
my $LigE_prodScore ={};
my $COOE_prodScore ={};




my $Checkpoint1 = 0;


#first, read in prod_score file to get determine abstracting residue and get ligand energies

printf STDERR "Reading Product_score file ..\n";
open(INF1,"${design}_prod_score.pdb") || die "Can't open file\n";
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  
  
  #the atom closest to the C atom has to be found
  if ($inline =~ /^ATOM/ ) {   

      my @linearray = split(' ', $inline);

      my $AtomChar = substr($linearray[2],0,1);

      if ( $linearray[3] eq "GLU" or $linearray[3] eq "ASP" or $linearray[3] eq "HIS") {    #make sure only base residues evaluated, some designs make this necessary

	  if ( $AtomChar ne "H" and $AtomChar ne "1" and $AtomChar ne "2" and $AtomChar ne "3"){  #make sure that only hetatms are compared
	  
      
	      $CurDist = &distance($COXcoord, $COYcoord, $COZcoord, $linearray[5], $linearray[6], $linearray[7]);
      
	      if ($CurDist < $ShortDist) {
		  $ShortDist = $CurDist;
		  $CloseAtomName = $linearray[2];
		  $CloseAtomRes = $linearray[3];
		  $CloseAtomResNr = $linearray[4];
	      }
	  }
  }
      next;
  }

#the atom should have been found
if ($ShortDist == 100) {printf STDERR "Error: Base atom not identified\n %f\n", $ShortDist; exit 1;}
 

#the atom was found, so read in total lig energies, base energies, COO and Nhis energies from the prod_score file 

 # if ( $CalcAtEnergies ) {
  if ($inline =~ /^res aa / ) {
      $reading_flag =1;
      #printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^energies-average/ ) {   #ask john how to recognize empty line
     $reading_flag = 0;
     #printf STDERR "Setting start_reading false\n"
     }

  elsif ( $reading_flag) {
      my @atarray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
     
      if ($atarray[0] == $CloseAtomResNr and $atarray[1] eq $CloseAtomRes){
	  $BaseE_prodScore->{sysTotE} = $atarray[16];
	  $BaseE_prodScore->{sysRepE} = $atarray[3];
      }

      if ($atarray[1] eq "LG1") {
	  $LigE_prodScore->{TotE} = $atarray[16];
	  $LigE_prodScore->{RepE} = $atarray[3];
      }

      if ($atarray[0] eq "totals") {$Checkpoint1 = 1;} 

      if($Checkpoint1) {

	  if($atarray[1] eq "Nhis") {
	      $NhisE_prodScore->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $NhisE_prodScore->{RepE} = $atarray[3];
	  }

	  if($atarray[1] eq "COO") {
	      $COOE_prodScore->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $COOE_prodScore->{RepE} = $atarray[3];
	  }

      }
  }

  if ( $inline =~ /^res chain aa /) {
      $pdbav_reading_flag =1;
  }

  elsif ( $inline =~ /^actual-average(in pdb) energies per /) {
      $pdbav_reading_flag = 0;
  }

  elsif ( $pdbav_reading_flag ) {
      my @atarray = split(' ', $inline);
      if ( $atarray[0] == $CloseAtomResNr and $atarray[2] eq $CloseAtomRes) {
	  $BaseE_prodScore->{ELJpdbav} = $atarray[13];
	  $BaseE_prodScore->{SASApack} = $atarray[14];
	  $BaseE_prodScore->{sasaprob} = $atarray[16];
      }
  }
 
if ( $inline =~ /^res1 / ) {
    $resume_reading=1;
    #printf STDERR "Setting resume_reading true\n";
  } elsif ( $inline =~ /^SCORE/ ) {
    $resume_reading=0;
    #printf STDERR "Setting resume_reading false\n";
  } elsif ( $resume_reading ) {
      my @atarray=split(' ',$inline);
      #if ($atarray[1] == 50) {                                        #!!!!! manual modification done,50 should be $CloseAtomResN
      if ($atarray[1] == $CloseAtomResNr) {                          
	  $BaseE_prodScore->{TotE} = $atarray[5]/2;
	  $BaseE_prodScore->{RepE} = $atarray[7]/2;
	  #printf STDERR "hello, %f\n", $atarray[5];
	  #printf STDERR "fuck, %f\n",$BaseE_prodScore->{TotE}; 
      }
  }
}
close(INF1);
printf STDERR "Done reading prod_score files\n";
printf STDERR "%s of %s %s is close atom at %.2f angstrom\n",$CloseAtomName, $CloseAtomRes, $CloseAtomResNr, $ShortDist;

#--------------------------------------------- Second file-----------------------------------------------------------#
#block to read in stTS file, 

$Checkpoint1 = 0;
$reading_flag =0;
$resume_reading = 0;

my $BaseE_stTSScore ={};
my $NhisE_stTSScore ={};
my $LigE_stTSScore ={};
my $COOE_stTSScore ={};
my $stTS_COOdist= -5;


printf STDERR "Reading stTS file ..\n";
open(INF2,"${design}_stTS_score.pdb") || die "Can't open file\n";
while (<INF2>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  
  #the atom closest to the C atom has to be found
  if ($inline =~ /^ATOM / ) {   
      my @linearray = split(' ', $inline);

      if($linearray[3] eq $CloseAtomRes) {
	  if ($linearray[4] eq $CloseAtomResNr) {
	      if($linearray[2] eq $CloseAtomName) {
		  $stTS_COOdist = &distance($COXcoord, $COYcoord, $COZcoord, $linearray[5], $linearray[6], $linearray[7]);
		  #printf STDERR "in the loop, %f\n", $linearray[5];
	      }
	  }
     
      }
      next;
      
  }
# check if the distances are as they should be
  my $DistSenseCheck = abs($ShortDist - $stTS_COOdist);
  if($DistSenseCheck > 0.1){
      printf STDERR "Error: Prod_score and stTS files don't match for ${design}, distance Difference is %.2f, Base atom was identified to be %s %.0f %s\n",$DistSenseCheck, $CloseAtomRes, $CloseAtomResNr, $CloseAtomName;
      printf STDERR "in prod_score %.2f, in stTS %.2f\n", $ShortDist, $stTS_COOdist;
      exit 1;
  }

 

#distance was checked, so read in total lig energies, base energies, COO and Nhis energies from the stTS file 

 # if ( $CalcAtEnergies ) {
  if ($inline =~ /^res aa / ) {
      $reading_flag =1;
      #printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^energies-average/ ) {   #ask john how to recognize empty line
     $reading_flag = 0;
     #printf STDERR "Setting start_reading false\n"
     }

  elsif ( $reading_flag) {
      my @atarray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
     
      
       if ($atarray[0] == $CloseAtomResNr and $atarray[1] eq $CloseAtomRes){
	  $BaseE_stTSScore->{sysTotE} = $atarray[16];
	  $BaseE_stTSScore->{sysRepE} = $atarray[3];
      }

      if ($atarray[1] eq "LG1") {
	  $LigE_stTSScore->{TotE} = $atarray[16];
	  $LigE_stTSScore->{RepE} = $atarray[3];
      }

      if ($atarray[0] eq "totals") {$Checkpoint1 = 1;} 

      if($Checkpoint1) {

	  if($atarray[1] eq "Nhis") {
	      $NhisE_stTSScore->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $NhisE_stTSScore->{RepE} = $atarray[3];
	  }

	  if($atarray[1] eq "COO") {
	      $COOE_stTSScore->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $COOE_stTSScore->{RepE} = $atarray[3];
	  }

      }
  }

 if ( $inline =~ /^res chain aa /) {
      $pdbav_reading_flag =1;
  }

  elsif ( $inline =~ /^actual-average(in pdb) energies per /) {
      $pdbav_reading_flag = 0;
  }

  elsif ( $pdbav_reading_flag ) {
      my @atarray = split(' ', $inline);
      if ( $atarray[0] == $CloseAtomResNr and $atarray[2] eq $CloseAtomRes) {
	  $BaseE_stTSScore->{ELJpdbav} = $atarray[13];
	  $BaseE_stTSScore->{SASApack} = $atarray[14];
	  $BaseE_stTSScore->{sasaprob} = $atarray[16];
      }
  }

 
if ( $inline =~ /^res1 / ) {
    $resume_reading=1;
    #printf STDERR "Setting resume_reading true\n";
  } elsif ( $inline =~ /^SCORE/ ) {
    $resume_reading=0;
    #printf STDERR "Setting resume_reading false\n";
  } elsif ( $resume_reading ) {
      my @atarray=split(' ',$inline);
      #if ($atarray[1] == 50) {                                        #!!!!! manual modification done,50 should be $CloseAtomResN
      if ($atarray[1] == $CloseAtomResNr) {
	  $BaseE_stTSScore->{TotE} = $atarray[5]/2;
	  $BaseE_stTSScore->{RepE} = $atarray[7]/2;
      }
  }
}
close(INF2);
printf STDERR "Done reading stTS file\n";


#--------------------------block for 3rd file, prod_min, new distance needs to be calculated-----------------------------------------#

$Checkpoint1 = 0;
$reading_flag =0;
$resume_reading = 0;

my $BaseE_prodMin ={};
my $NhisE_prodMin ={};
my $LigE_prodMin ={};
my $COOE_prodMin ={};
my $ProdMin_COOdist;



system "grep HETATM ${design}_prod_min.pdb | grep COO > tempminCOOfile";
open (COOMINFILE, "tempminCOOfile") || die "Can't open COO file\n";
my $tempcoominfileline=<COOMINFILE>;
my @coominarray=split(' ', $tempcoominfileline);
my $COXminCoord = $coominarray[5];
my $COYminCoord = $coominarray[6];
my $COZminCoord = $coominarray[7];
#printf STDERR "COO coordinates: %f  %f  %f\n",$COXcoord, $COYcoord, $COZcoord;
close (COOMINFILE);
system "rm tempminCOOfile";



printf STDERR "Reading Prod_min file ..\n";
open(INF3,"${design}_prod_min.pdb") || die "Can't open file\n";
while (<INF3>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  
  #C atom energy-minimized distance is being calculated
  if ($inline =~ /^ATOM/ ) {   

      my @linearray = split(' ', $inline);

      if($linearray[3] eq $CloseAtomRes) {
	  if ($linearray[4] eq $CloseAtomResNr) {
	      if($linearray[2] eq $CloseAtomName) {
		  $ProdMin_COOdist = &distance($COXminCoord, $COYminCoord, $COZminCoord, $linearray[5], $linearray[6], $linearray[7]);
		  #printf STDERR "dist calculated to be %.2f to %s %s %s\n",$ProdMin_COOdist, $linearray[3], $linearray[4], $linearray[2];
	      }
	  }
     
      }
      next;
  }

   

#Emin distance was checked, so read in total lig energies, base energies, COO and Nhis energies from the prod_Min file 

 # if ( $CalcAtEnergies ) {
  if ($inline =~ /^res aa / ) {
      $reading_flag =1;
      #printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^energies-average/ ) {   #ask john how to recognize empty line
     $reading_flag = 0;
     #printf STDERR "Setting start_reading false\n"
     }

  elsif ( $reading_flag) {
      my @atarray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
     
      if ($atarray[0] == $CloseAtomResNr and $atarray[1] eq $CloseAtomRes){
	  $BaseE_prodMin->{sysTotE} = $atarray[16];
	  $BaseE_prodMin->{sysRepE} = $atarray[3];
      }


      if ($atarray[1] eq "LG1") {
	  $LigE_prodMin->{TotE} = $atarray[16];
	  $LigE_prodMin->{RepE} = $atarray[3];
      }

      if ($atarray[0] eq "totals") {$Checkpoint1 = 1;} 

      if($Checkpoint1) {

	  if($atarray[1] eq "Nhis") {
	      $NhisE_prodMin->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $NhisE_prodMin->{RepE} = $atarray[3];
	  }

	  if($atarray[1] eq "COO") {
	      $COOE_prodMin->{TotE} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
	      $COOE_prodMin->{RepE} = $atarray[3];
	  }

      }
  }
 


 if ( $inline =~ /^res chain aa /) {
      $pdbav_reading_flag =1;
  }

  elsif ( $inline =~ /^actual-average(in pdb) energies per /) {
      $pdbav_reading_flag = 0;
  }

  elsif ( $pdbav_reading_flag ) {
      my @atarray = split(' ', $inline);
      if ( $atarray[0] == $CloseAtomResNr and $atarray[2] eq $CloseAtomRes) {
	  $BaseE_prodMin->{ELJpdbav} = $atarray[13];
	  $BaseE_prodMin->{SASApack} = $atarray[14];
	  $BaseE_prodMin->{sasaprob} = $atarray[16];
      }
  }



if ( $inline =~ /^res1 / ) {
    $resume_reading=1;
    #printf STDERR "Setting resume_reading true\n";
  } elsif ( $inline =~ /^SCORE/ ) {
    $resume_reading=0;
    #printf STDERR "Setting resume_reading false\n";
  } elsif ( $resume_reading ) {
      my @atarray=split(' ',$inline);
      #if ($atarray[1] == 50) {                                        #!!!!! manual modification done,50 should be $CloseAtomResN
      if ($atarray[1] == $CloseAtomResNr) {
	  $BaseE_prodMin->{TotE} = $atarray[5]/2;
	  $BaseE_prodMin->{RepE} = $atarray[7]/2;
      }
  }
}
close(INF3);
printf STDERR "Done reading prod_min file\n";


#---------------------------------now calculate accessible surface area of base and ligand ------------------------------------#

system "/users/wollacott/py_scripts/tools/surface.py -p ${design}_stTS_score.pdb > sasatempfile";

my $Base_SASA_stTS = 0;
my $Lig_SASA_stTS = 0;
my $Carboxy_SASA_stTS =0 ;

open(SASAFILE, "sasatempfile") || die "No sasa file there :((((((((((((\n";

while(<SASAFILE>) {
    my $inline = $_;
    my @sasalinearray = split(' ',$inline);
    if($sasalinearray[2] == $CloseAtomResNr) {
	$Base_SASA_stTS = $Base_SASA_stTS + $sasalinearray[3];
	
	if($CloseAtomRes eq "ASP") {
	    if ($sasalinearray[0] eq "CG" or $sasalinearray[0] eq "OD1" or $sasalinearray[0] eq "OD2") { $Carboxy_SASA_stTS = $Carboxy_SASA_stTS + $sasalinearray[3]; }
	}
	
	elsif($CloseAtomRes eq "GLU") {
	    if ($sasalinearray[0] eq "CD" or $sasalinearray[0] eq "OE1" or $sasalinearray[0] eq "OE2") { 
		#printf STDERR "Carboxyatom added: %s %s %f %f\n",$sasalinearray[0],$sasalinearray[1],$sasalinearray[2],$sasalinearray[3];
		$Carboxy_SASA_stTS = $Carboxy_SASA_stTS + $sasalinearray[3]; }
	}

	elsif($CloseAtomRes eq "HIS"){
	    if ($sasalinearray[0] eq "CG" or $sasalinearray[0] eq "ND1" or $sasalinearray[0] eq "CD2" or  $sasalinearray[0] eq "CE1" or  $sasalinearray[0] eq "NE2") { 
		#printf STDERR "Carboxyatom added: %s %s %f %f\n",$sasalinearray[0],$sasalinearray[1],$sasalinearray[2],$sasalinearray[3];
		$Carboxy_SASA_stTS = $Carboxy_SASA_stTS + $sasalinearray[3]; }
	}
    
    }
    elsif($sasalinearray[1] eq "LG1") { $Lig_SASA_stTS = $Lig_SASA_stTS + $sasalinearray[3]; }

}

close(SASAFILE);
system "rm sasatempfile";



#-------------------------Done reading the 3 files, now calculate diffs, rmsd and write output----------------------------------#


#first get RMSD
system "/users/wollacott/py_scripts/tools/rms_cur.py -t ${design}_prod_score.pdb -p ${design}_prod_min.pdb -s HET > rmsdtempfile";
open(RMSFILE, "rmsdtempfile") || die "Can't open RMSD file\n";
my $temprmsdfileline=<RMSFILE>;
my @rmsarray=split(' ', $temprmsdfileline);
my $LigRMSD= $rmsarray[2];
close (RMSFILE);
system "rm rmsdtempfile";

#calculate diff in distance, lig energy, Nhis energy,

my $CdistDiff = abs($ShortDist - $ProdMin_COOdist);
my $LigTotDiff_st_prod =$LigE_prodScore->{TotE} - $LigE_stTSScore->{TotE};
my $LigTotDiff_prod_prodmin = $LigE_prodMin->{TotE} - $LigE_prodScore->{TotE};
my $BaseTotDiff_st_prod = $BaseE_prodScore->{TotE} - $BaseE_stTSScore->{TotE};
my $BaseTotDiff_prod_prodmin = $BaseE_prodMin->{TotE} - $BaseE_prodScore->{TotE}; 
my $BaseSysTotDiff_st_prod = $BaseE_prodScore->{sysTotE} - $BaseE_stTSScore->{sysTotE};
my $BaseSysTotDiff_prod_prodmin = $BaseE_prodMin->{sysTotE} - $BaseE_prodScore->{sysTotE};
my $BasePackDiff_st_prod = $BaseE_prodScore->{SASApack} - $BaseE_stTSScore->{SASApack};
my $BasePackDiff_prod_prodmin = $BaseE_prodMin->{SASApack} - $BaseE_prodScore->{SASApack};

#rmsd obtained, now write everything out

if(!$calc_mode){

if(!$mode) {

printf STDOUT "${design}   %.2f     %.2f        %.2f          %.2f     %.2f     %.2f        %.2f    %.2f        %.2f         %.2f  %.2f  %.2f\n", $LigE_prodScore->{TotE},$LigTotDiff_st_prod, $LigTotDiff_prod_prodmin,$LigRMSD, $ShortDist, $CdistDiff, $BaseE_prodScore->{TotE}, $BaseTotDiff_st_prod, $BaseTotDiff_prod_prodmin, $NhisE_prodScore->{TotE}, $NhisE_stTSScore->{TotE},$NhisE_prodMin->{TotE}; 
}

if ($mode eq "spreadsheet_out"){
    printf STDOUT "${design} %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f\n", $LigE_prodScore->{TotE},$LigTotDiff_st_prod, $LigTotDiff_prod_prodmin,$LigRMSD, $ShortDist, $CdistDiff, $BaseE_prodScore->{TotE}, $BaseTotDiff_st_prod, $BaseTotDiff_prod_prodmin, $NhisE_prodScore->{TotE}, $NhisE_stTSScore->{TotE},$NhisE_prodMin->{TotE}, $BaseE_prodScore->{sysTotE}, $BaseSysTotDiff_st_prod, $BaseSysTotDiff_prod_prodmin, $BaseE_stTSScore->{ELJpdbav}, $BaseE_stTSScore->{SASApack}, $BaseE_stTSScore->{sasaprob}, $BasePackDiff_st_prod, $BasePackDiff_prod_prodmin;
}

}

elsif($calc_mode) {
  

       my $corLigE_prodScore;
       my $corLigE_prodMin;
       my $corLigE_stTSScore;
       my $corBaseE_prodScore;
       my $corBaseE_prodMin;
       my $corBaseE_stTSScore;

       $corLigE_prodScore = $LigE_prodScore->{TotE} - $COOE_prodScore->{RepE};
       $corLigE_prodMin = $LigE_prodMin->{TotE} - $COOE_prodMin->{RepE};
       $corLigE_stTSScore = $LigE_stTSScore->{TotE} - $COOE_stTSScore->{RepE};

       $corBaseE_prodScore = $BaseE_prodScore->{TotE} - $COOE_prodScore->{RepE};
       $corBaseE_prodMin = $BaseE_prodMin->{TotE} - $COOE_prodMin->{RepE};
       $corBaseE_stTSScore = $BaseE_stTSScore->{TotE} - $COOE_stTSScore->{RepE};
       #printf STDERR "base tot TS e is %f\n", $BaseE_stTSScore->{TotE};

       my $DiffLigE_prodmin_tsscore = $corLigE_prodMin - $corLigE_stTSScore;
       my $DiffBaseE_prodmin_tsscore = $corBaseE_prodMin - $corBaseE_stTSScore;

       #if(!$mode) {

      # printf STDOUT "${design}   %.2f     %.2f        %.2f          %.2f     %.2f     %.2f        %.2f    %.2f        %.2f         %.2f  %.2f  %.2f\n", $LigE_prodScore->{TotE},$LigTotDiff_st_prod, $LigTotDiff_prod_prodmin,$LigRMSD, $ShortDist, $CdistDiff, $BaseE_prodScore->{TotE}, $BaseTotDiff_st_prod, $BaseTotDiff_prod_prodmin, $NhisE_prodScore->{TotE}, $NhisE_stTSScore->{TotE},$NhisE_prodMin->{TotE}; 
#};

   if ($mode eq "spreadsheet_out"){
       #printf STDERR "yuhaa, that's me\n";
    printf STDOUT "${design} %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f\n", $corLigE_stTSScore, $corLigE_prodScore,$corLigE_prodMin, $DiffLigE_prodmin_tsscore, $corBaseE_stTSScore, $corBaseE_prodScore, $corBaseE_prodMin, $DiffBaseE_prodmin_tsscore, $Lig_SASA_stTS, $Base_SASA_stTS, $Carboxy_SASA_stTS,
}
#$BaseE_prodScore->{TotE}
}



