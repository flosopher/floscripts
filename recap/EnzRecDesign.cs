#!/bin/tcsh


#script to run a recapitulation calculation and then concatenate the obtained sequences into a fasta file
set rosettaloc = /work/flo/rosetta/trunk_rosetta++/rosetta.intel
#foreach enzyme (1ney 1p6o 1dqx)
foreach enzyme (1ney 1p6o 1dqx 1jcl 1c2t 6cpa 1h2j 1oex)

cd $enzyme

echo starting runs for $enzyme

nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}_polyA.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -resfile ${enzyme}.resfile -fix_catalytic_aa -pdbout ${enzyme}_des -nstruct 50 > ${enzyme}_des.out

mv ${enzyme}_des*pdb workruns/

cd workruns

rm ${enzyme}_des.fasta

foreach struct (${enzyme}_des_0*pdb)
~/scripts/pdbutils/getFastaFromCoords.pl -pdbfile $struct >> ${enzyme}_des.fasta
end

cd ../../

end

unset rosettaloc
