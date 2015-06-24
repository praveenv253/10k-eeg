Using HTCondor
==============

1. First, you need to design your program to be able to accept arguments that
   allow it to work on a part of the data (that's how I'm parallelizing most
   stuff, anyway). eg. prep_partial_leadfield.m
2. Then, you need to write a script that defines how many jobs are there
   overall, and which job does what - i.e. what arguments are to be passed to
   the program for each job. You also need to set some path parameters.
   eg. condor_prep_preppartial.sh
3. Make sure you read and understand all the comments in the prep script as
   well as in condor_submit.sh. The permissions issues discussed there are
   important.
4. Finally, while in the source repository that contains the run_condor_prog.sh
   script, source the prep script and the condor_submit.sh script. This should
   take care of submitting all your jobs to Condor.
