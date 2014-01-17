#!/usr/bin/perl

#script to compare two sets of rotamers. every rotamer that's in the second set but not in the first set is put out
#



use strict;


 
sub usage {
  printf STDERR "\n";
  printf STDERR "usage: -r1 <partial rot list> -r2 <all rot list> \n";
  printf STDERR "\n";
  exit 1;
}

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


#printf STDERR " $#ARGV \n";
if($#ARGV < 3) {&usage(); exit 1}


my $InListFile = -1;
my $OutListFile = -1;
my @RotList1 = ();
my @RotList2 = ();
my @DiffRotList = ();
my $RotFile1 = ();
my $RotFile2 = ();

for(my $ii = -1; $ii < $#ARGV;$ii++){
    if ($ARGV[$ii] eq '-r1'){$RotFile1 = $ARGV[$ii+1];}
    if ($ARGV[$ii] eq '-r2'){$RotFile2 = $ARGV[$ii+1];}
    
}


my $NumRot1 = 0;
my $NumRot2 = 0;

open(LIST1, $RotFile1) || die "Could not open $RotFile1\n";

while(<LIST1>){
    my $inline = $_;
    #chomp($inline);
    
    if($inline =~ /^ATOM/){ push(@{$RotList1[$NumRot1]},$inline);}

    if($inline =~ /^MODEL/) { $NumRot1++;}

}
close LIST1;

open(LIST2, $RotFile2) || die "Could not open $RotFile2\n";

while(<LIST2>){
    my $inline = $_;
    #chomp($inline);
    
    if($inline =~ /^ATOM/){ push(@{$RotList2[$NumRot2]},$inline);}

    if($inline =~ /^MODEL/) { $NumRot2++;}

}
close LIST2;

#printf STDERR "%s \n", $RotList2[0][0];
#printf STDERR "%s \n", $RotList2[0][1];
#printf STDERR "%s \n", $RotList2[1][0];

my $NumRotsNotFound = 0;
printf STDERR "%s rotamers in $RotFile1, %s rotamers in $RotFile2\n",$NumRot1,$NumRot2;

for(my $ii = 1; $ii <= $NumRot2; $ii++){

    my $RotPresent = 0;
    my $NumLinesRot2 = scalar @{$RotList2[$ii]};

    for(my $jj = 1; $jj <= $NumRot1; $jj++){

	my $NumLinesRot1 = scalar @{$RotList1[$jj]};
	
	if($NumLinesRot1 == $NumLinesRot2) {
	    
	    my $kk = 0;
	    while( ($RotList2[$ii][$kk] eq  $RotList1[$jj][$kk]) && ( $kk < $NumLinesRot2 ) ) { $kk++;}

	    #printf STDERR "%s is list2 $ii $kk \n",$RotList2[$ii][$kk];
	    #printf STDERR "%s is list1 $jj $kk \n",$RotList1[$jj][$kk];
	    if($kk == $NumLinesRot2) { $RotPresent = 1; }
	    #if($RotList2[$ii][$kk] ne $RotList1[$jj][$kk]){ printf STDERR " not present ..."; $RotPresent = 0; }
	    
	}
	else { printf STDERR " $ii $jj lines different\n";$RotPresent = 0; }
		
    }

    if(!$RotPresent) { 
	$NumRotsNotFound++;
	my $OutString = "MODEL     ".&zPad($NumRotsNotFound,4)."\n";
	foreach my $line ( @{$RotList2[$ii]} ) { $OutString = $OutString.$line; }
	$OutString = $OutString."ENDMDL \n";
	push(@DiffRotList, $OutString);		   
	#push(@DiffRotList,"MODEL     ".&zPad($NumRotsNotFound,4)."\n".@{$RotList2[$ii]}."\nENDMDL \n");
    }

}

foreach my $block ( @DiffRotList ) { printf STDOUT $block; }
#printf STDOUT @DiffRotList;
	    
printf STDERR "A total of %s rotamers were not found in the partial rot list.\n",$NumRotsNotFound;
    

