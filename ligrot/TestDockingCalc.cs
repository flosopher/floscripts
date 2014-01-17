#!/bin/tcsh

#put the pdb codes of the enzymes here
#foreach enzyme (1h2j 1p6o 1c2t 6cpa 1dqx 1ney)

foreach enzyme (1dqx)

cd $enzyme #move to specific directory

mkdir workruns #create directory for workruns


#testrun
nice +19 /work/flo/rosetta/workspaces/kaufman/rosetta++/rosetta.gcc bm nomv _ -dock -dock_min -ligand -nstruct 2 -dock_pert 0.0 0.0 0 -ex1 -ex1aro -ex2 -output_input_pdb -s ${enzyme}.pdb -fa_input -fa_output -read_all_chains -try_both_his_tautomers -ligand_mdlfile ${enzyme}_lig.mol -flexible_ligand > ${enzyme}_flexlig_nomv.out

mv bmnomv_${enzyme}_input_min.pdb workruns/
mv bmnomv_${enzyme}_input.pdb workruns/
mv bmnomv_${enzyme}_input_repacked.pdb workruns/
mv bm${enzyme}_00*pdb workruns/

~/scripts/ligrot/AnalyseDockingResults.pl $enzyme bmnomv 2 > ${enzyme}_flexlig_nomv.ana

cd ..

end

