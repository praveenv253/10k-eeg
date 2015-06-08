%% Load the forward matrices and compute normal components

clear;
load 'lead_field_92_2136.mat';
load 'reweighted_lead_field_92_2136.mat';

% Read data again, since this is also the normal to the surface
% No need to use Ted's patch-based method here, because we have a simplistic
% head model
% normals = dlmread('points-1212.out');
% normals = normals(:, 3:5);

num_sensors = size(sens.pnt, 1);
%num_dipoles = size(dipole_grid, 1);
num_dipoles = size(lead_field.leadfield(lead_field.inside), 2);

%normals = lead_field.cfg.grid.pos / 7.5;
dipole_grid = lead_field.pos(lead_field.inside, :);
normals = dipole_grid ./ (sqrt(sum(dipole_grid.^2, 2)) * ones(1, 3));

%L = zeros(num_sensors, num_dipoles);
%lf = lead_field.leadfield(lead_field.inside);

%% Find the lead-field of a normal dipole
%for i = 1:num_dipoles
%    forward_matrix = lf{i};
%    % Compute H(q)m(q): m(q) here are unit radial sources
%    forward_matrix = forward_matrix * normals(i, :)';
%    L(:, i) = forward_matrix;
%end

%% There really shouldn't be any nans, right?
%L(isnan(L)) = 0;

% ----- Normal forward matrix computation complete ----- %

%% Compute MNE inverse solution

% Arrays to hold the point spread function and bias for the reconstruction of a
% unit dipole at each voxel
psf = zeros(num_dipoles, 1);   % Size is equal to the number of dipoles
bias = zeros(num_dipoles, 1);
bias_vec = zeros(num_dipoles, 3);

for i = 1:num_dipoles
	disp(i);

	% The sensor values for a unit dipole at the i'th voxel is simply the
	% normal lead field vector corresponding to the i'th voxel.
	measurements = L(:, i);

	% Compute the reconstruction
	[b, stats] = lasso(L, measurements, 'Lambda', 0.0030);
	%[~, min_mse_index] = min(stats.MSE);
	%reconstruction = b(:, min_mse_index);
	reconstruction = b;

	% Compute psf and bias values
	if(max(reconstruction) > 0)
		reconstruction = reconstruction ./ max(reconstruction);
		d_vec = dipole_grid - repmat(dipole_grid(i, :), num_dipoles, 1);
		d = sqrt(sum(d_vec.^2, 2));
		psf(i) = max(d(reconstruction > exp(-1)));
		bias(i) = mean(d(reconstruction == 1));
		bias_vec(i, :) = mean(d_vec(reconstruction == 1, :), 1);
	else
		psf(i) = nan;
		bias(i) = nan;
		bias_vec(i, :) = nan;
	end
end

% ----- Done with MNE inverse solution ----- %

% Compute indices of one "slice" of the brain
% This is only for 10mm spacing
slice = logical((dipole_grid(:, 1) > -5) .* (dipole_grid(:, 1) < 5));

%% Plot PSF

figure;
scatter(dipole_grid(slice, 2), dipole_grid(slice, 3), ...
        30, psf(slice), 'filled');
%scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), ...
%         20, psf, 'filled');
axis equal;

% Title and axis labels
title('Width of PSF of reconstruction of a unit dipole at each voxel');
xlabel('x');
ylabel('y');
%zlabel('z');

% Colorbar
colormap(jet);
cb = colorbar;

% Plot sensor positions
%hold on;
%scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 5, 'filled', 'k');

%% Plot Bias

figure;
scatter(dipole_grid(slice, 2), dipole_grid(slice, 3), ...
        30, bias(slice), 'filled');
%scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), ...
%         20, bias, 'filled');
axis equal;

% Title and axis labels
title('Bias of midpoint of reconstruction of a unit dipole at each voxel');
xlabel('x');
ylabel('y');
%zlabel('z');

% Colorbar
colormap(jet);
cb = colorbar;

% Plot sensor positions
%hold on;
%scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 5, 'filled', 'k');

% ----- Done with simulation ----- %
