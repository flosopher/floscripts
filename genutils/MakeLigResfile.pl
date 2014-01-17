#!/usr/bin/perl

#script to determine whether any backbone atoms in a structure are clashing with HETATMs 
#same line in the files of the two molecules


use Math::Complex;

use strict;

my $CutOff1 = 0;
my $CutOff2 = 0;
my $CutOff3 = 10;
my $CutOff4 = 10;
my $mini = 0;
my $force_chain = 0;

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



#funtion to add two 3dimensional vectors , even though there is other information in the array 
#!!ATTENTION: the vectors MUST have equal size, and the coordinates MUST be the first three elements of each vector
sub Add3DVectors {
    my $VectSize = (scalar @_) / 2;
    my @ReturnVect = ();

    for(my $element = 0; $element < 3; $element++){
	$ReturnVect[$element] = $_[$element] + $_[$element + $VectSize];
    }
    
    return @ReturnVect;
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
      for(my $ii = 0; $ii < $NumResidues; $ii++){
	$DesignMap->{$ii} = 0;#default value is 0, means no lig contact
      }
      $HetatmBlockReadingFlag = 1;
    }
    if( ($HetatmBlockReadingFlag == 1) && ($inline !~ /^HETATM/ ) ){
      $HetatmBlockReadingFlag = 0;
    }

    if($AtomBlockReadingFlag){
      if( substr($inline,12,4) eq ' CA ') {
	my $CurResType = &AA_ThreeLetToOneLet(substr($inline,17,3));
	my @CurAtResAndPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,$CurResType,(substr($inline,22,4))/1, (substr($inline,21,1)) );
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
	my @CurAtResAndPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,$CurResType,(substr($inline,22,4))/1, (substr($inline,21,1)));
	push(@Cbetas,[@CurAtResAndPos]);
      }
    }

    if($HetatmBlockReadingFlag && (substr($inline,12,1) ne 'V') && (substr($inline,12,1) ne 'H') && (substr($inline,12,2) ne ' H') && (substr($inline,13,1) ne 'X') ) {

      my @CurSubAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,substr($inline,7,9),'dummy1','dummy2' );

      for(my $ii = 0; $ii < $NumResidues; $ii++){
	
	if( $DesignMap->{$ii} == 1) { next; }   #residue is already being redesigned

	my $CurCaDist = &VectorLength(&Substract3DVectors(@CurSubAtPos,@{$Calphas[$ii]}));
	#printf STDERR "Ca dist for residue %s to hetatm %s is $CurCaDist. \n",$Calphas[$ii][4],$CurSubAtPos[3];

	if($CurCaDist <= $CutOff4) {
	  if($CurCaDist <= $CutOff3) {
	    if($CurCaDist <= $CutOff2) {
	      if($CurCaDist <= $CutOff1) { 
		$DesignMap->{$ii} = 1; #set to redesign
		next;
	      }  #if < cutoff 1
	      elsif($Calphas[$ii][3] ne 'G' ) {
		if($Calphas[$ii][4] != $Cbetas[$ii][4]) {die "Error: $ReadStruct atoms are corrupted. \n'";}
		my $CurCbDist = &VectorLength(&Substract3DVectors(@CurSubAtPos,@{$Cbetas[$ii]}));
		#printf STDERR "Cb dist for residue %s to hetatm %s is $CurCbDist. \n",$Cbetas[$ii][4],$CurSubAtPos[3];
		if($CurCbDist < $CurCaDist) { 
	    
		  $DesignMap->{$ii} = 1;  #set to redesign
		  #printf STDERR "res %s set to redesign based on cb < ca\n", $Calphas[$ii][4];
		  next;
		}
	      }#elsif not gly 
	      elsif($Calphas[$ii][3] eq 'G'){$DesignMap->{$ii} = 1; next;} #set to redesign
	      else{$DesignMap->{$ii} = 2; next; }#set to repacking

	      #push(@DesignPositions,[@ResInfo]);
	    } #if < cutoff 2
	    $DesignMap->{$ii} = 2;  #set to repacking
	    next;
	  } #if < cutoff 3
	  else{
	    if($Calphas[$ii][3] ne 'G'){
	      my $CurCbDist = &VectorLength(&Substract3DVectors(@CurSubAtPos,@{$Cbetas[$ii]}));
	      if($CurCbDist < $CurCaDist) { 
		$DesignMap->{$ii} = 2; 
		#printf STDERR "residue %s %s is < cut4 but cb closer to sub atom %s\n",$Calphas[$ii][3], $Calphas[$ii][4],$CurSubAtPos[3];
		next;
	      }  #set to repacking
	    }
	  }
	} #if < Cutoff 4
      } #for loop through residues
    } #if hetatm reading
  } #while struct

  #last loop to assemble necessary information
  my $no_chain_present = 0;
  if($Calphas[0][5] eq " "){$no_chain_present = 1;}
  for(my $ii = 0; $ii < $NumResidues; $ii++){
    if($force_chain && $no_chain_present){$Calphas[$ii][5] = "A";}
    my @ResInfo = ($Calphas[$ii][4],$Calphas[$ii][3],0,0,$Calphas[$ii][5]); #the two last zeros will be used later
    $ResInfo[2] = $DesignMap->{$ii};
    # deprecated line if( $DesignMap->{$ii} == 1){ $ResInfo[2] = 1;}
    push(@DesignPositions,[@ResInfo]);
  }

  #@DesignPositions = (sort {$a <=> $b} @DesignPositions);
  #$DesignPositions[$#DesignPositions+1] = $NumResidues;
  return @DesignPositions;

}

 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -c <distance cutoff, default is 10> -l <listfile of structures> or -s <struct> -pos <resnum> <mutations> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 1) {&usage(); exit 1}



my $ListOption = 0;
my $ListFile = -1;
my $SingStruct = -1;
my $CutOffSpecified = 0;
my @StructList = ();
my $ChangeCounter = 0;
my $NumLigands = 1;
my $NoLigPresent = 0;
my @PosList = ();
my $keep_native = 0;
my $backrub = 0;
my $py_output = 0;

my @OutputLines = (" This file specifies which residues will be varied\n","\n"," Column   2:  Chain\n"," Column   4-7:  sequential residue number\n"," Column   9-12:  pdb residue number\n"," Column  14-18: id  (described below)\n"," Column  20-40: amino acids to be used\n","\n"," NATAA  => use native amino acid\n"," ALLAA  => all amino acids\n"," NATRO  => native amino acid and rotamer\n"," PIKAA  => select inividual amino acids\n"," POLAR  => polar amino acids\n"," APOLA  => apolar amino acids\n","\n"," The following demo lines are in the proper format\n","\n"," A    1    3 NATAA\n"," A    2    4 ALLAA\n"," A    3    6 NATAA\n"," A    4    7 NATAA\n"," B    5    1 PIKAA  DFLM\n"," B    6    2 PIKAA  HIL\n"," B    7    3 POLAR\n"," -------------------------------------------------\n"," start\n");



for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-cut1'){
      $CutOffSpecified = 1;
      $CutOff1 = ($ARGV[$ii+1])/1;
    }
    if ($ARGV[$ii] eq '-cut2'){$CutOff2 = ($ARGV[$ii+1])/1;}
    if ($ARGV[$ii] eq '-cut3'){$CutOff3 = ($ARGV[$ii+1])/1;}
    if ($ARGV[$ii] eq '-cut4'){$CutOff4 = ($ARGV[$ii+1])/1;}
    if ($ARGV[$ii] eq '-backrub'){ $backrub = 1;}
    if ($ARGV[$ii] eq '-mini'){$mini = 1;}
    if ($ARGV[$ii] eq '-force_chain'){$force_chain = 1;}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-pos'){
	if( ( ($ARGV[$ii+1]/1) != $ARGV[$ii+1] ) || !$ARGV[$ii+2] || (substr($ARGV[$ii+2],0,1) eq '-')  ){
	    printf STDERR "Error, bad input for position.\n"; &usage(); exit 1;
	}
	$PosList[$ChangeCounter][0] = $PosList[$ChangeCounter][1] = 'X'; #guard against bad user input
	$PosList[$ChangeCounter][0] = ($ARGV[$ii+1])/1;
	$PosList[$ChangeCounter][1] = $ARGV[$ii+2];
		
	$ChangeCounter++;
    }
    if ($ARGV[$ii] eq '-nolig'){
	$NoLigPresent = 1;
	printf STDERR "Warning: -nolig option will set all amino acids to repacking.\n";
    }
    if ($ARGV[$ii] eq '-numlig'){$NumLigands = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-include_native'){$keep_native = 1;}
    if ($ARGV[$ii] eq '-pyout'){$py_output = 1;}
    if ($ARGV[$ii] eq '-help'){&usage(); exit 1;}
}


if($CutOff1 < 0){printf STDERR "Error: have to give a cutoff value bigger than 0\n"; &usage(); exit 1;}

my $NumStruct = 0;
my $Scaf = 'X';

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    $Scaf = substr($ListFile,0,4);
    printf STDERR "Writing resfile for list of structures $ListFile containing $NumStruct $Scaf structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Writing resfile for $SingStruct ..\n";
    $ListFile = $SingStruct;
}

#input read in, now analyze structures
if(!$mini){
  foreach my $item (@OutputLines){   #output generic lines of rosetta++ resfile
    printf STDOUT $item;
  }
}
else{
  printf STDOUT "\nNATRO\n\nstart\n"  #print default behaviour
}


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
  
    if(-e $CurStruct) {
	
      my @DesignPos = &DetermineDesignPositions($CurStruct);
	  #file read in
      my $NumResidues = scalar @DesignPos;

	#printf STDERR "%s backbone atoms, %s substrate atoms\n",$NumBBatoms,$NumHetAtoms;		
	
	for(my $bx = 0; $bx < $NumResidues; $bx++) {

	  #printf STDERR "info for bx $bx is %s %s %s %s\n",$DesignPos[$bx][0],$DesignPos[$bx][1],$DesignPos[$bx][2],$DesignPos[$bx][3];
	    my $CurResMutate = 0;
	    my $CurResidueLigContact = 0;
	    my $BackrubString = ' ';
	    my $ResidueString = 'NATRO';
	    
	    if($NoLigPresent || ($DesignPos[$bx][2] != 0)) { 
	      $CurResidueLigContact = 1;
	      if($DesignPos[$bx][2] == 1){$ResidueString = 'ALLAA';}
	      elsif($NoLigPresent || ($DesignPos[$bx][2] == 2)){$ResidueString = 'NATAA';}
	    }

	    if($backrub) {

	      if( !$CurResidueLigContact && ($DesignPos[$bx+1][2] != 0) && (( $DesignPos[$bx+2][2]!=0) || 
									    ($DesignPos[$bx+3][2]!=0) ) ) {
		$DesignPos[$bx][3] = 1;
	      }
	      if( !$CurResidueLigContact && (($DesignPos[$bx-1][2] != 0) || ($DesignPos[$bx+1][2] != 0)) && 
		  ($DesignPos[$bx-1][3] == 1) ) {
		$DesignPos[$bx][3] = 1;
	      }

	      if($CurResidueLigContact && ( ($DesignPos[$bx-1][2] != 0) || #prevent isolated ligcontact residues from backrubbing
					    ($DesignPos[$bx+1][2] != 0) || ($DesignPos[$bx-1][3] == 1) ) ) {
		$DesignPos[$bx][3] = 1;
	      }
	     
		 if($DesignPos[$bx][3] == 1) {$BackrubString = 'B';}
	    }

	    foreach my $changeres (@PosList) {
		if( ${@{$changeres}}[0] == $DesignPos[$bx][0]) {
		    $CurResMutate = 1;

		    if($mini){
		      printf STDOUT "%s %s PIKAA %s",&spPad($DesignPos[$bx][0],4),$DesignPos[$bx][4],${@{$changeres}}[1];
		    }
		    else{
		      printf STDOUT " %s %s %s PIKAA".$BackrubString." %s",$DesignPos[$bx][4],&spPad($DesignPos[$bx][0],4),&spPad($DesignPos[$bx][0],4),${@{$changeres}}[1];
		    }
		    if($keep_native) {printf STDOUT "%s", $DesignPos[$bx][1];}
		    printf STDOUT "\n";

		}
	    }

	    if($CurResMutate){ next;}

	    if($CurResidueLigContact || ($DesignPos[$bx][3] == 1)) {
	      if($mini){
		printf STDOUT "%s %s %s \n",&spPad($DesignPos[$bx][0],4),$DesignPos[$bx][4],$ResidueString;
	      }
	      else{
		printf STDOUT " %s %s %s %s".$BackrubString." \n",$DesignPos[$bx][4],&spPad($DesignPos[$bx][0],4),&spPad($DesignPos[$bx][0],4),$ResidueString;
	      }
	    }
	    elsif(!$mini) {printf STDOUT " %s %s %s NATRO  \n",$DesignPos[$bx][4],&spPad($DesignPos[$bx][0],4),&spPad($DesignPos[$bx][0],4);}
	    
	}  #for num residues
	#have to add line for ligand to resfile
	if(!$NoLigPresent && !$mini) {
	    my $FirstLigPos = $DesignPos[$NumResidues - 1][0] + 1;
	    for(my $ii = 0; $ii < $NumLigands; $ii++){
	      my $lig_chain = "X";
	      if($DesignPos[0][4] eq ' ') {$lig_chain = " ";}  #no chain information present
		printf STDOUT " %s %s %s NATRO   \n",$lig_chain,&spPad(($FirstLigPos+$ii),4),&spPad(($FirstLigPos+$ii),4);
	    }
	}
      if($py_output) {
	for(my $ii = 0; $ii < $NumResidues; $ii++) {
	  if($DesignPos[$ii][3] == 1) { printf STDERR "$DesignPos[$ii][0]+";}
	}
	printf STDERR "\n";
      }

    } #if -e $CurStruct
    else {printf STDERR "Could not find file $CurStruct. \n";}
    
}


