#!/usr/bin/python


#my first python script:)
#reads in a list of backrub output files, calculates the CA RMSD of the backrub portion, and ranks by energy

import sys
import re
from math import sqrt

def add_spaces(string, newlen, dir = 0):
    if len(string) > newlen:
        return string

    fill = newlen - len(string)
    if dir == 0:
        for i in range(fill):
            string = string + ' '

    else:
        for i in range(fill):
            string = ' ' + string

    return string


def get_float_columns( filename, compare_column_local ):

    filename = filename.replace("\n","")
    file = open(filename,'r')
    file_lines = file.readlines()

    columns = []

    #first, let's see how many columns we have
    commentline_match = re.compile(r"#",re.I)
    index = 0
    commentless_line_found = 0
    num_columns = 0
    num_all_columns = 0

    compare_offset = 0


    while commentless_line_found == 0:
        if not commentline_match.search( file_lines[ index ] ):
            commentless_line_found = 1
            #print 'found commentless line, is '
            #print index
            firstline_cols = file_lines[index].split()
            num_all_columns = len(firstline_cols ) 
            for lcount in range( len(firstline_cols) ):
                #print lcount
                #print firstline_cols[lcount]
                #if (isinstance( firstline_cols[lcount] , float) or isinstance( firstline_cols[lcount], int )) :
                #if( firstline_cols[lcount] / 1.0 )
                try:
                    float( firstline_cols[ lcount ] )
                #print "meep "+firstline_cols[lcount]
                #if float( firstline_cols[lcount] ):
                except:
                    if( lcount == compare_column_local ):
                        print "Error, the column to be compared against seems to contain non-floats"
                        sys.exit()
                    if( lcount < compare_column_local ):
                        compare_offset = compare_offset + 1
                else :
                    num_columns = num_columns + 1
        index = index + 1

    #print "File "+filename+" has "+str(num_columns)+" columns with floats or ints."
    #print "offseting compare_local by "+str(compare_offset)

    compare_column_local = compare_column_local - compare_offset

    for j in range( num_columns ):
        columns.append( [] )

    #now let's split the columns
    for line in file_lines:
        if commentline_match.search( line ):
            continue
        cols_this_line = 0
        file_cols = line.split()
        if len( file_cols ) == 0:    #check for empty lines
            continue
        if len( file_cols ) != num_all_columns:
            print "Error, some lines in file "+filename+" seem to have an unequal number of columns"
            sys.exit()

        for entry in file_cols:
            #print 'entry is'
            #print entry
            #if isinstance( (entry/1.0),float):
            #if float( entry) or (entry == "0.0") or (entry == "0"):
            try:
                float( entry )
            except:
                dummy = 1
            else:
                #print 'counts as float'
                columns[cols_this_line].append( float(entry) )
                cols_this_line = cols_this_line + 1
        if cols_this_line != num_columns:
            print "Error: file "+filename+" seems to be corrupted, columns have different numbers of float entries. Num columns should be "+str(num_columns)+", this line is "+str(cols_this_line)
            print "first file entry this row was "+str( columns[ 0 ][ len(columns[0] ) -1 ])+" "
            sys.exit()

    return (columns , compare_column_local )


def calculate_correlation( list1, list2):

    if len(list1) != len(list2):
        print "rarrr, can't compute correlation for list of different lengths!"
        sys.exit()

    sum1 = 0.0
    sum2 = 0.0
    sum12 = 0.0
    sq_sum1 = 0.0
    sq_sum2 = 0.0

    samples = len(list1)

    #print "calculating correlation for 2 lists of size "+str(samples)+" , 1st element of list1 is "+str(list1[0])+", 1st element of list2 is "+str(list2[0])

    for i in range(samples):
        sum1 = sum1 + list1[i]
        sum2 = sum2 + list2[i]
        sum12 = sum12 + ( list1[i] * list2[i] )

        sq_sum1 = sq_sum1 + (  list1[i] * list1[i] )
        sq_sum2 = sq_sum2 + (  list2[i] * list2[i] )

    correl_numerator = samples * sum12 - sum1 * sum2

    correl_denominator = sqrt( samples*sq_sum1 - sum1*sum1) * sqrt( samples*sq_sum2 - sum2*sum2)

    return_val = "N/A"
    if correl_denominator != 0.0:
        return_val = correl_numerator / correl_denominator

    return return_val




FileList = []
Listfile = ''
SingleFile = ''
comp_column = 1
outfile = ' '
rub_residues = []
norub_residues = []


CommandArgs = sys.argv[1:]

for arg in CommandArgs:
    if arg == '-f':
        SingleFile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-l':
        Listfile = CommandArgs[CommandArgs.index(arg)+1]
    elif arg == '-compare_column':
        comp_column = int( CommandArgs[CommandArgs.index(arg)+1] )
    elif arg == '-out':
        outfile = CommandArgs[CommandArgs.index(arg)+1]


if ( (not Listfile) and (not SingleFile) ) :
     print 'Error, please supply name of the listfile, or of a single file'
     sys.exit()
elif (not SingleFile):
    inlist = open(Listfile,'r')
    FileList = inlist.readlines()
    inlist.close()

else :
    FileList.append( SingleFile );

#now read in resfile to determine the residues that moved



outstring = ''
highest_correl = 0.0
highest_correl_file = ""

for file in FileList:

    this_file_compare_column = comp_column

    #print "before getting columns, comp column is "+str( this_file_compare_column )
    (all_columns, this_file_compare_column ) = get_float_columns( file, this_file_compare_column )
    #print "after getting columns, comp column is "+str( this_file_compare_column ) 
     #get_float_columns( file, all_columns )

    correlations = file.replace("\n","")+" "
     #print "just got columns for file "+file+", has "+str( len(all_columns) )+" columns"

    for col_index in range( len( all_columns ) ) :

        if col_index == this_file_compare_column:
            continue

         #print "calculating correlations for column "+str(col_index)+" to column "+str(comp_column)
        #correlations = correlations + str( calculate_correlation(all_columns[ this_file_compare_column ], all_columns[ col_index ] ) )+" "
        cur_correl = calculate_correlation(all_columns[ this_file_compare_column ], all_columns[ col_index ] )
        if( isinstance( cur_correl, float) ):
            correlations = correlations + "%.3f  " % cur_correl
            if abs( cur_correl ) > abs( highest_correl ):
                highest_correl = cur_correl
                highest_correl_file = file.replace("\n","")

        else:
            correlations = correlations + str( cur_correl ) + " "

    outstring = outstring + correlations + '\n'
         


if outfile == ' ':
  print outstring

else:
   outf = open(outfile,'w')
   outf.write( outstring )                                       
   outf.close()


print "\nHighest correlation is "+str( highest_correl )+", observed in File "+highest_correl_file
