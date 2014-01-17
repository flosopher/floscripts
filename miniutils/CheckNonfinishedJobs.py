#!/usr/bin/python
import sys
import os


osreply =  os.popen("grep submitting submit.log")
alljobs = (osreply.read() ).split('\n')

jobs_finished = []
jobs_unfinished = []
jobs_aborted = []

for job in alljobs:
    fields = job.split()
    num_fields = len( fields )
    if num_fields < 1:
        continue
    jobdir = fields[ num_fields - 1]
    host = fields[ num_fields - 4 ]
    jobpdb = (jobdir.split('/'))[7]
    joblog = jobdir + jobpdb + '__match.log'
    finishreply = os.popen("tail %s | grep 'atcher ran'" % joblog )
    job_finished = 0
    if finishreply.read() != "":
        jobs_finished.append( jobpdb )
        continue

    unfinished_reply = os.popen("ssh %s \"ps aux | grep %s | grep -v grep\""%(host, jobpdb ) )
    #print "'" + unfinished_reply.read() + "'"
    
    if unfinished_reply.read() != "":
        jobs_unfinished.append( jobpdb )
    else:
        jobs_aborted.append( jobpdb )
    #print "'" + finishreply.read() + "'"

    #print " done with checking for " + jobpdb

outstring = "The following jobs were finished: \n"
for fin in jobs_finished:
    outstring = outstring + fin + "\n"
outstring = outstring + "The following jobs are unfinished: \n"
for fin in jobs_unfinished:
    outstring = outstring + fin + "\n"
outstring = outstring + "The following jobs were aborted: \n"
for fin in jobs_aborted:
    outstring = outstring + fin + "\n"

print outstring
