%% Compute error metrics for a pre-computed MNE solution

%% Load data

%clear;
load('fInfos_252_17199_15deg.mat');

%% Compute bias for each dipole's reconstruction.

final_biases = [];
for i = 1:length(indices_in_cone)
	dipole_index = indices_in_cone(i);
	f = fInfos(i);

	% Compute bias for each lambda (L1-regularization parameter value)
	%biases = [];
	%for lambda_index = 1:length(f.Lambda)
	%    reconstruction = f.B(:, lambda_index);
	%    if max(reconstruction) > 0
	%        % Compute bias
	%        a = reconstruction ./ max(reconstruction);
	%        d = sqrt(sum( (dipole_grid - ones(size(dipole_grid, 1), 1) * dipole_grid(dipole_index, :)).^2, 2 ));
	%        bias = mean(d(a == 1));
	%    else
	%        bias = NaN;
	%    end
	%    biases = [biases, bias];
	%end
	% Take the lambda corresponding to the minimum bias - somehow, this seems wrong...
	%final_bias = min(biases);

	% Or, take the bias corresponding to the minimum MSE
	[m, min_mse_index] = min(f.MSE);
	%final_bias = biases(min_mse_index);
	reconstruction = f.B(:, min_mse_index);
	if max(reconstruction) > 0
		a = reconstruction ./ max(reconstruction);
		d = sqrt(sum( (dipole_grid - ones(size(dipole_grid, 1), 1) * dipole_grid(dipole_index, :)).^2, 2 ));
		final_bias = mean(d(a == 1));
	else
		final_bias = NaN;
	end

	% Save the bias into an array for plotting
	final_biases = [final_biases, final_bias];
end

% Plot the bias for each dipole location
scatter3(dipole_grid(indices_in_cone, 1), dipole_grid(indices_in_cone, 2), dipole_grid(indices_in_cone, 3), 50, final_biases, 'filled');
axis equal;
