#!/bin/bash

# Results directory and directory for stdout, stderr and Condor logs
results_dir="/tmp/$USER/${task_name}_$(date '+%Y%m%d_%H%M%S')"
logdir="logs"
echo "Setting up results directory: $results_dir"
mkdir -p "$results_dir/$logdir"

# Condor submit file
submit_file="$results_dir/$task_name.condor"

# Job spec file - single file containing exact job descriptions
jobspec_file="$results_dir/jobspec.txt"

# Indirection script
# You must be in a directory which has read permissions for system:ece when
# calling condor_submit.sh, otherwise Condor won't be able to read the
# auto-generated indirection script.
indirection_script="run_condor_prog.sh"
if [[ ! -f $indirection_script ]]; then
   echo -e '#!/bin/bash\n\n"$@"' > $indirection_script
fi

# Preamble
echo "\
Executable = $PWD/$indirection_script
Universe = vanilla
Getenv = True
Requirements = (Arch == \"INTEL\" || Arch == \"X86_64\") && OpSys == \"LINUX\"
Copy_To_Spool = False
Priority = 0
Rank = TARGET.Mips

Output = $logdir/${task_name}_\$(cluster)_\$(process).out
Error = $logdir/${task_name}_\$(cluster)_\$(process).err
Log = $logdir/${task_name}_\$(cluster)_\$(process).log

InitialDir = $results_dir
Should_Transfer_Files = YES
When_To_Transfer_Output = ON_EXIT
Notification = ERROR" > $submit_file

# Job descriptions
i=0
while [ $i -lt $num_jobs ]; do
	# Get job details
	get_args $i
	get_outfile_name $i
	if type get_jobspec | grep -q 'function'; then
		# Check if a get_jobspec function has been defined. If so, assume
		# jobspec is defined by get_jobspec.
		get_jobspec $i
	else
		# If no get_jobspec function exists, create a jobspec out of the job
		# number and the arguments and output files for that job number.
		jobspec="$i:\n\t$args\n\t$outfile_name\n"
	fi

	# Save job details
	echo "$jobspec" >> $jobspec_file

	# Add arguments and output file names to the condor submit file.
	echo "
Arguments = \"$exec_path $args\"
Transfer_Output_Files = $outfile_name
Queue" >> $submit_file
	let i=i+1
done

# Submit to condor
condor_submit $submit_file

# Print queue and status
#condor_q
#condor_status
