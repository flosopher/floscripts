#!/usr/bin/perl

#script to remove all files in a file of redundant matches, and if that leaves empty directories, remove those

use File::Find;

sub usage {
  printf STDERR "\n";
  printf STDERR "usage: <redundant file> <CompleteFile>";
  printf STDERR "\n";
  exit 1;
}

my $RemoveOnly = 0;
my @RedunDirs = ();
$RedunDirs[0] = 'X';

#printf STDERR " $#ARGV \n";
if($#ARGV < 1) {&usage(); exit 1}
printf STDERR "$ARGV[0]\n";
open(RFILE, "$ARGV[0]") || die "No redundancy file found.\n";
my $RedunCounter = 0;
my $DirCounter = 1;
my @RedunArray = <RFILE>;
my $NumRedunt = scalar @RedunArray;

for(my $i=0; $i < $NumRedunt; $i++){ 

    $RedunCounter++;
    my @tmparray = split(' ',$RedunArray[$i]);
    $RedunArray[$i] = $tmparray[0];
    my $CurDir = ${split('/',$RedunArray[$i])}[0];
    
    if($CurDir ne $RedunDirs[$DirCounter-1]){
	$RedunDirs[$DirCounter] = $CurDir;
	$DirCounter++;
    }
    system "rm $RedunArray[$i] \n"

}
close RFILE;

printf STDERR "$RedunCounter redundant matches have been deleted.\n";

#for(my $ii = 1; $ii < $DirCounter; $ii++){
#    rmdir $DirCounter[$ii];
#}

finddepth(sub{rmdir},'.'); #removes empty directories


#now open matchfile to see which members to keep

if(!$RemoveOnly) {
    open(MFILE, "$ARGV[1]") || die "No complete list file found.\n";

    my @NewCompArray = ();
    my @OldCompArray = <MFILE>;

    my $NumOldComp = scalar @OldCompArray;
    my $UniqueCounter = 0;

    for(my $k=0; $k < $NumOldComp; $k++){ 
    
	my $CurUnique = 1;
	my $kk = 0;
	chomp($OldCompArray[$k]);
	while($CurUnique && ($kk < $NumRedunt) ){
		
	    if($OldCompArray[$k] eq $RedunArray[$kk]) {
	    $CurUnique = 0;
	    }
	    $kk++;
	}
	if($CurUnique){ 
	    $NewCompArray[$UniqueCounter] = $OldCompArray[$k]."\n";
	    $UniqueCounter++;
	}
    }
    close MFILE;

    printf STDERR "\n $UniqueCounter $RedunCounter $NumOldComp \n";
    if ($UniqueCounter + $RedunCounter == $NumOldComp) {
	foreach my $item (@NewCompArray){printf STDOUT "$item";}
    }	

}
