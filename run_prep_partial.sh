#!/bin/bash

MATLABPATH="/afs/ece.cmu.edu/usr/$USER/Public/condor/10k-eeg" matlab -nodesktop -nosplash -r "call_prep_partial('$USER', $1)"
