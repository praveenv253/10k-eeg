%% Define stuff ---------------------------------------------------------------

% load headmodel
load('concentric_headmodel.mat');

% Create sensory space
sens = [];
sens.type = 'eeg';
data = dlmread('points-252.out');
sens.pnt = 9.2 * data(:, 3:5);       % Scale all data by 9.2cm (radius of head)
sens.ori = sens.pnt ./ ( sqrt(sum(sens.pnt.^2, 2)) * ones(1,3) );
sens.label{1} = 'ref';
sens.chantype{1}='ref';
for i = 1:size(sens.pnt, 1)
    sens.label{i} = sprintf('%03d', i);
    sens.chantype{i} = 'eeg';
end
sens.label = sens.label';
sens.chantype = sens.chantype';

% Define voxel grids
data = dlmread('points-1212.out');
dipole_grid = 7.5 * data(:, 3:5);     % Dipoles are inside the head, at r=7.5cm

%% Compute leadfield vectors --------------------------------------------------

% Get the forward matrices
cfg = [];
cfg.vol = headmodel;
cfg.elec = sens;
cfg.grid.pos = dipole_grid;
cfg.grid.inside = 1:size(dipole_grid,1);
cfg.grid.unit = 'cm';
lead_field = ft_prepare_leadfield(cfg);

% TODO: Get rid of the cell and make lead_field into a 3d matrix. So much
% easier to handle...

%% Create the forward matrices ------------------------------------------------

% TODO: Unchecked code begins here...

% Read data again, since this is also the normal to the surface
% No need to use Ted's patch-based method here, because we have a simplistic
% head model
normals = dlmread('points-252.out')
normals = normals(:, 3:5);

L = [];
for idx = 1:length(lead_field.leadfield) % Iteration over number of dipoles, I think
    n = size(lead_field.leadfield{idx}, 1);  % n = number of sensors
	% Taking dot product of leadfield vector with the normal at that sensor
	% since we are interested only in the normal leadfield
	% TODO: Check somehow - Is it the same thing to say that you have a radial
	%       dipole, and then calculate the leadfield, as it is to calculate the
	%       leadfield for a dipole with three components, and to then find the
	%       effective leadfield in the radial direction?
    L(:, idx) = sum(lead_field{idx} .* (ones(n, 1) * normals(idx, :)), 2);
	% What is Ted doing here?
	% (252x3) .* (252x1 * 1x3) = (252x3 .* 252x3)
	% Why are we taking sum over the second axis? => Makes no sense...
	% TODO: Correct this equation.
	% We want forward matrices L, (252x1212)
	% => 252 radial leadfield vectors at sensors for 1212 dipoles
end

% Use this instead?
%forward_matrices = zeros(size(sensor_grid,1), size(dipole_grid,1));
%for i = 1:size(dipole_grid,1)
%    forward_matrix = lead_field.leadfield{1};
%    dipole_ori = dipole_grid(i,:)/norm(dipole_grid(i,:));
%    forward_matrix = forward_matrix * dipole_ori';
%    forward_matrices(:,i) = forward_matrix;
%end

% TODO: Figure out what on earth lst is!! - Done!
figure;
p=patch('Faces',head_model.head.faces,'Vertices',head_model.head.vertices);
for idx=1:4
    p=reducepatch(p, .25);  % Oh! This is a fancy way of taking only some
	                        % sensors! Keep reducing patch size, so you can
							% look at different scales. We can just forget this
							% whole thing.
    lst{idx}=find(ismember(sens.pnt,p.vertices,'rows'));
    label{idx}=[num2str(length(lst{idx})) '-electrodes'];
end
close

% There really shouldn't be any nans, right?
L(find(isnan(L)))=0;

% Lets compute the point spread function
% Let's not do this right off the bat, though.
PSF=zeros(size(L,2),length(lst));
BIAS=zeros(size(L,2),length(lst));

for idx2=1:length(lst)
   iL=pinv(L(lst{idx2},:));

    for idx=1:size(L,2)
        disp(idx);
        a=iL*L(lst{idx2},idx);
        if(max(a)>0)
            a=a./max(a);
            d=sqrt(sum((head_model.white.vertices-ones(size(L,2),1)*head_model.white.vertices(idx,:)).^2,2));
            PSF(idx,idx2)=max(d(find(a>exp(-1))));
            BIAS(idx,idx2)=mean(d(find(a==1)));
        else
            PSF(idx,idx2)=NaN;
            BIAS(idx,idx2)=NaN;
        end
    end
end


