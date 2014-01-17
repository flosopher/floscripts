#!/bin/tcsh

#first go through all the list of designs

#complete list
#foreach design (RA_0001_1a53 RA_0002_1tsn RA_0003_1nah RA_0005_1a53 RA_0006_1lbl RA_0014_1lbf RA_0015_1gca RA_0017_1thf RA_0019_1thf_1 RA_0022_1lbf RA_0024_1b9b )

#S_frag only
#foreach design (RA_0001_1a53 RA_0017_1thf RA_0019_1thf_1)
#foreach design (RA_0003_1nah RA_0005_1a53)

#R_frag designs only
foreach design (RA_0024_1b9b) # RA_0022_1lbf RA_0014_1lbf RA_0006_1lbl)

#foreach design (RA_0015_1gca RA_0002_1tsn)


#lines to get TS
#
#grep HETATM ${design}.pdb > tempfile
#head -33 tempfile > ${design}_ts.pdb
#rm tempfile
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip


	echo readpdb ${design}_ts.pdb > tempmolscript
	echo "select #i 33" >> tempmolscript
	echo "select #i 4" >> tempmolscript
	echo "select #i 2" >> tempmolscript
 	echo switch >> tempmolscript
# 	echo readpdb retro_fragR.pdb >> tempmolscript
	echo readpdb retro_fragS.pdb >> tempmolscript
	echo "select #i 16" >> tempmolscript
	echo "select #i 3" >> tempmolscript
	echo "select #i 1" >> tempmolscript
	echo fit >> tempmolscript
	echo writepdb ${design}_fra.pdb >> tempmolscript
	echo "exit" >> tempmolscript

	/net/enzdes/molecule/molecule.exe < tempmolscript

	rm tempmolscript

#the oxygen fragment has been superimposed on the transition state now, put it in one file with the protein so rosetta can read it.

	grep HEADER ${design}.pdb > ${design}_ofrag.pdb
	grep REMARK ${design}.pdb | grep LYS >> ${design}_ofrag.pdb
	grep ATOM ${design}.pdb >> ${design}_ofrag.pdb
	echo TER >> ${design}_ofrag.pdb
	grep HETATM ${design}_ts.pdb > ${design}_ofrag_temp.pdb
	grep aroC ${design}_fra.pdb >> ${design}_ofrag_temp.pdb    #write the substrate out to a separate file first, so it can be reordered in rosetta format
	~jiangl/bin/reorder_hetero.awk ${design}_ofrag_temp.pdb > ${design}_ofrag_order.pdb
	
	~jiangl/bin/SetRosettaName.tcsh ${design}_ofrag_order.pdb > tempfile
	grep -v V  tempfile | grep -v END > ${design}_ofrag_name.pdb
	grep V ${design}_ts.pdb | grep LYS >> ${design}_ofrag_name.pdb
	rm tempfile
	
#	../../scripts/write_names.awk headfile=name_template_iso.pdb ${design}_ofrag_order.pdb > ${design}_ofrag_name.pdb #substitute correct names from template file
	cat ${design}_ofrag_name.pdb >> ${design}_ofrag.pdb
	
	echo END >> ${design}_ofrag.pdb

	rm ${design}_ofrag_temp.pdb
	rm ${design}_ofrag_order.pdb
	rm ${design}_ofrag_name.pdb
	rm ${design}_fra.pdb
	
end
