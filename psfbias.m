function [psf, bias, bias_vec] = psfbias(dipole_grid, is, reconstructions)

num_dipoles = size(dipole_grid, 1);
num_reconstructions = size(reconstructions, 2);

% Arrays to hold the point spread function and bias for the reconstruction of a
% unit dipole at each voxel
psf = zeros(1, num_reconstructions);   % Size is equal to the number of dipoles
bias = zeros(1, num_reconstructions);
bias_vec = zeros(3, num_reconstructions);

for j = 1:num_reconstructions
	i = is(j);   % Source dipole number
	reconstruction = reconstructions(:, j);

	if(max(reconstruction) > 0)
		reconstruction = reconstruction ./ max(reconstruction);
		% Compute the vector and magnitude of the distance of each dipole from
		% the i'th dipole (the source).
		d_vec = dipole_grid - repmat(dipole_grid(i, :), num_dipoles, 1);
		d = sqrt(sum(d_vec.^2, 2));
		% Compute psf and bias based on the value of the reconstruction
		psf(1, j) = max(d(reconstruction > exp(-1)));
		bias(1, j) = mean(d(reconstruction == 1));
		bias_vec(:, j) = mean(d_vec(reconstruction == 1, :), 1)';
	else
		psf(1, j) = nan;
		bias(1, j) = nan;
		bias_vec(:, j) = nan;
	end
end
