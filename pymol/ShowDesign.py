#!/usr/bin/python

#script to read in a matcher generated pdb file, figure out the catalytic sidechains, and carry out some basic python commands

from pymol import cmd
from pymol import util
from pymol import os


def listload(listfile = None):

    if listfile == None:
        print 'please give the name of the list file containing all structures'
        return 1

    read_file = open(listfile,'r')
    file_list = read_file.readlines()
    read_file.close()

    listfile_dirs = listfile.split('/')
    listfile_path = ''
    for i in range( len( listfile_dirs ) - 1):
        listfile_path = listfile_path + listfile_dirs[i] + '/'

    for line in file_list:
        line = line.replace("\n","")
        linelist = line.split(' ')
        filename = linelist[0]
        if( not os.path.isfile( filename )):
            if( os.path.isfile( filename +'.pdb' ) ):
                filename = filename + '.pdb'
            elif( os.path.isfile( listfile_path + filename + '.pdb') ):
                filename = listfile_path + filename + '.pdb'
        cmd.load( filename )


def listload_movie( listfile, obj_name ):

    read_file = open(listfile,'r')
    file_list = read_file.readlines()
    read_file.close()

    listfile_dirs = listfile.split('/')
    listfile_path = ''
    for i in range( len( listfile_dirs ) - 1):
        listfile_path = listfile_path + listfile_dirs[i] + '/'

    counter = 0
    for line in file_list:
        line = line.replace("\n","")
        linelist = line.split(' ')
        filename = linelist[0]
        if( not os.path.isfile( filename )):
            if( os.path.isfile( filename +'.pdb' ) ):
                filename = filename + '.pdb'
            elif( os.path.isfile( listfile_path + filename + '.pdb') ):
                filename = listfile_path + filename + '.pdb'
        counter = counter + 1
        cmd.load( filename, obj_name, counter )

  

def showresregion( seqpos=0 ):
    if( seqpos == 0 ):
        print 'Invalid sequence position given'
        return 1
    seqpos_string = str( seqpos )
    #print 'received seqpos '+seqpos_string+' ya '

    loaded_sels = cmd.get_names('selections')
    #print loaded_sels
    for sel in loaded_sels:
        if sel == 'specres':
            cmd.hide('sticks','specres')
        if sel == ' resregion':
            cmd.hide('lines','resregion')

    cmd.select('specres','resi '+seqpos_string )
    cmd.select('resregion', 'byres specres around 5')
    cmd.select('resregion','(byres resregion) and !hydro',enable=0)
    cmd.show('sticks','specres')
    cmd.show('lines','resregion')

def showloop( pos1, pos2):
    cmd.select('loop','resi '+str( pos1)+'-'+str( pos2 )+' and !hydro' )
    cmd.select('aroundloop', 'byres loop around 5 and not hydrogen and not het')
    
def align_to_object( object_no=-1, chain='' ):
    loaded_objs = cmd.get_names('objects')
    if object_no == -1:
        object_no = 0
    else:
        object_no = object_no - 1
        
    num_objects = len( loaded_objs )
    for i in range(num_objects):
        if (loaded_objs[i])[:5] == 'measu':
            continue
        if i != object_no:
            if chain == '':
                cmd.align(loaded_objs[i], loaded_objs[object_no] )
            else:
                cmd.align(loaded_objs[i]+' and chain '+chain, loaded_objs[object_no]+' and chain '+chain )



    
def showdes(desname=None):
    
    loaded_objs = cmd.get_names('objects')
    print loaded_objs

    if desname == None and not(loaded_objs): 
        print 'Error: please load a file'
        return 1
    elif desname == None:
        desname = loaded_objs[0]+'.pdb'

    read_file = open(desname,'r')

    cat_res = []

    for line in read_file:
        if line[0:4] == 'ATOM': break
        if line[0:24] == 'REMARK BACKBONE TEMPLATE':
            cols = line.split()
            cat_res.append(cols[10])
        elif line[0:24] == 'REMARK   0 BONE TEMPLATE':
            cols = line.split()
            cat_res.append(cols[11])
        elif line[0:16] == 'REMARK 666 MATCH':
            cols = line.split()
            cat_res.append(cols[11])


    read_file.close()
    #print cat_res
    
    cat_string = 'resi '
    for resis in cat_res:
        cat_string = cat_string + resis + '+'
    
    cat_string = cat_string[:-1] #take away last +
   
    print cat_string
   
    cmd.select('lig','het and !name V*')
    cmd.select('cats',cat_string)
    cmd.select('acts','lig around 10 and !cats and !name V* and !lig')
    cmd.hide('lines')
    cmd.show('sticks','lig')
    cmd.show('sticks','cats')
    cmd.show('car')
    cmd.select('acts','(byres acts) and !hydro',enable=0)
    cmd.set('cartoon_transparency','0.5')
    util.cba(11,'cats')

cmd.extend("showdes",showdes)
cmd.extend("listload",listload)
cmd.extend("listload_movie",listload_movie)
cmd.extend("showloop",showloop)
cmd.extend("align_to_object",align_to_object)
