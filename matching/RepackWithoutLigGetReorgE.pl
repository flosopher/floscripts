#!/usr/bin/perl

#script to take out the ligand out of an input structure, repack the apo-structure and 
#then compare the bk_tot to the protein energy in the ligand bound structure 
#
#
#written by flo, dec 2007


use Math::Complex;

use strict;

my $CutOff1 = 6;
my $CutOff2 = 8;

my $RosettaExec = '~/rosetta/trunk_rosetta++/rosetta.mactel';
my $RosettaPaths = '~/rosetta/paths.txt';

sub AA_ThreeLetToOneLet {

    my $pass_aa = $_[0];
    
    if($pass_aa eq 'ALA') {return "A";}
    elsif($pass_aa eq 'CYS') {return "C";}
    elsif($pass_aa eq 'ASP') {return "D";}
    elsif($pass_aa eq 'GLU') {return "E";}
    elsif($pass_aa eq 'PHE') {return "F";}
    elsif($pass_aa eq 'GLY') {return "G";}
    elsif($pass_aa eq 'HIS') {return "H";}
    elsif($pass_aa eq 'ILE') {return "I";}
    elsif($pass_aa eq 'LYS') {return "K";}
    elsif($pass_aa eq 'LEU') {return "L";}
    elsif($pass_aa eq 'MET') {return "M";}
    elsif($pass_aa eq 'ASN') {return "N";}
    elsif($pass_aa eq 'PRO') {return "P";}
    elsif($pass_aa eq 'GLN') {return "Q";}
    elsif($pass_aa eq 'ARG') {return "R";}
    elsif($pass_aa eq 'SER') {return "S";}
    elsif($pass_aa eq 'THR') {return "T";}
    elsif($pass_aa eq 'VAL') {return "V";}
    elsif($pass_aa eq 'TRP') {return "W";}
    elsif($pass_aa eq 'TYR') {return "Y";}
    else{return "X";}
}

#function to substract two vectors, even if there is other information in the array: second vector will be substracted from first given vector
#!!ATTENTION: the vectors MUST have equal size, and the coordinates MUST be the first three elements of each vector
sub Substract3DVectors {
    my $VectSize = (scalar @_) / 2;
    my @ReturnVect = ();

    for(my $element = 0; $element < 3 ; $element++){
	$ReturnVect[$element] = $_[$element] - $_[$element + $VectSize];
	
    }
    
    return @ReturnVect;
}

sub VectorLength {
    my $SqSum = 0;
        
    foreach my $element (@_) { $SqSum = $SqSum + $element * $element;}
    return sqrt($SqSum);
    
}


sub ScaffoldName {

    my @ScaffoldList = ("1abe","1gca","1hsl","1wdn","2dri","1ey4","1fkj","1mbt","1oho","1rx8","1sjw","1tsn","1ank","1cbs","1dc9","1ifc","1lic","1nah","1sa8");
    my $CheckScaf = $_[0];
    
    foreach my $item (@ScaffoldList) {
	if($CheckScaf =~ m/$item/) { return $item;}
    }
    return 0;
}

sub ReadRosettaOutResidueEnergies {

    my @ResidueEnergies = ();
    my $ReadStruct = $_[0];


    open(STRUCT,$ReadStruct) || die "Error: could not find file $ReadStruct.\n"; 
    my $StructReadingFlag = 0;
    my $ResCounter = 0;
    my $NumResidues = 0;

    while(<STRUCT>) {
	my $inline = $_;

	if($inline =~ /totals/) { 
	  $StructReadingFlag = 0;
	  $NumResidues = $ResCounter;
	}
	if($inline =~ /avgtot/) {
	  $StructReadingFlag = 0;
	  if( (2*$NumResidues) != $ResCounter) {die "Fatal Error: $ReadStruct is corrupted. $NumResidues  $ResCounter \n";}
	}

	
	if($StructReadingFlag) {
	    #my @linearray = split(' ',$inline);
	    #if( ($linearray[1] eq 'LG1') || ($linearray[1] eq 'LG2') ) { next;}
	  if($inline =~ /LG/) {next;}
	  $ResCounter++;
	  #if($ResCounter != $linearray[0]) { die "Error: Residues in $ReadStruct are not continuous.\n";}
	  $ResidueEnergies[$ResCounter] = $inline;
	}
	
	if($inline =~ /res aa/) { $StructReadingFlag = 1;}
	if($inline =~ /res chain/) {$StructReadingFlag = 1;}
    }
    $ResidueEnergies[0]= $NumResidues;
    return @ResidueEnergies;

}

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -l <listfile of structures> or -s <struct> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 1) {&usage(); exit 1}


my $ECutOff = 0.9;
my $ListOption = 0;
my $ScafStruct = -1;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
}


my $NumStruct = 0;

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    #$Scaf = substr($ListFile,0,4);
    printf STDERR "Apo-repacking for list of structures $ListFile containing $NumStruct structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Apo-repacking single structure $SingStruct ..\n";
    $ListFile = $SingStruct;
}


#input read in, now analyze structures

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);

    my $CurStruct_nopdb;
    if( substr($CurStruct,-4,4) eq '.pdb') {$CurStruct_nopdb = substr($CurStruct,0,-4); }
    else {$CurStruct_nopdb = $CurStruct;}

    my $CurStruct_resfile = $CurStruct_nopdb.".resfile";
    my $CurStruct_aporepack = $CurStruct_nopdb."_AR";
    my $CurStruct_apopdb = $CurStruct_aporepack."_0001.pdb";
    #printf STDERR "$CurStruct_resfile ";
    #first we have to write the proper resfile
    my $resfile = readpipe "/Users/flo/scripts/genutils/MakeRepackAroundLigResfile.pl -s $CurStruct" ; #%s",$CurStruct_resfile;
    open(RESF,">$CurStruct_resfile");
    print RESF $resfile;
    close RESF;
    #get rid of the ligand
    system "grep -v HETATM $CurStruct | grep -v CHARGE > temp.pdb";
    #then score the structure without ligand
    system("$RosettaExec -pose1 -cst_mode -cst_score -s temp.pdb -pdbout tempscore -paths $RosettaPaths -overwrite > score_temp.out");
    #my $output1 = readpipe "$RosettaExec -pose1 -cst_mode -cst_score -s temp.pdb -pdbout tempscore -overwrite";
    #exec('%s -pose1 -cst_mode -cst_score -s temp.pdb -pdbout tempscore -overwrite > score_temp.out',$RosettaExec);
    #then do the repacking
    #printf STDERR "meeep \n";
    system("$RosettaExec -pose1 -cst_mode -cst_design -try_both_his_tautomers -ex1aro -ex2 -resfile $CurStruct_resfile -extrachi_cutoff 1.0 -s temp.pdb -overwrite -use_input_sc -cst_min -chi_move -nstruct 1 -paths $RosettaPaths -pdbout $CurStruct_aporepack > temp.out");
    
    #and now calculate the differences in energy
    #my @CurStructEnergies = &ReadRosettaOutResidueEnergies('tempscore.pdb');
    #my @CurStructApoEnergies = &ReadRosettaOutResidueEnergies($CurStruct_apopdb);
    printf STDERR "ho ";
    my $ScoreEstring = readpipe "grep bk_tot tempscore_0001.pdb";
    my @ScoreE = split(' ',$ScoreEstring);
    printf STDERR "ha $CurStruct_apopdb ";
    my $RepackEstring = readpipe "grep bk_tot $CurStruct_apopdb";
    printf STDERR "hi \n";
    my @RepackE = split(' ',$RepackEstring);

    my $ReorgE = $RepackE[1] - $ScoreE[1];

    printf STDOUT "$CurStruct $ScoreE[1]  $RepackE[1] $ReorgE \n";

    if(-e 'CHECKPOINT'){system 'rm CHECKPOINT';}

} #for numstruct loop


