#!/usr/bin/env perl


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

my $infile1;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $infile1 = shift(@ARGV);
    }
}


printf STDERR "Starting program...\n";
my @enelist=();
my $totEtot=0;
my $totErep=0;

printf STDERR "Reading infile ..\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
my $start_reading=0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  if ( $inline =~ /^res1 / ) {
    $start_reading=1;
    printf STDERR "Setting start_reading true\n";
  } elsif ( $inline =~ /^SCORE/ ) {
    $start_reading=0;
    printf STDERR "Setting start_reading false\n";
  } elsif ( $start_reading ) {
      my @p=split(' ',$inline);
      my $resinfo = join(" ",$p[0],$p[1]);
      my $f={};
      $totEtot = $totEtot + $p[4];
      $totErep = $totErep + $p[6];
      $f->{resid}=$resinfo;
      $f->{Etot}=$p[4];
      $f->{Erep}=$p[6];
    push(@enelist,$f);
  }
}
close(INF1);
printf STDERR "Done reading %d +1 energies\n", $#enelist;

my @slist = ( sort {$b->{Etot} <=> $a->{Etot} } @enelist );

printf STDOUT "total   %.2f   %.2f\n\n", $totEtot, $totErep;

foreach my $f ( @slist ) {
    printf STDOUT "%s  %.2f   %.2f\n", $f->{resid}, $f->{Etot}, $f->{Erep};
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




