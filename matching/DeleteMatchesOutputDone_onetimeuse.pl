#!/usr/bin/perl

#script to read in a list of matcher generated output files, see if they completed,
# (as indicated by the DONE block at the end), and if not resubmit the command in condor input format



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


#function: zeroPad(InpString,len) adds zeros to the beginning of the input string until the desired length is reached
sub zeroPad {
    my $InpString = $_[0];
    my $newlen = $_[1];
    
    my $origlen=length($InpString);
    for (my $i=0; $i<($newlen-$origlen); $i++) {
	$InpString="0".$InpString;
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
if($#ARGV < 1) {&usage(); exit 1}


my $ListOption = 0;
my $ListFile = -1;
my @StructList = ();
my $SingStruct = 'X';
my %AtomsToRemove = ();
my $TempDirCount = 1;
my $MakeDirs = 0;

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-l'){$ListOption = 1; $ListFile = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-s'){$SingStruct = $ARGV[$ii+1];}
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
    #system "mv $StructList[$ii] tempfile";
    #open(NEWFILE,">$StructList[$ii]");
    #open(OLDFILE,"tempfile");

    my $RunCompleted = 0;
    my @TailArray = readpipe "tail $StructList[$ii]";
    for(my $tailcount = 0; $tailcount <=  $#TailArray; $tailcount++ ){
	if( $TailArray[$tailcount] =~ /DONE ::/ ) { $RunCompleted = 1; }
    }
    if($RunCompleted) {
   
	my @DirArray = split('/',$StructList[$ii]);
	my $CurDir = $DirArray[0]."/";
	for(my $dircount = 1; $dircount < $#DirArray - 1; $dircount++ )
	{
	    $CurDir = $CurDir.$DirArray[$dircount]."/";
	}

	my @HeadArray = readpipe "head $StructList[$ii]";
	my $CurCommand = "Arguments = ";
	for(my $headcount = 0; $headcount <= $#HeadArray; $headcount++ )
	{
	    if( $HeadArray[$headcount] =~/command executed/) {

		my @CommandArray = split(' ',$HeadArray[$headcount]);
		my $CurHetfile = 'X';
		for(my $commandcount =0; $commandcount <= $#CommandArray; $commandcount++) {
		    if($CommandArray[$commandcount] eq '-heterofile'){
			my @temparray = split('/',$CommandArray[$commandcount+1]);
			$CurHetfile = $temparray[$#temparray];
			$CurHetfile = substr($CurHetfile,0,-4);
			last;
		    }
		}
		my $stringtodelete = $CurDir."match*".$CurHetfile."*pdb";
		printf STDOUT "deleting $stringtodelete \n";
		system "rm -f $stringtodelete";
	       
	    }
	}
   }
  
}


