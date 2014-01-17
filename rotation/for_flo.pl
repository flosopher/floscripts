#!/usr/bin/env perl


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1 infile2\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

my $infile1;
my $infile2;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $infile1 = shift(@ARGV);
    $infile2 = shift(@ARGV);
  }
}

&usage() if (! defined $infile2);

printf STDERR "Starting program...\n";
my @enelist=();

printf STDERR "Reading infile 1...\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
my $start_reading=0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;
  if ( $inline =~ /^res aa / ) {
    $start_reading=1;
    printf STDERR "Setting start_reading true\n";
  } elsif ( $inline =~ /^totals/ ) {
    $start_reading=0;
    printf STDERR "Setting start_reading false\n";
  } elsif ( $start_reading ) {
    my @p=split(' ',$inline);
    push(@enelist,$p[3]);
    printf STDERR "Got energy %d\n",$p[3];
  }
}
close(INF1);

printf STDERR "Done reading %d energies\n", $#enelist;


printf STDERR "Reading infile 2...\n";
open(INF2,"$infile2") || die "Can't open file $infile2\n";
$start_reading=0;
printf STDOUT "Resnum Resname Ediff\n";
while (<INF2>) {
  chomp;   # remove newline if present
  my $inline=$_;
  if ( $inline =~ /^res aa / ) {
    $start_reading=1;
  } elsif ( $inline =~ /^totals/ ) {
    $start_reading=0;
  } elsif ( $start_reading ) {
    my @p=split(' ',$inline);
    my $enediff = $p[3] - shift(@enelist);
    printf STDOUT "%d %s %f\n",$p[0],$p[1],$enediff;
  }
}
close(INF2);


#  @slist = ( sort { $a<=>$b } @unsorted )





