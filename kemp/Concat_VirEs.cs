#!/bin/tcsh

#first go through all the list of designs
#echo design ligEfrac TotEfrac > CatGeoExpectVs.ana
echo expectvalues > Screen_CatExpectVs_${1}.ana
#complete list
foreach design (KAB KAB_stTS KE_0007_1thf KE_0010_1a53 KE_0015_1thf KE_0016_1thf KE_0035_2izj)
#foreach design (KE_0010_1a53 KE_0010_N130I KE_0010_N130L KE_0010_N130V)

#foreach design ( amw_1a53_1 amw_KE_v04_1 amw_1igs_1 amw_KE_v04_2 amw_1dc9_1 amw_1i4n_1 amw_1lbm_1 amw_1thf_1 )

#echo ${design}_stTS ${design}/${design}_stTS > ${design}list.list
#echo ${design}_F ${design}/${design}_F > ${design}list.list

#/work/flo/edesign/scripts/DetCloseResidue.pl ${design} cmd >> condor_amw_hack.inp
#/work/flo/edesign/scripts/amw_DetCloseRes_write_cmd_line.pl ${design} cmd >> condor_amw_hack.inp
#echo "Initialdir = /users/flo/kempdock/amw"  >> condor_amw_hack.inp
#echo "Queue 2"  >> condor_amw_hack.inp
#echo >> condor_amw_hack.inp

#echo design            values > Screen_CatExpectVs_${1}.ana
 


/work/flo/edesign/scripts/kemp/CalcVirE.pl $design $1 >> Screen_CatExpectVs_${1}.ana

end

echo >> Screen_CatExpectVs_${1}.ana

foreach design(KE_0001_1eix KE_0002_1eix KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf  KE_0008_1thf KE_0009_1thf  KE_0011_1a53 KE_0012_148l KE_0013_1thf KE_0014_1thf  KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii KE_0027_1pii KE_0033_1vo4 KE_0034_1v04  KE_0036_1tsn KE_0037_6cpa KE_0038_1lbm)

/work/flo/edesign/scripts/kemp/CalcVirE.pl $design $1 >> Screen_CatExpectVs_${1}.ana


end

