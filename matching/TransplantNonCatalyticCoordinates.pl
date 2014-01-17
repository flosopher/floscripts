#!/usr/bin/perl

#script to read in a wildtype structure, then read in a list of matches, and copy all coordinates
#of NON-BACKBONE atoms of non-catalytic residues to each match.
#used to retrofit the coordinates of matches to the repacked and minimized wildtype
#
#written by flo, oct 2007


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


sub ScaffoldName {

    my @ScaffoldList = ("1abe","1gca","1hsl","1wdn","2dri","1ey4","1fkj","1mbt","1oho","1rx8","1sjw","1tsn","1ank","1cbs","1dc9","1ifc","1lic","1nah","1sa8");
    my $CheckScaf = $_[0];
    
    foreach my $item (@ScaffoldList) {
	if($CheckScaf =~ m/$item/) { return $item;}
    }
    return 0;
}

sub ReadPDBAtomCoordinatesByResidue {

    my @StructAtoms = ();
    my @StructFile = @_;
    my $NumFileLines = scalar @StructFile;
    
    my $CurRes = 0;
    my $rescounter = 0;
    my $atomcounter= 0;

     
    for(my $ii = 0; $ii < $NumFileLines; $ii++){
	my $inline = $StructFile[$ii];

	if($inline =~ /^ATOM/) { 
	    my $AtomRes = substr($inline,22,4)/1; 
	    if( $AtomRes != $CurRes) {
		$CurRes = $AtomRes;
		$rescounter++;
		$atomcounter = 0;
	    }
	    #if(( substr($inline,12,1) eq 'H') || (substr($inline,13,1) eq 'H') ) {next;} #skip H atoms
	    my @CurAtom = ( (substr($inline,6,5))/1, (substr($inline,12,4)), substr($inline,17,3), substr($inline,21,1), 
			     $AtomRes, (substr($inline,30,8)),(substr($inline,38,8)), 
			     (substr($inline,46,8)),$ii,0 );#keep the information about where this atom is in the original file
	    push(@{$StructAtoms[$rescounter][$atomcounter]},@CurAtom);
	    $atomcounter++;
			   
	}

    }
        
    return @StructAtoms;

}
 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -t <template scaffold> -l <listfile of structures> or -s <struct> -Ecut <energy cutoff, default 1.0> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $ListOption = 0;
my $ScafStruct = -1;
my $ListFile = -1;
my $SingStruct = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-t'){$ScafStruct = $ARGV[$ii+1];}
}



my $NumStruct = 0;

if($ListOption){

    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    #$Scaf = substr($ListFile,0,4);
    printf STDERR "Changing non-catalytic sidechain coordiantes for list of structures $ListFile containing $NumStruct structures..\n";
}

else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    printf STDERR "Changing non-catalytic sidechain coordinates for single structure $SingStruct ..\n";
    $ListFile = $SingStruct;
}


#input read in, now analyze structures
my @ScafFile = ();
open(SCAF,$ScafStruct)  || die "Could not open scaffold\n"; 
@ScafFile = <SCAF>;
close SCAF;

my @ScafAtoms = &ReadPDBAtomCoordinatesByResidue(@ScafFile);
my $NumScafResidues = scalar @ScafAtoms;

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CurStruct = $StructList[$ii];
    chomp($CurStruct);
    open(STRUCT,$CurStruct) || die "Could not open $CurStruct.\n";
    my @CurFile = <STRUCT>;
    close STRUCT;

    my @CurStructCatRes = ();
    
    my @CurStructAtoms = &ReadPDBAtomCoordinatesByResidue(@CurFile);
    my $NumCurStructResidues = scalar @CurStructAtoms;
    
    if($NumCurStructResidues != $NumScafResidues) { 
	printf STDERR "Error: $CurStruct does not have the same number of residues as the scaffold, skipping... \n";
	next;
    }
    
    #read in catalytic residues
    my $CatNotFound =1;
     while($CatNotFound){
	
	if($CurFile[$CatNotFound -1] =~ /^ATOM/) {
	    $CatNotFound = 0;
	    last;
	}
	if($CurFile[$CatNotFound - 1] =~ /^REMARK BACKBONE TEMPLATE/) {
	    my @linearray = split(' ',$CurFile[$CatNotFound -1]);
	    push(@CurStructCatRes, ($linearray[10])/1);
	}
	$CatNotFound++;

    }
    @CurStructCatRes = sort {$a <=> $b} @CurStructCatRes; #sorting catalytic residues to keep track of them easier

    #printf STDERR "For struct $CurStruct the catalytic residues are ";
    #foreach my $item (@CurStructCatRes) { printf STDERR " $item";}
    #printf STDERR "\n";
    
    my $ExcludeLine={};
    my $Structure_Fucked = 0;

    for(my $jj = 1; $jj < $NumScafResidues; $jj++) {
	
	#printf STDERR "$ScafAtoms[$jj][1][4]  ";
	if($ScafAtoms[$jj][0][4] == $CurStructCatRes[0]) {
	    shift(@CurStructCatRes);
	    next;
	}
	my $NumAtomsScafCurResidue = scalar @{$ScafAtoms[$jj]};
	my $NumAtomsCurStructCurResidue = scalar @{$CurStructAtoms[$jj]};

	#if ($NumAtomsCurResidue != scalar @{$CurStructAtoms[$jj]} ) {
	#    printf STDERR "Error: $CurStruct has unequal number of Atoms in residue %s, skipping...\n",$ScafAtoms[$jj][0][4];
	#    $Structure_Fucked = 1;
	#    last;
	#}

	for(my $kk = 0; $kk < $NumAtomsScafCurResidue; $kk++) {
	    if( ($ScafAtoms[$jj][$kk][1] ne ' N  ') && ($ScafAtoms[$jj][$kk][1] ne ' CA ') &&
	      ($ScafAtoms[$jj][$kk][1] ne ' C  ') && ($ScafAtoms[$jj][$kk][1] ne ' O  ')){
 

		for(my $mm = 0; $mm < $NumAtomsCurStructCurResidue; $mm++) {

		    if( ($CurStructAtoms[$jj][$mm][1] eq ' N  ') || ($CurStructAtoms[$jj][$mm][1] eq ' CA ') ||
			($CurStructAtoms[$jj][$mm][1] eq ' C  ') || ($CurStructAtoms[$jj][$mm][1] eq ' O  ') ||
			($CurStructAtoms[$jj][$mm][1] eq ' OXT') || ($CurStructAtoms[$jj][$mm][9] == 1) ) { next;}
	    
		    
		    #printf STDERR "comparing $CurStructAtoms[$jj][$mm][2]  $CurStructAtoms[$jj][$mm][1],  k=$kk with  $ScafAtoms[$jj][$kk][1] \n ";
		    
		    if( ($jj == 1) && ( ($CurStructAtoms[$jj][$mm][1] eq '1H  ') || ($CurStructAtoms[$jj][$mm][1] eq '2H  ') ||
					($CurStructAtoms[$jj][$mm][1] eq '3H  ') ) ) 
		    {
			$CurStructAtoms[$jj][$mm][9] = 1; # mark N-termini
			next;
		    }

		    if( ($ScafAtoms[$jj][$kk][2] ne $CurStructAtoms[$jj][$mm][2]) ||
			($ScafAtoms[$jj][$kk][4] != $CurStructAtoms[$jj][$mm][4]) )
		    {
			$Structure_Fucked = 1;
			printf STDERR "Error: $kk $mm $CurStruct has atom problems in residue %s, skipping...\n",$ScafAtoms[$jj][0][4];
			last;
		    }
		    elsif($CurStructAtoms[$jj][$mm][1] eq $ScafAtoms[$jj][$kk][1]) { #copy coordinates
			substr($CurFile[$CurStructAtoms[$jj][$mm][8]],30,8) = $ScafAtoms[$jj][$kk][5];
			substr($CurFile[$CurStructAtoms[$jj][$mm][8]],38,8) = $ScafAtoms[$jj][$kk][6];
			substr($CurFile[$CurStructAtoms[$jj][$mm][8]],46,8) = $ScafAtoms[$jj][$kk][7];


			$CurStructAtoms[$jj][$mm][9] = 1; #indicate that this atom had its coordinates changed
			$ScafAtoms[$jj][$kk][9] = 1; #indicate that this atom has been found
			last;

		    }
		
		}
				    
	    }
		
	}
	
	if($Structure_Fucked) {last;}
	
	#make sure all atoms have their coordinates changed
	for(my $mm = 0; $mm < $NumAtomsCurStructCurResidue; $mm++) {
	    if( ($CurStructAtoms[$jj][$mm][1] ne ' N  ') && ($CurStructAtoms[$jj][$mm][1] ne ' CA ') &&
		($CurStructAtoms[$jj][$mm][1] ne ' C  ') && ($CurStructAtoms[$jj][$mm][1] ne ' O  ') &&
		($CurStructAtoms[$jj][$mm][1] ne ' OXT') && ($CurStructAtoms[$jj][$mm][9] == 0) ) { 

		#account for tautomers
		if( (($CurStructAtoms[$jj][$mm][1] eq ' HE2') || ($CurStructAtoms[$jj][$mm][1] eq ' HD1' )) && ($CurStructAtoms[$jj][$mm][2] eq 'HIS')){ 
		    $ExcludeLine->{$CurStructAtoms[$jj][$mm][8]} = 'yes';
		    next;
		}

		$Structure_Fucked = 1;
		printf STDERR "Error: Atom $CurStructAtoms[$jj][$mm][4] $CurStructAtoms[$jj][$mm][1] was not found in $CurStruct, skipping... \n";
		last;
	    }
		    
	}

	if($Structure_Fucked) {last;}

    }

    if(!$Structure_Fucked) {
	my $NumLines = scalar @CurFile;
	open(NEW,">$CurStruct") || die ("Can't open file $CurStruct for waiting.\n");
	for(my $line=0; $line < $NumLines; $line++) {
	    if($ExcludeLine->{$line} ne 'yes') {
		printf NEW "%s",$CurFile[$line];
	    }
	}
	close NEW;
    }

  }


