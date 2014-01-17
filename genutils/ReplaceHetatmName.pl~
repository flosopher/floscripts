#!/usr/bin/perl

#script to replace the rosetta code of a file, i.e. characters -8 to -4, with a new string


use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -s <substitute string> -l <listfile of files> or -f <struct>\n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $ListOption = 0;
my $NewString = -1;
my $ListFile = -1;
my @StructList = ();
my $SingStruct = 'X';

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-s'){$NewString = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-f'){$SingStruct = $ARGV[$ii+1];}
}


my $NumStruct = 0;

if($ListOption){
    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
    system "rm $ListFile";
    open(NEW,">$ListFile");
}



else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    $ListFile = $SingStruct;
}


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    chomp($StructList[$ii]);
    my $CurStruct = $StructList[$ii];
    my $CurLength = length ($StructList[$ii]);

    substr($StructList[$ii],$CurLength -8, 4) = $NewString;
    if($CurStruct ne $StructList[$ii]){system "mv $CurStruct $StructList[$ii]";}
    $StructList[$ii] = $StructList[$ii]."\n";
    if($ListOption){
	printf NEW $StructList[$ii];
    }
}     
if($ListOption){close NEW;}
printf STDERR "\n";
    

