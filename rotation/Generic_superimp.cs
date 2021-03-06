#!/bin/tcsh

#first go through all the list of designs
#foreach design ( AB019_1a53  AB016_1thf AB015_1thf AB014_1thf AB013_1thf AB012_1lbm AB006 AB005 AB004 AB003 AB002 AB001 )
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

	echo readpdb DA1_ts.pdb > tempmolscript
	echo "select #i 13" >> tempmolscript
	echo "select #i 15" >> tempmolscript
	echo "select #i 28" >> tempmolscript
	echo switch >> tempmolscript
	echo readpdb DA2_ts.pdb >> tempmolscript
	echo "select #i 13" >> tempmolscript
	echo "select #i 15" >> tempmolscript
	echo "select #i 28" >> tempmolscript
	echo fit >> tempmolscript
	echo writepdb DA2_sub.pdb >> tempmolscript
	echo "exit" >> tempmolscript

	/net/enzdes/molecule/molecule.exe < tempmolscript

	rm tempmolscript

#the substrate has been superimposed on the transition state now, put it in one file with the protein so rosetta can read it.

#	grep HEADER ${design}.pdb > ${design}_insub.pdb
#	grep REMARK ${design}.pdb >> ${design}_insub.pdb
#	grep ATOM ${design}.pdb >> ${design}_insub.pdb
#	echo TER >> ${design}_insub.pdb
#	grep HETATM ${design}_sub.pdb >> ${design}_insub.pdb
#	echo TER >> ${design}_insub.pdb
#	echo END >> ${design}_insub.pdb 

