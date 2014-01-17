#!/usr/bin/env perl


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

my $design;
my $decoy;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $decoy = shift(@ARGV);
    }
}

if(substr($decoy,-8,-4) eq "TS_H") {exit 1;}

my $DecName = substr($decoy,0,-4);
my $DecTotE = 0;
my $DecLigE = 0;
my $DecRMSD = -1;


open(INF1,"$decoy") || die "Can't open file $decoy\n";
my $start_reading=0;
while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  

  if ($inline =~ /^CHARGE / ) {
      $start_reading =1;
      #printf STDERR "Setting start_reading true\n";
 } elsif ( $inline =~ /^res aa/ ) {   #ask john how to recognize empty line
     $start_reading = 0;
     #printf STDERR "Setting start_reading false\n"
     }

  elsif ( $start_reading) {
      my @linearray=split(' ',$inline);
      #my $AtID = join(" ",$atarray[0],$atarray[1]);
      if ($linearray[0] eq "bk_tot:"){ $DecTotE = $linearray[1];}
      if ($linearray[0] eq "lig_sum:"){ $DecLigE = $linearray[1];}
  }
}
close(INF1);

my $rmsdline;

if(substr($design,0,3) eq "amw") {
   
 $rmsdline= readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t ../${design}.pdb -p ${decoy} -s HET";
}  

elsif(substr($design,0,5) eq "match") {
 $rmsdline= readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t ../${design}_F.pdb -p ${decoy} -s HET";
}   

elsif($design eq "KAB") {
$rmsdline= readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t /work/flo/edesign/designs/kemp/${design}.pdb -p ${decoy} -s HET";  
}

else {
$rmsdline= readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t /work/flo/edesign/designs/kemp/${design}_stTS.pdb -p ${decoy} -s HET";  
}

#open(RMSDfile,"rmsdtempfile") || die "No RMSD file found.\n";
#  while (<RMSDfile>) {
#      my $inline=$_;
my @linearray = split(' ',$rmsdline);
$DecRMSD = $linearray[2];
 

  printf STDOUT "%s %.2f %.2f %.2f\n", $DecName, $DecTotE, $DecLigE, $DecRMSD;

