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

%% Create measurements

% Choose a particular dipole
i = 1;     % Shallow
%i = 800;   % Deep
%disp(i);

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

% Lasso
%alpha = 1;
%[b, stats] = lasso(L, measurements, 'Lambda', 0.003);
%reconstruction = b;

% Ridge regression
%alpha = 0;
%b = ridge(measurements, L);
%reconstruction = b;

% Compute psf and bias values
[psf, bias] = psfbias(dipole_grid, i, reconstruction)

% ----- Done with MNE inverse solution ----- %

%% Plot reconstruction

fig = figure;
fig.Units = 'pix';
fig.Position = [0, 0, 520, 400];
ax = scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), ...
              20, reconstruction, 'filled');
%ax = scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), ...
              %20, log10(abs(reconstruction)), 'filled');

% Axis and view
axis equal;
az = -61.5; el = 6;   % Camera view parameters
view(az, el);

% Title and axis labels
title_text = sprintf(strcat('Reconstruction of a unit dipole at i=%d\n', ...
                            '\\alpha=%f, \\lambda=%f\n', ...
                            '#dipoles=%d, #sensors=%d'), ...
                     i, alpha, lambda, num_dipoles, num_sensors);
title(title_text);
xlabel('x');
ylabel('y');
zlabel('z');

% Colorbar
colormap(jet);
cb = colorbar;
caxis([-0.1, 0.1]);
%caxis([-3, -1]);

% Plot sensor positions
%hold on;
%scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 5, 'filled', 'k');

% Save figure
filename = sprintf('m%d-alpha-1e-3.png', lambda_index);
print(fig, filename, '-dpng', '-r0');

% ----- Done with simulation ----- %
