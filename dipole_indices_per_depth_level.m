function dipole_indices_per_depth_level(num_dipoles, max_radius)
%% Choose ~100 dipoles for each of 7 different depth levels

dipole_grid_filename = sprintf('dipole_grid_%d.mat', num_dipoles);
load(dipole_grid_filename);

min_radius = max_radius / 7;

x = dipole_grid(:, 1);
y = dipole_grid(:, 2);
z = dipole_grid(:, 3);
r = sqrt(x.^2 + y.^2 + z.^2);

dipole_subset_indices = [];
for i = 1:7
	inner_shell_radius = (i - 1) * min_radius;
	outside_inner_shell = (r >= inner_shell_radius);
	outer_shell_radius = i * min_radius;
	inside_outer_shell = (r < outer_shell_radius);

	indices = find((outside_inner_shell & inside_outer_shell));
	disp(size(indices));
	if size(indices, 1) > 100
		indices = datasample(indices, 100, 'Replace', false);
	end
	dipole_subset_indices = [dipole_subset_indices; indices];
end

filename = sprintf('dipole_subset_%d.mat', num_dipoles);
save(filename, 'dipole_subset_indices', '-v7.3');

return
