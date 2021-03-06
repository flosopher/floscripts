#!/usr/bin/env perl


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

my $infile1;
my $design;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $infile1 = shift(@ARGV);
    $design = shift(@ARGV);
    }
}


printf STDERR "Starting program...\n";
my @enelist=();
my $TotETot = 0;
my $AvETot;
my $LowETot = 1000;

printf STDERR "Reading infile ..\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  my @p=split(' ',$inline);
  my $f={};
  $f->{decid}=$p[0];
  $f->{Etot}=$p[1];
  $TotETot = $TotETot + $f->{Etot};
  if ($f->{Etot} < $LowETot) {$LowETot = $f->{Etot} ;}
  $f->{Elig}=$p[2];
  $f->{DecRMSD} = $p[3];
  if($f->{Etot} != 0 || $f->{Elig} != 0 ||$f->{DecRMSD} != 0){ 
     push(@enelist,$f);
 }
}

close(INF1);
printf STDERR "Done reading %d +1 energies\n", $#enelist;

$AvETot = $TotETot / $#enelist;

open(TOTEFILE,">>../analysis/TotalAvEnergies.ana");
printf TOTEFILE "$design %.2f %.2f\n",$LowETot, $AvETot;
close(TOTEFILE);

my @slist = ( sort {$a->{Elig} <=> $b->{Elig} } @enelist );


foreach my $f ( @slist ) {
    printf STDOUT "%s  %.2f  %.2f  %.2f\n", $f->{decid}, $f->{Elig}, $f->{DecRMSD}, $f->{Etot};
}
printf STDOUT "\n\n";

printf STDERR "Done!\n";


#while ( ($Kbuf, $Vbuf) = each %Ediffs) {
#    printf STDOUT  "%s %f\n", $Kbuf,$Vbuf;
#}

#sub hashValueDescendingNum {
#    $Ediffs{$b} <=> $Ediffs{$a};
#}

#foreach $key (sort hashValueDescendingNum (keys(%Ediffs))) {
#    printf STDOUT "\t\t %f \t\t %s\n", $Ediffs{$key}, $key;
#}




