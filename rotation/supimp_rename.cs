#!/bin/tcsh

#first go through all the list of designs
#foreach design ( AB019_1a53  AB016_1thf AB015_1thf AB014_1thf AB013_1thf AB012_1lbm AB006 AB005 AB004 AB003 AB002 AB001 )
foreach design ( AB018_1thf AB017_1thf AB011 AB010 AB009 AB008 AB007 )
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

	echo readpdb ${design}_ts.pdb > tempmolscript
	echo "select #i 11" >> tempmolscript
	echo "select #i 12" >> tempmolscript
	echo "select #i 16" >> tempmolscript
 	echo switch >> tempmolscript
# 	echo readpdb frag_ts.pdb >> tempmolscript
	echo readpdb frag_iso.pdb >> tempmolscript
	echo "select #i 1" >> tempmolscript
	echo "select #i 2" >> tempmolscript
	echo "select #i 3" >> tempmolscript
	echo fit >> tempmolscript
	echo writepdb ${design}_fra.pdb >> tempmolscript
	echo "exit" >> tempmolscript

	/net/enzdes/molecule/molecule.exe < tempmolscript

	rm tempmolscript

#the oxygen fragment has been superimposed on the transition state now, put it in one file with the protein so rosetta can read it.

	grep HEADER ${design}.pdb > ${design}_ofrag.pdb
	grep REMARK ${design}.pdb >> ${design}_ofrag.pdb
	grep ATOM ${design}.pdb >> ${design}_ofrag.pdb
	echo TER >> ${design}_ofrag.pdb
	grep HETATM ${design}.pdb > ${design}_ofrag_temp.pdb
	grep O ${design}_fra.pdb >> ${design}_ofrag_temp.pdb    #write the substrate out to a separate file first, so it can be reordered in rosetta format
	~jiangl/bin/reorder_hetero.awk ${design}_ofrag_temp.pdb > ${design}_ofrag_order.pdb
	
	../../scripts/write_names.awk headfile=name_template_iso.pdb ${design}_ofrag_order.pdb > ${design}_ofrag_name.pdb #substitute correct names from template file
	cat ${design}_ofrag_name.pdb >> ${design}_ofrag.pdb
	
	#echo END >> ${design}_ofrag.pdb

	rm ${design}_ofrag_temp.pdb
	rm ${design}_ofrag_order.pdb
	rm ${design}_ofrag_name.pdb
	rm ${design}_fra.pdb
	
end
