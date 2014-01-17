#!/usr/bin/perl

#script to determine whether any backbone atoms in a structure are clashing with HETATMs 
#same line in the files of the two molecules


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
 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -c <distance cutoff, default is 10> -l <listfile of structures> or -s <struct> -pos <resnum> <mutations> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 1) {&usage(); exit 1}


my $CutOff = 10;
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

my @OutputLines = (" This file specifies which residues will be varied\n","\n"," Column   2:  Chain\n"," Column   4-7:  sequential residue number\n"," Column   9-12:  pdb residue number\n"," Column  14-18: id  (described below)\n"," Column  20-40: amino acids to be used\n","\n"," NATAA  => use native amino acid\n"," ALLAA  => all amino acids\n"," NATRO  => native amino acid and rotamer\n"," PIKAA  => select inividual amino acids\n"," POLAR  => polar amino acids\n"," APOLA  => apolar amino acids\n","\n"," The following demo lines are in the proper format\n","\n"," A    1    3 NATAA\n"," A    2    4 ALLAA\n"," A    3    6 NATAA\n"," A    4    7 NATAA\n"," B    5    1 PIKAA  DFLM\n"," B    6    2 PIKAA  HIL\n"," B    7    3 POLAR\n"," -------------------------------------------------\n"," start\n");



for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-c'){
      $CutOffSpecified = 1;
      $CutOff = $ARGV[$ii+1];
    }
    if ($ARGV[$ii] eq '-backrub'){ $backrub = 1;}
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
    if ($ARGV[$ii] eq '-help'){&usage(); exit 1;}
}


if($CutOff <= 0){printf STDERR "Error: have to give a cutoff value bigger than 0\n"; &usage(); exit 1;}

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

my @ResidueCalphas = ();
my @NoClashStructs = ();

foreach my $item (@OutputLines){   #output generic lines of resfile
    printf STDOUT $item;
}


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
    
    my $AtomBlockReadingFlag = 0;
    my $StartRes;
    my $CurRes;

     my @HetAtoms = ();
    
    if(-e $CurStruct) {
	open(CURFILE, $CurStruct);

	while(<CURFILE>) {
	    my $inline = $_;
	    if($AtomBlockReadingFlag == 0 && $inline =~ /^ATOM/) {
		$AtomBlockReadingFlag = 1;
		$StartRes = substr($inline,22,4)/1;
		$CurRes = $StartRes;
	    }	
    
	    
	    if(($inline =~ /^ATOM/ )){
		my $CurAt = substr($inline,12,4);
		if( $CurAt eq ' CA ' ) {
		    my $CurResType = &AA_ThreeLetToOneLet(substr($inline,17,3));
		    my @CurAtResAndPos = ((substr($inline,22,4))/1,(substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,$CurResType  );
		    push(@ResidueCalphas,[@CurAtResAndPos]);
		   
		}
		
	    }

	    if( ($inline =~ /^HETATM/ ) && (substr($inline,12,1) ne 'V') && (substr($inline,12,1) ne 'H') ) {   #don't count virtual atoms or H
		my @CurSubAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,substr($inline,7,9) );
		push(@HetAtoms,[@CurSubAtPos]);
	    }

	    if($inline =~ /^END/) {close CURFILE;}
	
	}  #file read in

	my $NumResidues = scalar @ResidueCalphas;
	my $NumHetAtoms = scalar @HetAtoms;

	#printf STDERR "%s backbone atoms, %s substrate atoms\n",$NumBBatoms,$NumHetAtoms;
		
	
	for(my $bx = 0; $bx < $NumResidues; $bx++) {
	    my $CurResMutate = 0;
	    my $CurResidueLigContact = 0;
	    foreach my $changeres (@PosList) {
		if( ${@{$changeres}}[0] == $ResidueCalphas[$bx][0]) {
		    $CurResMutate = 1;
		    printf STDOUT " A %s %s PIKAA  %s",&spPad($ResidueCalphas[$bx][0],4),&spPad($ResidueCalphas[$bx][0],4),${@{$changeres}}[1];
		    if($keep_native) {printf STDOUT "%s", $ResidueCalphas[$bx][4];}
		    printf STDOUT "\n";

		}
	    }

	    if($CurResMutate){ next;}

	    my @CurResidueCalpha = ($ResidueCalphas[$bx][1],$ResidueCalphas[$bx][2],$ResidueCalphas[$bx][3]);
	    

	    if($NoLigPresent) { $CurResidueLigContact = 1;}   #use this script to write resfiles for apoproteins
	    else {
		for(my $hx = 0; $hx < $NumHetAtoms ; $hx++) {
		    if((my $CurDist = &VectorLength(&Substract3DVectors(@CurResidueCalpha,@{$HetAtoms[$hx]}))) < $CutOff) {
			#printf STDERR $ClashString;
			$CurResidueLigContact = 1;
		    }
		}
	    }

	    if($CurResidueLigContact) {
		printf STDOUT " A %s %s NATAA   \n",&spPad($ResidueCalphas[$bx][0],4),&spPad($ResidueCalphas[$bx][0],4);
	    }
	    else {printf STDOUT " A %s %s NATRO   \n",&spPad($ResidueCalphas[$bx][0],4),&spPad($ResidueCalphas[$bx][0],4);}
	    
	}
	#have to add line for ligand to resfile
	if(!$NoLigPresent) {
	    my $FirstLigPos = $ResidueCalphas[$NumResidues - 1][0] + 1;
	    for(my $ii = 0; $ii < $NumLigands; $ii++){
		printf STDOUT " A %s %s NATRO   \n",&spPad(($FirstLigPos+$ii),4),&spPad(($FirstLigPos+$ii),4);
	    }
	}
    }
    else {printf STDERR "Could not find file $CurStruct. \n";}
    
}


