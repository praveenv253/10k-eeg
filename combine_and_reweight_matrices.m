function combine_and_reweight_matrices(num_sensors, num_dipoles)
%% Read a jobspec file and combine the partial leadfield matrices it describes
%  Output the column-reweighted matrix of the partials, having unit norm for
%  each column.

% Load the jobspec file to get job details
jobspec_file = sprintf('lead-field-%d-%d/jobspec.txt', ...
                       num_sensors, num_dipoles);
jobspec = dlmread(jobspec_file);
num_jobs = size(jobspec, 1);

% Load the dipole grid and compute normals at each dipole
dipole_grid_file = sprintf('dipole_grid_%d.mat', num_dipoles);
dipole_grid = load(dipole_grid_file);
normals = dipole_grid ./ (sqrt(sum(dipole_grid.^2, 2)) * ones(1, 3));

% Resultant leadfield matrix
L = zeros(num_sensors, num_dipoles);

% Iterate through jobs and accumulate each partial leadfield matrix
for i = 1:num_jobs
	disp(i);

	% Load the i'th partial leadfield matrix
	imin = jobspec(i, 2);
	imax = jobspec(i, 3);
	filename = sprintf('lead-field-%d-%d/partial_leadfield_%d_%d.mat', ...
	                   num_sensors, num_dipoles, imin, imax);
	load(filename);

	% Accumulate the j'th normal leadfield into L
	for j = imin:imax
		% Compute radial component of sensor values for the j'th unit dipole
		forward_matrix = lead_field.leadfield{j-imin+1};
		forward_matrix = forward_matrix * normals(j, :)';
		L(:, j) = forward_matrix;
	end
end

% There really shouldn't be any nans, right?
L(isnan(L)) = 0;

% Reweight the columns of L to have unit norm
for i = 1:num_dipoles
	L(:, i) = L(:, i) ./ norm(L(:, i));
end

% Save the reweighted normal leadfield matrix.
save('reweighted_lead_field.mat', 'L', '-v7.3');
