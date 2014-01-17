#!/bin/tcsh

#first, write the trunk superpositioning script
echo readpdb temphetfile > molscript
echo "select #i 6" >> molscript
echo "select #i 9" >> molscript
echo "select #i 10" >> molscript
echo switch >> molscript
echo readpdb /work/flo/edesign/designs/kemp/docking/smallperturb/cluster/TS_H.pdb >> molscript
echo "select #i 6" >> molscript
echo "select #i 9" >> molscript
echo "select #i 10" >> molscript
echo fit >> molscript





foreach design (KAB_stTS KE_0001_1eix KE_0002_1eix KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf KE_0008_1thf KE_0009_1thf KE_0010_1a53 KE_0011_1a53 KE_0012_148l KE_0013_1thf KE_0014_1thf KE_0015_1thf KE_0016_1thf KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii  KE_0027_1pii KE_0033_1vo4 KE_0034_1v04 KE_0036_1tsn KE_0037_6cpa KE_0038_1lbm)

#foreach design (KAB ) #KE_0007_1thf)


set f = `/work/flo/edesign/scripts/DetCloseResidue.pl ${design}`
#set f = "GLU 50 OE1 CD OE2"

cd ${design}

echo starting calc for ${design}
rm *_TS_H.pdb
rm ${design}_CatGeom_unordered.ana #make sure to work in clean directory


echo decoy LigE  COdist  CHO_ang  HOB_ang  Dih  alt_COdist  alt_CHO_ang  alt_HOB_ang  alt_Dih  TotE> ../analysis/${design}_CatGeom.ana

foreach decoy (`ls -1 *.pdb`)
#foreach decoy (spKE_0035_2izj_stTS_1400.pdb )

grep HETATM ${decoy} > temphetfile
cat ../molscript > tempmolscript
echo writepdb ${decoy}_TS_H.pdb >> tempmolscript
echo "exit" >> tempmolscript

/work/flo/edesign/molecule.exe < tempmolscript   # fill in path of molecule.exe



/work/flo/edesign/scripts/Calc_Decoy_Cat_geom.pl ${design} ${decoy} $f >> ${design}_CatGeom_unordered.ana

end

unset f

/work/flo/edesign/scripts/kemp/ConcatDockCatGeomVsE.pl ${design}_CatGeom_unordered.ana >> ../analysis/${design}_CatGeom.ana


cd ..

end



#/work/flo/edesign/scripts/kemp/ConcatDockCatGeomVsE.pl ${design}_CatGeom_unordered.ana >> /work/flo/edesign/designs/kemp/docking/smallperturb/CaGeoAna/${design}_CatGeom.ana
