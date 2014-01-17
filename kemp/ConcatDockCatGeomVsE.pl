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


#printf STDERR "Starting program...\n";
my @enelist=();

#printf STDERR "Reading infile ..\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  my @p=split(' ',$inline);
  my $f={};
  $f->{decid}=$p[0];
  $f->{Elig}=$p[1];
  $f->{Etot}=$p[2];
  $f->{C_hetbase_dist} = $p[3];
  $f->{C_H_O_angle} = $p[4];
  $f->{H_O_hetcarb1_angle} = $p[5];
  $f->{torsion_OorN_to_C1} = $p[6];
  $f->{alt_C_hetbase_dist} = $p[7];
  $f->{alt_C_H_O_angle} = $p[8];
  $f->{alt_H_O_hetcarb1_angle} = $p[9];
  $f->{alt_torsion_OorN_to_C1} = $p[10];
  
  push(@enelist,$f);
  }

close(INF1);
printf STDERR "Done reading %d +1 energies\n", $#enelist;

my @slist = ( sort {$a->{Elig} <=> $b->{Elig} } @enelist );


foreach my $f ( @slist ) {
    printf STDOUT "%s  %.2f  %.2f  %.2f  %.2f  %.2f  %.2f %.2f  %.2f  %.2f  %.2f\n", $f->{decid}, $f->{Elig}, $f->{Etot},$f->{C_hetbase_dist},$f->{C_H_O_angle},$f->{H_O_hetcarb1_angle},$f->{torsion_OorN_to_C1}, $f->{alt_C_hetbase_dist},$f->{alt_C_H_O_angle},$f->{alt_H_O_hetcarb1_angle},$f->{alt_torsion_OorN_to_C1};
}
#printf STDOUT "\n\n";

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




