#!/usr/bin/perl

use strict;


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   CalcVirE.pl design\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

my $design;
my $mode = 0;
my $lowdec_fraction = 0;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $lowdec_fraction = shift(@ARGV);
    $mode = shift(@ARGV);
    }
}

if($lowdec_fraction == 0){printf STDERR "Error, please supply the lowE fraction as second argument\n"; exit 1;}

my @decoyElist;
my $lenVIRe;
my $lendiff;
my $CHO_diff;
my $HOB_diff;
my $Dih_diff;
my $LigEPartition_function = 0;
my $TotEPartition_function = 0;
my $KbT = 4.14e-21;
my $T = 300;
my $len_expectVlig = 0;
my $CHO_expectVlig = 0;
my $HOB_expectVlig = 0;
my $Dih_expectVlig = 0;
my $len_expectVtot = 0;
my $CHO_expectVtot = 0;
my $HOB_expectVtot = 0;
my $Dih_expectVtot = 0;

my $LigMinE = 1000;
my $TotMinE = 1000;


open(CATGEOFILE,"${design}_CatGeom.ana") || die "Can't open catgeofile for ${design}";
my @FirstLineArray = split(' ',<CATGEOFILE>);
while(<CATGEOFILE>){
    my @linearray = split(' ',$_);
    my $f = {};
    $f->{decoy} = $linearray[0];
    $f->{Elig} = $linearray[1];
    $f->{TotE} = $linearray[2];
    $f->{COdist} = $linearray[3];
    $f->{CHO_ang} = $linearray[4];
    $f->{HOB_ang} = $linearray[5];
    $f->{Dih} = $linearray[6];
    $f->{alt_COdist} = $linearray[7];
    $f->{alt_CHO_ang} = $linearray[8];
    $f->{alt_HOB_ang} = $linearray[9];
    $f->{alt_Dih} = $linearray[10];
    $f->{backupdist} =  $linearray[12];
    $f->{backupang} =  $linearray[13];
    $f->{backupdist_alt} = $linearray[14];
    $f->{backupang_alt} = $linearray[15];
    $f->{alt_backupdist} = $linearray[16];
    $f->{alt_backupang} = $linearray[17];
    $f->{alt_backupdist_alt} = $linearray[18];
    $f->{alt_backupang_alt} = $linearray[19];
    $f->{comment1} = "n/a";
    $f->{comment2} = "n/a";
    $f->{backup_comment} = "n/a";

    if($f->{Elig} < $LigMinE) { $LigMinE = $f->{Elig}; }
    if($f->{TotE} < $TotMinE) { $TotMinE = $f->{TotE}; }

    #if(!$mode) { 
#	$LigEPartition_function = $LigEPartition_function + exp( -($f->{Elig})/$KbT);
#	$TotEPartition_function = $TotEPartition_function + exp( -($f->{TotE})/$KbT);
#    }

#    printf STDERR "%f %f %f\n", $LigEPartition_function, $KbT, exp( -($f->{Elig})/$KbT);
    
    
#-----------now calculate virtual energies----------------------------#
#
#    if( ($lendiff = abs($f->{COdist} - 2.64)) > 0.1 ) { $f->{lenVirE} = 10 * ($lendiff - 0.1) * ($lendiff - 0.1);}
#    else { $f->{lenVirE} = 0; }
#
#    if( ($CHO_diff = abs($f->{CHO_ang} - 175)) > 10 ) { $f->{CHOVirE} = 0.5 * ($CHO_diff - 10) * ($CHO_diff - 10); }
#    else {$f->{CHOVirE} = 0; }

#    if( ($HOB_diff = abs($f->{HOB_ang} - 114)) > 10 ) { $f->{HOBVirE} = 0.5 * ($HOB_diff - 10) * ($HOB_diff - 10);}
 #   else {$f->{HOBVirE} = 0;}

  #  if ( ($f->{Dih} < 155) and ($f->{Dih} > 25) ) {
	#if ($f->{Dih} < 90) { $Dih_diff = $f->{Dih}; }
	
	#else { $Dih_diff = 180 - $f->{Dih}; }
	    
#	$f->{DihVirE} = 0.5 * ($Dih_diff - 25) * ($Dih_diff - 25);
#
 #   }

  #  else { $f->{DihVirE} = 0; }

   # $f->{TotVirE} = $f->{lenVirE} + $f->{CHOVirE} + $f->{HOBVirE} + $f->{DihVirE};

#---------virtual energies calculated---------------------#

    push(@decoyElist,$f);
}
close(CATGEOFILE);


#---------murphs boltzmann implementation strategy follows---------------#

#open(TotOUTF, ">DecTotEs_debug");
#foreach my $f (@TotE_sortlist) {
#    printf TotOUTF "%s %.2f  \n",$f->{decoy},$f->{TotE};
#}
#close(TotOUTF);
#printf STDERR "%s %.2f\n",$decoyElist[0]->{decoy},$decoyElist[0]->{Elig};
#printf STDERR "%s %.2f\n",$decoyElist[1]->{decoy},$decoyElist[1]->{Elig};

my @TotE_sortlist = ( sort {$a->{TotE} <=> $b->{TotE} } @decoyElist );

#printf STDERR "%.2f %.2f\n", $TotMinE,  $TotE_sortlist[0]->{TotE};


if ($TotE_sortlist[0]->{TotE} != $TotMinE) { printf STDERR "${design} The impossible tot sometimes happens... %.2f\n", $TotMinE; exit 1; }
if ( $decoyElist[0]->{Elig} != $LigMinE) { printf STDERR "${design} The impossible lig sometimes happens... %.2f  %.2f\n", $LigMinE, $decoyElist[0]->{Elig}; exit 1; }


my $DecLigESat = 0;
my $DecLigESat_backup = 0;
my $DecTotESat = 0;
my $DecTotESat_backup = 0;

my $COdistCutoff = 3.7;
my $CHO_angCutoff = 110;
my $HOB_angCutoff = 25;
my $DihCutoff = 40;
my $backupdistcutoff = 4.01;
my $backupangcutoff = 40;


my $lowdecs = $#decoyElist * $lowdec_fraction;

my $backupdistcutoff = 4.01;

my @Satdecs;

for( my $i = 0; $i < $lowdecs; $i++ ) {
    
    if($decoyElist[$i]->{COdist} <$COdistCutoff ) {
	if($decoyElist[$i]->{CHO_ang} > $CHO_angCutoff) {
	    if(abs($decoyElist[$i]->{HOB_ang} - 120) <$HOB_angCutoff ) {
		if($decoyElist[$i]->{Dih} < $DihCutoff || $decoyElist[$i]->{Dih} > (180 - $DihCutoff) ){
		    $DecLigESat = $DecLigESat + 1;
		    $decoyElist[$i]->{comment1} = "lig_designed"; 
		    
		    if($decoyElist[$i]->{backupdist} < $backupdistcutoff) {
			if( abs($decoyElist[$i]->{backupang} - 120) < $backupangcutoff) { 
			    $DecLigESat_backup = $DecLigESat_backup + 1;
			    $decoyElist[$i]->{backup_comment} = ", backed up by designed O";
			}
		    }
		    elsif($decoyElist[$i]->{alt_backupdist} < $backupdistcutoff){
			if( abs($decoyElist[$i]->{alt_backupang} - 120) < $backupangcutoff) { 
			    $DecLigESat_backup = $DecLigESat_backup + 1;
			    $decoyElist[$i]->{backup_comment} = ", backed up by other O";
			}
		    }

		    push(@Satdecs,$decoyElist[$i]);
		    }
		}
	    }
	}
    

    if($decoyElist[$i]->{comment1} ne "lig_designed" && $decoyElist[$i]->{alt_COdist} < $COdistCutoff) { 
	#printf STDERR "entering altlig for %s\n", $decoyElist[$i]->{decoy};
	if($decoyElist[$i]->{alt_CHO_ang} > $CHO_angCutoff) {
	    #printf STDERR "beep\n";
	    if(abs($decoyElist[$i]->{alt_HOB_ang} - 120) < $HOB_angCutoff ) { #printf STDERR "beep2\n";
		if($decoyElist[$i]->{alt_Dih} < $DihCutoff || $decoyElist[$i]->{alt_Dih} > (180 - $DihCutoff) ){ #printf STDERR "%s qualifies for alt\n", $decoyElist[$i]->{decoy};
		    $DecLigESat = $DecLigESat + 1;
		    $decoyElist[$i]->{comment1} = "lig_alt"; 
		    
		    if($decoyElist[$i]->{backupdist_alt} < $backupdistcutoff) {
			if( abs($decoyElist[$i]->{backupang_alt} - 120) < $backupangcutoff) { 
			    $DecLigESat_backup = $DecLigESat_backup + 1;
			    $decoyElist[$i]->{backup_comment} = ", backed up by designed O";
			}
		    }
		    elsif($decoyElist[$i]->{alt_backupdist_alt} < $backupdistcutoff){
			if( abs($decoyElist[$i]->{alt_backupang_alt} - 120) < $backupangcutoff) { 
			    $DecLigESat_backup = $DecLigESat_backup + 1;
			    $decoyElist[$i]->{backup_comment} = ", backed up by other O";
			}
		    }

		    push(@Satdecs,$decoyElist[$i]);
		    }
		}
	}
    }


#---------------ligand energy treated, now same thing for tot energy------------------#

if($TotE_sortlist[$i]->{COdist} <$COdistCutoff ) {
	if($TotE_sortlist[$i]->{CHO_ang} > $CHO_angCutoff) {
	    if(abs($TotE_sortlist[$i]->{HOB_ang} - 120) <$HOB_angCutoff ) {
		if($TotE_sortlist[$i]->{Dih} < $DihCutoff || $TotE_sortlist[$i]->{Dih} > (180 - $DihCutoff) ){
		    $DecTotESat = $DecTotESat + 1;
		    $TotE_sortlist[$i]->{comment2} = "tot_designed"; 
		    
		    if($TotE_sortlist[$i]->{backupdist} < $backupdistcutoff) {
			if( abs($TotE_sortlist[$i]->{backupang} - 120) < $backupangcutoff) { 
			    $DecTotESat_backup = $DecTotESat_backup + 1;
			    $TotE_sortlist[$i]->{backup_comment} = ", backed up by designed O";
			}
		    }
		    elsif($TotE_sortlist[$i]->{alt_backupdist} < $backupdistcutoff){
			if( abs($TotE_sortlist[$i]->{alt_backupang} - 120) < $backupangcutoff) { 
			    $DecTotESat_backup = $DecTotESat_backup + 1;
			    $TotE_sortlist[$i]->{backup_comment} = ", backed up by other O";
			}
		    }

		    }
		}
	    }
	}
    

    if($TotE_sortlist[$i]->{comment2} ne "tot_designed" && $TotE_sortlist[$i]->{alt_COdist} < $COdistCutoff) {
	if($TotE_sortlist[$i]->{alt_CHO_ang} > $CHO_angCutoff) {
	    if(abs($TotE_sortlist[$i]->{alt_HOB_ang} - 120) <$HOB_angCutoff ) {
		if($TotE_sortlist[$i]->{alt_Dih} < $DihCutoff || $TotE_sortlist[$i]->{alt_Dih} > (180 - $DihCutoff) ){
		    $DecTotESat = $DecTotESat + 1;
		    $TotE_sortlist[$i]->{comment2} = "tot_alt"; 
		    
		    if($TotE_sortlist[$i]->{backupdist_alt} < $backupdistcutoff) {
			if( abs($TotE_sortlist[$i]->{backupang_alt} - 120) < $backupangcutoff) { 
			    $DecTotESat_backup = $DecTotESat_backup + 1;
			    $TotE_sortlist[$i]->{backup_comment} = ", backed up by designed O";
			}
		    }
		    elsif($TotE_sortlist[$i]->{alt_backupdist_alt} < $backupdistcutoff){
			if( abs($TotE_sortlist[$i]->{alt_backupang_alt} - 120) < $backupangcutoff) { 
			    $DecTotESat_backup = $DecTotESat_backup + 1;
			    $TotE_sortlist[$i]->{backup_comment} = ", backed up by other O";
			}
		    }

		  }
		}
	}
    }

}

#------------------totE also treated------------------------#



if($DecLigESat > 0) {
open(SatDecFILE,">debug_${design}_decoys");
printf SatDecFILE "Top %s decoys examined, %s decoys qualify\n",$lowdecs, $DecLigESat;
foreach my $f (@Satdecs) {
    printf SatDecFILE "%s %s%s %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f backup: %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f\n",$f->{decoy},$f->{comment1},$f->{backup_comment}, $f->{Elig},$f->{TotE},$f->{COdist},$f->{CHO_ang},$f->{HOB_ang},$f->{Dih}, $f->{alt_COdist}, $f->{alt_CHO_ang},  $f->{alt_HOB_ang}, $f->{alt_Dih}, $f->{backupdist},$f->{backupang}, $f->{backupdist_alt}, $f->{backupang_alt},$f->{alt_backupdist}, $f->{alt_backupang}, $f->{alt_backupdist_alt}, $f->{alt_backupang_alt};
  
}
close(SatDecFILE);
}

my $LigEDecFrac = $DecLigESat / $lowdecs;
my $LigEDecFrac_backup = $DecLigESat_backup / $lowdecs;
my $TotEDecFrac = $DecTotESat / $lowdecs;
my $TotEDecFrac_backup = $DecTotESat_backup / $lowdecs;


#my $LigE_wannabe_partition = 0;
#my $TotE_wannabe_partition = 0;


#if($mode eq "murph") {
#foreach my $item (@decoyElist) {
#
#    $LigE_wannabe_partition = $LigE_wannabe_partition + exp( -($item->{Elig} - $LigMinE) / $T);
#    $TotE_wannabe_partition = $TotE_wannabe_partition + exp( -($item->{TotE} - $TotMinE) / $T);

#}   
#}



#------now calculate the boltzmann probability for each state, and the corresponding expectation values----#

if($mode eq "murph") {    #old shattered ideas in this block
foreach my $boltzdec (@decoyElist) {
    


 if(!$mode) { 
    #$boltzdec->{Lig_Probability} = (exp( -($boltzdec->{Elig})/$KbT))/$LigEPartition_function;
    #$boltzdec->{Tot_Probability} = (exp( -($boltzdec->{TotE})/$KbT))/$TotEPartition_function;
 }
 
 

    $len_expectVlig = $len_expectVlig + ( $boltzdec->{COdist} * $boltzdec->{Lig_Probability} ) ;
    $CHO_expectVlig = $CHO_expectVlig + ( $boltzdec->{CHO_ang} * $boltzdec->{Lig_Probability} ) ;
    $HOB_expectVlig = $HOB_expectVlig + ( $boltzdec->{HOB_ang} * $boltzdec->{Lig_Probability} ) ;
    $Dih_expectVlig = $Dih_expectVlig + ( $boltzdec->{Dih} * $boltzdec->{Lig_Probability} ) ;
    $len_expectVtot = $len_expectVtot + ( $boltzdec->{COdist} * $boltzdec->{Tot_Probability} ) ;
    $CHO_expectVtot = $CHO_expectVtot + ( $boltzdec->{CHO_ang} * $boltzdec->{Tot_Probability} ) ;
    $HOB_expectVtot = $HOB_expectVtot + ( $boltzdec->{HOB_ang} * $boltzdec->{Tot_Probability} ) ;
    $Dih_expectVtot = $Dih_expectVtot + ( $boltzdec->{Dih} * $boltzdec->{Tot_Probability} ) ;

}

}

#-------------done, now output stuff---------------------------------#



#my $FirstLineItems = $#FirstLineArray;

#foreach my $ArItem ( @FirstLineArray) {printf STDOUT "%s  ", $ArItem;}
#printf STDOUT "VirE_tot VirE_len VirE_CHO VirE_HOB VirE_Dih  ba_up_dis\n";

#    foreach my $f ( @decoyElist) {
#	printf STDOUT "%s  %.2f %f %.2f  %.2f  %.2f  %.2f  %.2f %f  %.2f  %.2f  %.2f  %.2f  %.2f\n",$f->{decoy},$f->{Elig},$f->{Lig_Probability},$f->{COdist},$f->{CHO_ang},$f->{HOB_ang},$f->{Dih},$f->{TotE},$f->{Tot_Probability},$f->{TotVirE},$f->{lenVirE},$f->{CHOVirE},$f->{HOBVirE},$f->{DihVirE};
#    }

#open(BolOUTf, ">>CatGeoExpectVs.ana");
#print BolOUTf "${design}  %.2f  %.2f  %.2f  %.2f    %.2f  %.2f  %.2f  %.2f\n",$len_expectVlig,$CHO_expectVlig,$HOB_expectVlig,$Dih_expectVlig,$len_expectVtot,$CHO_expectVtot,$HOB_expectVtot,$Dih_expectVtot;

printf STDOUT "${design}  ligEfrac: %.3f, ligEfrac_backup: %.3f; TotEfrac: %.3f, TotEfrac_backup: %.3f\n", $LigEDecFrac,$LigEDecFrac_backup, $TotEDecFrac, $TotEDecFrac_backup;

#close(BolOUTf);


