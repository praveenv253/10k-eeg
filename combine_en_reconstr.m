function combine_en_reconstr(num_sensors, num_dipoles)
%% Read a jobspec file and combine the partial elastic-net reconstruction
%  matrices it defines. Output the concatenated result.

% Load the jobspec file to get job details
jobspec_file = sprintf('lead-field-%d-%d/jobspec.txt', ...
                       num_sensors, num_dipoles);
jobspec = dlmread(jobspec_file);
num_jobs = size(jobspec, 1);

% Load the file describing selected dipole indices
dipole_subset_indices_filename = sprintf('dipole_subset_%d.mat', num_dipoles);
load(dipole_subset_indices_filename);   % Defines `dipole_subset_indices`
num_selected = numel(dipole_subset_indices);

concatenated_reconstr = {};
for i = 1:num_jobs
	disp(i);
	
	% Load the i'th partial reconstruction
	imin = jobspec(:, 2);
	imax = jobspec(:, 3);
	filename = sprintf('mne-en-%d-%d/partial_en_reconstr_%d_%d.mat', ...
	                   num_sensors, num_dipoles, imin, imax);
	load(filename);  % Defines the variable `reconstructions`

	% Concatenate
	concatenated_reconstr = [concatenated_reconstr, reconstructions];
end

% Save the concatenated reconstruction
result_filename = sprintf('en_reconstr_%d_%d.mat', num_sensors, num_dipoles);
save(result_filename, 'concatenated_reconstr', '-v7.3');

return
