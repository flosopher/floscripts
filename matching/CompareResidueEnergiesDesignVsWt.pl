#!/usr/bin/perl

#script to compare the residual energies of a given design to the energies of the 
#wildtype structure. all the residue numbers that have worse energies in the 
#design are reported
#
#written by flo, oct 2007


use Math::Complex;

use strict;

my $CutOff1 = 6;
my $CutOff2 = 8;

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


#function that returns an array containing all the residue positions that 
#have a Ca within CutOff1 of any ligand atom or a Ca within Cutoff2 and Cb
#closer to ligand than Ca
sub DetermineDesignPositions {

  my @DesignPositions = ();
  my @HetAtoms = ();
  my @Calphas = ();
  my @Cbetas = ();

  my $DesignMap={};

  my $ReadStruct = $_[0];
  my $ScafResidues = $_[1];


  open(STRUCT,$ReadStruct) || die "Error: could not find file $ReadStruct.\n"; 
  
  my $AtomBlockReadingFlag = 0;
  my $HetatmBlockReadingFlag = 0;
  my $NumResidues = 0;
  my $GlyCounter = 0;
  
  while(<STRUCT>) {

    my $inline = $_;
    if( ($AtomBlockReadingFlag == 0) && ($inline =~ /^ATOM/ ) ){
      $AtomBlockReadingFlag = 1;
    }
    if( ($AtomBlockReadingFlag == 1) && ($inline !~ /^ATOM/ ) ){
      $AtomBlockReadingFlag = 0;
    }
    if( ($HetatmBlockReadingFlag == 0) && ($inline =~ /^HETATM/ ) ){
      if($NumResidues != $ScafResidues) {die "Error: $ReadStruct does not have the right number of residues in the ATOM block.\n";}
      $HetatmBlockReadingFlag = 1;
    }
    if( ($HetatmBlockReadingFlag == 1) && ($inline !~ /^HETATM/ ) ){
      $HetatmBlockReadingFlag = 0;
    }

    if($AtomBlockReadingFlag){
      if( substr($inline,12,4) eq ' CA ') {
	my $CurResType = &AA_ThreeLetToOneLet(substr($inline,17,3));
	my @CurAtResAndPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,$CurResType,(substr($inline,22,4))/1 );
	push(@Calphas,[@CurAtResAndPos]);
	$NumResidues++;
	if($CurResType eq 'G') { 
	  $GlyCounter++;
	  my @DummyArray = (-1,-1,-1,'G',substr($inline,22,4)/1);
	  push(@Cbetas,[@DummyArray])
	}
      }

      if( substr($inline,12,4) eq ' CB ') {
	my $CurResType = &AA_ThreeLetToOneLet(substr($inline,17,3));
	my @CurAtResAndPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,$CurResType,(substr($inline,22,4))/1);
	push(@Cbetas,[@CurAtResAndPos]);
      }
    }

    if($HetatmBlockReadingFlag && (substr($inline,12,1) ne 'V') && (substr($inline,12,1) ne 'H')) {

      my @CurSubAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,substr($inline,7,9),'dummy' );

      for(my $ii = 0; $ii < $NumResidues; $ii++){

	if( $DesignMap->{$ii} == 1) { next; }

	my $CurCaDist = &VectorLength(&Substract3DVectors(@CurSubAtPos,@{$Calphas[$ii]}));

	if($CurCaDist <= $CutOff1) { 
	  push(@DesignPositions,$Calphas[$ii][4]);
	  $DesignMap->{$ii} = 1;
	}
	elsif($CurCaDist <= $CutOff2 && ($Calphas[3] ne 'G') ) {
	  if($Calphas[$ii][4] != $Cbetas[$ii][4]) {die "Error: $ReadStruct atoms are corrupted. \n'";}
	  my $CurCbDist = &VectorLength(&Substract3DVectors(@CurSubAtPos,@{$Cbetas[$ii]}));
	  #printf STDERR "Cb dist for residue %s to hetatm %s is $CurCbDist. \n",$Cbetas[$ii][4],$CurSubAtPos[3];
	  if($CurCbDist < $CurCaDist) { 
	    push(@DesignPositions,$Calphas[$ii][4]);
	    $DesignMap->{$ii} = 1;
	  }
	}#elsif ca < 
      } #for loop through residues
    } #if hetatm reading
  } #while struct

  @DesignPositions = (sort {$a <=> $b} @DesignPositions);
  return @DesignPositions;

}
 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -t <template scaffold> -l <listfile of structures> or -s <struct> -Ecut <energy cutoff, default 1.0> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $ECutOff = 0.9;
my $ListOption = 0;
my $ScafStruct = -1;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-Ecut'){$ECutOff = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-t'){$ScafStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-cut1'){$CutOff1 = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-cut2'){$CutOff2 = $ARGV[$ii+1];}
}

if($ECutOff <= 0){printf STDERR "Error: have to give a cutoff value bigger than 0\n"; &usage(); exit 1;}


my $NumStruct = 0;

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    #$Scaf = substr($ListFile,0,4);
    printf STDERR "Comparing residue energies for list of structures $ListFile containing $NumStruct structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Comparing residue energies for single structure $SingStruct ..\n";
    $ListFile = $SingStruct;
}


#input read in, now analyze structures

my @ScafEnergies = &ReadRosettaOutResidueEnergies($ScafStruct);
my $NumScafResidues = $ScafEnergies[0];



for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
    my @BadResidues = ();

    my @DesignPos = &DetermineDesignPositions($CurStruct,$NumScafResidues);
    printf STDERR "Design Positions of $CurStruct are ";
    foreach my $item (@DesignPos) {printf STDERR " $item";}
    printf STDERR "\n";

    my @CurStructEnergies = &ReadRosettaOutResidueEnergies($CurStruct);
    my $NumCurStructResidues = $CurStructEnergies[0];

    if($NumScafResidues != $NumCurStructResidues) {
	printf STDERR "Error: $CurStruct does not have the same number of residues as the scaffold, skipping... \n";
	printf STDOUT "Error: $CurStruct does not have the same number of residues as the scaffold, skipping... \n";
	next;
    }

    for(my $ii = 1; $ii <= $NumScafResidues; $ii++) {
      my @CurScafRes = split(' ',$ScafEnergies[$ii]);
      if($CurScafRes[0] == $DesignPos[0]) {
	shift(@DesignPos);
	next;
      }
      my @CurStructRes = split(' ',@CurStructEnergies[$ii]);
      if( $CurStructRes[1] ne $CurScafRes[1] ) { 
	next;
	#die "Fatal Error: $CurStruct is corrupted, unequal number of residues\n";
      }
      my $ResEDiff = $CurStructRes[17] - $CurScafRes[17];
      if($ResEDiff > $ECutOff) { push(@BadResidues,$ii);}
    }

    printf STDOUT "$CurStruct has violations at pos: ";
    foreach my $resi (@BadResidues) { printf STDOUT "$resi ";}
    printf STDOUT "\n";
}


