#!/bin/tcsh

echo "Residues that interact the most with ligand:\n" > ClashingResidues.out
#first go through all the list of designs
##
foreach design (KE_0001_1eix KE_0002_1eix KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf KE_0007_1thf KE_0008_1thf KE_0009_1thf KE_0010_1a53 KE_0011_1a53 KE_0012_148l KE_0013_1thf KE_0014_1thf KE_0015_1thf KE_0016_1thf KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii KE_0027_1pii  KE_0033_1vo4 KE_0034_1v04 KE_0035_2izj KE_0036_1tsn KE_0037_6cpa KE_0038_1lbm)

#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

echo ${design} >> ClashingResidues.out
~wollacott/py_scripts/tools/rms_cur.py -t ${design}_prod_min.pdb -p ../${design}_prod.pdb -s HET >> ClashingResidues.out
echo "residue Etot   Erep" >> ClashingResidues.out
/work/flo/edesign/scripts/kemp/TotLigAtE.pl ${design}_prod_min.pdb >> ClashingResidues.out
echo "\n" >> ClashingResidues.out
end
