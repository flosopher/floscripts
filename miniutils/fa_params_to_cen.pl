#!/opt/local/bin/perl

use strict;
use warnings;
use Switch;

#judge the argv
if ( $#ARGV != 1 )
{
  print "Usage: [cmd] input.params output_name\n";
  die("Wrong arguments\n");
}

#read the table file into lines
my $file = 'fa_to_centroid_equivalence.txt';
open( TABLE, $file ) or die("Can not find the table file!\n");
my @lines = <TABLE>;
close( TABLE );

#creat a hash table
my %fa_to_cen_table;
my $line;
my @element;
foreach $line (@lines)
{
   $line =~ s/#.*// ;
   chomp($line);
   @element = split( /[ \t\n]+/, $line );

   if ( $#element == 1 )
   {
      #key and ref
      $fa_to_cen_table{$element[0]} = $element[1];	
   }
}

#parse the file name
my $para_file = $ARGV[0];
my $para_outn = $ARGV[1];
my $para_outf = "$para_outn".".params";	        #output params file
my $conf_outf = "$para_outn"."_confs.pdb";	#output rotamer pdb

#read the params file
open( PARAMS, $para_file ) or die("Can not find the input params file!");
@lines = <PARAMS>;
close( PARAMS );

#open the output params file
open( OUTFP, ">$para_outf" ) or die("Can not open the output params file!");

my %name_to_type_table;
foreach $line (@lines)
{
   $line =~ s/#.*// ;
   chomp( $line );
   @element = split( /[ \t\n]+/, $line );
   if ( $#element <= 0 ) { next; }

   #seems a good line
   switch( $element[0] )
   {
      case "NAME"
      {
         print OUTFP "$line\n";
      }

      case "IO_STRING"
      {
         print OUTFP "$line\n";
      }

      case "TYPE"
      {
         print OUTFP "$line\n";
      }

      case "AA"
      {
         print OUTFP "$line\n";
      }

      case "ATOM"
      {
         #build the name_to_type table
         #skip the atom whose type match "DELETE"
         my $name = $element[1];
         my $type = $element[2];
         my $new_type = $fa_to_cen_table{$type};
         $name_to_type_table{$name} = $new_type;

         if ( $new_type eq "") { die("Can not match the type $type!\n"); }
         if ( $new_type ne "DELETE")
         {
	    $line =~ s/$element[2]/$new_type/;
	    print OUTFP "$line\n";
	 }
      }

      case "BOND"
      {
         my $name1 = $element[1];
         my $name2 = $element[2];
         if ( $name_to_type_table{$name1} ne "DELETE"
	    && $name_to_type_table{$name2} ne "DELETE" )
         {
	    print OUTFP "$line\n";  
	 }
      }

      case "CHI"
      {
         print OUTFP "$line\n";
      }

      case "NBR_ATOM"
      {
         print OUTFP "$line\n";
      }

      case "NBR_RADIUS"
      {
         print OUTFP "$line\n";
      }

      case "ICOOR_INTERNAL"
      {
         my $name = $element[1];
         if ($name_to_type_table{$name} ne "DELETE")
         {
	    print OUTFP "$line\n";
	 }
      }

      case "PDB_ROTAMERS"
      {
         open( INFC, $element[1] );
         open( OUTFC, ">$conf_outf" ) or die("Can not open the output confs file!");

         my $pdbline;
         my @pdbelem;

         while(<INFC>)
         {
	     $pdbline = $_;
	     $pdbline =~ s/#.*// ;
	     chomp( $pdbline );
	     @pdbelem = split( /[ \t\n]+/, $pdbline );
	     if ( $#pdbelem < 0 ) { next; }

	     switch ( $pdbelem[0] )
	     {
	         case "HETATM"
		 {
		    my $name = $pdbelem[2];
		    if ($name_to_type_table{$name} ne "DELETE")
		    {
		       print OUTFC "$pdbline\n";
		    }
		 }

		 case "TER"
		 {
		    print OUTFC "$pdbline\n"
		 }

		 else
		 {
		    print "Warning: Unknown mark \"$pdbelem[0]\", just skip this line.\n";
		    #print OUTFC "$pdbline\n"
		 }
	     }
         }

         close( INFC );
         close( OUTFC );

         print OUTFP "PDB_ROTAMERS $conf_outf\n";
      }

      else
      {
	 print "Warning: Unknown mark \"$element[0]\", just copy this line.\n";
         print OUTFP "$line\n";
      }
   }
}
close( OUTFP );

