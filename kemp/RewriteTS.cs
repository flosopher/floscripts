#!/bin/tcsh

#first go through all the list of designs

#complete list
foreach design (KE_0001_1eix KE_0002_1eix KE_0007_1thf KE_0008_1thf KE_0009_1thf KE_0010_1a53 KE_0011_1a53 KE_0012_148l)

mv ${design}_ts.pdb tempfile
#lines to get TS
#
foreach line (01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16)
grep 90${line} tempfile >> ${design}_ts.pdb
end
rm tempfile
#
#alternatively foreach desing (`cat list`)
#
# now write the temporary 'molecule' superpositioning scrip

#

end
