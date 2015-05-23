%% load headmodel
load('fwd/concentric_headmodel.mat');

%% define voxel grids
grid_pnt = dlmread('fwd/points-6252.out');
grid_pnt = 75 * grid_pnt(:,3:5);

%% define sensor grids
sens_pnt = dlmread('fwd/points-492.out');
sens_pnt = 92 * sens_pnt(:,3:5);

sens=[];
sens.type='eeg';
sens.pnt=sens_pnt;  %For now, just use a subset of the surface as EEG positions;  TODO- pay more attention to avoid the face, neck etc.
sens.unit = 'mm';
sens.chanpos  = sens_pnt;
sens.elecpos  = sens_pnt;

for i=1:size(sens.pnt,1)
    sens.label{i} = sprintf('%03d', i);
    sens.chantype{i}='eeg';
end

sens.label=sens.label';
sens.chantype=sens.chantype';

%% get the forward matrices
cfg = [];
cfg.vol = headmodel;
cfg.elec = sens;
cfg.grid.pos = grid_pnt;
cfg.grid.inside = true(size(grid_pnt,1),1);
cfg.grid.unit = 'mm';
cfg.unit = 'mm';
lead_field = ft_prepare_leadfield(cfg);

%% Reduce forward matrices to radial direction
M = size(grid_pnt, 1); % number of sensors
N = size(sens_pnt, 1); % number of dipoles

forward_matrices = zeros(N, M);
lf = lead_field.leadfield(lead_field.inside);
for i = 1:M
    forward_matrix = lf{i};
    dipole_ori = grid_pnt(i,:)/norm(grid_pnt(i,:));
    forward_matrix = forward_matrix * dipole_ori';
    forward_matrices(:,i) = forward_matrix;
end


%% beamformer
% Setting up candiadate dipole locations
tic;
L = M; % number of possible dipoles
N = size(sens_pnt,1); % number of sensors
Hs = forward_matrices;
snr = 50;

Q = eye(N); % noise covariance matrix -- now we assume iid noise
Cx = zeros(N);
for i = 1:L
    Cq = snr^2; % just to amplify neural signal by 100x to make it comparable to the noise
    Cx = Cx + Hs(:,i) * Cq *Hs(:,i)';
end
Cx = Cx + Q;

Ws = zeros(N, L);
Cx_inv = Cx\eye(N);
reverseStr = '';
for i = 1:L
  noise = normrnd(0,std2(Hs)/snr, N,1);
   H = Hs(:,i)+noise;
   Ws(:,i) = (H' * Cx_inv * H) \ (H' * Cx_inv); 
   msg = sprintf('computing beamformer matrices %d/%d\n', i, L);
   fprintf([reverseStr, msg]);
   reverseStr = repmat(sprintf('\b'), 1, length(msg));
end

t=toc;
fprintf('time for computating beamformer matrices: %f\n',t);

%% Plot 
figure;
dipole_index = 1;
psf = Ws'*Hs(:,dipole_index);
scatter3(grid_pnt(:,1), grid_pnt(:,2), grid_pnt(:,3), 3, psf);
hold on ;
scatter3(grid_pnt(dipole_index,1), grid_pnt(dipole_index,2), grid_pnt(dipole_index,3), 20, 'r', 'filled');
caxis([min(psf), max(psf)]);
colorbar;
title(sprintf('(%.3f, %.3f, %.3f)', grid_pnt(dipole_index,1), grid_pnt(dipole_index,2), grid_pnt(dipole_index,3)));
xlabel('x'); ylabel('y'); zlabel('z');

%% Calculate PSF
PSF = zeros(L,1); BIAS = zeros(L,1);
for i = 1:L
    psf=psf./max(psf);
    d= sqrt(sum((grid_pnt - repmat(grid_pnt(dipole_index,:), L, 1)).^2,2));
    PSF(i) = max(d(psf>exp(-1)));
    BIAS(i) =mean(d(psf==1));
end
mean(PSF)
mean(BIAS)

