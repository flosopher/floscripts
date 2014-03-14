#!/usr/bin/python


#class to extract desired data from an excel sheet
#takes an excel sheet name and an info file about which cells contain data as argument
#can return tuples of dat inside tiny helper class, i.e. a tuple containing two lists (x and y)

import sys
from mmap import mmap,ACCESS_READ
from xlrd import open_workbook

MAX_DIMENSIONALITY = 2 #x,y data

#import re
#import math

#small helper class
class ExtractedDataSeries:

    def __init__( self, data_lists, name ):
        #data lists should be a tuple of lists of the same length
         #should also add some error checking to make sure that the handed in lists have the same length
        self.__data_lists = list(data_lists)
        self.name = name
        #print "initiated extracted data series %s with values " % self.name
        #print self.__data_lists
        #print "done"

    def num_series_elements(self):
        return len( self.__data_lists[0] )

    def get_series_for_index( self, index ):
        return self.__data_lists[index]

    def show(self):
        print "showing an instance of data series"
        print self.name
        print self.__data_lists
        print "done showing"


class ExtractedDataFromExcel:

    def __init__(self, excel_name, cell_file_name, relevant_sheet=0):
        self.sheet = (open_workbook( excel_name )).sheet_by_index( relevant_sheet )
        self.data_series = []

        cellfile = open( cell_file_name, 'r')
        cellf_lines = cellfile.readlines()
        cellfile.close()
        self.name_counter = 0

        current_data_lists = []
        for i in range( MAX_DIMENSIONALITY):
            current_data_lists.append( [] )
        
        cur_name = "noname"
        name_found = 0;
        for line in cellf_lines:
            items = line.split()
            if len( items ) == 0:
                continue
            if items[0] == "series":
                cur_dimension = int( items[1] )
                if cur_dimension >= MAX_DIMENSIONALITY:
                    print "too many dimensions asked for"
                    sys.exit()
                    
                row_position = int( items[2] )
                row_end_position = int( items[4] )
                col_position = int( items[3] )
                col_end_position = int( items[5] )
                current_data_lists[  cur_dimension ] = []

                while(row_position <= row_end_position) :
                    while( col_position <= col_end_position):
                        current_data_lists[ cur_dimension ].append( self.sheet.cell(row_position, col_position).value )
                        col_position += 1
                    row_position += 1
                if( len(items) > 6 ):
                    cur_name = items[6]
                    name_found = 1

            elif items[0] == "complete":
                if name_found == 0:
                    self.name_counter += 1
                    cur_name = "noname" + str( self.name_counter )
                name_found = 0
                self.data_series.append( ExtractedDataSeries( current_data_lists, cur_name) )
                '''
                print self.data_series
                self.data_series.append( 0  )
                print self.data_series
                self.data_series[ len(self.data_series) - 1 ] = new_series
                print self.data_series
                print "ARRRGH"
                self.data_series[0].show()
                print "URRRGH"
                '''

    def num_extracted_series( self ):
        return len( self.data_series )

    def return_data_series( self, series_index ):
        return self.data_series[ series_index ]

  
