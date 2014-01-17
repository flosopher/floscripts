#!/bin/tcsh


#script to run a repacking calculation to see how well the active site conformation is regained
foreach enzyme (1ney 1p6o 1dqx 1jcl)
#foreach enzyme (1jcl)

cd $enzyme

echo repacking $enzyme 


rm ${enzyme}_repack.out
rm ${enzyme}_repack.pdb

nice +19 /work/jiangl/workspaces/rosetta++/rosetta.gcc -pose1 -cst_mode -enable_ligand_aa -cst_design -s ${enzyme}_score.pdb -cstfile ${enzyme}.cst -try_both_his_tautomers -short_interface -cut1 0.0 -cut2 0.0 -cut3 10.0 -cut4 12.0 -fix_catalytic_aa -pdbout ${enzyme}_repack -nstruct 1 > ${enzyme}_repack.out

mv ${enzyme}_repack_0001.pdb workruns/${enzyme}_repack.pdb

/work/wollacott/py_scripts/tools/rms_cur.py -t ${enzyme}_score.pdb -p ${enzyme}_repack.pdb -s "type=ATOM  ;element!=H"


cd ..

end
