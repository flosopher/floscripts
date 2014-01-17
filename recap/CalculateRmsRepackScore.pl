#!/usr/bin/perl


# use in c shell script
#
#foreach enzyme (1c2t 1h2j 1oex 6cpa)
#foreach? cd $enzyme
#foreach? cp ${enzyme}_score.pdb workruns/
#foreach? echo  >> RepackRMS.ana
#foreach? echo $enzyme >> RepackRMS.ana
#foreach? ~/scripts/recap/CalculateRmsRepackScore.pl $enzyme >> RepackRMS.ana
#foreach? cd ..
#foreach? end
#


use strict;
my $enzyme;


my @RepackRmsArray = ();
my $TotRSD = 0;
my $mode;
my @DesPosArray = ();

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: give name of enzyme. The file despos_6_8_\${enzyme}.txt, containing the design positions, has to be present in the directory, and the score and repack files have to be present in the workrun directory.\n";
  printf STDERR "\n";
  exit 1;
}
if($#ARGV== -1) {&usage();}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $enzyme = shift(@ARGV);
    $mode = shift(@ARGV);
    }
}
#

my $ScoreFile = "workruns/${enzyme}_score.pdb";
my $RepackFile = "workruns/${enzyme}_repack.pdb";

open(DFILE,"despos_6_8_${enzyme}.txt") || die "Can't open despos file";
@DesPosArray = split(' ',<DFILE>);
close DFILE;

my $NumDesPos = scalar @DesPosArray;
my $DesignPosRmsLine = $DesPosArray[0];
printf STDOUT "RMSDs between repacked and scored structure: ";
for( my $dcount=0; $dcount<$NumDesPos; $dcount++) {
    
    my $rmsline = readpipe "/work/wollacott/py_scripts/tools/rms_cur.py -t $ScoreFile -p $RepackFile -s \"resi=$DesPosArray[$dcount]\;element!=H\"";


    my @tmparray = split(' ',$rmsline);
    $RepackRmsArray[$dcount]=$tmparray[1];
    $TotRSD = $TotRSD + $RepackRmsArray[$dcount];
    printf STDOUT "$DesPosArray[$dcount] %.2f, ",$RepackRmsArray[$dcount];
    if($dcount != 0) {$DesignPosRmsLine = $DesignPosRmsLine.",".$DesPosArray[$dcount];}

}
printf STDOUT "$DesignPosRmsLine\n";
my $totrmsline = readpipe "/work/wollacott/py_scripts/tools/rms_cur.py -t $ScoreFile -p $RepackFile -s \"resi=${DesignPosRmsLine};element!=H\"";
my @TotRMSD = split(' ',$totrmsline);
printf STDOUT "\n Total RMSD of repacked design positions: $TotRMSD[1]\n";
if($TotRMSD[1] != ($TotRSD/$NumDesPos)) {printf STDOUT "oink";}
