#!/usr/bin/perl

#script to analyse, i.e. read out the important energy variables, from a list of designed structures. 
#the energy variables being read are bk_tot and the lines for the catalytic residues + ligand from the residual energy block 

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

#function: Padsp(InpString,len) adds spaces to the end of the input string until the desired length is reached
sub Padsp {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString=$InpString." ";
    }
    return $InpString;
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


#function to check whether a given value is in a given array. the value has to be the 0th argument, the array follows.
#If the value is in the array, the function returns the corresponding original array position + 1
sub ValueInArray{
  
    my $NumElements = scalar @_ - 1;
    for(my $ii = 1; $ii <= $NumElements; $ii++){
	if($_[0] == $_[$ii]){ return $ii;}
    }
    return 0;
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


# 
#subroutine to read out energy values 
#
#every line of the file of interest is saved in array @{$DataArray[0]}. first element[0] is bktot, the next $numcatres elements are the lines for the respective catalytic residues, element $NumCatRes+1 is the line for the ligand,aft 
#in the second array of DataArray, the residue numbers of residues that are within the 10,12A cutoff are saved 
sub ReadRosettaOutPDB { 
    
    my $CurFile = $_[0];
    my @DataArray = ();
    my @CatRes = ();
    my $CatRes_Sequence = {};  #
    my $NumCatRes = 0;
    
    my $RemarkReadingFlag = 1;
    my $HetatmReadingFlag = 0;
    my $GenSummaryReadingFlag = 0;
    my $ResBlockReadingFlag = 0;
    my $DesPosCounter = 0;
    my $CatResCounter = 0;
    
    open(OUTPDB,$CurFile) || die "Can't open $CurFile ";
    printf STDERR "Reading file $CurFile ...\n";

    while(<OUTPDB>) {
	chomp;
	my $inline = $_;

	
	if($RemarkReadingFlag == 1 && $inline =~ /^ATOM/) { 
	    $RemarkReadingFlag = 0;
	    my @SortCatRes = sort {$a <=> $b} @CatRes;
	    @CatRes = @SortCatRes;
	    $NumCatRes = scalar @CatRes;
	}

	if($inline =~ /^HETATM/ && $HetatmReadingFlag == 0){$HetatmReadingFlag = 1;}

	if($HetatmReadingFlag && $inline !~ /^HETATM/){$HetatmReadingFlag = 0;}
	
	
	if($inline =~ /^res aa /) {
	    $GenSummaryReadingFlag = 0;
	    $ResBlockReadingFlag = 1;
	    
	    $DesPosCounter = 0;
	    	    
	}

	if($inline =~ /^totals /) {
	    $GenSummaryReadingFlag = 0;
	    $ResBlockReadingFlag = 0;
	    $DataArray[0][0] = $inline;
	} 


	if($RemarkReadingFlag) {
	    my @LineArray=split(' ',$inline);
	    if($LineArray[1] eq "BACKBONE" && $LineArray[2] eq "TEMPLATE") {
		my $CurCatRes = $LineArray[10];
		my $CurCatResAlreadyFound = 0;
		my $CatResArraySize = scalar @CatRes;
		for(my $ii = 0; $ii < $CatResArraySize; $ii++){
		    if($CatRes[$ii] eq $CurCatRes) {$CurCatResAlreadyFound = 1;}
		}
		if(!$CurCatResAlreadyFound){
		    $CatRes[$CatResArraySize] = $CurCatRes;
		    $CatRes_Sequence->{$CurCatRes} = $LineArray[11];
		}
	    }
	}

	if($HetatmReadingFlag ){
	    if(substr($inline,12,1) ne 'H'  && substr($inline,12,1) ne 'V'){push(@{$DataArray[2]},$inline);}
	}
	
  
	if($ResBlockReadingFlag){ 
	    my @LineArray=split(' ',$inline);
	    
	    if($LineArray[0] == $CatRes[$CatResCounter]) {
		$DataArray[0][$CatRes_Sequence->{$LineArray[0]}] = $inline;
		$DataArray[1][$CatRes_Sequence->{$LineArray[0]}] = $CatRes[$CatResCounter];
		$CatResCounter++
	    }

	    if($CatResCounter == $NumCatRes && $LineArray[1] eq "LG1") {
	    $DataArray[0][$NumCatRes+1] = $inline;
	    $DataArray[1][$NumCatRes+1] = $LineArray[0]; 
	    }

   	}

    }
    $DataArray[1][0] = $NumCatRes;
    return @DataArray;

    close OUTPDB;	

}

#function to read the output generated by Andrew Wollacott's checkHbonds.py script
#the function needs an array of residue numbers and a filename as arguments. filename MUST be the last argument passed to the function.
#It returns an array of arrays, [residue][numhbond].
#note: the last number passed should be the residue number of the ligand
sub ReadWollacottHbondOutput{

    my @InputArray = @_;
    my @ReturnArray = ();
    my @AllHBonds = ();
    my $InpFileLength = length($InputArray[$#InputArray]);
    
    printf STDERR "analysing hbonds for $InputArray[$#InputArray]... ";

    #first check whether the file has already been analysed for hbonds
    my @pdblines = ();
    my $FileAnalyzedBefore = 0;

    open(PDB,$InputArray[$#InputArray]);
    
    my $HbondReadingFlag = 0;
    my $RemarkReadingFlag = 0;

    while(<PDB>){

	my $inline = $_;
	if(!$RemarkReadingFlag and $inline =~ /^REMARK/){$RemarkReadingFlag = 1;}
 
	if($inline =~ /^REMARK wollacott hbond-analysis results appended at end of file/){
	    $FileAnalyzedBefore = 1;
	    printf STDERR " has already been done, getting info from file...\n";
	}
	if($inline =~ /^ATOM/ && !$FileAnalyzedBefore && $RemarkReadingFlag) {
	    $RemarkReadingFlag = 0;
	    my $NewRemark = "REMARK wollacott hbond-analysis results appended at end of file \n";
	    push(@pdblines,$NewRemark);
	}

	if($FileAnalyzedBefore && !$HbondReadingFlag && $inline =~ /^wollacott_hbond_info/){$HbondReadingFlag = 1;}
	if($FileAnalyzedBefore && $HbondReadingFlag && $inline !~ /^wollacott_hbond_info/){$HbondReadingFlag = 0; close PDB;}

	if($HbondReadingFlag){push(@AllHBonds,$inline);}
	
	if(!$FileAnalyzedBefore){push(@pdblines,$inline);}

    }

    if(!$FileAnalyzedBefore){close PDB;}
	

    if(!$FileAnalyzedBefore){
	@AllHBonds = readpipe "~/wollascripts/tools/checkHbonds.py -p $InputArray[$#InputArray] | grep $InputArray[$#InputArray]";
	push(@pdblines,"\n");
    }
    my $NumHBonds = scalar @AllHBonds;
    #printf STDERR "read in %s hbonds, last is: %s \n",$NumHBonds,$AllHBonds[$NumHBonds-1];
    shift(@InputArray); #remove first element of input array, so subroutine ValueInArray returns proper numbers

    for(my $ii = 0; $ii < $NumHBonds; $ii++) {

	my @CurHbond = split(' ',$AllHBonds[$ii]);
	
	if(!$FileAnalyzedBefore){
	    substr($AllHBonds[$ii],0,$InpFileLength) = "wollacott_hbond_info";
	    push(@pdblines,$AllHBonds[$ii]);
	}

	
	my $CurDonorResArrayPos = &ValueInArray($CurHbond[2],@InputArray);
	if($CurDonorResArrayPos){ 
	    #printf STDERR "found donor, hbond %s, resarraypos is $CurDonorResArrayPos, hbondline \n %s\n",$ii+1,$AllHBonds[$ii];
	    push(@{$ReturnArray[$CurDonorResArrayPos]},$AllHBonds[$ii]);}
	
	my $CurAccResArrayPos = &ValueInArray($CurHbond[8],@InputArray);
	if($CurAccResArrayPos){ 
	    #printf STDERR "$CurHbond[8] found acceptor, hbond %s, resarraypos is $CurAccResArrayPos, hbondline \n %s\n",$ii+1,$AllHBonds[$ii];
	    push(@{$ReturnArray[$CurAccResArrayPos]},$AllHBonds[$ii]);
	}
    }
    #have to push sentinel onto each array, so in case a given residue makes no hbonds, the array size is still defined
    my $sentinel = "sentinel";
    for(my $ii = 1; $ii <= $#InputArray; $ii++) { push(@{$ReturnArray[$ii]},$sentinel);}

    #printf STDERR "return %s \n",$ReturnArray[1][1]

    #if the file hasn't been analyzed before, we have to rewrite it
    if(!$FileAnalyzedBefore){
	system "rm $InputArray[$#InputArray]";
	open(NEWPDB,">$InputArray[$#InputArray]");
	for(my $line = 0; $line <= $#pdblines; $line++){
	    printf NEWPDB $pdblines[$line];
	}
	close NEWPDB;
    printf STDERR "done\n";

    }
    return @ReturnArray;


}

#function to generate the output generated by Andrew Wollacott's surface.py script. 
#the function needs an array of residue numbers and a filename as arguments.filename MUST be the last argument passed to the function.
#it returns an array of arrays, [residue][atom] containing all the atoms of the residue and their surface area 
#InputArray[0] should be the number of catalytic residues among the passed residues
sub ReadWollacottSASAOutput{

    my @InputArray = @_;
    my @ReturnArray = ();
    
    printf STDERR "analysing SASAs for $InputArray[$#InputArray]... ";
    my $NumResidues = scalar @InputArray - 2;
    my $NumCats = $InputArray[0];
    

    my @CompleteSASA = readpipe "~/wollascripts/tools/surface.py -p $InputArray[$#InputArray]";
    shift(@InputArray); #remove first element of input array, so subroutine ValueInArray returns proper numbers
    
    for(my $ii = 1; $ii <= $#CompleteSASA; $ii++) {
	
	my @CurSasaLine = split(' ',$CompleteSASA[$ii]);
	my $CurResArrayPos = &ValueInArray($CurSasaLine[3],@InputArray);

	if($CurSasaLine[3] == $InputArray[$NumCats]){push(@{$ReturnArray[$NumCats+1]},$CompleteSASA[$ii]);} #ligand, store every atom

	elsif($CurResArrayPos && (substr($CurSasaLine[1],0,1) eq 'N' || substr($CurSasaLine[1],0,1) eq 'O' || substr($CurSasaLine[1],0,1) eq 'S')){
	    push(@{$ReturnArray[$CurResArrayPos]},$CompleteSASA[$ii]);
	}

    }  

    printf STDERR "done\n";
    return @ReturnArray;
}


#helper function to read the sasa of a particular atom out of the sasa array
sub LookupAtomSASA{

    my $InputSize = scalar @_;
    my $CurAt = $_[0];
   

    for(my $ii=1;$ii < $InputSize; $ii++){
	my @CurLine = split(' ',$_[$ii]);
	if($CurLine[0] == $CurAt){return $CurLine[4];}
    }
    return -1;

}

sub LookupAtomHbonds{

    my $InputSize = scalar @_;
    my $NumHbonds = 0;
    
    if($InputSize > 2 ){ #the input arrays have a sentinel as the last member, so we need to check if there actually is an hbond in the array
	my $CurAt = $_[0];
	for(my $ii=1;$ii < $InputSize; $ii++){
	    my @CurLine = split(' ',$_[$ii]);
	    if($CurLine[5] == $CurAt || $CurLine[11] == $CurAt){$NumHbonds++;}
	}
    }

    return $NumHbonds;
}



my @DesignList = ();
my @DesignRawDataArray = ();
my @DesignDataArray = ();
my @DesignAdditionalDataArray = ();
my @ResNumArray = ();
my @LigArray = ();
my @DesignHBondsArray = ();
my @DesignSasaArray = ();

my $CheckHBonds = 0;
my $CheckSASA = 0;
my $ListFile;
my $SingStruct;
my $Scaf = 0;
my $ListOption = 0;

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-scaf'){$Scaf = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-hbond'){$CheckHBonds = 1;}
    if ($ARGV[$ii] eq '-sasa'){$CheckSASA = 1;}
}
my $NumDesigns = 0;

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @DesignList = <LISTFILE>;
    close LISTFILE;
    $NumDesigns = scalar @DesignList;
}

else {
    $DesignList[0] = $SingStruct;
    $NumDesigns =1;
    $ListFile = $SingStruct;
}

#input is taken care of, now read in every file in the input list
for(my $ii = 0; $ii < $NumDesigns; $ii++){

    
    chomp($DesignList[$ii]);
    if(-e $DesignList[$ii]) {
	my @CurFileArray = &ReadRosettaOutPDB($DesignList[$ii]);
	@{$DesignRawDataArray[$ii]} = @{$CurFileArray[0]};
	@{$ResNumArray[$ii]} = @{$CurFileArray[1]}; #ResNumArray stores all numbers of residues that have been redesigned or repacked,with the catalytic residues and the ligand being the first entries
	@{$LigArray[$ii]} = @{$CurFileArray[2]};#array that has all ligand heavy atoms
					
    }
    else{ @{$DesignRawDataArray[$ii]} = ("N/A","N/A","N/A"); }
}

my $MaxCat = 0;
#now get the relevant information out of the raw data
for(my $ii = 0; $ii < $NumDesigns; $ii++){
    
    if($DesignRawDataArray[$ii][0] eq "N/A") {@{$DesignDataArray[$ii]} = ($DesignList[$ii],"N/A","N/A");}
    else {
	
	#my @CatResArray = ();
	my $NumRows = scalar @{$DesignRawDataArray[$ii]};
	my $NumCatRes = $ResNumArray[$ii][0];
	if($NumCatRes > $MaxCat){$MaxCat = $NumCatRes;}

	my @CurTotArray = split(' ',$DesignRawDataArray[$ii][0]);
	$DesignDataArray[$ii][0] = $DesignList[$ii];  #design name
	$DesignDataArray[$ii][1] = $CurTotArray[16];  #bk_tot
	$DesignDataArray[$ii][2] = $CurTotArray[15];  #E_cst
	$DesignDataArray[$ii][3] = $CurTotArray[2];  #E_rep

	my @CurLigArray = split(' ',$DesignRawDataArray[$ii][$NumRows - 1]);
	$DesignDataArray[$ii][4] = $CurLigArray[17]; #lig_sum
	$DesignDataArray[$ii][5] = $CurLigArray[3];  #lig_rep
	$DesignDataArray[$ii][6] = $CurLigArray[10]; #lig_hb

	for(my $jj =1; $jj < ($NumRows - 1); $jj++) {
	    my @CurCatArray = split(' ',$DesignRawDataArray[$ii][$jj]);
	    my $CurCatName = &AA_ThreeLetToOneLet($CurCatArray[1]).$CurCatArray[0];
	    $DesignDataArray[$ii][6+$jj] = $CurCatName." ".$CurCatArray[3]." ".$CurCatArray[16];
	}

	#if($ResNumArray[$ii][0] != $MaxCat) {printf STDERR "arrrgh klsdjf\n";}
	
	#determine number of hbonds per catalytic residue
	if($CheckHBonds){
	    @{$DesignHBondsArray[$ii]} = &ReadWollacottHbondOutput(@{$ResNumArray[$ii]},$DesignList[$ii]);
	    for(my $kk = 0; $kk < $NumCatRes + 1; $kk++) {
		$DesignHBondsArray[$ii][0][$kk] = scalar @{$DesignHBondsArray[$ii][$kk+1]} - 1; #0th element of ReadWolllacottHbondOutput is not defined, can be used to store number of hbonds for each cat residue and ligand
	    }
	}

	#now determine solvent accessible surfaces
	if($CheckSASA){
	    @{$DesignSasaArray[$ii]} = &ReadWollacottSASAOutput(@{$ResNumArray[$ii]},$DesignList[$ii]);
	}
	my $NumLigAts = scalar @{$LigArray[$ii]};
	
	#important: determine whether ligand has buried unsatisfied H-bonds
	$DesignAdditionalDataArray[$ii][0] = 0; #initialize value
	
	#first we need to determine the heavy atom connectivity information, i.e. how many heavy atoms each ligand atom is bonded to.
	my @LigBonds = ();
	for(my $ligat1=0; $ligat1 < $NumLigAts; $ligat1++){
	    $LigBonds[$ligat1] = 0;
	    my @CurLigAt1 = split(' ',$LigArray[$ii][$ligat1]);
	    for(my $ligat2=0; $ligat2 < $NumLigAts; $ligat2++){
		my @CurLigAt2 = split(' ',$LigArray[$ii][$ligat2]);
		if($ligat1 != $ligat2 && ( &VectorLength(&SubstractVectors($CurLigAt1[5],$CurLigAt1[6],$CurLigAt1[7],$CurLigAt2[5],$CurLigAt2[6],$CurLigAt2[7])) < 2.1)) { $LigBonds[$ligat1]++;}
		}
	}
	#connectivity determined
	#printf STDERR "blep @LigBonds \n";
	
	if($CheckSASA && $CheckHBonds){
	    for(my $ligat=0; $ligat < $NumLigAts; $ligat++){
		my @CurLigAt = split(' ',$LigArray[$ii][$ligat]);
		if(substr($CurLigAt[2],0,1) eq 'N' || substr($CurLigAt[2],0,1) eq 'O') { 

		    if(&LookupAtomSASA($CurLigAt[1],@{$DesignSasaArray[$ii][$NumCatRes+1]}) < 5){

			my $NumCurAtHbonds = &LookupAtomHbonds($CurLigAt[1],@{$DesignHBondsArray[$ii][$NumCatRes+1]});
			#printf STDERR "ligatom $ligat has sasa of %.3f, $LigBonds[$ligat] bonds  and $NumCurAtHbonds hbonds.\n",&LookupAtomSASA($CurLigAt[1],@{$DesignSasaArray[$ii][$NumCatRes+1]});
			my $NumUnsatisfiedHbonds = 3 - $NumCurAtHbonds - $LigBonds[$ligat];
			if($NumUnsatisfiedHbonds > 0){$DesignAdditionalDataArray[$ii][0]+= $NumUnsatisfiedHbonds;} 
		    }
		}
	    }

	    #ligand stuff determined, now check unsatisfied hbonds for each catalytic aa
	    #-to do
	    #-to do
	    #-to do
	    #-to do
	    #unsatisfied hbonds for catalytic amino acids determined
	}
    }
}
printf STDERR "\n";
#printf STDERR "blep $DesignHBondsArray[0][0][0], max cat is $MaxCat \n";


#---------everything analysed, now output---, implementation not ideal yet,

my $OutfileName= "temphihi";

if($ListOption) { 
    $OutfileName = $ListFile.".ana";
}
open(OUTFILE,">$OutfileName");


#build header line
my @HeaderLine = ();
if($CheckHBonds) { @HeaderLine = ("# Design","bk_tot","Ecst","Erep_tot","lig_sum","lig_rep","lig_hbond","#lig_HB");}
else { @HeaderLine = ("# Design","bk_tot","Ecst","Erep_tot","lig_sum","lig_rep","lig_hbond");}

my $NumNoRes = $#HeaderLine;
for(my $ii=1; $ii <= $MaxCat; $ii++){
    if($CheckHBonds){$HeaderLine[$NumNoRes+$ii] = "CatRes".$ii." rep cst #HB";}
    else{$HeaderLine[$NumNoRes+$ii] = "CatRes".$ii." rep cst";}
}

my $NumColumns = scalar @HeaderLine ;

if($CheckSASA && $CheckHBonds){$HeaderLine[$NumColumns] = "#lig_bur_HB";}

#header line built, now output header line
printf OUTFILE "%s",&Padsp($HeaderLine[0],62);
for(my $ii = 1; $ii <= $NumNoRes; $ii++){ printf OUTFILE "%s",&Padsp(&spPad($HeaderLine[$ii],9),10);}
if($CheckHBonds){for(my $ii = $NumNoRes + 1; $ii < $NumColumns; $ii++){ printf OUTFILE "%s",&Padsp(&spPad($HeaderLine[$ii],20),21);}}
else{for(my $ii = $NumNoRes + 1; $ii < $NumColumns; $ii++){ printf OUTFILE "%s",&Padsp(&spPad($HeaderLine[$ii],16),17);}}
if($CheckSASA && $CheckHBonds){ printf OUTFILE "%s",&Padsp(&spPad($HeaderLine[$NumColumns],12),13);}
printf OUTFILE "\n";

#header line was spit out, now output designs
for(my $ii = 0; $ii < $NumDesigns; $ii++){
    printf OUTFILE "%s",&Padsp($DesignDataArray[$ii][0],62);
    for(my $jj = 1; $jj <= $NumNoRes - $CheckHBonds; $jj++){ printf OUTFILE "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],9),10);}
    if($CheckHBonds){printf OUTFILE "%s",&Padsp(&spPad($DesignHBondsArray[$ii][0][$MaxCat],7),10);}

    if($CheckHBonds){
	for(my $jj = $NumNoRes; $jj < $NumColumns -1; $jj++){ 
	    printf OUTFILE "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],16),17);
	    printf OUTFILE "%s",&Padsp(&spPad($DesignHBondsArray[$ii][0][$jj - $NumNoRes],2),4);
	}
    
    }
    else {
	for(my $jj = $NumNoRes + 1; $jj < $NumColumns; $jj++){ printf OUTFILE "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],16),17);}
    }
    
    if($CheckSASA && $CheckHBonds){printf OUTFILE "%s",&Padsp(&spPad($DesignAdditionalDataArray[$ii][$0],8),13);}
    printf OUTFILE "\n";
}

close OUTFILE;

if(!$ListOption){ 
    system "cat temphihi";
    system "rm temphihi";
}
