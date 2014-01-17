#!/bin/tcsh



foreach design (DA_0001_1lbf DA_0002_1tsn DA_0003_1tsn DA_0004_1tsn DA_0005_1tsn DA_0006_1e1a DA_0007_1e1a DA_0008_1e1a)

cd $design

cd $design

foreach decoy (*.pdb)
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

/users/flo/scripts/dockERMSD_cluster.pl $design $decoy >> tempunordered
#rm rmsdtempfile

end

echo "decoy       Elig   RMSD  Etot" > ../analysis/${design}_DockEvsRMSD.ana
/users/flo/scripts/ConcatDockRmsdE.pl tempunordered >> ../analysis/${design}_DockEvsRMSD.ana

cd ..

end
