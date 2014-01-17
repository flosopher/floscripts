#!/bin/tcsh

#script to do some initial design calculations using the input sidechains.
set rosettaloc = /work/flo/rosetta/trunk_rosetta++/rosetta.intel



#foreach enzyme (1dqx 1h2j 1jcl 1ney 1oex 1p6o 6cpa)
foreach enzyme (hagga)

cd $enzyme 

echo starting runs for $enzyme
#first design using the input sidechains, starting from pdb file
nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -resfile ${enzyme}.resfile -use_input_sc -fix_catalytic_aa -pdbout ${enzyme}_des_useisc -nstruct 30 > ${enzyme}_des_useisc.out


mv ${enzyme}_des_useisc*pdb workruns/

#then design starting from pdb file, but without input sidechains
nice +19 $rosettaloc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -resfile ${enzyme}.resfile -fix_catalytic_aa -pdbout ${enzyme}_des_pdbinp -nstruct 30 > ${enzyme}_des_pdbinp.out

mv ${enzyme}_des_pdbinp*pdb workruns/ 

cd workruns
foreach struct (${enzyme}_des_pdbinp*pdb)
~/scripts/pdbutils/getFastaFromCoords.pl -pdbfile $struct >> ${enzyme}_des_pdbinp.fasta
end

foreach struct (${enzyme}_des_useisc*pdb)
~/scripts/pdbutils/getFastaFromCoords.pl -pdbfile $struct >> ${enzyme}_des_useisc.fasta
end
cd ..

cd ..

echo

end
unset rosettaloc
