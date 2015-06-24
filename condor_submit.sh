#!/bin/bash

# Results directory and directory for stdout, stderr and Condor logs
results_dir="/tmp/$USER/${task_name}_$(date '+%Y%m%d_%H%M%S')"
logdir="logs"
echo "Setting up results directory: $results_dir"
mkdir -p "$results_dir/$logdir"

# Condor submit file
submit_file="$results_dir/$task_name.condor"

# Indirection script
# You must be in the directory containing this indirection script while
# sourcing condor_sumbit.sh, because the executable path specification as
# defined below is dependent on $PWD.
# Further, this directory should have read permissions for system:ece when
# sourcing condor_submit.sh, otherwise Condor won't be able to read the
# indirection script.
indirection_script="run_condor_prog.sh"

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
	get_args $i
	get_outfile_name $i
	echo "
Arguments = \" $exec_path $args \"
Transfer_Output_Files = $outfile_name
Queue" >> $submit_file
	let i=i+1
done

# Submit to condor
condor_submit $submit_file

# Print queue and status
#condor_q
#condor_status
