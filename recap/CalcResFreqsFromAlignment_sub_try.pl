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

my $NumDesPos = 0;
my $NumAlSeqs = 0;
my $count_arr=();  #will be array of counts at that position

sub CalcFreqs {

    my @SeqArray = @{$_[0]};
    my @PosArray = @{$_[1]};


    my @IdFreqArray = (); #will be array of hashes
    #my $count_arr=();  #will be array of counts at that position

    for( my $dcount=0; $dcount<$NumDesPos; $dcount++) {

	my $dist={};
	my $ncounts=0;

	for(my $scount=0; $scount<$NumAlSeqs; $scount++) {
	    my $currAA = substr($SeqArray[$scount],$PosArray[$dcount]-1,1);

	    if ( $currAA ne "-") {
		$dist->{$currAA}=0 if ( ! defined $dist->{$currAA} );
		$dist->{$currAA}++;
		$ncounts++;
	    }
	}
	push(@IdFreqArray,$dist);
	push(@{$count_arr}, $ncounts);
    }

    return @IdFreqArray;

}

my $enzyme;
my $mode;
my $designposfile;
my $SeqAlfile;
my @Sequences = ();

my @DesPosArray = ();


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

$NumDesPos = scalar @DesPosArray;

printf STDOUT "${enzyme}: Design Position file read, %s variable positions.\n",$NumDesPos;

#design positions read, no read in fasta sequences
my $SeqFileLine;

$SeqAlfile = "homologs/${enzyme}_al_cont.fasta";
open(SAFILE,$SeqAlfile);

while($SeqFileLine=<SAFILE>) {
    chomp;

    if (substr($SeqFileLine,0,1) eq '>') {$NumAlSeqs++;}

    elsif (substr($SeqFileLine,0,1) eq ' ') {}

    else {substr($Sequences[$NumAlSeqs-1],-1) = $SeqFileLine;}

}

close SAFILE;

printf STDOUT "${enzyme}: Alignment file with %s sequences read. %s\n",$NumAlSeqs, scalar @Sequences;

#printf STDERR "$SeqArray[42]\n";

#aligned fasta sequences read, now calculate the frequencies

my @homo_ids=();

@homo_ids = &CalcFreqs(${@Sequences},${@DesPosArray});

printf STDOUT "Position          Natural distribution      ||         Designed sequences distribution\n";

for( my $dcount=0; $dcount<$NumDesPos; $dcount++) {
    my $DesPos = $homo_ids[$dcount];

    #my %shiit = sort { $DesPos->{$a} <=> $DesPos->{$b} } keys %{$DesPos};
    #printf STDOUT %shiit;

    printf STDOUT $DesPosArray[$dcount]; printf STDOUT "   ";
    #foreach my $argf (values %shiit ) { printf STDOUT $argf; }
    #printf STDOUT values %{$DesPos};
    foreach my $aa ( keys %{$DesPos} ) {
	printf STDOUT "%.2f %s, ", ($DesPos->{$aa}+0.0)/$count_arr->[$dcount]+0.0, $aa, ;

    }
    printf STDOUT "|| \n";
    
}



#printf STDERR "$DesPosArray[5], \n";
#my $debug1 = substr($SeqArray[5],$DesPosArray[5]-1,1);
#printf STDERR "$debug1\n";
#printf STDERR "$IdFreqArray[5][0]->{id}, $IdFreqArray[5][0]->{num}\n";


