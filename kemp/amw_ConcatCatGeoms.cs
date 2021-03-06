#!/bin/tcsh

foreach design ( amw_1a53_1_F amw_KE_v04_1_F amw_1dc9_1_F amw_1igs_1_F amw_KE_v04_2_F )

#foreach design (match_26_16_QM_HSP5u_1a53)

#first, write the trunk superpositioning script
echo readpdb temphetfile > ts1molscript
echo "select #i 6" >> ts1molscript
echo "select #i 7" >> ts1molscript
echo "select #i 8" >> ts1molscript
echo switch >> ts1molscript
echo readpdb /work/flo/edesign/designs/kemp/amw/TS_H.pdb >> ts1molscript
echo "select #i 1" >> ts1molscript
echo "select #i 2" >> ts1molscript
echo "select #i 3" >> ts1molscript
echo fit >> ts1molscript

end

foreach design (amw_1thf_1_F amw_1lbm_1_F amw_1i4n_1_F)

echo readpdb temphetfile > ts2molscript
echo "select #i 1" >> ts2molscript
echo "select #i 2" >> ts2molscript
echo "select #i 3" >> ts2molscript
echo switch >> ts2molscript
echo readpdb /work/flo/edesign/designs/kemp/amw/TS_H.pdb >> ts2molscript
echo "select #i 1" >> ts2molscript
echo "select #i 2" >> ts2molscript
echo "select #i 3" >> ts2molscript
echo fit >> ts2molscript

end



#set f = `/work/flo/edesign/scripts/amw_DetCloseResidue_write_cmd_line.pl ${design}`
#set f = "GLU 177 OE1 CD OE2"

#set amw_1a53_1_F_cats = "HIS 109 NE2 CD2 CE1 ND1 50 OE2"
#set amw_1dc9_1_F_cats = "HIS 14 NE2 CD2 CE1 ND1 11 OD2"
#set amw_1i4n_1_F_cats = "HIS 107 NE2 CD2 CE1 ND1 80 OD1"
#set amw_1igs_1_F_cats = "HIS 109 NE2 CD2 CE1 ND1 50 OE2"
#set amw_1lbm_1_F_cats = "HIS 7 ND1 CG CE1 NE2 5 OE1"
#set amw_1thf_1_F_cats = "HIS 128 ND1 CG CE1 NE2 78 OE1"
#set amw_KE_v04_1_F_cats = "HIS 268 NE2 CD2 CE1 ND1 307 OE1"
#set amw_KE_v04_2_F_cats = "HIS 268 NE2 CD2 CE1 ND1 307 OE1"


foreach design ( amw_1a53_1_F amw_KE_v04_1_F amw_1igs_1_F amw_KE_v04_2_F amw_1dc9_1_F)
#foreach design (amw_1dc9_1_F)

#foreach design (match_26_16_QM_HSP5u_1a53)

#foreach design(match_10_802_QM_HYP6d_1ifc match_11_100_QM_HSP6d_1thf match_11_101_QM_HSP6d_1thf match_11_120_QM_HYP5d_1ftx match_11_123_QM_HYP5d_1ftx match_11_350_QM_HYP5d_1ftx match_11_93_QM_HSP6d_1thf match_11_95_QM_HSP6d_1thf match_12_33_QM_HYP5d_1lbl match_13_11_QM_HYP5d_1ifc_ match_17_221_QM_HYP6d_1ifc match_17_43_QM_HYP5d_1lbl match_17_44_QM_HYP5d_1lbl match_1_101_QM_HSP6d_1igs match_1_1405_QM_HYP6d_1ifc match_1_164_QM_HYP5d_1cbs_ match_1_1903_QM_HSP6u_1i4n match_1_1968_QM_HSP6u_1i4n match_1_5_QM_HSP5d_1i4n match_1_684_QM_HYP5d_1cbs_ match_1_78_QM_HSP5d_1pvx_ match_1_7_QM_HSP5d_1i4n match_1_81_QM_HSP6d_1igs match_1_82_QM_HSP6d_1igs match_1_8_QM_HSP5d_1i4n match_1_8_QM_HYP6u_1N1Y_ match_20_2_QM_HSP6u_1ifc match_20_9_QM_HSP6u_1ifc match_23_30_QM_HYP5d_1ft match_23_490_QM_HSP5u_1i4n match_23_494_QM_HSP5u_1i4n match_23_495_QM_HSP5u_1i4n match_23_496_QM_HSP5u_1i4n match_23_499_QM_HSP5u_1i4n match_23_506_QM_HSP5u_1i4n match_23_80_QM_HYP6d_1yna match_24_1_QM_HYP6u_1icn_ match_24_3_QM_HYP6u_1icn_ match_26_4_QM_HSP5u_1a53 match_26_7_QM_HSP5u_1a53 match_2_97_QM_HYP6d_1cbs_ match_2_9_QM_HYP6d_1dc9 match_2_9_QM_HYP6u_1N1V_ match_3_26_QM_HSP6d_1li match_3_55_QM_HSP6d_1li match_3_59_QM_HSP6d_1li match_3_71_QM_HYP5d_1ftx match_3_73_QM_HSP6u_1lic match_3_82_QM_HSP6u_1lic match_3_85_QM_HSP6u_1lic match_3_986_QM_HYP5d_1a53_ match_3_990_QM_HYP5d_1a53_ match_44_1_QM_HYP6u_1ftx match_45_3_QM_HYP6u_1ftx match_45_5_QM_HYP6u_1ftx match_54_3_QM_HSP5u_1igs match_54_4_QM_HSP5u_1igs match_54_6_QM_HSP5u_1igs match_5_1_QM_HYP6d_1dc9 match_5_7_QM_HYP6d_1dc9 match_5_8_QM_HSP5d_1li match_60_37_QM_HSP5u_1ifc match_60_43_QM_HSP5u_1ifc match_7_11_QM_HYP6u_1N1V_ match_7_7_QM_HYP6u_1N1V_ match_9_94_QM_HSP6u_1i4n match_9_98_QM_HSP6u_1i4n match_9_99_QM_HSP6u_1i4n) 

set f = `./Detour_script.pl ${design}`
#set f = `/work/flo/edesign/scripts/amw_DetCloseRes_write_cmd_line.pl ${design}`
echo $f
cd ${design}

echo starting calc for ${design}
#rm *_TS_H.pdb
#rm ${design}_CatGeom_unordered.ana #make sure to work in clean directory


echo decoy LigE  TotE  COdist  CHO_ang  HOB_ang  Dih  COdist_alt CHO_ang_alt HOB_ang_alt Dih_alt  backed_dist  backed_ang  backed_dist_alt backed_ang_alt alt_backed_dist alt_backed_ang alt_backed_dist_alt alt_backed_ang_alt > ../analysis/${design}_CatGeom.ana

#foreach decoy (`ls -1 *.pdb`)
foreach fuckthat()
#foreach decoy (spmatch_26_16_QM_HSP5u_1a53_F_1464.pdb)

grep HETATM ${decoy} > temphetfile
cat ../ts1molscript > tempmolscript
echo writepdb ${decoy}_TS_H.pdb >> tempmolscript
echo "exit" >> tempmolscript

/work/flo/edesign/molecule.exe < tempmolscript   # fill in path of molecule.exe

/work/flo/edesign/scripts/kemp/amw_Calc_Decoy_Cat_geom.pl $design $decoy $f >> ${design}_CatGeom_unordered.ana
echo $design $decoy $f

end

unset f
#unset ${design}_cats

/work/flo/edesign/scripts/kemp/amw_ConcatDockCatGeomsVsE.pl ${design}_CatGeom_unordered.ana >> ../analysis/${design}_CatGeom.ana


cd ..

end



foreach design (amw_1thf_1_F amw_1lbm_1_F amw_1i4n_1_F)

#foreach design()
set f = `./Detour_script.pl ${design}`
cd ${design}

echo starting calc for ${design}
#rm *_TS_H.pdb
#rm ${design}_CatGeom_unordered.ana #make sure to work in clean directory


echo decoy LigE  COdist  CHO_ang  HOB_ang  Dih  TotE > ../analysis/${design}_CatGeom.ana

#foreach decoy (`ls -1 *.pdb`)
foreach fuckthat()

grep HETATM ${decoy} > temphetfile
cat ../ts2molscript > tempmolscript
echo writepdb ${decoy}_TS_H.pdb >> tempmolscript
echo "exit" >> tempmolscript

/work/flo/edesign/molecule.exe < tempmolscript   # fill in path of molecule.exe

/work/flo/edesign/scripts/kemp/amw_Calc_Decoy_Cat_geom.pl $design $decoy $f >> ${design}_CatGeom_unordered.ana

end

#unset f
#unset ${design}_cats

/work/flo/edesign/scripts/kemp/amw_ConcatDockCatGeomsVsE.pl ${design}_CatGeom_unordered.ana >> ../analysis/${design}_CatGeom.ana


cd ..

end
