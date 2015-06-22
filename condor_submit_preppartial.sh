#!/bin/bash

# Note about file permissions:
# The directories under condor should have suitable file permissions, so that
# they are readable by remote machines.
# Check UNIX file permissions with `ls -l` and edit them using `chmod`.
# - The requisite files should at least have `a+r`.
# Check AFS ACL settings using `fs la` and edit them using `fs sa`.
# - The directories should at least have `rl`.

# Condor directory - directory containing code source repository and other
# necessary repositories (eg. fieldtrip).
condor_dir="/afs/ece.cmu.edu/usr/$USER/Public/condor"

# Executable's details
exec_name="matlab"
exec_suffix=""
exec_dir="/usr/local/bin"
exec_path="$exec_dir/${exec_name}${exec_suffix}"

# Program arguments and output file name
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
	userpath_cmd="userpath('$condor_dir/10k-eeg:$condor_dir/fieldtrip-20150308');"
	prep_leadfield_cmd="prep_partial_leadfield($num_sensors, $num_dipoles, $min_dipole_num, $max_dipole_num);"
	quit_cmd="quit;"
	args="$common_args \"$userpath_cmd $prep_leadfield_cmd $quit_cmd\""
}
get_outfile_name() {
	get_min_max_dipole_nums $1
	outfile_name="partial_leadfield_${min_dipole_num}_${max_dipole_num}.mat"
}

# Job details
num_jobs=172

# Results directory and directory for stdout, stderr and Condor logs
results_dir="/tmp/$USER/${exec_name}_$(date '+%Y%m%d_%H%M%S')"
logdir="logs"
echo "Setting up results directory: $results_dir"
mkdir -p "$results_dir/$logdir"

# Condor submit file
submit_file="$results_dir/$exec_name.condor"

# Preamble
echo "\
Executable = $exec_path
Universe = vanilla
Getenv = True
Requirements = (Arch == \"INTEL\" || Arch == \"X86_64\") && OpSys == \"LINUX\"
Copy_To_Spool = False
Priority = 0
Rank = TARGET.Mips

Output = $logdir/${exec_name}_\$(cluster)_\$(process).out
Error = $logdir/${exec_name}_\$(cluster)_\$(process).err
Log = $logdir/${exec_name}_\$(cluster)_\$(process).log

InitialDir = $results_dir
Should_Transfer_Files = YES
When_To_Transfer_Output = ON_EXIT
Notification = ERROR" > $submit_file

i=0
while [ $i -lt $num_jobs ]; do
	get_args $i
	get_outfile_name $i
	echo "
Arguments = $args
Transfer_Output_Files = $outfile_name
Queue" >> $submit_file
	let i=i+1
done

# Submit to condor
#condor_submit $submit_file

# Print queue and status
#condor_q
#condor_status
