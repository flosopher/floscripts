#!/bin/tcsh
#
#Adding hydrogens to ligand and Convert ligand from PDB standard format to Rosetta format...
# Lin Jiang 08/18/04
#
#modified to fit new file system, 04/23/2007, Florian Richter

#arg
set arg0 = `echo $0 | awk -F'/' '{print $NF}'`
set pdbfile = $1

if ($#argv<1) then
  echo "Usage: $arg0 <INPUT_PDB>"
  echo "INPUT_PDB:  pdb file containing HETATM"
  echo "OUTOUT:     it will only ouput the hetero atom after adding hydrogens"
  echo "OUTPUT:     and convert PDB format to Rosetta format"
  exit 
endif

grep "^HETATM" $pdbfile |awk '{if(substr($0,76,2)=="  ") print substr($0,1,76) substr($0,13,2); else print $0}' > fun.pdb
/work/jiangl/bin/molecule.exe < /work/jiangl/scripts/AddH_lig.script >tmp
awk '{if($1=="HETATM") print $0; else if($1=="ATOM") print "HETATM" substr($0,7,100);}END{print "END"}' fun_lig.pdb
rm -f fun.pdb fun_lig.pdb tmp 
