#!/usr/bin/perl

#script to determine which atom of a catalytic histidine does the backing up. atom in the substrate that is to be backed up has to be given as input 
#same line in the files of the two molecules


use Math::Complex;
use Math::Trig;


use strict;


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
 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -a <#num atom in ligand> -l <listfile of structures> -s <struct>\n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $BkdUpAtomNo = -1;
my $ListOption = 0;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-a'){$BkdUpAtomNo = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
}

my $NumStruct = 0;
my $Scaf = 'X';

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    $Scaf = substr($ListFile,0,4);
    printf STDERR "Checking backing up atoms for list of structures $ListFile containing $NumStruct $Scaf structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Checking backing up atoms for single structure $SingStruct ..\n";
}

#input read in, now analyze structures


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);

    my $HisNotFound = 1;

    my $BackingUpHis;
    my @CurND1Pos = ('X','X','X');
    my @CurNE2Pos = ('X','X','X');
    my @CurSubAtPos = ('X','X','X');
    
    if(-e $CurStruct) {
	open(CURFILE, $CurStruct);

	while(<CURFILE>) {
	    my $inline = $_;
    
	    if( $HisNotFound == 1 && $inline =~ /^REMARK/){
		my @linearray = split(' ',$inline); 
		if($linearray[4] eq 'HIS' && ($linearray[9] eq 'ASP' || $linearray[9] eq 'GLU')){$BackingUpHis = $linearray[5];}
	    }

	    if($HisNotFound == 1 && ($inline =~ /^ATOM/ )){
		if(substr($inline,23,4)/1 == $BackingUpHis) {
		
		    if(substr($inline,12,4) eq ' ND1') {
			@CurND1Pos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1 );
		    
		    }
		    elsif(substr($inline,12,4) eq ' NE2') {
			@CurNE2Pos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1 );
		    
		    }
		}
		if(substr($inline,23,4)/1 == $BackingUpHis + 1) { $HisNotFound = 0;}
	    }

	    if($inline =~ /^HETATM/ && ( (substr($inline,7,5))/1 == $BkdUpAtomNo)) {
		@CurSubAtPos = ((substr($inline,31,7))/1, (substr($inline,39,7))/1, (substr($inline,47,7))/1 );
		close CURFILE;

	    }
	
	}
    
    
	my $CurND1Dist = &VectorLength(&SubstractVectors(@CurSubAtPos,@CurND1Pos));
	my $CurNE2Dist = &VectorLength(&SubstractVectors(@CurSubAtPos,@CurNE2Pos));

	#printf STDERR "$CurStruct His is $BackingUpHis, NE $CurNE2Dist, ND $CurND1Dist \n";
	if(($CurND1Dist < 6.9) && ($CurND1Dist < $CurNE2Dist)) { printf STDERR "alarm $CurStruct ";}#printf STDOUT "$CurStruct ND1\n";}
	elsif(($CurNE2Dist < 2.9) && ($CurNE2Dist < $CurND1Dist)) {
	    #system "cp $CurStruct /work/flo/designs/esterase/matches/NE/${Scaf}/"; 
	    printf STDOUT "$CurStruct\n";
	}
	else{}#printf STDOUT "$CurStruct shit\n";
    
    }
    #else {printf STDOUT "Couldn't find $CurStruct\n";}
}



