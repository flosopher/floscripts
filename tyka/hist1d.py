#!/usr/bin/python

import string
import sys
from pd import * 


if len(sys.argv)<=1:
  print "Syntax: av.py filename [-col column] [-begin {0.0-1.0}] [-end {0.0-1.0}] [-binwidth [1.0]] [-binspread [-1.0]] [-gibbs]"
  sys.exit()

if sys.argv[1][0] == '-':   
	f = sys.stdin.read()
else:
	f = open(sys.argv[1], 'r').read()
	
lines = string.split(f,'\n')

datacol = int(after("-col","0"))
datamcol = int(after("-mcol","-1"))
avbegin = float(after("-begin","0.0"))
avend = float(after("-end","1.0"))
binwidth = float(after("-binwidth","1.0"))
binspread = float(after("-binspread","-1.0"))

hist = Histogram1D(binwidth)
#print avbegin,avend
n = 0.0
for line in lines:
  prop = (n/len(lines))
  #print line
  if (prop > avbegin) and (prop < avend):
    token = string.split(line)
    if len(token)<=0:
      continue
    if len(token)<=datacol:
      continue
    ydata = eval(token[datacol])
    if(datamcol >= 0): 
      ydata -= eval(token[datamcol])
    if binspread < 0:
      hist.addPoint( ydata )
    else: 
      hist.addWidePoint( ydata, binspread )

    #print sum, sumcnt, token[0]
  n = n + 1.0

if isarg("-gibbs"):
  hist.print_gibbs(300.0)
elif isarg("-counts"):
  hist.print_counts()
else:
  if isarg("-cumul"): hist.print_prob_cumul()
  else:               hist.print_prob()

#print hist.n()

 
