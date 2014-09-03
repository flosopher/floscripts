#!/usr/bin/python

token_titles = {}

def setup_token_titles( title_string ):
    token_titles.clear()
    
    tokens = title_string.split()
    for i in range( len(tokens)):
        token_titles[ tokens[i] ] = i


    
class ResResE:

    def __init__(self, init_string, token_titles):
        tokens = init_string.split()
        self.name = tokens[1][1:] + "_" + tokens[2][1:]
        self.values = [0] * len( tokens )
        self.values[0] = 'DiffResResE'
        self.values[1] = tokens[1]
        self.values[2] = tokens[2]
        self.first_float = 3
        
        for i in range (len( tokens ) - self.first_float):
            try:
                i_float = float( tokens[i+self.first_float] )
                self.values[i+self.first_float] = i_float
            except ValueError:
                print "Error: non float value encountered where it shouldn't be"
                sys.exit()

    def substract_other_ResResE( self, other ):
        for i in range (len( self.values ) - self.first_float):
            self.values[ i+self.first_float ] = self.values[i+self.first_float] - other.values[i+self.first_float]

    def negate( self ):
        for i in range (len( self.values ) - self.first_float):
            self.values[ i+self.first_float ] = self.values[i+self.first_float] * (-1.0)

    def get_name(self):
        return self.name

    def get_value( self, label ):
        return self.values[ token_titles[ label ] ]

    def get_all_values( self ):
        return self.values

    def get_outstring(self):
        to_return = ''
        #to_return = self.name
        for val in self.values:
            to_return = to_return  + str( val ) + "  "
        return to_return +'\n'

    #sets all values to 0
    def nullify( self ):
        for i in range (len( self.values ) - self.first_float):
            self.values[ i+self.first_float ] = 0.0

def ResE_dict_from_file( filename ):
    file = open(filename, 'r')
    content = file.readlines()
    file.close()
    first_resE_line_seen = 0

    to_return = {}
    
    for line in content:
        if line[0:7] == 'ResResE':
            line = line.replace('\n','')
            if not first_resE_line_seen:
                first_resE_line_seen = 1
                if len( token_titles.keys() ) == 0:
                    setup_token_titles( line )
            else:
                if line[11:18] == 'nonzero':
                    continue
                this_record = ResResE( line, token_titles )
                totval = this_record.get_value( 'total' )
                if isinstance( totval, float ):
                    to_return[ this_record.get_name() ] = this_record
                else:
                    print "Error: total value column is not a float, offending line reads: "
                    print line
                    sys.exit()
    return to_return
