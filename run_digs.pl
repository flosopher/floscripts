#! /usr/bin/perl


# ####################################################################
#
# distribute matching w/ IG on a set of nodes (the digs in that case)
# number of scaffolds per node is specified on command line.
# If multiple scaffolds are run per node, the resulting log file will
# have to be split by a companion script
#
# If the -m is set, a list of heterofiles is supplied, and the runs
# are split so that multiple heterofiles are run.
#
# Author: Alex Zanghellini (who else would do such bad perl, boo, nasty)
#
# ####################################################################

use strict;
no strict "refs";
use Options::Options;
use Bio::RosettaPaths;

my $parser = new Options(
			 -cmdline => [ @ARGV ],
			 -cmds => [ "-n", "-d", "-c", "-s", "-l", "-b", "-i" ],
			 -flags => [ "-h", "--help" ],
			 -progfile => "match_ig_digs.pl"
			);

$parser->show_summary();

my $n = $parser->{'-n'};
my $dir = $parser->{'-d'};
my $cmdfile = $parser->{'-c'}; # w/o the -l
my $scaffolds = $parser->{'-s'};
my $logprefix = $parser->{'-l'};
my $batch = $parser->{'-b'};
my $startstructdir = "scaffolds";
if( $parser->is_def( '-i' ) ){
  $startstructdir = $parser->{'-i'};
}

if(
   ! defined  $parser->{'-l'} ||
   $parser->{'-l'} =~ /\s+/ ||
   $parser->{'-l'} eq "" ){
  $logprefix = "match";
}

if(
   ! defined  $parser->{'-b'} ||
   $parser->{'-b'} =~ /\s+/ ||
   $parser->{'-b'} eq "" ){
  $batch = "1";
}


my @DIGS1 = (
	     # "dig1",
	     "dig2",
	     "dig3",
	     # "dig4",
	     "dig5",
	     "dig6",
	     "dig7",
	     "dig8",
	     "dig9",
	     "dig10",
	     "dig11",
	     "dig12",
	     "dig13",
	     "dig14",
	     "dig15",
	     "dig16",
	     "dig17",
	     "dig18",
	     "dig19",
	     "dig20",
	     "dig21",
	     "dig22",
	     "dig23",
	     "dig24",
	     "dig25",
	     "dig26",
	     "dig27",
	     "dig28",
	     "dig29",
	     "dig30",
	     "dig31",
	     "dig32"

	    );


my @DIGS2 = (
             "dig12",
             "dig13",
             "dig14",
             "dig15",
             "dig16",
             "dig20",
             "dig21",
             "dig22",
             "dig23",
             "dig25",
             "dig26"
            );



chdir( $dir );

# get commandline
open( C, "<$cmdfile" ) || die "cannot open command line $cmdfile\n";
my $cmdline = <C>;
chop( $cmdline );
close( C );

# count number of lines in list
my $size = (split /\s+/, `wc -l $scaffolds` )[0];


# split file list
open( L, "<$scaffolds" ) || die "error: cannot open list $scaffolds\n";

my $chunks = int($size/$n);


my $c = 0;
my $cc = 0;
open( LO , ">list.$cc" ) || die "cannot open list" . ".$cc\n";
while( <L> ){

  # last one gather the remaining
  if( $c >= $chunks && $cc < $n-1 ){
    close( LO );
    $cc++;
    $c=0;
    my $name = "list.$cc";
    open( LO , ">$name" ) || die "cannot open $name\n";
  }

  print  LO;
  $c++;

}
close( L );


# split dirs and make paths files
foreach (0..($n-1) ){
  `mkdir  $_`;
  #my $paths = Bio::RosettaPaths->new();
  #$paths->{'file'} =  "paths_$_.txt" ;
  #$paths->startstruct( "./$startstruct/" );
  #$paths->pdbpath( "./$_/" );
  #$paths->datafiles( "/work/zanghell/rosetta_databases/" );
  #$paths->write();
}


# round-robin, yeah baby!
foreach (0..$n-1){

  my $list = "scaffolds_$_.list";
  my $log = $logprefix . "_" . $_ . ".log";

  if( $batch == 1 ){

    my $indx = $_ % ($#DIGS1+1);
     # print "[DEBUG] about to run: ssh " . $DIGS1[$indx] . " \"cd $dir; nohup nice -n +10 $cmdline -l list.$_ -paths paths_$_.txt > $log &\"\n";
    print "submitting on $DIGS1[$indx]...";

    # wait 5s between submission to avoid concurrence problems.
    sleep( 5 );
    system("ssh $DIGS1[$indx] \"cd $dir; nohup nice -n +19 $cmdline -l list.$_ -paths paths_$_.txt > $log &\" &");
    print "done\n";
  }

  if( $batch == 2 ){

    my $indx = $_ % ($#DIGS2+1);
    print "submitting on $DIGS2[$indx]...";

    # wait 5s between submission to avoid concurrence problems.
    sleep( 5 );
    system("ssh $DIGS2[$indx] \"cd $dir; nohup nice -n +19 $cmdline -l list.$_ -paths paths_$_.txt > $log &\" &");
    print "done\n";

    my $indx = $_ % ($#DIGS2+1);
    system("ssh $DIGS2[$indx] \"cd $dir; nohup nice -n +19 $cmdline -l list.$_ -paths paths_$_.txt > $log &\" &");


  }
}


exit(0);
