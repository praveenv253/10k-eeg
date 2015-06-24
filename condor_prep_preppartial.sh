#!/bin/bash

## Variables and functions that this file should define
#
# Executable's details:
# - exec_path
#   Executable's name if findable by `which`, else full path to the executable
# - exec_prefix
#   Additional environment variables to be passed to the executable, if any
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

# Condor directory - directory containing code source repository and other
# necessary repositories (eg. fieldtrip).
condor_dir="/afs/ece.cmu.edu/usr/$USER/Public/condor"

# Name of this task - used to name the results folder and the log files.
task_name="prep_leadfield"

# Path to executable, or just the file itself, if the shell can find it.
# This will be called via indirection.
exec_path="matlab"
exec_prefix="MATLABPATH=$condor_dir/10k-eeg:$condor_dir/fieldtrip-20150308:"

# Program arguments and output file names
num_sensors=252
num_dipoles=17199
get_min_max_dipole_nums() {
	# Convert job number into dipole slice to operate upon
	let "min_dipole_num = 100 * $1 + 1"
	let "max_dipole_num = 100 * $1 + 100"
	let "max_dipole_num = (max_dipole_num < num_dipoles) ? max_dipole_num : num_dipoles"
}
get_args() {
	get_min_max_dipole_nums $1
	common_args="-nodesktop -nosplash -r"
	prep_leadfield_cmd="prep_partial_leadfield($num_sensors, $num_dipoles, $min_dipole_num, $max_dipole_num);"
	quit_cmd="quit;"
	# Must double-quote quotes - this is an escaping mechanism in Condor:
	# Read http://research.cs.wisc.edu/htcondor/manual/v8.2/condor_submit.html,
	# the section on arguments
	args="$common_args '$prep_leadfield_cmd $quit_cmd'"
}
get_outfile_name() {
	get_min_max_dipole_nums $1
	outfile_name="partial_leadfield_${min_dipole_num}_${max_dipole_num}.mat"
}

# Job details
num_jobs=172