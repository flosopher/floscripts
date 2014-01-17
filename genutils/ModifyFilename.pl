#!/usr/bin/perl

#script to read in a list of files and substitute a certain pattern with another pattern.
#same line in the files of the two molecules


use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -l <listfile of structures> or -s <struct>  -op <old pattern> -np <replacing pattern> ";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $Dir = -1;
my $ListFile = -1;
my $ListMode = 0;
my @StructList = ();
my $OldPattern = 'never-occurs';
my $NewPattern = 'never-occurs';

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-d'){$Dir = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListFile = $ARGV[$ii+1]; $ListMode = 1;}
    if ($ARGV[$ii] eq '-op'){$OldPattern = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-np'){$NewPattern = $ARGV[$ii+1];}
    
}

if( ($OldPattern eq $NewPattern) ) {
    printf STDOUT "Error, have to supply a string for new and old pattern, aborting...\n";
    exit 1;
}

my $NumStruct = 0;

open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
@StructList = <LISTFILE>;
close LISTFILE;
$NumStruct = scalar @StructList;

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my @LineArray = split(' ',$StructList[$ii]);
    my $CurFile = $LineArray[0];
    $StructList[$ii] =~ s/$OldPattern/$NewPattern/g;
    chomp($CurFile);
    system "mv $CurFile $StructList[$ii]";
}

if($ListMode) {
    system "rm $ListFile";
    open(NEW,">$ListFile"); 
    for(my $line=0; $line < $NumStruct; $line++) {
	    
	printf NEW "%s",$StructList[$line];
    }
    close NEW;

}    

