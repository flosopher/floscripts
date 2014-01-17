#!/usr/bin/env perl

    use strict;


my $design;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   DockFunnelAnalysis.pl $design, dock rmsd file has to be in folder\n \n";
  printf STDERR "\n";
  exit 1;
}



while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    }
}


printf STDERR "Starting program...\n";
my @enelist=();
my $bufferline;
my $minimized = {};

printf STDERR "Reading infile ..\n";
open(INF1,"${design}_DockEvsRMSD.ana") || die "Can't open file ${design}_DockEvsRMSD.ana\n";
$bufferline = <INF1>;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  my @p=split(' ',$inline);
  my $f={};
  $f->{decid}=$p[0];
  $f->{Elig}=$p[1];
  $f->{DecRMSD}=$p[2];
  $f->{Etot} = $p[3];
  #printf STDERR "%s  ",substr($p[0],-3); 
  if( substr($p[0],-3) eq "min") {
      $minimized->{decid} = $f->{decid};
      $minimized->{Elig} = $f->{Elig};
      $minimized->{DecRMSD} = $f->{DecRMSD};
      $minimized->{Etot} = $f->{Etot};
  }

  if($f->{Etot} != 0 || $f->{Elig} != 0 ||$f->{DecRMSD} != 0){ 
     push(@enelist,$f);
 }
}
close(INF1);

my $num_decoys = $#enelist;

printf STDERR "Done reading %d +1 energies\n", $num_decoys;

my @Elig_slist = ( sort {$a->{Elig} <=> $b->{Elig} } @enelist );
my @RMSD_slist = ( sort {$b->{DecRMSD} <=> $a->{DecRMSD} } @enelist );

my $top50rmsdnum = $num_decoys / 2;

my $tot_high_RMSD_E = 0;
my $outliers = 0;

#open(DEBUGF, ">${design}_funnel_ana_debug.out");

my $i;
for($i = 0; $i < $top50rmsdnum; $i++) {
    if ($RMSD_slist[$i]->{Elig} <= 5){
	$tot_high_RMSD_E = $tot_high_RMSD_E + $RMSD_slist[$i]->{Elig};
    }
    else {$outliers++;}
    
    #printf DEBUGF "%s %.2f %.2f %.2f\n",$RMSD_slist[$i]->{decid}, $RMSD_slist[$i]->{Elig}, $RMSD_slist[$i]->{DecRMSD}, $RMSD_slist[$i]->{Etot};
}
#close(DEBUGF);



my $av_high_RMSD_E = $tot_high_RMSD_E / ($top50rmsdnum - $outliers);
my $funnel_depth = $Elig_slist[0]->{Elig} - $av_high_RMSD_E;

my $design_E_diff = $minimized->{Elig} - $Elig_slist[0]->{Elig};

#printf STDOUT "$design %.2f %.2f\n", $funnel_depth, $design_E_diff;
printf STDOUT "$design %.2f %.2f\n", $funnel_depth, $minimized->{Elig};

#debug shit

#printf STDERR "%.4f %.4f\n",$av_high_RMSD_E,$Elig_slist[0]->{Elig};

