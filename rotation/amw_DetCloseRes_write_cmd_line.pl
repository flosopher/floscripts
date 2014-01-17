#!/usr/bin/perl

use strict;
use Math::Complex;
use Math::Trig;


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

my $design;
my $mode;

while ($#ARGV>=0) {    # comment: $# means "index to last element of the array
  if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
  } else {
    $design = shift(@ARGV);
    $mode = shift(@ARGV);
    }
}


sub distance {             #function to determine the distance between two atoms

    my $Xdist = $_[0] - $_[3];
    my $Ydist = $_[1] - $_[4];
    my $Zdist = $_[2] - $_[5];

    my $SqXdist = $Xdist * $Xdist;
    my $SqYdist = $Ydist * $Ydist;
    my $SqZdist = $Zdist * $Zdist;

    my $dist = sqrt($SqXdist + $SqYdist + $SqZdist);
    return $dist;
}




sub angle {     #here be the function to determine the angle between two vectors


    my $vect1_length = sqrt(($_[0] * $_[0])+($_[1] * $_[1])+($_[2] * $_[2]));
    my $vect2_length = sqrt(($_[3] * $_[3])+($_[4] * $_[4])+($_[5] * $_[5]));
    #printf STDERR "vect1length: %.2f, vect2length: %.2f\n",$vect1_length,$vect2_length;
    my $vect1_2_dot_product = $_[0] * $_[3] + $_[1] * $_[4] + $_[2] * $_[5];
    my $angle = acos($vect1_2_dot_product/($vect1_length * $vect2_length));

    my $degangle = $angle * 57.295779513;
    
    if ($_[6] == 1) {return $angle; }
    else { return $degangle; }

}


my $COXcoord;
my $COYcoord;
my $COZcoord;


#printf STDERR "Starting script for ${design}\n";


#to be able to compare the distances between C and proton abstracting residue, the C coordinates have to be read in

my $tempcoofileline= readpipe "grep HETATM ${design}_F.pdb | grep COO";
my @cooarray=split(' ', $tempcoofileline);
$COXcoord = $cooarray[6];
$COYcoord = $cooarray[7];
$COZcoord = $cooarray[8];

my $CurDist;
my $ShortDist = 100;
my $CloseAtomName;
my $CloseAtomRes;
my $CloseAtomResNr;
my $BackedAtom = {};
my $pdbcheck = -1 ;
my $ND1buffer = {};
my $NE2buffer = {};

my $glucheck = 0;
my $aspcheck = 0;
my $backedcheck = 0;

my $cur_glu = 0;
my $cur_asp = 0;

my @gluarray;
my @asparray;
#printf STDERR "%f %f %f \n", $COXcoord, $COYcoord, $COZcoord;

#printf STDERR "Reading Product_score file ..\n";
open(INF1,"${design}_F.pdb") || die "Can't open file\n";
my @dumpbuffer = split(' ',<INF1>);
while($dumpbuffer[0] ne "ATOM") {
    @dumpbuffer = split(' ',<INF1>);
}
my @chaintestarray = split(' ',<INF1>);
#printf STDOUT "%s\n", $chaintestarray[4];
if($chaintestarray[4] eq "A" or $chaintestarray[4] eq "B" or $chaintestarray[4] eq "C") { $pdbcheck = 0;}
#printf STDOUT "%s\n", $pdbcheck;

while (<INF1>) {
  chomp;   # remove newline if present
  my $inline=$_;           #??? current line in file
  
  #the atom closest to the C atom has to be found
  if ($inline =~ /^ATOM/ ) {   

      my @linearray = split(' ', $inline);
      my $AtomChar = substr($linearray[2],0,1);

   
#----------------------code for reading in aspartates and glutamates-----------#

   if($gluarray[$cur_glu]->{Res_nr} == ($linearray[5 + $pdbcheck] - 1) && $glucheck == 1) { #if glu has been read in, set glucheck back to 0
	  $glucheck = 0;
	  $cur_glu++;
      }

      if($linearray[3] eq "GLU" && $glucheck == 0) {#if glu is encountered, start reading in glus
	  $gluarray[$cur_glu]->{Res_nr} = $linearray[5 + $pdbcheck];
	  $glucheck = 1;
      }

      
#-------------block to read in Glu coords-------------------------------#
      if($linearray[3] eq "GLU" && $glucheck == 1) {
	  if($linearray[2] eq "OE1"){
	      $gluarray[$cur_glu]->{OE1xcoord} = $linearray[6 + $pdbcheck];
	      $gluarray[$cur_glu]->{OE1ycoord} = $linearray[7 + $pdbcheck];
	      $gluarray[$cur_glu]->{OE1zcoord} = $linearray[8 + $pdbcheck];
	  }

	  if($linearray[2] eq "OE2"){
	      $gluarray[$cur_glu]->{OE2xcoord} = $linearray[6 + $pdbcheck];
	      $gluarray[$cur_glu]->{OE2ycoord} = $linearray[7 + $pdbcheck];
	      $gluarray[$cur_glu]->{OE2zcoord} = $linearray[8 + $pdbcheck];
	  }
	  if($linearray[2] eq "CD"){
	      $gluarray[$cur_glu]->{CDxcoord} = $linearray[6 + $pdbcheck];
	      $gluarray[$cur_glu]->{CDycoord} = $linearray[7 + $pdbcheck];
	      $gluarray[$cur_glu]->{CDzcoord} = $linearray[8 + $pdbcheck];
	  }
      }

#---------blockfinished, now start reading aspartates--------------------#


if($asparray[$cur_asp]->{Res_nr} == ($linearray[5 + $pdbcheck] - 1) && $aspcheck == 1) { #if asp has been read in, set aspcheck back to 0
	  $aspcheck = 0;
	  $cur_asp++;
      }

      if($linearray[3] eq "ASP" && $aspcheck == 0) {#if asp is encountered, start reading in asps
	  $asparray[$cur_asp]->{Res_nr} = $linearray[5 + $pdbcheck];
	  $aspcheck = 1;
      }

      
#-------------block to read in Glu coords-------------------------------#
      if($linearray[3] eq "ASP" && $aspcheck == 1) {
	  if($linearray[2] eq "OD1"){
	      $asparray[$cur_asp]->{OD1xcoord} = $linearray[6 + $pdbcheck];
	      $asparray[$cur_asp]->{OD1ycoord} = $linearray[7 + $pdbcheck];
	      $asparray[$cur_asp]->{OD1zcoord} = $linearray[8 + $pdbcheck];
	  }

	  if($linearray[2] eq "OD2"){
	      $asparray[$cur_asp]->{OD2xcoord} = $linearray[6 + $pdbcheck];
	      $asparray[$cur_asp]->{OD2ycoord} = $linearray[7 + $pdbcheck];
	      $asparray[$cur_asp]->{OD2zcoord} = $linearray[8 + $pdbcheck];
	  }
	  if($linearray[2] eq "CD"){
	      $asparray[$cur_asp]->{CGxcoord} = $linearray[6 + $pdbcheck];
	      $asparray[$cur_asp]->{CGycoord} = $linearray[7 + $pdbcheck];
	      $asparray[$cur_asp]->{CGzcoord} = $linearray[8 + $pdbcheck];
	  }
      }

#---------blockfinished-----------------------------------------------#

#-----code for reading in glu and asp finished------------------------#


#--------block to save NE2, ND1 coordinates if they are backed up----#      
      
      if ($backedcheck == 1 && $linearray[5 +$pdbcheck] == ($CloseAtomResNr + 1)){
	  $backedcheck = 0;
	  if ($CloseAtomName eq "ND1") {
	      $BackedAtom->{Xcoord} = $NE2buffer->{Xcoord};
	      $BackedAtom->{Ycoord} = $NE2buffer->{Ycoord};
	      $BackedAtom->{Zcoord} = $NE2buffer->{Zcoord};
	      $BackedAtom->{resnr}  = $NE2buffer->{resnr};
	      $BackedAtom->{Name} = "NE2";
	  }
	  if ($CloseAtomName eq "NE2") {
	      $BackedAtom->{Xcoord} = $ND1buffer->{Xcoord};
	      $BackedAtom->{Ycoord} = $ND1buffer->{Ycoord};
	      $BackedAtom->{Zcoord} = $ND1buffer->{Zcoord};
	      $BackedAtom->{resnr}  = $ND1buffer->{resnr};
	      $BackedAtom->{Name} = "ND1";
	  }
      }



      if ( $linearray[3] eq "HIS" && $linearray[2] eq "ND1"){
	  $ND1buffer->{Xcoord} = $linearray[6 + $pdbcheck];
	  $ND1buffer->{Ycoord} = $linearray[7 + $pdbcheck];
	  $ND1buffer->{Zcoord} = $linearray[8 + $pdbcheck];
	  $ND1buffer->{resnr} = $linearray[5 + $pdbcheck];
      }

      if ( $linearray[3] eq "HIS" && $linearray[2] eq "NE2"){
	  $NE2buffer->{Xcoord} = $linearray[6 + $pdbcheck];
	  $NE2buffer->{Ycoord} = $linearray[7 + $pdbcheck];
	  $NE2buffer->{Zcoord} = $linearray[8 + $pdbcheck];
	  $NE2buffer->{resnr} = $linearray[5 + $pdbcheck];
      }

#--------block finished---------------#


      if ( $linearray[3] eq "GLU" or $linearray[3] eq "ASP" or $linearray[3] eq "HIS") {    #make sure only base residues evaluated, some designs make this necessary
	  #printf STDERR "evaluating %s %f \n", $linearray[3], $linearray[5];
	  if ( $AtomChar ne "H" and $AtomChar ne "1" and $AtomChar ne "2" and $AtomChar ne "3"){  #make sure that only hetatms are compared

      	  
      
	      $CurDist = &distance($COXcoord, $COYcoord, $COZcoord, $linearray[6 + $pdbcheck], $linearray[7 + $pdbcheck], $linearray[8 + $pdbcheck]);
      
	      if ($CurDist < $ShortDist) {
		  $ShortDist = $CurDist;
		  $CloseAtomName = $linearray[2];
		  $CloseAtomRes = $linearray[3];
		  $CloseAtomResNr = $linearray[5 + $pdbcheck];
		  $backedcheck = 1;
		  #$CloseAtomXcoord = $linearray[6 + $pdbcheck];
		  #$CloseAtomYcoord = $linearray[7 + $pdbcheck];
		  #$CloseAtomZcoord = $linearray[8 + $pdbcheck];
                  #printf STDERR "atom found...\n";
	      }
	  }
  }
    
  

#the atom should have been found

  }
}
close(INF1);

#printf STDERR "%s %f %s %.2f \n", $CloseAtomRes, $CloseAtomResNr, $CloseAtomName, $ShortDist;
if ($ShortDist == 100) {printf STDERR "Error: Base atom not identified\n %f\n", $ShortDist; exit 1;}
 
  if($BackedAtom->{resnr} != $CloseAtomResNr) { printf STDERR "learn how to program, stupid fuck\n"; exit 1; }

#printf STDERR "%s %s %f %f %f\n", $BackedAtom->{resnr},$BackedAtom->{Name},$BackedAtom->{Xcoord},$BackedAtom->{Ycoord},$BackedAtom->{Zcoord};


#----base abstracting atom has been found, no determine backing up residue--#

my $backup_dist = 100;

  foreach my $f (@gluarray) {
      $f->{OE1dist} = &distance($BackedAtom->{Xcoord},$BackedAtom->{Ycoord},$BackedAtom->{Zcoord},$f->{OE1xcoord},$f->{OE1ycoord},$f->{OE1zcoord});

      $f->{OE2dist} = &distance($BackedAtom->{Xcoord},$BackedAtom->{Ycoord},$BackedAtom->{Zcoord},$f->{OE2xcoord},$f->{OE2ycoord},$f->{OE2zcoord});

      if( $f->{OE1dist} < $f->{OE2dist}) {
	  #if( abs(($f->{OE1angle} = &angle($f->{CDxcoord} - $f->{OE1xcoord}, $f->{CDycoord} - $f->{OE1ycoord},$f->{CDzcoord} - $f->{OE1zcoord}, $BackedAtom->{Xcoord} - $f->{OE1xcoord}, $BackedAtom->{Ycoord} - $f->{OE1ycoord}, $BackedAtom->{Zcoord} - $f->{OE1zcoord}) ) - 180) <= 30 ) {
	  $f->{BackingO} = "OE1"; $f->{BackingOdist} = $f-> {OE1dist};}

	  #elsif( abs(($f->{OE2angle} = &angle($f->{CDxcoord} - $f->{OE2xcoord}, $f->{CDycoord} - $f->{OE2ycoord},$f->{CDzcoord} - $f->{OE2zcoord}, $BackedAtom->{Xcoord} - $f->{OE2xcoord}, $BackedAtom->{Ycoord} - $f->{OE2ycoord}, $BackedAtom->{Zcoord} - $f->{OE2zcoord}) ) - 180) <= 30 ) {$f->{BackingO} = "OE2"; $f->{BackingOdist} = $f-> {OE2dist};}

      

      else {
	  #if(abs($f->{OE2angle} - 180) <= 30){
	  $f->{BackingO} = "OE2"; $f->{BackingOdist} = $f-> {OE2dist};}
	  #elsif(abs($f->{OE1angle} - 180) <= 30){$f->{BackingO} = "OE1"; $f->{BackingOdist} = $f-> {OE1dist};}
      
  }


  foreach my $f (@asparray) {
      $f->{OD1dist} = &distance($BackedAtom->{Xcoord},$BackedAtom->{Ycoord},$BackedAtom->{Zcoord},$f->{OD1xcoord},$f->{OD1ycoord},$f->{OD1zcoord});

      $f->{OD2dist} = &distance($BackedAtom->{Xcoord},$BackedAtom->{Ycoord},$BackedAtom->{Zcoord},$f->{OD2xcoord},$f->{OD2ycoord},$f->{OD2zcoord});

      if( $f->{OD1dist} < $f->{OD2dist}) {
	  #if( abs(($f->{OD1angle} = &angle($f->{CGxcoord} - $f->{OD1xcoord}, $f->{CGycoord} - $f->{OD1ycoord},$f->{CGzcoord} - $f->{OD1zcoord}, $BackedAtom->{Xcoord} - $f->{OD1xcoord}, $BackedAtom->{Ycoord} - $f->{OD1ycoord}, $BackedAtom->{Zcoord} - $f->{OD1zcoord}) ) - 180) <= 30 ) {
	  $f->{BackingO} = "OD1"; $f->{BackingOdist} = $f-> {OD1dist};}

	  #elsif( abs(($f->{OD2angle} = &angle($f->{CGxcoord} - $f->{OD2xcoord}, $f->{CGycoord} - $f->{OD2ycoord},$f->{CGzcoord} - $f->{OD2zcoord}, $BackedAtom->{Xcoord} - $f->{OD2xcoord}, $BackedAtom->{Ycoord} - $f->{OD2ycoord}, $BackedAtom->{Zcoord} - $f->{OD2zcoord}) ) - 180) <= 30 ) {$f->{BackingO} = "OD2"; $f->{BackingOdist} = $f-> {OD2dist};}

      else {
	  #if(abs($f->{OD2angle} - 180) <= 30){
	  $f->{BackingO} = "OD2"; $f->{BackingOdist} = $f-> {OD2dist};}
	  #elsif(abs($f->{OD1angle} - 180) <= 30){$f->{BackingO} = "OD1"; $f->{BackingOdist} = $f-> {OD1dist};}
      
  }

#-------------almost done
  my $BackingAtom={};
  
  my @glusortlist = ( sort {$a->{BackingOdist} <=> $b->{BackingOdist} } @gluarray );
  my @aspsortlist = ( sort {$a->{BackingOdist} <=> $b->{BackingOdist} } @asparray );

  if($aspsortlist[0]->{BackingOdist} < $glusortlist[0]->{BackingOdist}){
      $BackingAtom->{resname} = "ASP";
      $BackingAtom->{name} = $aspsortlist[0]->{BackingO};
      $BackingAtom->{dist} = $aspsortlist[0]->{BackingOdist};
      $BackingAtom->{resnr} = $aspsortlist[0]->{Res_nr};
  }

  else {
      $BackingAtom->{resname} = "GLU";
      $BackingAtom->{name} = $glusortlist[0]->{BackingO};
      $BackingAtom->{dist} = $glusortlist[0]->{BackingOdist};
      $BackingAtom->{resnr} = $glusortlist[0]->{Res_nr};
  }






if($mode eq "cmd") {
    printf STDOUT "Arguments = sp 1pro _ -dock -use_input_sc -ligand -dock_mcm -nstruct 1500 -dock_pert 3.0 3.0 75 -ex1 -ex1aro -ex2 -output_input_pdb -l %slist.list -fa_input -fa_output -read_all_chains -try_both_his_tautomers -flo_exclude -fhid 6 -fresid %s -fatom %s\n", ${design},$CloseAtomResNr,$CloseAtomName;
}

else {
    if ($CloseAtomRes eq "ASP") {
	if($CloseAtomName eq "OD1") {
	    printf STDOUT "%s %s OD1 CG OD2", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "OD2") {
	    printf STDOUT "%s %s OD2 CG OD1", $CloseAtomRes, $CloseAtomResNr;
	}

    }

    if ($CloseAtomRes eq "GLU") {
	if($CloseAtomName eq "OE1") {
	    printf STDOUT "%s %s OE1 CD OE2", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "OE2") {
	    printf STDOUT "%s %s OE2 CD OE1", $CloseAtomRes, $CloseAtomResNr;
	}

    }

    if ($CloseAtomRes eq "HIS") {
	if($CloseAtomName eq "ND1") {
	    printf STDOUT "%s %s ND1 CG CE1", $CloseAtomRes, $CloseAtomResNr;
	}
	if($CloseAtomName eq "NE2") {
	    printf STDOUT "%s %s NE2 CD2 CE1", $CloseAtomRes, $CloseAtomResNr;
	}

    }
}

printf STDOUT " %s %s %s %s %.2f ", $BackedAtom->{Name}, $BackingAtom->{resname},$BackingAtom->{resnr},$BackingAtom->{name}, $BackingAtom->{dist};# $BackingAtom->{angle};
   

