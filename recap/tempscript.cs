#!/bin/tcsh



mkdir /dump/flo/recap/wfac20_rots/$1

cd ${1}/workruns/
find . -name "${1}_des_useisc_wlrm*pdb" -not -name "${1}*wlrm_00*_0001.pdb" -exec mv '{}' /dump/flo/recap/wfac20_rots/$1 \;

ls ${1}_des_useisc*00*_0001.pdb > templist
/arc/flo/scripts/genutils/ModifyFilename.pl -l templist -op _wlrm_ -np _
/arc/flo/scripts/genutils/ModifyFilename.pl -l templist -op _0001.pdb -np .pdb
foreach struct (${1}_des_useisc_0*pdb)
~/scripts/pdbutils/getFastaFromCoords.pl -pdbfile $struct >> ${1}_des_useisc.fasta
end


find . -name "${1}_des_wlrm*pdb" -not -name "${1}*wlrm_00*_0001.pdb" -exec mv '{}' /dump/flo/recap/wfac20_rots/$1 \;

ls ${1}_des_*00*_0001.pdb > templist
/arc/flo/scripts/genutils/ModifyFilename.pl -l templist -op _wlrm_ -np _
/arc/flo/scripts/genutils/ModifyFilename.pl -l templist -op _0001.pdb -np .pdb
foreach struct (${1}_des_0*pdb)
~/scripts/pdbutils/getFastaFromCoords.pl -pdbfile $struct >> ${1}_des.fasta
end


cd ../../



#really temporary storage 

#flo@para simann]$ grep bk_tot *repack*pdb
#1h2j_macrepack_0001.pdb:        bk_tot:    -721.42
#1h2j_repack_0001.pdb:        bk_tot:    -720.51
#1ney_macrepack_0001.pdb:        bk_tot:    -532.56
#1ney_repack_0001.pdb:        bk_tot:    -532.08
#1oex_macrepack_0001.pdb:        bk_tot:    -666.92
#1oex_repack_0001.pdb:        bk_tot:    -667.13

