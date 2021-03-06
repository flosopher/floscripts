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
#every line of the file of interest is saved in array @DataArray. first element[0] is bktot, the next $numcatres elements are the lines for the respective catalytic residues, element $NumCatRes+1 is the line for the ligand, 
sub ReadRosettaOutPDB { 
    
    my $CurFile = $_[0];
    my @DataArray = ();
    my @CatRes = ();
    my $CatRes_Sequence = {};  #
    my $NumCatRes = 0;
    
    my $RemarkReadingFlag = 1;
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
	
	
	if($inline =~ /^res aa /) {
	    $GenSummaryReadingFlag = 0;
	    $ResBlockReadingFlag = 1;
	    
	    $DesPosCounter = 0;
	    	    
	}

	if($inline =~ /^totals /) {
	    $GenSummaryReadingFlag = 0;
	    $ResBlockReadingFlag = 0;
	    $DataArray[0] = $inline;
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
	
  
	if($ResBlockReadingFlag){ 
	    my @LineArray=split(' ',$inline);
	    
	    if($LineArray[0] == $CatRes[$CatResCounter]) {
		$DataArray[$CatRes_Sequence->{$LineArray[0]}] = $inline;
		$CatResCounter++;
	    }

	    if($CatResCounter == $NumCatRes && $LineArray[1] eq "LG1") {
	    $DataArray[$NumCatRes+1] = $inline;
	    }

   	}

    }

    return @DataArray;

    close OUTPDB;	

}

#function to read the output generated by Andrew Wollacott's checkHbonds.py script
#the function needs an array of residue numbers and a filename as arguments. filename MUST be the last argument passed to the function.
#It returns an array of arrays, [cat_residue][numhbond].
#note: the last number passed should be the residue number of the ligand
sub ReadWollacottHbondOutput{

    my @InputArray = @_;
    my @ReturnArray = ();
    
    printf STDERR "analysing hbonds for $InputArray[$#InputArray]... \n";
    my @AllHBonds = readpipe "~wollacott/py_scripts/tools/checkHbonds.py -p $InputArray[$#InputArray] | grep $InputArray[$#InputArray]";
    my $NumHBonds = scalar @AllHBonds;
    #printf STDERR "read in %s hbonds, last is: %s \n",$NumHBonds,$AllHBonds[$NumHBonds-1];

    for(my $ii = 0; $ii < $NumHBonds; $ii++) {
	my @CurHbond = split(' ',$AllHBonds[$ii]);
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

    #printf STDERR "return %s \n",$ReturnArray[1][1];
    return @ReturnArray;


}



my @DesignList = ();
my @DesignRawDataArray = ();
my @DesignDataArray = ();
my @DesignHBondsArray = ();

my $CheckHBonds = 0;
my $ListFile;
my $SingStruct;
my $Scaf = 0;
my $ListOption = 0;

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-scaf'){$Scaf = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-hbond'){$CheckHBonds = 1;}
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
	@{$DesignRawDataArray[$ii]} = &ReadRosettaOutPDB($DesignList[$ii]);
    }
    else{ @{$DesignRawDataArray[$ii]} = ("N/A","N/A","N/A"); }
}

my $MaxCat = 0;
#now get the relevant information out of the raw data
for(my $ii = 0; $ii < $NumDesigns; $ii++){
    
    if($DesignRawDataArray[$ii][0] eq "N/A") {@{$DesignDataArray[$ii]} = ($DesignList[$ii],"N/A","N/A");}
    else {
	
	my @CatResArray = ();
	my $NumRows = scalar @{$DesignRawDataArray[$ii]};
	if( ($NumRows - 2) > $MaxCat) {$MaxCat = $NumRows - 2;}  #check how many catalytic residues there are in file ii
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
	    $CatResArray[$jj-1] = $CurCatArray[0];
	}
	$CatResArray[$NumRows - 2] = $CurLigArray[0];   #catresarray holds the sequence positions of the catalytic residues in the same order as they are in the file header

	#determine number of hbonds per catalytic residue
	if($CheckHBonds){
	    @{$DesignHBondsArray[$ii]} = &ReadWollacottHbondOutput(@CatResArray,$DesignList[$ii]);
	    for(my $kk = 0; $kk < $MaxCat + 1; $kk++) {
		$DesignHBondsArray[$ii][0][$kk] = scalar @{$DesignHBondsArray[$ii][$kk+1]} - 1; #0th element of ReadWolllacottHbondOutput is not defined, can be used to store number of hbonds for each cat residue and ligand
	    }
	}
    
    }
}
printf STDERR "\n";
#printf STDERR "blep $DesignHBondsArray[0][0][0], max cat is $MaxCat \n";


#---------everything analysed, now output---, implementation not ideal yet,

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

#header line built, now output header line
printf STDOUT "%s",&Padsp($HeaderLine[0],62);
for(my $ii = 1; $ii <= $NumNoRes; $ii++){ printf STDOUT "%s",&Padsp(&spPad($HeaderLine[$ii],9),10);}
if($CheckHBonds){for(my $ii = $NumNoRes + 1; $ii < $NumColumns; $ii++){ printf STDOUT "%s",&Padsp(&spPad($HeaderLine[$ii],20),21);}}
else{for(my $ii = $NumNoRes + 1; $ii < $NumColumns; $ii++){ printf STDOUT "%s",&Padsp(&spPad($HeaderLine[$ii],16),17);}}
printf STDOUT "\n";

#header line was spit out, now output designs
for(my $ii = 0; $ii < $NumDesigns; $ii++){
    printf STDOUT "%s",&Padsp($DesignDataArray[$ii][0],62);
    for(my $jj = 1; $jj <= $NumNoRes - $CheckHBonds; $jj++){ printf STDOUT "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],9),10);}
    if($CheckHBonds){printf STDOUT "%s",&Padsp(&spPad($DesignHBondsArray[$ii][0][$MaxCat],7),10);}

    if($CheckHBonds){
	for(my $jj = $NumNoRes; $jj < $NumColumns -1; $jj++){ 
	    printf STDOUT "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],16),17);
	    printf STDOUT "%s",&Padsp(&spPad($DesignHBondsArray[$ii][0][$jj - $NumNoRes],2),4);
	}
    
    }
    else {
	for(my $jj = $NumNoRes + 1; $jj < $NumColumns; $jj++){ printf STDOUT "%s",&Padsp(&spPad($DesignDataArray[$ii][$jj],16),17);}
    }
    printf STDOUT "\n";
}




