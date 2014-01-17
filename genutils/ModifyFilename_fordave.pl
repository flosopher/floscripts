#!/usr/bin/perl

#script to read in a list of files and substitute a certain pattern with another pattern.
#special version for dave: 


use strict;



## function: zPad(num,len) 
## pads the input number with leading zeros
## to return a string of the desired length
sub zPad {
    my $num=shift;
    my $newlen=shift;

    my $origlen=length($num);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$num="0".$num;
    }
    return $num;
}

 
sub usage {
  printf STDERR "\n";
  #printf STDERR "usage: -l <listfile of structures> or -s <struct>  -op <old pattern> -np <replacing pattern> ";   #commented out for dave
  printf STDERR "usage: -l <listfile of structures>, -offset <offset, i.e. where numbering begins>" #modification for dave
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
my $offset = 0;

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-d'){$Dir = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-l'){$ListFile = $ARGV[$ii+1]; $ListMode = 1;}
    #if ($ARGV[$ii] eq '-op'){$OldPattern = $ARGV[$ii+1];}   #commented out for dave
    #if ($ARGV[$ii] eq '-np'){$NewPattern = $ARGV[$ii+1];}   #commented out for dave
    if ($ARGV[$ii] eq '-offset'){$offset = $ARGV[$ii+1];}    #modification for dave
    
}

#following block commented out for dave
#if( ($OldPattern eq $NewPattern) ) {
#    printf STDOUT "Error, have to supply a string for new and old pattern, aborting...\n";
#    exit 1;
#}

my $NumStruct = 0;

open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
@StructList = <LISTFILE>;
close LISTFILE;
$NumStruct = scalar @StructList;

for(my $ii = 0; $ii < $NumStruct; $ii ++){
    

    my $CurNumber = &zPad($offset + $ii,4);    #modification for dave
    my $CurNewName = $CurNumber.".mrc";        #modification for dave

    my @LineArray = split(' ',$StructList[$ii]);
    my $CurFile = $LineArray[0];
    #$StructList[$ii] =~ s/$OldPattern/$NewPattern/g;    #commented out for dave
    $StructList[$ii] = $CurNewName;                      #put in for dave
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

