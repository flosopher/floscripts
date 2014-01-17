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
    if ($ARGV[$ii] eq '-dirs'){$MakeDirs = 1;}
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


printf STDOUT "Executable = /users/flo/novozyme_1_0/rosetta++/rosetta.gcc \n";
printf STDOUT "Universe = vanilla \n\n";

printf STDOUT "Error = Est_hisnuc3.\$(Process).err\n";
printf STDOUT "Log = Est_hisnuc3.\$(Process).condor \n";
printf STDOUT "Output = Est_hisnuc3.\$(Process).out \n";

printf STDOUT "Requirements = Memory > 512 \n\n";

printf STDOUT "\# Notification = Complete \n";
printf STDOUT "\# Notify_user = your email here \n\n\n";


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
    if($RunCompleted) {next;}

    else {
	my @DirArray = split('/',$StructList[$ii]);
	my $CurDir = $DirArray[0]."/";
	for(my $dircount = 1; $dircount < $#DirArray ; $dircount++ )
	{
	    $CurDir = $CurDir.$DirArray[$dircount]."/";
	}

	my @HeadArray = readpipe "head $StructList[$ii]";
	my $CurCommand = "Arguments = ";
	for(my $headcount = 0; $headcount <= $#HeadArray; $headcount++ )
	{
	    if( $HeadArray[$headcount] =~/command executed/) {
		my $CommandStartFound = 0;
		my $CommandStart = 0;
		while(!$CommandStartFound && ($CommandStart  < 1000) )
		{
		    if(substr($HeadArray[$headcount],$CommandStart,1) eq '-') {$CommandStartFound = 1;}
		    $CommandStart++;
		}
		$CurCommand = $CurCommand.substr($HeadArray[$headcount],$CommandStart - 1, -1);
	    }
	}

	if($MakeDirs){
	    my $TempDir = $CurDir."out".&zeroPad($TempDirCount,4);
	    system "mkdir $TempDir";
	    #printf STDERR "$TempDir  ";
	    $TempDirCount++;
	    #printf STDERR "$TempDirCount \n";
	    $CurDir = $TempDir;
	}

	printf STDOUT "$CurCommand \n";	
	printf STDOUT "Initialdir = $CurDir \n";
	printf STDOUT "Queue 1 \n\n\n";    
    }

   
}     


