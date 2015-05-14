%% Define stuff ---------------------------------------------------------------

% load headmodel
load('headmodel_new.mat');

% Create sensory space
sens = [];
sens.type = 'eeg';
data = dlmread('points-252.out');
sens.pnt = 92 * data(:, 3:5);       % Scale all data by 9.2cm (radius of head)
%sens.ori = sens.pnt ./ ( sqrt(sum(sens.pnt.^2, 2)) * ones(1,3) );
sens.unit = 'mm';
sens.label{1} = 'ref';
sens.chantype{1}='ref';
for i = 1:size(sens.pnt, 1)
    sens.label{i} = sprintf('%03d', i);
    sens.chantype{i} = 'eeg';
end
sens.label = sens.label';
sens.chantype = sens.chantype';

% Define voxel grids
% data = dlmread('points-1212.out');
% dipole_grid = 75 * data(:, 3:5);     % Dipoles are inside the head, at r=7.5cm

%% Compute leadfield vectors --------------------------------------------------

% Get the forward matrices
cfg = [];
cfg.vol = headmodel;
cfg.elec = sens;
cfg.unit = 'mm';
%cfg.grid.pos = dipole_grid;
cfg.grid.resolution = 10;
cfg.grid.unit = 'mm';
%cfg.grid.inside = ones(size(dipole_grid, 1), 1);
lead_field = ft_prepare_leadfield(cfg);

save('lead_field.mat', 'lead_field', 'sens');