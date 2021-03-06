#!/bin/tcsh

#first go through all the list of designs

#complete list
#foreach design (KE_0001_1eix KE_0002_1eix KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf KE_0007_1thf KE_0008_1thf KE_0009_1thf KE_0010_1a53 KE_0011_1a53 KE_0012_148l KE_0013_1thf KE_0014_1thf KE_0015_1thf KE_0016_1thf KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii  KE_0027_1pii KE_0033_1vo4 KE_0034_1v04 KE_0035_2izj KE_0036_1tsn KE_0037_6cpa KE_0038_1lbm)

#foreach design (KE_0001_1eix KE_0002_1eix KE_0007_1thf KE_0008_1thf KE_0009_1thf KE_0010_1a53 KE_0011_1a53 KE_0012_148l KE_0014_1thf)

#foreach design (KE_0003_1thf KE_0004_1thf KE_0005_1lbm KE_0006_1thf KE_0013_1thf KE_0015_1thf KE_0016_1thf KE_0017_1thf KE_0018_1a53 KE_0019_1v04 KE_0020_1lbm KE_0021_1lbl KE_0022_1lbl KE_0023_1a53 KE_0024_1a53 KE_0025_1pii KE_0026_1pii  KE_0027_1pii KE_0037_6cpa)

#foreach design (KE_0033_1vo4)

#foreach design (KE_0034_1v04 KE_0035_2izj KE_0036_1tsn KE_0038_1lbm)


#lines to get TS
#
#grep HETATM ${design}.pdb > tempfile
#head -16 tempfile > ${design}_ts.pdb
#rm tempfile
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip
foreach design (KAB)
#
	#echo readpdb ${design}_ts.pdb > tempmolscript
	echo readpdb temphetfile > tempmolscript
	echo "select #i 5" >> tempmolscript
	echo "select #i 9" >> tempmolscript
	echo "select #i 10" >> tempmolscript
 	echo switch >> tempmolscript
 	echo readpdb prod_template >> tempmolscript
#	echo readpdb TS.pdb >> tempmolscript
	echo "select #i 1" >> tempmolscript
	echo "select #i 7" >> tempmolscript
	echo "select #i 8" >> tempmolscript
	echo fit >> tempmolscript
	echo writepdb ${design}_fra.pdb >> tempmolscript
	echo "exit" >> tempmolscript

	/net/enzdes/molecule/molecule.exe < tempmolscript

	rm tempmolscript


	/work/flo/edesign/scripts/kemp/DetermineCatBase.pl ${design}.pdb 6 prod 
	
	rm ${design}_fra.pdb
	

end
