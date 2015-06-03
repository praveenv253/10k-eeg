%% Re-weight the lead-field matrix, so that its columns have unit norm

%% Load data
load 'lead_field_492_2145.mat';

%% Compute the normal-leadfield matrix
%  i.e. the leadfield martrix for radial dipoles

num_sensors = size(sens.pnt, 1);
%num_dipoles = size(dipole_grid, 1);
num_dipoles = size(lead_field.leadfield(lead_field.inside), 2);

%normals = lead_field.cfg.grid.pos / 7.5;
dipole_grid = lead_field.pos(lead_field.inside, :);
normals = dipole_grid ./ (sqrt(sum(dipole_grid.^2, 2)) * ones(1, 3));

L = zeros(num_sensors, num_dipoles);
lf = lead_field.leadfield(lead_field.inside);

% Find the lead-field of a normal dipole
for i = 1:num_dipoles
	forward_matrix = lf{i};
	% Compute H(q)m(q): m(q) here are unit radial sources
	forward_matrix = forward_matrix * normals(i, :)';
	L(:, i) = forward_matrix;
end

% There really shouldn't be any nans, right?
L(isnan(L)) = 0;

% ----- Normal forward matrix computation complete ----- %

%% Normalize the columns of the lead field matrix

for i = 1:num_dipoles
	L(:, i) = L(:, i) / norm(L(:, i));
end

save('reweighted_lead_field.mat', 'L');
