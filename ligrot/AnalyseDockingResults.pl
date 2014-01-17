#!/usr/bin/env perl

#script to read in sidechain and ligand energies and rmsds for a docking calculation

## function: zPad(num,len) 
## pads the input number with leading zeros
## to return a string of the desired length
sub zPad {
    my $num=shift;
    my $newlen=shift;

    my $origlen=length($num);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$num="0".$num;
    }
    return $num;
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



sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

if($#ARGV== -1) {&usage();}

my $enzyme;
my $numstruct = 0;
my @tmpdecoylist = ();
my @DesPosArray = ();
my $RosettaCode = 0;
my $DesignPosRmsLine;
my $InputFile; 
my $RepackFile;
my $MinFile; 
my $OutCol1Len = 30;
my $OutCol2Len = 8;

sub ReadDockOutputStructPDB {

    my $CurFile = $_[0];
    printf STDERR "Reading $CurFile ...\n";
    open(INF1,$CurFile);
    my $start_reading=0;
    my $CurDecValues={};
	
    while (<INF1>) {
	chomp;   # remove newline if present
	my $inline=$_;           #??? current line in file
  
	if ($inline =~ /^CHARGE / ) {
	    $start_reading =1;
		#printf STDERR "Setting start_reading true\n";
	} elsif ( $inline =~ /^res aa/ ) {   #ask john how to recognize empty line
		$start_reading = 0;
     #printf STDERR "Setting start_reading false\n"
	  }

	  elsif ( $start_reading) {
	      my @linearray=split(' ',$inline);
		#my $AtID = join(" ",$atarray[0],$atarray[1]);
	      if ($linearray[0] eq "bk_tot:"){ $CurDecValues->{bktot} = $linearray[1];}
	      if ($linearray[0] eq "lig_sum:"){ $CurDecValues->{ligsum} = $linearray[1];}
	    }
	}
    close(INF1);

    my $ligrmsdline;
    my $scrmsdline;
	
    $ligrmsdline= readpipe "/work/wollacott/py_scripts/tools/rms_cur.py -t $InputFile -p $CurFile  -s \"HET;element!=H\"";  
    $scrmsdline = readpipe "/work/wollacott/py_scripts/tools/rms_cur.py -t $InputFile -p $CurFile  -s \"resi=${DesignPosRmsLine};element!=H\"";

    my @ligrmsdarray = split(' ',$ligrmsdline);
    my @scrmsdarray = split(' ',$scrmsdline);
    $CurDecValues->{ligrms} = $ligrmsdarray[1];
    $CurDecValues->{scrms} = $scrmsdarray[1];

    return $CurDecValues;

}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $enzyme = shift(@ARGV);
    $RosettaCode = shift(@ARGV);
    $numstruct = shift(@ARGV);
    printf STDERR "$enzyme $RosettaCode $numstruct \n";
    }
}

#if($RosettaCode == 0){ printf STDERR "arrgh"; &usage(); exit 1;}

my $RosCode1 = substr($RosettaCode,0,2);
my $RosCode2 = substr($RosettaCode,2,4);

$InputFile = "workruns/${RosettaCode}_${enzyme}_input.pdb";
$RepackFile = "workruns/${RosettaCode}_${enzyme}_input_repacked.pdb";
$MinFile = "workruns/${RosettaCode}_${enzyme}_input_min.pdb";


if($numstruct == 0) {$numstruct = 50; printf STDERR "No input for the number of structures, using 50 as default.\n";
		 }

#--in the following block, the rmsd calculation for the sidechains is prepared

open(DFILE,"/work/flo/recap/${enzyme}/despos_6_8_${enzyme}.txt") || die "Can't open despos file";
@DesPosArray = split(' ',<DFILE>);
close DFILE;
my $NumDesPos = scalar @DesPosArray;

$DesignPosRmsLine = $DesPosArray[0];  #input line for wolla script
for( my $dcount=1; $dcount<$NumDesPos; $dcount++) {
    $DesignPosRmsLine = $DesignPosRmsLine.",".$DesPosArray[$dcount];
} 
printf STDERR "$DesignPosRmsLine .\n";

#--input line written, all design positions contained

for(my $ii=1; $ii<=$numstruct; $ii++) {
    my $convert_ii = &zPad($ii,4);

    my $curfile = "analysis/${RosCode1}${enzyme}_${convert_ii}.pdb";
    
    if(-e $curfile){
	
	my $CurDec = &ReadDockOutputStructPDB($curfile);
	$CurDec->{decname}="bm${enzyme}_${convert_ii}";
	push(@tmpdecoylist,$CurDec);
	printf STDERR "Done reading structure ${ii}.\n";
    }
    else {printf STDERR "bm${enzyme}_${convert_ii}.pdb doesn't exist.\n";}
}
    
my $InputDec = &ReadDockOutputStructPDB($InputFile);
$InputDec->{decname} = "${RosettaCode}_${enzyme}_input";
push(@tmpdecoylist,$InputDec);
my $RepackDec = &ReadDockOutputStructPDB($RepackFile);
$RepackDec->{decname} = "${RosettaCode}_${enzyme}_input_repacked";
push(@tmpdecoylist,$RepackDec);
my $MinDec = &ReadDockOutputStructPDB($MinFile);
$MinDec->{decname} = "${RosettaCode}_${enzyme}_input_min";
push(@tmpdecoylist,$MinDec);

my @decoylist = ( sort {$a->{ligsum} <=> $b->{ligsum} } @tmpdecoylist );

printf STDERR "\n\n";
printf STDOUT "#  Structure                         lig_sum        bk_tot     lig_rms    sidechain_rms \n";        

foreach my $f ( @decoylist ) {
    my $Curligsum = &spPad($f->{ligsum},$OutCol2Len);
    my $Curbktot = &spPad($f->{bktot},$OutCol2Len);
    my $Curligrms = &spPad($f->{ligrms},$OutCol2Len);
    my $Curscrms = &spPad($f->{scrms},$OutCol2Len);
    printf STDOUT "%s      %s      %s       %.2f        %.2f\n", &Padsp($f->{decname},$OutCol1Len), $Curligsum, $Curbktot, $Curligrms,$Curscrms;
} 



