#!/bin/tcsh


set saveloc = /work/flo/recap/oldruns/wlig2_0_br

cd /work/flo/recap/

foreach enzyme ( 1jcl 1c2t 6cpa 1h2j 1oex 1ney 1dqx)
#foreach enzyme (1p6o)

echo cleaning up $enzyme

cd ${enzyme}/workruns
/arc/flo/scripts/recap/DeleteDesignrunRedundantSequences.pl $enzyme useisc
#~/scripts/recap/DeleteDesignrunRedundantSequences.pl $enzyme pdbinp
cd ../../

cp -r $enzyme ${saveloc}
echo done copying for $enzyme

cd $enzyme

rm ${enzyme}_*.out
rm ${enzyme}_score.pdb
rm ${enzyme}_repack.pdb

rm CHECKPOINT
rm ${enzyme}_repackrms*

rm workruns/*pdb
rm workruns/*fasta

cd ..

end
