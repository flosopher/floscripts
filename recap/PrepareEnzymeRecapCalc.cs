#!/bin/tcsh

# script to prepare for an enzyme design wild type sequence recapitulation. the pdb and the cst file and a paths.txt file have to be present and correct, in their respective enzyme directory.

set rosettaloc = /work/flo/rosetta/trunk_rosetta++/rosetta.intel
#put the pdb codes of the enzymes here
#foreach enzyme (1c2t 1dqx 1h2j 1jcl 1ney 1oex 1p6o 6cpa)

foreach enzyme (1p6o 6cpa 1c2t)


#foreach enzyme (6cpa)

cd $enzyme #move to specific directory

rm workruns/${enzyme}_des*.pdb
rm workruns/${enzyme}_des*fasta
mkdir workruns #create directory for workruns

rm ${enzyme}.resfile
rm ${enzyme}_polyA.resfile
#rm despos_6_8_${enzyme}.txt


#make resfile for design
~jiangl/bin/make_ligand_resfile_new.bash ${enzyme}.pdb 6.0 8.0 10.0 12.0 

#make polyA resfile and write design positions
/work/flo/scripts/recap/GetDesPosFromResfile.pl ${enzyme}.resfile ala #output is despos


#score wildtype structure
nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_score -s ${enzyme}.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -pdbout ${enzyme}_score > score_${enzyme}.out

mv ${enzyme}_score_0001.pdb ${enzyme}_score.pdb

#repack wildtype structure
echo repacking $enzyme 
rm ${enzyme}_repack.out
rm ${enzyme}_repack.pdb

nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}_score.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -short_interface -cut1 0.0 -cut2 0.0 -cut3 10.0 -cut4 12.0 -fix_catalytic_aa -pdbout ${enzyme}_repack -nstruct 1 > ${enzyme}_repack.out

mv ${enzyme}_repack_0001.pdb ${enzyme}_repack.pdb
cp ${enzyme}_score.pdb workruns/
cp ${enzyme}_repack.pdb workruns/

calculate repack rmsd
~/scripts/recap/CalculateRmsRepackScore.pl $enzyme > ${enzyme}_repackrms.out


#create polyA scaffold
nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -resfile ${enzyme}_polyA.resfile -fix_catalytic_aa -pdbout ${enzyme}_polyA > ${enzyme}_polyA.out

mv ${enzyme}_polyA_0001.pdb ${enzyme}_polyA.pdb

#rm ${enzyme}_score.pdb 
#rm ${enzyme}_repack.pdb

cd ..

end

unset rosettaloc
