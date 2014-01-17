#!/usr/bin/perl

#script to copy all files given in a list file to a specified location
#same line in the files of the two molecules


use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -l <listfile of structures> or -s <struct>\n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $Dir = -1;
my $ListFile = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-d'){$Dir = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListFile = $ARGV[$ii+1];}
    
}


my $NumStruct = 0;

open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
@StructList = <LISTFILE>;
close LISTFILE;
$NumStruct = scalar @StructList;

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my @LineArray = split(' ',$StructList[$ii]);
    my $CurFile = $LineArray[0];
    chomp($CurFile);
    system "cp $CurFile $Dir";
}
    

