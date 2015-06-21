#!/bin/bash

# Note about file permissions:
# The directories under condor should have suitable file permissions, so that
# they are readable by remote machines.
# Check UNIX file permissions with `ls -l` and edit them using `chmod`.
# - The requisite files should at least have `a+r`.
# Check AFS ACL settings using `fs la` and edit them using `fs sa`.
# - The directories should at least have `rl`.
exec_name="run_prep_partial"
exec_suffix=".sh"
exec_dir="/afs/ece.cmu.edu/usr/$USER/Public/condor/10k-eeg"
outfile_prefix="partial_leadfield_"
outfile_suffix=".mat"
num_jobs=172

exec_path="$exec_dir/${exec_name}${exec_suffix}"
logdir="logs"

# Set up results directory
dir="/tmp/$USER/${exec_name}_$(date '+%Y%m%d_%H%M%S')"
echo "Setting up results directory: $dir"
mkdir -p $dir
mkdir "$dir/$logdir"

# Condor submit file
submit_file="$dir/$exec_name.condor"

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

InitialDir = $dir
Should_Transfer_Files = YES
When_To_Transfer_Output = ON_EXIT
Notification = ERROR" > $submit_file

i=0
while [ $i -lt $num_jobs ]; do
	echo "
Arguments = $i
Transfer_Output_Files = ${outfile_prefix}${i}${outfile_suffix}
Queue" >> $submit_file
	let i=i+1
done

# Submit to condor
#condor_submit $submit_file

# Print queue and status
#condor_q
#condor_status
