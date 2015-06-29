function plot_error_vs_depth(num_sensors, num_dipoles)

reconstructions_filename = sprintf('en_reconstr_%d_%d.mat', num_sensors, ...
                                   num_dipoles);
load(reconstructions_filename);

dipole_grid_filename = sprintf('dipole_grid_%d.mat', num_dipoles);
load(dipole_grid_filename);

dipole_subset_filename = sprintf('dipole_subset_%d.mat', num_dipoles);
load(dipole_subset_filename);
num_selected = numel(dipole_subset_indices);

% Basic - choose lambda that minimizes MSE
psfs = zeros(num_selected, 1);
biases = zeros(num_selected, 1);
for i = 1:num_selected
	true_source_index = dipole_subset_indices(i);

	stats = concatenated_reconstr{i};
	[~, min_mse_index] = min(stats.MSE);
	reconstruction = stats.b(:, min_mse_index);

	[psf, bias] = psfbias(dipole_grid, true_source_index, reconstruction);
	psfs(i) = psf;
	biases(i) = bias;
end

% Plot psf vs depth and bias vs depth
depths = sqrt(sum(dipole_grid(dipole_subset_indices, :).^2, 2));
scatter(depths, psfs);
scatter(depths, biases);
