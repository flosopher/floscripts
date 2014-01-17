#!/usr/bin/perl


# script to read in all the files from a design run and delete those that have sequences that occur multiple times
# if a sequence occurs multiple times, the file with the lowest bk_tot is kept
# the script has to be called from a directory that contains the design files as well as a file that contains all the sequences 
# in fasta format
#
# Florian Richter, Baker lab, 06/2007
#


use strict;


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

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: give name of enzyme. The file despos_6_8_\${enzyme}.txt, containing the design positions, has to be present in the directory, and the file \${enzyme}_al_cont.fasta, containing the correctly aligned homologous sequences has to be present in the 'homologs' subdirectory \n";
  printf STDERR "\n";
  exit 1;
}

my $enzyme;
my $design_run = "huargh";
my $designposfile;
my @DesSeqArray = ();
my @DesPosArray = ();


if($#ARGV== -1) {&usage();}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $enzyme = shift(@ARGV);
    $design_run = shift(@ARGV);
    }
}

my $DesFileString = ${enzyme}."_des_".${design_run}."_";
my $DesFileStringLen = length($DesFileString);   #WARNING

#design positions read, no read in fasta sequences

my $NumDesSeqs = 0;
my $SeqFileLine;

#now read in the designed sequences
my $DesSeqFile = "${enzyme}_des_".${design_run}.".fasta";
#my $DesSeqFile = "${enzyme}_des_useisc.fasta";
#printf STDERR "Warning: Sequence file name hardcoded in current copy of script to accomodate weight factor differences\n";
my $DesSeqFileLine;
my @NameDesSeqArray = ();

    
open(DSFILE,$DesSeqFile) || die "Can't open $DesSeqFile";
    
while($DesSeqFileLine=<DSFILE>) {
   chomp;

   if (substr($DesSeqFileLine,0,1) eq '>') {
       $NumDesSeqs++;
       #my $structnum = "struct".$NumDesSeqs;
       #printf STDERR "%s\n",$structnum;
       $NameDesSeqArray[$NumDesSeqs-1] = substr($DesSeqFileLine,$DesFileStringLen+1,4);
   }

   elsif (substr($DesSeqFileLine,0,1) eq ' ' || substr($DesSeqFileLine,0,1) eq '#') {}

   else {substr($DesSeqArray[$NumDesSeqs-1],-1) = $DesSeqFileLine;}

}
close DSFILE;

printf STDERR "${enzyme}: Alignment file with %s designed sequences read. \n",$NumDesSeqs;
printf STDERR "%s\n",$NameDesSeqArray[1];

#$NumDesSeqs = 2;

my @RemoveSeqs = ();
#for( my $ii = 0; $ii < $NumDesSeqs; $ii++) { $RemoveSeqs[$ii] = 0;}

for( my $seqcount=0; $seqcount < $NumDesSeqs; $seqcount++) {

    my $CurFileName = $DesFileString.$NameDesSeqArray[$seqcount].".pdb";
    #printf STDERR "%s\n",$CurFileName;
    if(-e $CurFileName){

	#printf STDERR "miep ";
	my $CurSeqDeleteFlag = 0;
	my $tmpstring = readpipe "grep bk_tot $CurFileName";
	
	my $CurSeq_bk_tot = (split(' ',$tmpstring))[1];
	printf STDERR "$CurSeq_bk_tot \n";
	
	for(my $compare_count = $seqcount+1; $compare_count < $NumDesSeqs; $compare_count++) {
	    my $CurCompareFileName = $DesFileString.$NameDesSeqArray[$compare_count].".pdb";
	    
	    if( -e $CurCompareFileName && !$CurSeqDeleteFlag && ($DesSeqArray[$seqcount] eq $DesSeqArray[$compare_count])){

		printf STDERR "Sequences for $seqcount+1 and $compare_count+1 are equal\n";
		
		#my $compare_structnum = "struct".($seqcount+$compare_count);
		my $compare_tmpstring = readpipe "grep bk_tot $CurCompareFileName";
		my $CompareSeq_bk_tot = (split(' ',$compare_tmpstring))[1];

		if($CurSeq_bk_tot > $CompareSeq_bk_tot) {
		    printf STDERR "removing $CurFileName \n";
		    system "rm $CurFileName";
		    $CurSeqDeleteFlag = 1;
		}
		else {
		    printf STDERR "removing $CurCompareFileName \n";
		    system "rm $CurCompareFileName";
		}
	    }
	}
    }
}


		
	






