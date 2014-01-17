#!/usr/bin/perl

#script to determine whether any backbone atoms in a structure are clashing with HETATMs 
#same line in the files of the two molecules


use Math::Complex;

use strict;


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



sub ScaffoldName {

    my @ScaffoldList = ("1abe","1gca","1hsl","1wdn","2dri","1ey4","1fkj","1mbt","1oho","1rx8","1sjw","1tsn","1ank","1cbs","1dc9","1ifc","1lic","1nah","1sa8");
    my $CheckScaf = $_[0];
    
    foreach my $item (@ScaffoldList) {
	if($CheckScaf =~ m/$item/) { return $item;}
    }
    return 0;
}


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -c <min allowed distance> -l <listfile of structures> or -s <struct> -check_native -native_cut <cut distance> -lig_neighbors\n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $CutOff = 2.8;
my $NativeCutOff = 5.00;
my $ListOption = 0;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();
my $CheckNativeLig = 0;
my $CheckLigNeighbors = 0;
my $NeighborCutOff = 7;
my $AtomicNeighborBurialCutoff = 3;
my $ResidualNeighborBurialCutoff = 10;
my $NoClashCheck = 0;

my @LigAtomRegion = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-c'){$CutOff = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-check_native'){$CheckNativeLig = 1;}
    if ($ARGV[$ii] eq '-native_cut'){$NativeCutOff = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-lig_neighbors'){$CheckLigNeighbors = 1;}
    if ($ARGV[$ii] eq '-no_clash'){$NoClashCheck = 1;}
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
    printf STDERR "Performing clash check for list of structures $ListFile containing $NumStruct $Scaf structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Performing clash check for single structure $SingStruct ..\n";
    $ListFile = $SingStruct;
}

#input read in, now analyze structures

#first read in which parts of the ligand the different atoms belong to
if($CheckLigNeighbors) {
    open(LIGFILE, "/arc/flo/scripts/database/Est_d2.txt") || die "Could not open ligand partition file.\n";
    my @ligfilearray = <LIGFILE>;
    close LIGFILE;
       
    for(my $ii = 0; $ii <= $#ligfilearray; $ii++) {

	my @tmplinearray = split(' ',$ligfilearray[$ii]);
	if($tmplinearray[0] eq 'ATOM') { $LigAtomRegion[$tmplinearray[1]] = $tmplinearray[2]; } 
    }
}

my @ClashingStructs = ();
my @NoClashStructs = ();


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
    

    my $CurClash = 0;
    my @BBAtoms = ();
    my @CbCoords = ();    #array to save all the Cb coordinates for neighbor analysis
    my @HetAtoms = ();
    my @NativeLigAtoms = ();
    my $NumNativeLigAtoms = 0;
    my $CurScaf = 0;
    my $NumNeighborsA = 0;
    my $NumNeighborsB = 0;
    my $NumNeighborsC = 0;
    my $NumNeighborsD = 0;

    my $NumBuriedAtomsNotWithinNative = 0;
    
    if(-e $CurStruct) {
	open(CURFILE, $CurStruct);

	while(<CURFILE>) {
	    my $inline = $_;
    
	    
	    if(($inline =~ /^ATOM/ )){
		my $CurAt = substr($inline,12,4);
		if( ($NoClashCheck == 0) && ($CurAt eq ' N  ' || $CurAt eq ' CA ' || $CurAt eq ' C  ' || $CurAt eq ' O  ' )) {
		    my @CurAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,substr($inline,7,9)  );
		    push(@BBAtoms,[@CurAtPos]);
		   
		}

		if ( $CheckLigNeighbors && ( ($CurAt eq ' CB ') || ( (substr($inline,17,3) eq 'GLY') && ($CurAt eq ' CA ') ) ) ){
		    my @CurNeighAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,"-",0,0,0  ); #the last element, intialized as -, keeps track of whether this residue neighbors the ligand, and if so, which parts. The last three 0s are necessary dummies
		    push(@CbCoords, [@CurNeighAtPos]);
		    #printf STDERR "%s %.3f %.3f\n",substr($inline,7,4),$CurNeighAtPos[0],$CurNeighAtPos[1];
		}
		    
		
	    }

	    if( ($inline =~ /^HETATM/ ) && (substr($inline,12,1) ne 'V') && (substr($inline,12,1) ne 'H') ) {   #don't count virtual atoms or H
		my @CurSubAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1,#the last two indices indicate whether a hetatm
				   substr($inline,7,9),(substr($inline,8,3))/1,0,0 ); #within a certain distance of native hetatms and whether it is buried

		push(@HetAtoms,[@CurSubAtPos]);
	    }

	    if($inline =~ /^END/) {close CURFILE;}
	
	}

	#now roughly check where the ligand is in relation to the native ligand
	if($CheckNativeLig) {
	    
	    $CurScaf = "/dump/flo/matching/scaffolds/retranspose/".&ScaffoldName($CurStruct)."_0_rt.pdb";
	    #printf STDERR "Scaffold of $CurStruct is $CurScaf \n";
	    if(!(-e $CurScaf)){
		$CheckNativeLig = 0;
		printf STDERR "Error: no native scaffold found for $CurStruct.\n";
	    }
	    else{
		@NativeLigAtoms = readpipe "grep HETATM $CurScaf";
		$NumNativeLigAtoms = scalar @NativeLigAtoms;
	    }
	}

	my $NumBBatoms = scalar @BBAtoms;
	my $NumHetAtoms = scalar @HetAtoms;
	my $NumResidues = scalar @CbCoords;

	#printf STDERR "%s backbone atoms, %s substrate atoms\n",$NumBBatoms,$NumHetAtoms;
	my $WorstDist = 1000;
	my $WorstClash;
	#else {printf STDERR "Atom %s is not within reach of any native atom.\n",$CurSubAt[3];}
	
	for(my $hx = 0; $hx < $NumHetAtoms; $hx++) {

	    my $AtomWithinNative = 0;
	    my @CurSubAt = @{$HetAtoms[$hx]};
	    
	    if($NoClashCheck == 0) {
		for(my $bx = 0; $bx < $NumBBatoms ; $bx++) {
		    if((my $CurDist = &VectorLength(&Substract3DVectors(@CurSubAt,@{$BBAtoms[$bx]}))) < $CutOff) {
			if($CurDist < $WorstDist) {
			    $WorstDist = $CurDist;
			    my $ClashString = " worst: ".$CurSubAt[3]." ".${@{$BBAtoms[$bx]}}[3].", dist=".$CurDist;
			    $WorstClash = $ClashString;
			}
			#printf STDERR $ClashString;
			$CurClash = 1;
		    }
		}
	    }

	    if($CheckNativeLig){
		for(my $nx = 0; $nx < $NumNativeLigAtoms ; $nx++) {
		    if( (substr($NativeLigAtoms[$nx],12,1) eq 'H') || (substr($NativeLigAtoms[$nx],13,1) eq 'H') ) { next;}
		    
		    my @CurNativeAtom = ((substr($NativeLigAtoms[$nx],31,7))/1, (substr($NativeLigAtoms[$nx],39,7))/1, (substr($NativeLigAtoms[$nx],47,7))/1,substr($NativeLigAtoms[$nx],7,9),0,0,0 ); #last 3 0 are given because the function needs them
		    #my $CurNativeHetDist = &VectorLength(&Substract3DVectors(@CurSubAt,@CurNativeAtom));
		    if( &VectorLength(&Substract3DVectors(@CurSubAt,@CurNativeAtom)) < $NativeCutOff ) { $HetAtoms[$hx][5] = 1; next; }
		    #printf STDERR "Distance between %s and %s is %.2f, where the latter coordinates are %.3f, %.3f, %.3f\n",$CurSubAt[3],substr($NativeLigAtoms[$nx],12,4),$CurNativeHetDist,$CurNativeAtom[0],$CurNativeAtom[1],$CurNativeAtom[2];

		}
		#else {printf STDERR "Atom %s is not within reach of any native atom.\n",$CurSubAt[3];}
	    }

	    if($CheckLigNeighbors) {

		my $NumNeighborsThisAtom = 0;
		if( ! exists $LigAtomRegion[$CurSubAt[4]]) { printf STDERR "Warning: $CurStruct does not have the right type of ligand atoms.\n";}
		my $CurAtomLigPart = $LigAtomRegion[$CurSubAt[4]];

		for(my $rx = 0; $rx < $NumResidues ; $rx++ ) {
		    if( &VectorLength(&Substract3DVectors(@CurSubAt,@{$CbCoords[$rx]})) < $NeighborCutOff) {

			#printf STDERR "Residue $rx within distance of %s ",$CurSubAt[3];
			$NumNeighborsThisAtom++;
			if($CbCoords[$rx][3] !~ m/$CurAtomLigPart/) {$CbCoords[$rx][3] = $CbCoords[$rx][3].$CurAtomLigPart; }
			#printf STDERR ", info is %s\n",$CbCoords[$rx][3];
		    }
		}
		if($NumNeighborsThisAtom > $AtomicNeighborBurialCutoff) 
		{ 
		    $HetAtoms[$hx][6] = 1; #atom is buried
		    if($HetAtoms[$hx][5] == 0){ $NumBuriedAtomsNotWithinNative++; }
		}
	    
	    }		
	}


	if($CheckNativeLig){
	    #my $WithinNativeRatio;
	    if($NumNativeLigAtoms < 1 ) { $NumBuriedAtomsNotWithinNative = 0;}   #no native ligand there, so we can't eliminate on this criterion
	    #else { $WithinNativeRatio = sprintf( "%.2f",($NumAtomsWithinNative/$NumHetAtoms));}
	    $CurStruct = $CurStruct." $NumBuriedAtomsNotWithinNative ";
	}

	if($CheckLigNeighbors){
	    for(my $rx = 0; $rx < $NumResidues ; $rx++ ) {
		#printf STDERR "Residue $rx has info %s\n",$CbCoords[$rx][3];
		if( $CbCoords[$rx][3] =~ m/A/ ) { $NumNeighborsA++;}
		if( $CbCoords[$rx][3] =~ m/B/ ) { $NumNeighborsB++;}
	    }

	    #printf STDERR "ligneighbordebug $NumNeighborsA $NumNeighborsB \n";
	    my $neighbor_ratio = "N/A";
	    if($NumNeighborsB != 0) { $neighbor_ratio = sprintf("%.2f",$NumNeighborsA / $NumNeighborsB);}
	    $CurStruct = $CurStruct." $NumNeighborsA $NumNeighborsB $neighbor_ratio ";
	}

	$CurStruct = $CurStruct.$WorstClash."\n";
	if($CurClash){ 
	    push(@ClashingStructs,$CurStruct);
	}
	else{push(@NoClashStructs,$CurStruct);}
    
    }
    else{}#printf STDOUT "$CurStruct shit\n";
}

my $ClashStructNum = scalar @ClashingStructs;
my $NoClashNum = scalar @NoClashStructs;

printf STDERR "$ListFile: a total of %s structures have bb hetatm clashes.\n",$ClashStructNum;

for(my $ii = 0; $ii < $NoClashNum; $ii ++){
    printf STDOUT $NoClashStructs[$ii];
   
}

    #else {printf STDOUT "Couldn't find $CurStruct\n";}


