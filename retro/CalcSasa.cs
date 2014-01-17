#!/bin/tcsh

echo here we go > sasa_results.out
#first go through all the list of designs
foreach design (RA_0001_1a53 RA_0002_1tsn RA_0003_1nah RA_0005_1a53 RA_0006_1lbl RA_0014_1lbf RA_0015_1gca RA_0017_1thf RA_0019_1thf_1 RA_0022_1lbf RA_0024_1b9  )
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
