function mne_elastic_net(num_sensors, num_dipoles)
%% Compute the MNE reconstruction using the elastic net penalty.
%  Plot PSF-width and Bias.

%% Load the forward matrices and compute normal components

mat1 = sprintf('lead_field_%d_%d.mat', num_sensors, num_dipoles);
mat2 = sprintf('reweighted_lead_field_%d_%d.mat', num_sensors, num_dipoles);
load(mat1);
load(mat2);

dipole_grid = lead_field.pos(lead_field.inside, :);

% ----- Normal forward matrix computation complete ----- %

%% Take a subset of dipoles if desired

[indices_in_cone, dipoles_in_cone] = cone_slice(dipole_grid);
num_in_cone = length(indices_in_cone)

%% MNE inverse solution
psfs = zeros(num_in_cone, 1);
biases = zeros(num_in_cone, 1);
for j = 1:num_in_cone
	disp(j);

	% Choose a particular dipole
	i = indices_in_cone(j);
	%i = 1;     % Shallow
	%i = 800;   % Deep

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
	alpha = 1e-3;
	[b, stats] = lasso(L, measurements, 'Alpha', alpha, 'Lambda', 0.1);
	%[~, lambda_index] = min(stats.MSE);
	lambda_index = 1;
	lambda = stats.Lambda(lambda_index);
	reconstruction = b(:, lambda_index);

	% Compute PSF-width and bias values
	[psf, bias] = psfbias(dipole_grid, i, reconstruction)
	psfs(j) = psf;
	biases(j) = bias;
end

% ----- Done with MNE inverse solution ----- %

%% Plot PSF-width and bias

fig = figure;
fig.Units = 'pix';
fig.Position = [0, 0, 520, 400];
ax = scatter3(dipoles_in_cone(:, 1), dipoles_in_cone(:, 2), ...
              dipoles_in_cone(:, 3), 20, psfs, 'filled');

% Axis and view
axis equal;
az = -61.5; el = 6;   % Camera view parameters
view(az, el);

% Title and axis labels
title_text = sprintf(strcat('PSF-width of unit dipoles\n', ...
                            '\\alpha=%f, \\lambda=%f\n', ...
                            '#dipoles=%d, #sensors=%d'), ...
                     alpha, lambda, num_dipoles, num_sensors);
title(title_text);
xlabel('x');
ylabel('y');
zlabel('z');

% Colorbar
colormap(jet);
cb = colorbar;
caxis([0, 70]);
%caxis([-3, -1]);

% Plot sensor positions
%hold on;
%scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 5, 'filled', 'k');

% Save figure
%filename = sprintf('m%d-alpha-1e-3.png', lambda_index);
%print(fig, filename, '-dpng', '-r0');

% ----- Done with simulation ----- %
