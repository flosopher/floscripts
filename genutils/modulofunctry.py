#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

# math
import sys

a = 0
x = 0

CommandArgs = sys.argv[1:]


for arg in CommandArgs:
    if arg == '-a':
        a = float( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-x':
        x = float( CommandArgs[CommandArgs.index(arg)+1])
 


unsigned_result = a
signed_result = a
halfx = 0.5 * x
a_mod_x = a % x

if (a >= x) or  ( a <0 ):
    unsigned_result  = (a_mod_x + x) % x 


if ( a >= halfx) or (a < -halfx ):
    signed_result = ((a_mod_x + (x+halfx)) % x ) - halfx


print "Signed Periodic range %.2f" % signed_result
print "Unsinged Periodic range %.2f" % unsigned_result
