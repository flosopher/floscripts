#!/usr/bin/env perl

    use strict;


my $datafile;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage:  datafile, column 1 label, column 2 xval, column 3 yval\n \n";
  printf STDERR "\n";
  exit 1;
}



while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $datafile = shift(@ARGV);
    }
}

open(DATAF,"$datafile") || die "Can't open datafile\n";

open(GNUSCRIPT,">tempplotscript");
printf GNUSCRIPT "p \'${datafile}\' u 2:3\n";
printf GNUSCRIPT "set xrange \[-15:0\]\n";
printf GNUSCRIPT "set yrange \[-100:1200\]\n";
while(<DATAF>){
    my @linearray = split(' ',$_);
    my $desname = substr($linearray[0],0,2).substr($linearray[0],5,2);
    #my $desname = substr($linearray[0],6,6);
    if(substr($desname,-1,1) eq "M") { $desname = substr($desname,0,-1);}
    if(substr($desname,-1,1) eq "Q") { $desname = substr($desname,0,-1);}
    if(substr($desname,-1,1) eq "_") { $desname = substr($desname,0,-1);}
    printf GNUSCRIPT "set label \"%s\" at %.4f,%.4f\n",$desname,$linearray[1],$linearray[2];
}

printf GNUSCRIPT "set terminal postscript color\n";
printf GNUSCRIPT "set output \"competing.plot\"\n";

printf GNUSCRIPT "replot\n";
printf GNUSCRIPT "exit\n";

close(GNUSCRIPT);
close(DATAF);

system "gnuplot < tempplotscript";
