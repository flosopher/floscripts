#!/bin/tcsh

echo "Residues that interact the most with ligand O atom:\n" > ClashingResidues.out
#first go through all the list of designs
foreach design ( RA_0001_1a53 RA_0002_1tsn RA_0003_1nah RA_0005_1a53 RA_0006_1lbl RA_0014_1lbf RA_0015_1gca RA_0017_1thf RA_0019_1thf_1 RA_0022_1lbf RA_0024_1b9b )
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

echo ${design} >> ClashingResidues.out
echo "residue Etot   Erep" >> ClashingResidues.out
/work/flo/edesign/scripts/retro/TotLigEs.pl ${design}_singleO_score.pdb >> ClashingResidues.out
echo "\n" >> ClashingResidues.out
end
