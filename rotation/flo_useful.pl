#!/usr/bin/env perl

# extract fields from a file with space-delimited data (eg. a scorefile)
#
# 2004, John Karanicolas, Baker group, UW

sub usage {
  printf STDERR "usage:   extract_fields.pl [-ignore_header] infile field1 [field2 [field3] ...]\n";
  printf STDERR "Note:  field numbering starts with zero\n";
  exit 1;
}

use vars qw ( $perllibdir );

BEGIN {
  $perllibdir="$ENV{MMTSBDIR}/perl" if (defined $ENV{MMTSBDIR});
  ($perllibdir=$0)=~s/[^\/]+$// if (!defined $perllibdir);
}

use lib $perllibdir;
use strict;
use GenUtil;

my $ignore_header=0;
my $fname;
my @fields=();

while ($#ARGV>=0) {
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } elsif ($ARGV[0] eq "-ignore_header") {
    shift @ARGV;
    $ignore_header=1;
  } else {
    $fname=shift(@ARGV);
    while ($#ARGV>=0) {
      push(@fields,shift(@ARGV));
    }
  }
}

&usage() if ($#fields < 0);

my $infile=&GenUtil::getInputFile($fname);
my $outfile=&GenUtil::getOutputFile("-");
my $junk=<$infile> if ($ignore_header);
while (<$infile>) {
    my $inline=$_;
    chomp($inline);
    my @p=split(' ',$inline);
    my @outarr=();
    foreach my $i ( @fields ) {
	push(@outarr,$p[$i]);
    }
    printf $outfile "%s\n",join(" ",@outarr);
}
undef $infile;

exit(0);
