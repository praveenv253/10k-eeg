function mne_en_partial(num_sensors, num_dipoles, min_j, max_j)
%% Compute the MNE reconstruction using the elastic net penalty.
%  Plot PSF-width and Bias.

% Load the forward matrix
leadfield_filename = sprintf('reweighted_lead_field_%d_%d.mat', ...
                             num_sensors, num_dipoles);
load(leadfield_filename);

% Load the dipole grid
dipole_grid_filename = sprintf('dipole_grid_%d.mat', num_dipoles);
load(dipole_grid_filename);

%% Take a subset of dipoles if desired

%[indices_in_cone, dipoles_in_cone] = cone_slice(dipole_grid, [1 0 0], 15);
%num_in_cone = length(indices_in_cone)
dipole_subset_indices_filename = sprintf('dipole_subset_%d.mat', num_dipoles);
load(dipole_subset_indices_filename);   % Defines `dipole_subset_indices`
num_selected = numel(dipole_subset_indices);

%% MNE inverse solution

reconstructions = {};
for j = [max(1, min_j):min(num_selected, max_j)]
	disp(j);

	% Choose a particular dipole
	i = dipole_subset_indices(j);

	% Set noise values
	snr = inf;
	noise = zeros(size(L(:, i)));
	%snr = 10;
	%noise_var = 1.0 / (snr * num_sensors);
	%sigma_n = sqrt(noise_var);
	%noise = sigma_n .* randn(num_sensors, 1);

	% The sensor values for a unit dipole at the i'th voxel is simply the
	% normal lead field vector corresponding to the i'th voxel, plus noise.
	measurements = L(:, i) + noise;

	%% Compute the reconstruction

	% Elastic net
	alpha = 1e-2;
	[b, stats] = lasso(L, measurements, 'Alpha', alpha, 'NumLambda', 50, ...
	                   'LambdaRatio', 1e-3);
	stats.b = b;
	%[~, lambda_index] = min(stats.MSE);
	%lambda_index = 1;
	%lambda = stats.Lambda(lambda_index);
	%reconstruction = b(:, lambda_index);

	reconstructions{j - max(1, min_j) + 1} = stats;
end

% ----- Done with MNE inverse solution ----- %

%% Save results

matfile = sprintf('partial_en_reconstr_%d_%d.mat', max(1, min_j), ...
                  min(num_selected, max_j));
save(matfile, 'reconstructions', '-v7.3');

return
