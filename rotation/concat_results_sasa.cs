#!/bin/tcsh

echo here we go > sasa_results.out
#first go through all the list of designs
foreach design ( AB018_1thf AB017_1thf AB011 AB010 AB009 AB008 AB007 AB019_1a53  AB016_1thf AB015_1thf AB014_1thf AB013_1thf AB012_1lbm AB006 AB005 AB004 AB003 AB002 AB001 )
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip
echo ${design} >> sasa_results.out
/users/wollacott/py_scripts/tools/surface.py -p ${design}_ofrag_min.pdb -s HETATM > tempfile
#grep LG1 ${design}_ofrag_min.pdb > tempfile
tail -1 tempfile >> sasa_results.out
rm tempfile
	
end
