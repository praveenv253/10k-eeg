%% Load the forward matrices and compute normal components

clear;
load 'lead_field_92_2136.mat';
load 'reweighted_lead_field_92_2136.mat';

%% Re-weight the forward matrix to have unit-norm columns

num_sensors = size(sens.pnt, 1);
num_dipoles = size(lead_field.leadfield(lead_field.inside), 2);

dipole_grid = lead_field.pos(lead_field.inside, :);
normals = dipole_grid ./ (sqrt(sum(dipole_grid.^2, 2)) * ones(1, 3));

% ----- Normal forward matrix computation complete ----- %

%% Create measurements

% Choose a particular dipole
%i = 1;     % Shallow
i = 800;   % Deep

% Set noise values
snr = inf;
noise = zeros(size(L(:, i)));
%snr = 10000;
%noise_var = 1.0 / (snr * num_sensors);
%sigma_n = sqrt(noise_var);
%noise = sigma_n .* randn(num_sensors, 1);

% The sensor values for a unit dipole at the i'th voxel is simply the
% normal lead field vector corresponding to the i'th voxel, plus noise.
measurements = L(:, i) + noise;

%% Compute the reconstruction and error metrics for different parameter values

alphas = [1, 1e-1, 1e-2, 1e-3];
lambdas = logspace(log10(3e-4), log10(0.3), 50);

psfs = zeros(length(alphas), length(lambdas));
biases = zeros(length(alphas), length(lambdas));
errors = zeros(length(alphas), length(lambdas));
for j = 1:length(alphas)
	disp(j);
	alpha = alphas(j);

	% Elastic net
	[b, stats] = lasso(L, measurements, 'Alpha', alpha, 'Lambda', lambdas);

	% Compute psf and bias values
	[psf, bias] = psfbias(dipole_grid, i * ones(length(b), 1), b);
	psfs(j, :) = psf;
	biases(j, :) = bias;

	% Compute MSE of fit
	x = repmat(measurements, 1, length(lambdas));
	err = mean((x - L * b).^2, 1);
	errors(j, :) = err;
end

% ----- Done with MNE inverse solution ----- %

%% Plot a 3D plot of psf and bias vs alpha and lambda

figure;
bar3(psfs);
%ax = gca;
%ax.XTick = 1:length(lambdas)
%ax.YTick = 1:length(alphas)
%ax.XTickLabel = num2str(lambdas);
%ax.YTickLabel = num2str(alphas);
title('PSF width');
xlabel('\lambda');
ylabel('\alpha');
zlabel('PSF width');

%figure;
%scatter3(alphas, lambdas, bias, 10, bias, 'filled');
%title('Bias');
%xlabel('\alpha');
%ylabel('\lambda');
%zlabel('Bias');

% ----- Done with simulation ----- %
