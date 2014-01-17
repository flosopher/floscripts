#!/usr/bin/perl

#script to check whether for all files in list, there is an $file:END entry in a given checkpoint file, t
#the not-found files are put out


use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -c CHECKPOINT -l <listfile of structures> \n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $CheckPoint = -1;
my $ListFile = -1;
my @StructList = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-c'){$CheckPoint = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListFile = $ARGV[$ii+1];}
    
}


my $NumStruct = 0;

open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
@StructList = <LISTFILE>;
close LISTFILE;
$NumStruct = scalar @StructList;

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    my $CheckString;
    chomp($StructList[$ii]);
    #printf STDERR "%s \n",substr($StructList[$ii],-4,4);
    #printf STDERR "%s \n",substr($StructList[$ii],0,-4);
    if(substr($StructList[$ii],-4,4) eq '.pdb'){$CheckString = substr($StructList[$ii],0,-4);}
    if( readpipe "grep $CheckString $CheckPoint | grep END"){}
    else{ printf STDOUT $StructList[$ii]."\n";}
    
}
    

