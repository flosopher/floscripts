#!/usr/bin/python


from ExtractDataFromExcel import ExtractedDataFromExcel
from numpy import *
from scipy.optimize import leastsq
import math
import sys

#script to fit data in an excel sheet using scipy leastsq
#method. Essentially copied from
#http://docs.scipy.org/doc/scipy/reference/tutorial/optimize.html


excel_file_name = ''
cellspec_file = ''
fit_function = 1

GASCONST = 0.0019872 #kcal/mol

#returns residuals for a function of type
#y(x) = A *exp( -k * x ) + B
def single_exponential_residuals( parameters, yvals, xvals):    
    Aconst = parameters[0]
    kconst = parameters[1]
    Bconst = parameters[2]
    #print "hackparam"
    #print parameters
    #print "xsize is %s, ysize is %s" % (len(xvals), len(yvals))
    #print "hackyvals"
    #print yvals
    #print "hackxvals"
    #print xvals
    
    err = yvals - ( Aconst * exp( -1 * kconst * xvals) + Bconst )
    return err

def arrhenius_residuals( parameters, yvals, xvals ):
    Aval = parameters[0]
    Eaval = parameters[1]
    #print "calling arrhenius shit w Aval %.4f and Eaval %.4f" % (Aval, Eaval )
    #print "xvals is "
    #print xvals
    #print "and yvals is "
    #print yvals
    err = yvals - ( Aval * exp( (-1 * Eaval) / (GASCONST * xvals) ) )
    #print "returning"
    #print err
    #print "done"
    return err

CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-xl':
        excel_file_name = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-cells':
        cellspec_file = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-fitfunc':
        fit_function = int( CommandArgs[CommandArgs.index(arg)+1] )

if( excel_file_name == '' or cellspec_file == '' ):
    print "Need to specify an excel file with -xl and and a cellspec file with -cells"
    sys.exit()

excel_sheet = ExtractedDataFromExcel( excel_file_name, cellspec_file)

num_series_to_fit = excel_sheet.num_extracted_series()

#hardcoded for x,y single exponential fitting
for i in range (num_series_to_fit):
    current_data_series = excel_sheet.return_data_series( i )
    series_length =  current_data_series.num_series_elements()
    #print "For series %s, aguess is %s and bguess is %s, while series is:" %(current_data_series.name, aguess, bguess )
    #current_data_series.show()

    #we have to convert the lists to numpy arrays
    xarray = array( current_data_series.get_series_for_index(0) )
    yarray = array( current_data_series.get_series_for_index(1) )
    #print "in iteration %s, xarray is %s" % (i, xarray )
    #print "and yarray is %s" % yarray
    #print "fitting data with x[0] of %s and y[0] of %s" % (xarray[0], yarray[0] )

    if fit_function == 1:
        bguess = (current_data_series.get_series_for_index(1))[series_length-1]
        aguess = ((current_data_series.get_series_for_index(1))[0]) - bguess
        kguess = 0.03
        parameters0 = [ aguess, kguess, bguess ]
        #opt_params = leastsq(single_exponential_residuals, parameters0, args=(current_data_series.data_lists[1], current_data_series.data_lists[0] ) )
        opt_params = leastsq(single_exponential_residuals, parameters0, args=(yarray, xarray ), full_output=1 )
        #print opt_params
        opt_residuals = single_exponential_residuals( opt_params[0], yarray, xarray )
    #print opt_residuals
        sum_residual_sq = 0
        for j in range( len( opt_residuals ) ):
            sum_residual_sq += ( opt_residuals[j] * opt_residuals[j] )
            #print "hackoptparams"
            #print opt_params
            #print opt_params[0]
            #print opt_params[0][0]
        print "For series %s, optk is %.4f (optA=%.4f, optB=%.4f, sum_residual_sq=%.7f)." % (current_data_series.name, opt_params[0][1], opt_params[0][0], opt_params[0][2], sum_residual_sq )

    elif fit_function == 2:
        Aguess = exp( 20 )
        Eaguess = 15
        parameters0 = [ Aguess, Eaguess ]
        opt_params = leastsq( arrhenius_residuals, parameters0, args=(yarray,xarray), full_output=1 )
        #print "optparams is "
        #print opt_params
        opt_residuals = arrhenius_residuals( opt_params[0], yarray, xarray)
        sum_residual_sq = 0
        for j in range( len( opt_residuals ) ):
            sum_residual_sq += ( opt_residuals[j] * opt_residuals[j] )
        print "For series %s, opt Ea is %.4f (optA=%.4f, sum_residuals=%.4f)" % (current_data_series.name, opt_params[0][1], opt_params[0][0], sum_residual_sq )
        print ""
