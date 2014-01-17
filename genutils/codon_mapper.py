#! /usr/bin/python

import sys
import fileinput
import re

dna_codon_dictionary = {
 'I' : ['ATT', 'ATC', 'ATA'],
 'L' : ['CTT', 'CTC', 'CTA', 'CTG', 'TTA', 'TTG'],
 'V' : ['GTT', 'GTC', 'GTA', 'GTG'],
 'F' : ['TTT', 'TTC'],
 'M' : ['ATG'],
 'C' : ['TGT', 'TGC'],
 'A' : ['GCT', 'GCC', 'GCA', 'GCG'],
 'G' : ['GGT', 'GGC', 'GGA', 'GGG'],
 'P' : ['CCT', 'CCC', 'CCA', 'CCG'],
 'T' : ['ACT', 'ACC', 'ACA', 'ACG'],
 'S' : ['TCT', 'TCC', 'TCA', 'TCG', 'AGT', 'AGC'],
 'Y' : ['TAT', 'TAC'],
 'W' : ['TGG'],
 'Q' : ['CAA', 'CAG'],
 'N' : ['AAT', 'AAC'],
 'H' : ['CAT', 'CAC'],
 'E' : ['GAA', 'GAG'],
 'D' : ['GAT', 'GAC'],
 'K' : ['AAA', 'AAG'],
 'R' : ['CGT', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG']
}

degeneracy_codes = {
	'ACGT': 'N',
	'CGT' : 'B',# B = C,G, or T;
	'AGT' : 'D',# D = A,G, or T; 
	'ACT' : 'H',# H = A,C, or T;
	'ACG' : 'V',# V = A,C, or G;
	'AG' : 'R', # R = A or G (puRine);
	'CT' : 'Y', # Y = C or T (pYrimidine);
	'GT' : 'K', # K = G or T (Keto);
	'AC' : 'M', # M = A or C (aMino);
	'CG' : 'S', # S = G or C (Strong -3H bonds);
	'AT' : 'W',  # W = A or T (Weak - 2H bonds);
	'A' : 'A',
	'C' : 'C',
	'T' : 'T',
	'G' : 'G'
}

# define inverse dictionary of degeneray codes
inv_degeneracy_codes = dict((v,k) for k, v in degeneracy_codes.iteritems())

def split_on_empty_or_comma(str):
	chars = ','
	return filter(None,re.split('['+chars+']+',re.sub('([^'+chars+'])','\\1'+chars[0],str)))

def convert_degeneracy_list(base):
	# sorts the bases in alphabetical order and removes commas
	base = split_on_empty_or_comma(base)
	base.sort()
	return ''.join(base)

def calculate_degeneracy(codes):
	total = 1
	for code in codes:
		total *= len(inv_degeneracy_codes[code])
	return total

def get_codons(aminoacid):
	# single letter aminoacid
	try:
		#each -> look up 3 letter code for each
		codons = dna_codon_dictionary[aminoacid]
	except KeyError:
		raise Exception('Error: no codons for \''+aminoacid+'\'')
	#restrict to codons ending in C or G
	codons = filter(lambda codon: re.search('[CG]$',codon),codons)
	return codons

def get_degeneracy_codon(bases):
	# bases: ['AC','ACT','CG'] array[3] of possibilities at each index
	
	degeneracy_codon = ''
	bases = map(convert_degeneracy_list,bases)
	for base in bases:
		try:
			#look up the combined code for each superset
			degeneracy_codon += degeneracy_codes[base]
		except KeyError:
			raise Exception('Error: no degeneracy code for \''+base+'\'')
	#return 3 letter combined code
	return degeneracy_codon

def get_best_options(options):
	best_option_degeneracy = 999999;
	for option in options:
		if calculate_degeneracy(option) <= best_option_degeneracy:
			best_option_degeneracy = calculate_degeneracy(option)
	
	best_options = []
	for option in options:
		if calculate_degeneracy(option) == best_option_degeneracy:
			best_options.append(option)
	return [best_options, best_option_degeneracy]

class Combinator:
	def try_all(self,f,args):
		self.inc_val = i = 0
		self.bits = ''
		r = f(c,args)
		while r == None:
			self.bits = ''
			i += 1
			self.inc_val = i
			r = f(c,args)
		return r
	def next_bit(self):
		b = self.inc_val % 2
		self.inc_val /= 2
		self.bits += str(b)
		return b
	def choose(self,arr):
		n = 0
		for j in range(len(arr)-1):
			b = self.next_bit()
			if 1==b:
				n+=1
		return arr[n]
	def done(self,ret):
		if len(self.bits)==0 or self.bits.find('0')==-1:
			return ret
		return None


# combinator object, args for callback (aminoacids, options)
# aminoacids = ['A','I','F','V' ...]
# options = [] (array to be filled with potential degeneracy codons)
def degeneracy_codon_callback(combinator,args):
	aminoacids, options = args
	bases = []
	for a in range(len(aminoacids)):
		codon = combinator.choose(get_codons(aminoacids[a]))
		for i in range(len(codon)):
			base = codon[i]
			if i >= len(bases):
				bases.append('')
			#calculate the superset for each of the three digits
			if bases[i].find(base) == -1:
				bases[i] += base
	codes = get_degeneracy_codon(bases)	
	if not codes in options:
		options.append(codes)
	return combinator.done(options)

total_degeneracy = 1

for line in fileinput.input():
	line = line.strip().upper()
	params = line.split(' ')
	aminoacids = split_on_empty_or_comma(params[1])
	
	c = Combinator()
	options = c.try_all(degeneracy_codon_callback,[aminoacids,[]])
	
	best_options, best_option_degeneracy = get_best_options(options)
	total_degeneracy *= best_option_degeneracy
	print params[0]+" "+",".join(best_options)+" "+str(best_option_degeneracy)


print "Total Degeneracy: "+str(total_degeneracy)









