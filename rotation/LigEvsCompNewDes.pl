#!/usr/bin/perl

use strict;


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   enter design\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

my $design;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    }
}

if(!$design) { &usage;;}


my $count = 0;
my $minfound = 0;
my $buffer;
my $minimizedE = 0;
my $desname = substr($design,6,6);

if(substr($desname,-1,1) eq "M") { $desname = substr($desname,0,-1);}
if(substr($desname,-1,1) eq "Q") { $desname = substr($desname,0,-1);}
if(substr($desname,-1,1) eq "_") { $desname = substr($desname,0,-1);}
    

open(RMSDFILE,"${design}_DockEvsRMSD.ana")|| die "Can't open rmsdfile for $design\n";
$buffer = <RMSDFILE>;

while($minfound == 0){ #&& <RMSDFILE>) {
    chomp;
    my $fileline;
    if ( $fileline = <RMSDFILE> ) {
	my @linearray = split(' ',$fileline);
	#my $desname;
	#my $desname = "ear";
	my $desname = substr($linearray[0],-3,3);
	#printf STDERR "%s ",$desname;
	if( $desname eq "min") {
	    $minimizedE = $linearray[1];
	    $minfound = 1;
	}
	$count++;
    } else {
	$minfound=1;
    }
}

printf STDOUT "${desname} %.2f %s\n",$minimizedE, $count - 1;
