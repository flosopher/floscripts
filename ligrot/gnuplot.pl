#!/usr/bin/env perl

    use strict;


my $datafile;
my $Xname = "dummy";
my $Yname = "dummy";
my $Xcolumn = 3;
my $Ycolumn = 2;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:  datafile, column 1 label, column 2 yval, column 4 xval\n \n";
  printf STDERR "\n";
  exit 1;
}



while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $datafile = shift(@ARGV);
    $Xname = shift(@ARGV);
    $Yname = shift(@ARGV);
    }
}
my $plotname = substr($datafile,0,-3)."png";



open(DATAF,"$datafile") || die "Can't open datafile\n";

#read the first line to determine which is which
if( ($Xname ne "dummy") || ($Yname ne "dummy") ) {
  my $firstline = <DATAF>;
  my @firstline_array = split(' ',$firstline);
  my $xfound = 0;
  my $yfound = 0;
  for(my $ii = 0; $ii < scalar @firstline_array; $ii++){
    if( $firstline_array[$ii] eq $Xname) { $Xcolumn = $ii; $xfound = 1; }
    if( $firstline_array[$ii] eq $Yname) { $Ycolumn = $ii; $yfound = 1; }
  }

  if( !$xfound || !$yfound || ( ($firstline_array[0] ne "SCORES") && ($firstline_array[0] ne "description") && ($firstline_array[0] ne "SCORE:") ) ){
    die "first line of datafile is corrupted.\n";
  }
}
#read data to determine ranges

my $low_ca_rmsd = 100;
my $high_ca_rmsd = -1;
my $high_all_rmsd = -1;
my $low_E = 10000;
my $high_E = -10000;

while(<DATAF>){

    my @linearray = split(' ',$_);

    if($linearray[$Ycolumn] < $low_E) { $low_E = $linearray[$Ycolumn];}
    if($linearray[$Ycolumn] > $high_E) { $high_E = $linearray[$Ycolumn];}

    if($linearray[$Xcolumn] < $low_ca_rmsd) { $low_ca_rmsd = $linearray[$Xcolumn];}
    if($linearray[$Xcolumn] > $high_ca_rmsd) { $high_ca_rmsd = $linearray[$Xcolumn];}

    #if($linearray[3] > $high_all_rmsd) { $high_all_rmsd = $linearray[3];}

}

my $lower_ybound = $low_E - 5;
#my $higher_ybound = 100;
#my $ydiff = $high_E-$low_E
#my $yrange = $ydiff / 0.8
my $higher_ybound = $low_E + (($high_E - $low_E)/0.4);
$higher_ybound = $low_E + 40.0;
my $bigrmsd = 0;
if ($high_all_rmsd > $high_ca_rmsd) { $bigrmsd = $high_all_rmsd;}
else {$bigrmsd = $high_ca_rmsd;}

my $lower_xbound = 0;
my $higher_xbound = $bigrmsd + (0.6 * $bigrmsd);
if($higher_xbound > 10){ $higher_xbound = 10; }

my $Xgraph = $Xcolumn + 1;
my $Ygraph = $Ycolumn + 1;

open(GNUSCRIPT,">tempplotscript");
#printf GNUSCRIPT "set title \"${datafile}\"\n";
#printf GNUSCRIPT "set xlabel \"${Xname}\"\n";
#printf GNUSCRIPT "set ylabel \"${Yname}\"\n";
#printf GNUSCRIPT "p \'${datafile}\' u ${Xgraph}:${Ygraph} \n";
#printf GNUSCRIPT "p \'${datafile}\' u ${Xgraph}:${Ygraph} title \'RMSD_Ca\', \'${datafile}\' \n"; #u 4:2 title \'RMSD_all\', \'${datafile}\' u 5:2 title \'RMSD_cat\' \n";
printf GNUSCRIPT "set xrange \[-0:%s\]\n", $higher_xbound;
printf GNUSCRIPT "set yrange \[%s:%s\]\n", $lower_ybound, $higher_ybound;

#while(<DATAF>){
#    my @linearray = split(' ',$_);
#    my $desname = substr($linearray[0],0,2).substr($linearray[0],5,2);
#    #my $desname = substr($linearray[0],6,6);
#    if(substr($desname,-1,1) eq "M") { $desname = substr($desname,0,-1);}
#    if(substr($desname,-1,1) eq "Q") { $desname = substr($desname,0,-1);}
#    if(substr($desname,-1,1) eq "_") { $desname = substr($desname,0,-1);}
#    printf GNUSCRIPT "set label \"%s\" at %.4f,%.4f\n",$desname,$linearray[1],$linearray[2];
#}
#printf GNUSCRIPT "replot\n";
printf GNUSCRIPT "set terminal postscript color\n";
printf GNUSCRIPT "set terminal png\n";
printf GNUSCRIPT "set output \"$plotname\"\n";
printf GNUSCRIPT "p \'${datafile}\' u ${Xgraph}:${Ygraph} \n";


printf GNUSCRIPT "exit\n";

close(GNUSCRIPT);
close(DATAF);

system "gnuplot < tempplotscript";
