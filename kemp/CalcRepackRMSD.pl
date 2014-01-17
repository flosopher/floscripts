#!/usr/bin/perl 


sub usage {
  printf STDERR "\n";
  printf STDERR "usage:   for_flo.pl infile1\n It's not hard, idiot!!\n";
  printf STDERR "\n";
  exit 1;
}

use strict;     # vars must be declared before usage

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
if (!$design) {printf STDERR "Please specify design\n";
	       exit 1;
}


my $start_reading = 0;
my @resarray;
my $nr_actsite_res = 0;
my $BaseId = 0;


#  if ($inline =~ /^res aa / ) {



open(RESFILE,"${design}_nolig.resfile") || die "Can't open resfile\n";

while(<RESFILE>) {
    chomp;
    my $inline=$_;

    if($inline =~ /start/ ) {$start_reading = 1;
			     printf STDERR "setting start reading true...\n";}
    
    elsif($start_reading) {
	my @p = split(' ', $inline);
	if ($p[3] eq "NATAA") {
	    push(@resarray,$p[2]);
            #my $f = {};
	    #$f->{resid} = $p[2];
	    #push(@resarray,$f);
	    $nr_actsite_res++;
	}

    }

}
	
close(RESFILE);

my $base_rmsd_string;
my $base_rmsd;
my $tot_rmsd_string;
my $tot_rmsd;

my $base_res_string = readpipe "head -1 ../${design}_stTS.pdb";
my @basarray = split(' ',$base_res_string);
$BaseId = $basarray[5];


system "grep ATOM ${design}_nolig_design.pdb > ${design}_tempfile";  #necessary so rmsd script doesn't get confused

$base_rmsd_string = readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t ${design}_nolig.pdb -p ${design}_tempfile -s resi=${BaseId}";
my @base_rmsd_array = split(' ',$base_rmsd_string);
$base_rmsd = $base_rmsd_array[2];


#foreach my $test (@resarray) { print STDOUT "${test}  ";}

my $acts_string = join(',',@resarray);

$tot_rmsd_string = readpipe "/users/wollacott/py_scripts/tools/rms_cur.py -t ${design}_nolig.pdb -p ${design}_tempfile -s resi=${acts_string}";
my @tot_rmsd_array = split(' ',$tot_rmsd_string);
$tot_rmsd = $tot_rmsd_array[2];


print STDERR "${acts_string}\n";

system "rm ${design}_tempfile";





printf STDOUT "%s %f %f\n",$design, $base_rmsd, $tot_rmsd;



#foreach my $res (@resarray);
#readpipe '/users/wollacott/py_scripts/tools/
