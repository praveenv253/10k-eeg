#!/bin/bash

matlab -nodesktop -nosplash -r "userpath('/afs/ece.cmu.edu/usr/$USER/Public/condor/10k-eeg'); call_prep_partial('$USER', 6252, 17199, $1)"
