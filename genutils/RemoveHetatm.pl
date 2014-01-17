#!/usr/bin/perl

#script to remove a command-line specified heteroatom from an input file


use strict;

#function: Padsp(InpString,len) adds spaces to the end of the input string until the desired length is reached
sub Padsp {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString=$InpString." ";
    }
    return $InpString;
}


#function: spPad(InpString,len) adds spaces to the beginning of the input string until the desired length is reached
sub spPad {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString=" ".$InpString;
    }
    return $InpString;
}


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -a <hetatm id1 to replace> -a <hetatm id2 to replace> -n <new name>-l <listfile of files> or -s <struct>\n";
  printf STDERR "\n";
  exit 1;
}

#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $ListOption = 0;
my $ListFile = -1;
my @StructList = ();
my $SingStruct = 'X';
my %AtomsToRemove = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-a'){ $AtomsToRemove{ $ARGV[$ii+1] } = 1;}
    #if ($ARGV[$ii] eq '-a'){ %AtomsToRemove{ 1 } = 1;}
}


my $NumStruct = 0;

if($ListOption){
    open(LISTFILE, $ListFile) || die "Could not open $ListFile\n";
    @StructList = <LISTFILE>;
    close LISTFILE;
    $NumStruct = scalar @StructList;
}



else {
    $StructList[0] = $SingStruct;
    $NumStruct =1;
    $ListFile = $SingStruct;
}


for(my $ii = 0; $ii < $NumStruct; $ii ++){
    
    chomp($StructList[$ii]);
    system "mv $StructList[$ii] tempfile";
    open(NEWFILE,">$StructList[$ii]");
    open(OLDFILE,"tempfile");
    
    my $RemovedAtoms = 0;

    while(<OLDFILE>){

	my $inline = $_;
	if($inline =~ /^HETATM/){
	    my $CurAtomId = (substr($inline,7,4))/1;
	    #printf STDERR "hetatm id is $CurAtomId  ..\n";
	    if( $AtomsToRemove{ $CurAtomId } == 1 ) {
		$RemovedAtoms++;
		#printf STDERR " is removed.\n";
	    }
	    else {
		substr($inline,7,4) = &spPad(($CurAtomId - $RemovedAtoms),4);
		printf NEWFILE $inline;
	    }
	}
	else {
	    printf NEWFILE $inline;
	}
    }
    close OLDFILE;
    close NEWFILE;
    system "rm tempfile";
   
}     

printf STDERR "\n";
    

