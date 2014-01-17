#!/bin/tcsh



set rosettalocb = /work/flo/rosetta/trunk_rosetta++/rosetta.intel
set comlineoptionsb = "-pose1 -cst_mode -enable_ligand_aa -cst_design -try_both_his_tautomers -fix_catalytic_aa -ex1aro -ex2 -soft_rep_design -cst_min -chi_move -extrachi_cutoff 1.0" 


foreach enzyme ($1 $2 $3 $4)

cd $enzyme
echo starting stuff for $enzyme

mv workruns/${enzyme}_des*pdb .

ls ${enzyme}_des_useisc_wl*pdb > ${enzyme}_des_useisc_wl.list
nice +19 $rosettalocb $comlineoptionsb -l ${enzyme}_des_useisc_wl.list -cstfile ${enzyme}.cst -short_interface -cut1 0.0 -cut2 0.0 -cut3 10.0 -cut4 12.0  > ${enzyme}_repack_useisc_wl.out

mv ${enzyme}_des_useisc*pdb workruns/
echo done with repacking inputsc designs for $enzyme

ls ${enzyme}_des_wl*pdb > ${enzyme}_des_wl.list
nice +19 $rosettalocb $comlineoptionsb -l ${enzyme}_des_wl.list -cstfile ${enzyme}.cst -short_interface -cut1 0.0 -cut2 0.0 -cut3 10.0 -cut4 12.0 > ${enzyme}_repack_wl.out

mv ${enzyme}_des*pdb workruns/

cd ..

end
