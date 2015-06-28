function generate_dipole_grid(resolution, max_radius)
%% Generate a dipole (voxel) grid of specified inter-voxel spacing for an
%  idealized head model
%  Resolution and maximum radius must be specified in millimeters

% Specify coordinates of grid points. These are chosen to be `resolution`
% apart, and symmetrically centered around the origin, but such that there are
% no grid points on the axes themselves.
coords = [resolution/2:resolution:max_radius];
coords = [-coords(end:-1:1), coords];
n = numel(coords);

% Create the dipole_grid - the full list of (x, y, z) coordinates
[x, y, z] = meshgrid(coords, coords, coords);
x = reshape(x, n^3, 1);
y = reshape(y, n^3, 1);
z = reshape(z, n^3, 1);
dipole_grid = [x, y, z];

% Restrict the grid to contain only those grid points that fall inside the
% sphere
r = sqrt(x.^2 + y.^2 + z.^2);
dipole_grid = dipole_grid(r <= max_radius, :);
num_dipoles = size(dipole_grid, 1);
disp(num_dipoles);

% Save a file containing the grid points and the final number of voxels.
filename = sprintf('dipole_grid_%d.mat', num_dipoles);
save(filename, 'dipole_grid', '-v7.3');

% Visualize the grid
%scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), 30, ...
%         r(r <= max_radius), 'filled');

return
