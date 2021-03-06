#!/bin/tcsh

echo "Residues that interact the most with ligand O atom:\n" > ClashingResidues.out
#first go through all the list of designs
foreach design ( AB018_1thf AB017_1thf AB011 AB010 AB009 AB008 AB007 AB019_1a53  AB016_1thf AB015_1thf AB014_1thf AB013_1thf AB012_1lbm AB006 AB005 AB004 AB003 AB002 AB001 )
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

echo ${design} >> ClashingResidues.out
/work/flo/edesign/scripts/DiffRepEs.pl ${design}_singleO_score.pdb ${design}_nolig_0001.pdb >> ClashingResidues.out
echo "\n" >> ClashingResidues.out
end
