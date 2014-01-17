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

open(INF2, "$infile2") || die "Can't open $infile2\n".;
my $template_line=$_;
my @temparray = split(' ',$template_line);
close (INF2);

printf STDERR "Reading infile 1...\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
my $start_reading=0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  if ( $inline =~ /^HETATM / ) {
      my @des_array = split(' ', $inline);
      if ($des_array[2] = VKNZ) {
 elsif ( $start_reading ) {
    my @p=split(' ',$inline);
    push(@enelist,$p[3]);
  }
}
close(INF1);

printf STDERR "Done reading %d energies\n", $#enelist;

my @enediffs=();

printf STDERR "Reading infile 2...\n";
open(INF2,"$infile2") || die "Can't open file $infile2\n";
$start_reading=0;
#printf STDOUT "Resnum Resname Ediff\n";
while (<INF2>) {
  chomp;   # remove newline if present
  my $inline=$_;
  if ( $inline =~ /^res aa / ) {
    $start_reading=1;
  } elsif ( $inline =~ /^totals/ ) {
    $start_reading=0;
  } elsif ( $start_reading ) {
    my @p=split(' ',$inline);
    my $resinfo = join(" ",$p[0],$p[1]); 
    my $enediff =  shift(@enelist) - $p[3];

    if ($enediff >= 0.01) {
    my $f={};
    $f->{Ediff}=$enediff;
    $f->{resid}=$resinfo;
    push(@enediffs,$f);  
    }
  }
}
close(INF2);

my @slist = ( sort { $b->{Ediff} <=> $a->{Ediff} } @enediffs );   # array is being sorted 

foreach my $f ( @slist ) {
    printf STDOUT "%s %f\n", $f->{resid}, $f->{Ediff};
}

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




