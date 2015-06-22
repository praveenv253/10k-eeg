function prep_partial_leadfield(num_sensors, num_dipoles, min_dipole_num, ...
                                max_dipole_num)

%% Define stuff ---------------------------------------------------------------

% load headmodel
load('headmodel_new.mat');

% Create sensory space
sens = [];
sens.type = 'eeg';
sensor_grid_filename = sprintf('points-%d.out', num_sensors);
data = dlmread(sensor_grid_filename);
sens.pnt = 92 * data(:, 3:5);       % Scale all data by 9.2cm (radius of head)
%sens.ori = sens.pnt ./ ( sqrt(sum(sens.pnt.^2, 2)) * ones(1,3) );
sens.unit = 'mm';
sens.label{1} = 'ref';
sens.chantype{1} = 'ref';
for i = 1:size(sens.pnt, 1)
    sens.label{i} = sprintf('%03d', i);
    sens.chantype{i} = 'eeg';
end
sens.label = sens.label';
sens.chantype = sens.chantype';

% Define voxel grids
% data = dlmread('points-1212.out');
% dipole_grid = 75 * data(:, 3:5);     % Dipoles are inside the head, at r=7.5cm
dipole_grid_filename = sprintf('dipole_grid_%d.mat', num_dipoles);
load(dipole_grid_filename);

%% Compute leadfield vectors --------------------------------------------------

% Get the forward matrices
cfg = [];
cfg.vol = headmodel;
cfg.elec = sens;
cfg.unit = 'mm';
cfg.grid.pos = dipole_grid(min_dipole_num:max_dipole_num, :);
%cfg.grid.resolution = 5;  % 10mm ~ 2145 dipoles; 5mm ~ 17199 dipoles
cfg.grid.unit = 'mm';
cfg.grid.inside = 1:size(dipole_grid(min_dipole_num:max_dipole_num, :), 1);
lead_field = ft_prepare_leadfield(cfg);

filename = sprintf('partial_leadfield_%d.mat', arg);
save(filename, 'lead_field', '-v7.3');
