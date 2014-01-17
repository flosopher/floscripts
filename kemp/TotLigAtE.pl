#!/usr/bin/env perl


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

my $infile1;
my $mode = 0;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $infile1 = shift(@ARGV);
    $mode = shift(@ARGV);
    }
}

if ($mode) {
    if ($mode eq "score" ) {
	printf STDERR "Running in score mode...\n";
    }
}

my $CalcAtEnergies = 0;
$CalcAtEnergies = 1;


printf STDERR "Starting program...\n";
my @enelist=();
my $totEtot=0;
my $totErep=0;
my @AtElist = ();

printf STDERR "Reading infile ..\n";
open(INF1,"$infile1") || die "Can't open file $infile1\n";
my $start_reading=0;
my $resume_reading =0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  

  if ( $CalcAtEnergies ) {
  if ($inline =~ /^atm_id atm_name / ) {
      $start_reading =1;
      printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^energies-average/ ) {   #ask john how to recognize empty line
     $start_reading = 0;
     printf STDERR "Setting start_reading false\n"
     }

  elsif ( $start_reading) {
      my @atarray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
      my $x = {};
      $x->{AtName} = $atarray[1];
      $x->{EAtTot} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
      $x->{EAtAtr} = $atarray[2]; 
      $x->{EAtRep} = $atarray[3];
      $x->{EAtSol} = $atarray[4];
      $x->{EAtHbnd} = $atarray[5];
      push(@AtElist, $x);
  }
}

if ( $inline =~ /^res1 / ) {
    $resume_reading=1;
    printf STDERR "Setting resume_reading true\n";
  } elsif ( $inline =~ /^SCORE/ ) {
    $resume_reading=0;
    printf STDERR "Setting resume_reading false\n";
  } elsif ( $resume_reading ) {
      my @p=split(' ',$inline);
      my $resinfo = join(" ",$p[2],$p[1]);
      my $f={};
      $totEtot = $totEtot + $p[5];
      $totErep = $totErep + $p[7];
      $f->{resid}=$resinfo;
      $f->{Etot}=$p[5];
      $f->{Erep}=$p[7];
    push(@enelist,$f);
  }
}
close(INF1);
printf STDERR "Done reading %d +1 energies\n", $#enelist;


#block to read in other file
my $NbefRepE;

 if ( $CalcAtEnergies and $mode) {
     printf STDERR "Getting score energy...\n";
	 my $score_reading = 0;

     my $file2 = substr($infile1, 0, - 8);
         
     open(FILE2,"${file2}_score.pdb") || die "Can't open file $file2\n";
     while (<FILE2>){
	 chomp;
	 my $inline=$_;
 
  if ($inline =~ /^atm_id atm_name / ) {
      $score_reading =1;
      printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^energies-average/ ) {   #ask john how to recognize empty line
     $score_reading = 0;
     printf STDERR "Setting start_reading false\n"
     }

  elsif ( $score_reading) {
       my @at2array=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
       if ($at2array[1] eq "Nhis") {
	   $NbefRepE = $at2array[3];
       }
      #my $x = {};
      #$x->{AtName} = $atarray[1];
      #$x->{EAtTot} = $atarray[2]+$atarray[3]+$atarray[4]+$atarray[5];
      #$x->{EAtAtr} = $atarray[2]; 
      #$x->{EAtRep} = $atarray[3];
      #$x->{EAtSol} = $atarray[4];
      #$x->{EAtHbnd} = $atarray[5];
      #push(@AtElist, $x);
  }
}
}

#end of block to read in other file



if ( $CalcAtEnergies ) {
my @sATlist = ( sort {$b->{EAtTot} <=> $a->{EAtTot} } @AtElist );

foreach my $x ( @sATlist ) {
    if ($x->{AtName} eq "Nhis") {
	printf STDOUT "Nhis energies before minimization: %.2f , after minimization: %.2f \n", $NbefRepE, $x->{EAtRep};
}
}
}
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



