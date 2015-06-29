#!/bin/bash

## Variables and functions that this file should define
#
# Executable's details:
# - exec_path
#   Executable's name if findable by `which`, else full path to the executable
#
# Job details:
# - task_name
#   Name of this program
# - num_jobs
#   Number of jobs to create. get_args and get_outfile_name should be able to
#   handle these many job numbers (see below).
#
# Division of labour:
# - get_args()
#   A function that accepts the job number (1..$num_jobs), and defines a
#   variable called `args` - the arguments to be passed to the executable for
#   that job number.
# - get_outfile_name()
#   A function that accepts the job number (1..$num_jobs), and defines a
#   variable called `outfile_name`, containing a comma separated list of the
#   names of output files that the executable produces for that job number.
# - get_jobspec()
#   An optional function that accepts the job number (1..$num_jobs), and
#   defines a variable called `jobspec` that contains a suitable job
#   description, possibly for parsing while post-processing.

## Note about file permissions:
#
# The condor_dir and its subdirs should have suitable file permissions, so that
# they are readable by remote machines.
#
# Check UNIX file permissions with `ls -l` and edit them using `chmod`.
# - The requisite files should at least have `a+r`.
#
# Check AFS ACL settings using `fs la` and edit them using `fs sa`.
# - The directories should at least have `rl` for system:ece.
# - For instance, recursively set condor_dir to have suitable permissions, use:
#       find $condor_dir -type d -exec fs sa {} system:ece rl \;

## How to source this particular file
#
# source condor_prep_mneenpartial.sh <num_sensors> <num_dipoles> <num_jobs> \
#                                                         <num_dipoles_per_job>

# Condor directory - directory containing code source repository and other
# necessary repositories (eg. fieldtrip).
condor_dir="/afs/ece.cmu.edu/usr/$USER/Public/condor"

# Name of this task - used to name the results folder and the log files.
task_name="mne_en"

# Path to executable, or just the file itself, if the shell can find it.
# This will be called via indirection.
exec_path="matlab"

# Program arguments and output file names
# NOTE: This relies on the fact that you can pass arguments while sourcing
# scripts in bash. This only works in bash, to my knowledge. It certainly won't
# work in sh.
num_sensors="$1"
num_dipoles="$2"
num_dipoles_per_job="$4"
get_min_max_dipole_nums() {
	# Convert job number into dipole slice to operate upon
	let "min_dipole_num = $num_dipoles_per_job * $1 + 1"
	let "max_dipole_num = $num_dipoles_per_job * $1 + $num_dipoles_per_job"
	let "max_dipole_num = (max_dipole_num < num_dipoles) ? max_dipole_num : num_dipoles"
}
get_args() {
	get_min_max_dipole_nums $1
	common_args="-nodesktop -nosplash -r"
	addpath_cmd="addpath(''$condor_dir/10k-eeg'');"
	mne_en_cmd="mne_en_partial($num_sensors, $num_dipoles, $min_dipole_num, $max_dipole_num);"
	quit_cmd="quit;"
	args="$common_args '$addpath_cmd $mne_en_cmd $quit_cmd'"
}
get_outfile_name() {
	get_min_max_dipole_nums $1
	outfile_name="partial_en_reconstr_${min_dipole_num}_${max_dipole_num}.mat"
}

# Job description
get_jobspec() {
	get_min_max_dipole_nums $i
	jobspec="$i $min_dipole_num $max_dipole_num"
}

# Job details
num_jobs="$3"
