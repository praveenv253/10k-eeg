function plot_error_vs_depth(num_sensors, num_dipoles)

reconstructions_filename = sprintf('en_reconstr_%d_%d.mat', num_sensors, ...
                                   num_dipoles);
load(reconstructions_filename);

dipole_grid_filename = sprintf('dipole_grid_%d.mat', num_dipoles);
load(dipole_grid_filename);

dipole_subset_filename = sprintf('dipole_subset_%d.mat', num_dipoles);
load(dipole_subset_filename);
num_selected = numel(dipole_subset_indices);

% Compute depths
depths = 80 - sqrt(sum(dipole_grid(dipole_subset_indices, :).^2, 2));
subsubset = find(depths <= 35);
depths = depths(subsubset);

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

psfs = psfs(subsubset);
biases = biases(subsubset);
p = polyfit(depths, psfs, 2);

x = linspace(min(depths), max(depths));
y = polyval(p, x);

% Plot psf vs depth and bias vs depth
fig = figure;
fig.Units = 'pix';
fig.Position = [0, 0, 520, 400];
scatter(depths+0.1*randn(size(depths)), psfs+0.1*randn(size(psfs)));

hold on;
plot(x, y, 'r');

xlim([0, 35]);
ylim([0, 45]);
fig_filename = sprintf('psf-vs-depth-%d-%d.png', num_sensors, num_dipoles);
print(fig, fig_filename, '-dpng', '-r0');
%scatter(depths, biases);

psfs_filename = sprintf('psfs_%d_%d.mat', num_sensors, num_dipoles);
save(psfs_filename, 'psfs', 'depths', 'x', 'y');

%biases_filename = sprintf('biases_%d_%d.mat', num_sensors, num_dipoles);
%save(biases_filename);

%depths_filename = sprintf('depths_%d.mat', num_dipoles);
%save(depths_filename, 'depths');
