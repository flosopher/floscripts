#!/bin/tcsh



#foreach design(match_10_802_QM_HYP6d_1ifc match_11_100_QM_HSP6d_1thf match_11_101_QM_HSP6d_1thf match_11_120_QM_HYP5d_1ftx match_11_123_QM_HYP5d_1ftx match_11_350_QM_HYP5d_1ftx match_11_93_QM_HSP6d_1thf match_11_95_QM_HSP6d_1thf match_12_33_QM_HYP5d_1lbl match_13_11_QM_HYP5d_1ifc_ match_17_221_QM_HYP6d_1ifc match_17_43_QM_HYP5d_1lbl match_17_44_QM_HYP5d_1lbl match_1_101_QM_HSP6d_1igs match_1_1405_QM_HYP6d_1ifc match_1_164_QM_HYP5d_1cbs_ match_1_1903_QM_HSP6u_1i4n match_1_1968_QM_HSP6u_1i4n match_1_5_QM_HSP5d_1i4n match_1_684_QM_HYP5d_1cbs_ match_1_78_QM_HSP5d_1pvx_ match_1_7_QM_HSP5d_1i4n match_1_81_QM_HSP6d_1igs match_1_82_QM_HSP6d_1igs match_1_8_QM_HSP5d_1i4n match_1_8_QM_HYP6u_1N1Y_ match_20_2_QM_HSP6u_1ifc match_20_9_QM_HSP6u_1ifc match_23_30_QM_HYP5d_1ft match_23_490_QM_HSP5u_1i4n match_23_494_QM_HSP5u_1i4n match_23_495_QM_HSP5u_1i4n match_23_496_QM_HSP5u_1i4n match_23_499_QM_HSP5u_1i4n match_23_506_QM_HSP5u_1i4n match_23_80_QM_HYP6d_1yna) 

foreach design(match_24_1_QM_HYP6u_1icn_ match_24_3_QM_HYP6u_1icn_ match_26_16_QM_HSP5u_1a53 match_26_4_QM_HSP5u_1a53 match_26_7_QM_HSP5u_1a53 match_2_97_QM_HYP6d_1cbs_ match_2_9_QM_HYP6d_1dc9 match_2_9_QM_HYP6u_1N1V_ match_3_26_QM_HSP6d_1li match_3_55_QM_HSP6d_1li match_3_59_QM_HSP6d_1li match_3_71_QM_HYP5d_1ftx match_3_73_QM_HSP6u_1lic match_3_82_QM_HSP6u_1lic match_3_85_QM_HSP6u_1lic match_3_986_QM_HYP5d_1a53_ match_3_990_QM_HYP5d_1a53_ match_44_1_QM_HYP6u_1ftx match_45_3_QM_HYP6u_1ftx match_45_5_QM_HYP6u_1ftx match_54_3_QM_HSP5u_1igs match_54_4_QM_HSP5u_1igs match_54_6_QM_HSP5u_1igs match_5_1_QM_HYP6d_1dc9 match_5_7_QM_HYP6d_1dc9 match_5_8_QM_HSP5d_1li match_60_37_QM_HSP5u_1ifc match_60_43_QM_HSP5u_1ifc match_7_11_QM_HYP6u_1N1V_ match_7_7_QM_HYP6u_1N1V_ match_9_94_QM_HSP6u_1i4n match_9_98_QM_HSP6u_1i4n match_9_99_QM_HSP6u_1i4n)

#mkdir ${design}

#echo ${design}_F ${design}/${design}_F >> firsthalf.list

#scp para:/work/flo/edesign/designs/kemp/amw/NewDes/${design}_F.pdb .


/work/flo/edesign/scripts/amw_DetCloseRes_write_cmd_line.pl ${design} cmd >> condor_2half.inp
echo "Initialdir = /users/flo/kempscreen/"  >> condor_2half.inp
echo "Queue 2"  >> condor_2half.inp
echo >> condor_2half.inp

#Arguments = sp 1tes _ -dock -use_input_sc -ligand -dock_mcm -nstruct 500 -dock_pert 3.0 3.0 75 -ex1 -ex1aro -ex2 -output_input_pdb -l clusterlist.list -fa_input -fa_output -read_all_chains

end

