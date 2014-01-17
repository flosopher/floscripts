#!/bin/tcsh


#original script
#
#cat match*log > match.log
#rotamerIG.py -f exrot3IG -g match.log -r -a H
#./run_asp > asp.log 
#checkBackedUpMatches.py -b asp.log -m match.log -g exrot3IG
#find . -name "match*bk.pdb" | sed 's/\.\///g' > list
#graftLigandDump.py -P list -s $1_9.pdb -r 
#
#orig script over

#adaptation follows

foreach scaf (1abe 1gca 1hsl 1wdn 2dri)
#foreach scaf( 1abe )
echo starting stuff for $scaf

~wollacott/py_scripts/tools/rotamerIG.py -f ../${scaf}_9.exrot3IG -g Est_HNN.${scaf}.out -o ${scaf}_9.exrot3IG_trim -a H

~khare/novozyme_1_0/rosetta++/novozyme.gcc -match -enzyme -enzyme_constraint -heterofile /work/flo/designs/esterase/matches/asp.pdb -fa_input -fa_output -nstruct 1 -s ../${scaf}_9.pdb -scbb_bump_cutoff 10.0 -ligbb_bump_cutoff 50000.0 -scsc_bump_cutoff 10.0 -ligsc_bump_cutoff 80.0 -grid_bin 1.0 -euler_bin 10.0 -Wlig_vir 3.0 -extrachi_cutoff 1.0 -enzyme_virE_cut 70.0 -enzyme_repE_cut 40.0 -try_both_his_tautomers -short_range_interf -paths ../paths.txt -include_ligand_rotamers -full_filename -max_ghost_threshold 4 -max_ghost_score 5 -pi_stack -ex1aro -ex1 -ex2 -exrot_depth 3 -catres1 -bkupIG ../${scaf}_9.exrot3IG -greedy_matching -output_structures -minimize_ligpos_only -overwrite -backed_up_residue 1 -dump_ligand_only -cst_header -skip_grid_check 1 > ${scaf}_aspmatch.out

echo $scaf checking backed up matches
~wollacott/py_scripts/tools/checkBackedUpMatches.py -l -b ${scaf}_aspmatch.out -m Est_HNN.${scaf}.out -g ${scaf}_9.exrot3IG_trim 

find . -name "match*${scaf}*bk.pdb" | sed 's/\.\///g' > ${scaf}_list

echo $scaf putting ligand matches back into scaffold
~wollacott/py_scripts/tools/graftLigandDump.py -P ${scaf}_list -s ../${scaf}_9.pdb -r

end


