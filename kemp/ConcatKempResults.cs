#!/bin/tcsh

#echo "              <-------------ligand Energy--------><------lig movement-------->  <-------Base Energy----------><--------Nhis Energy----->" > kempresults.ana
#echo "   design      prod  (prod-ts) (prod_min -prod)    RMSD    Cdist   Diff_Cdist    prod   prod-ts   prod_min-prod    prod   TS   prodmin " >> kempresults.ana

 
#echo "design ligprodE  lig(prodE-tsE) lig(prod_minE-prodE) RMSD Cdist Diff_Cdist baseprodE baseE(prod-ts) baseE(prod_min-prod) NhisEprod NhisETS NhisEprodmin TotBaseE(prod) TotBaseE(prod-ts) TotBaseE(prodmin-prod) BaseEav(ts) BaseSASA(ts) BaseSASAprob(ts) BaseSASA(prod-ts) BaseSASA(prodmin-prod" > kempresults.spread 

echo "design ligETS ligEprodscore ligEprodmin ligdiff(prodmin-ts) baseETS baseEprodscore baseEprodmin basediff(prodmin-ts) ligSASA(ts) baseSASA(ts) CarboxySASA(ts)" > kempresults_noCrep.spread

foreach design (KE_0007_1thf KE_0010_1a53 KE_0015_1thf KE_0016_1thf KE_0035_2izj KE_0001_1eix KE_0002_1eix KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf 1thf KE_0008_1thf KE_0009_1thf KE_0011_1a53 KE_0012_148l KE_0013_1thf KE_0014_1thf KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii  KE_0027_1pii KE_0033_1vo4 KE_0034_1v04 KE_0036_1tsn KE_0037_6cpa KE_0038_1lbm)


/work/flo/edesign/scripts/kemp/compareEsRMSDs.pl $design spreadsheet_out COO >> kempresults_noCrep.spread

end
