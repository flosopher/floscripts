#!/usr/bin/perl


# script to read in a file containing alignments in Fasta format and another
# file containing the design positions, and then calculate the frequency
# of residues observed at the design positions
#
# Florian Richter, Baker lab, 05/2007
#


use strict;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: give name of enzyme. The file despos_6_8_\${enzyme}.txt, containing the design positions, has to be present in the directory, and the file \${enzyme}_al_cont.fasta, containing the correctly aligned homologous sequences has to be present in the 'homologs' subdirectory \n";
  printf STDERR "\n";
  exit 1;
}

my $enzyme;
my $mode;
my $designposfile;
my $Homo_Alfile;
my @HomoSeqArray = ();
my @DesSeqArray = ();
my @DesPosArray = ();
my @HomoActCharges = ();
my @DesActCharges = ();


if($#ARGV== -1) {&usage();}

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $enzyme = shift(@ARGV);
    $mode = shift(@ARGV);
    }
}

$designposfile = "despos_6_8_${enzyme}.txt";

#first read in design positions
open(DFILE,$designposfile);
@DesPosArray = split(' ',<DFILE>);
close DFILE;

my $NumDesPos = scalar @DesPosArray;

printf STDERR "${enzyme}: Design Position file read, %s variable positions.\n",$NumDesPos;

#design positions read, no read in fasta sequences
my $NumHomoSeqs = 0;
my $NumDesSeqs = 0;
my $SeqFileLine;

$Homo_Alfile = "homologs/${enzyme}_al_cont.fasta";
open(SAFILE,$Homo_Alfile);

while($SeqFileLine=<SAFILE>) {
    chomp;

    if (substr($SeqFileLine,0,1) eq '>') {$NumHomoSeqs++;}

    elsif (substr($SeqFileLine,0,1) eq ' ') {}

    else {substr($HomoSeqArray[$NumHomoSeqs-1],-1) = $SeqFileLine;}

}
close SAFILE;

if($enzyme eq '1dqx'){
    
    for(my $dq_count=0;$dq_count<$NumHomoSeqs;$dq_count++){
	my $sbuf = substr($HomoSeqArray[$dq_count],90,54);
	substr($HomoSeqArray[$dq_count],-1) = $sbuf;
    }

    printf STDERR substr($HomoSeqArray[0],273,4);
}



printf STDERR "${enzyme}: Alignment file with %s homologous sequences read. %s\n",$NumHomoSeqs, scalar @HomoSeqArray;

#printf STDERR "$HomoSeqArray[42]\n";

#now read in the designed sequences
my $DesSeqFile = "workruns/${enzyme}_des.fasta";
my $DesSeqFileLine;

if($mode eq 'des') {
    
    open(DSFILE,$DesSeqFile) || die "Can't open $DesSeqFile";
    
    while($DesSeqFileLine=<DSFILE>) {
    chomp;

    if (substr($DesSeqFileLine,0,1) eq '>') {$NumDesSeqs++;}

    elsif (substr($DesSeqFileLine,0,1) eq ' ') {}

    else {substr($DesSeqArray[$NumDesSeqs-1],-1) = $DesSeqFileLine;}

    }
    close DSFILE;

    printf STDERR "${enzyme}: Alignment file with %s designed sequences read. %s\n",$NumDesSeqs, scalar @DesSeqArray;
}


#aligned fasta sequences read, now calculate the frequencies

my @HomoFreqArray = (); #will be array of hashes
my @DesFreqArray = ();
my $count_arr=();  #will be array of counts at that position

for( my $dcount=0; $dcount<$NumDesPos; $dcount++) {

    my $homo_dist={};
    my $des_dist={};
    my $ncounts=0;

    for(my $scount=0; $scount<$NumHomoSeqs; $scount++) {
	my $currAA = substr($HomoSeqArray[$scount],$DesPosArray[$dcount]-1,1);

	if ( $currAA ne "-") {
	    $homo_dist->{$currAA}=0 if ( ! defined $homo_dist->{$currAA} );
	    $homo_dist->{$currAA}++;
	    $ncounts++;
	}
	
	if( $currAA eq "K" || $currAA eq "R"){
	    $HomoActCharges[$scount]->{Pos}++;
	}
	elsif( $currAA eq "E" || $currAA eq "D"){
	    $HomoActCharges[$scount]->{Neg}++;
	}
    }
    push(@HomoFreqArray,$homo_dist);
    push(@{$count_arr}, $ncounts);

    if($mode eq 'des') {
	for(my $scount=0; $scount<$NumDesSeqs; $scount++) {
	   my $currAA = substr($DesSeqArray[$scount],$DesPosArray[$dcount]-1,1); 
	   $des_dist->{$currAA}=0 if ( ! defined $des_dist->{$currAA} );
	   $des_dist->{$currAA}++;

	   if( $currAA eq "K" || $currAA eq "R"){
	    $DesActCharges[$scount]->{Pos}++;
	   }
	   elsif( $currAA eq "E" || $currAA eq "D"){
	    $DesActCharges[$scount]->{Neg}++;
	   }
        }

	push(@DesFreqArray,$des_dist);
    }
}

#add block to calculate charges in complete protein here
#have to use raw sequence data
#

printf STDOUT "pos/neg charges at design positions of homologous sequences:\n";

for (my $ii=0; $ii<$NumHomoSeqs; $ii++) {
	printf STDOUT $HomoActCharges[$ii]->{Pos}; printf STDOUT  "/"; printf STDOUT $HomoActCharges[$ii]->{Neg}; printf STDOUT "  ";
}

if($mode eq 'des'){

    printf STDOUT "\n\n pos/neg charges at design positions of designed sequences: \n";
    for (my $ii=0; $ii<$NumDesSeqs; $ii++) {
	printf STDOUT $DesActCharges[$ii]->{Pos}; printf STDOUT "/"; printf STDOUT $DesActCharges[$ii]->{Neg}; printf STDOUT "  ";
    }
}
printf STDOUT "\n";


printf STDOUT "Position          Natural distribution      ||         Designed sequences distribution\n";

for( my $dcount=0; $dcount<$NumDesPos; $dcount++) {
    my $Homo_DesPos = $HomoFreqArray[$dcount];
    my $Des_DesPos;
    if($mode eq 'des') {$Des_DesPos = $DesFreqArray[$dcount];}

    #my %shiit = sort { $DesPos->{$a} <=> $DesPos->{$b} } keys %{$DesPos};
    #printf STDOUT %shiit;
    my $WtRes = substr($HomoSeqArray[0],$DesPosArray[$dcount]-1,1);
    printf STDOUT "$WtRes$DesPosArray[$dcount]"; printf STDOUT "   ";
    #foreach my $argf (values %shiit ) { printf STDOUT $argf; }
    #printf STDOUT values %{$DesPos};
    foreach my $aa ( keys %{$Homo_DesPos} ) {
	printf STDOUT "%.2f %s, ", ($Homo_DesPos->{$aa}+0.0)/$count_arr->[$dcount]+0.0, $aa;

    }
    printf STDOUT " || ";

    if($mode eq 'des') {
	foreach my $aa ( keys %{$Des_DesPos} ) {
	    printf STDOUT " %.2f %s, ", ($Des_DesPos->{$aa}+0.0)/$NumDesSeqs, $aa; 
	}
    }
    printf STDOUT "\n";
    
}



#printf STDERR "$DesPosArray[5], \n";
#my $debug1 = substr($HomoSeqArray[5],$DesPosArray[5]-1,1);
#printf STDERR "$debug1\n";
#printf STDERR "$HomoFreqArray[5][0]->{id}, $HomoFreqArray[5][0]->{num}\n";


