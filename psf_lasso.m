%% Load the forward matrices and compute normal components

clear;
load 'lead_field_92_17141.mat';

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

L = zeros(num_sensors, num_dipoles);
lf = lead_field.leadfield(lead_field.inside);

for i = 1:num_dipoles
    forward_matrix = lf{i};
	% Compute H(q)m(q): m(q) here are unit radial sources
    forward_matrix = forward_matrix * normals(i, :)';
    L(:, i) = forward_matrix;
end

% There really shouldn't be any nans, right?
L(isnan(L)) = 0;

% ----- Normal forward matrix computation complete ----- %

%% Select dipoles within a cone

% Cone parameters
cone_central_vector = [1, 0, 0];
cone_central_vector = cone_central_vector / norm(cone_central_vector);
cone_half_angle = 20 * pi / 180;

% Find indices of dipoles within this cone
% - First find the angle that each dipole position vector makes with the cone's
%   central vector: cos(<(a, b)) = a.b / |a||b|
% - Then choose those angles which are less than the half angle of the cone
angle_with_central_vector = sum(dipole_grid .* (ones(num_dipoles, 1) * cone_central_vector), 2); % Compute dot product
angle_with_central_vector = angle_with_central_vector ./ sqrt(sum(dipole_grid.^2, 2));           % Divide by norms (cone_central_vector has unit norm)
in_cone = (angle_with_central_vector > cos(cone_half_angle));                                    % Between 0 and 180, cos is a decreasing fn.
                                                                                                 % If the angle is less, the cosine of the angle is more.
dipoles_in_cone = dipole_grid(in_cone, :);
indices_in_cone = find(in_cone);
disp(length(indices_in_cone))

% Scatter plot the dipole the grid to see if the indexing worked correctly
%scatter3(dipoles_in_cone(:, 1), dipoles_in_cone(:, 2), dipoles_in_cone(:, 3), 30, sqrt(sum(dipoles_in_cone.^2, 2)), 'filled');
%axis equal;
%break;

% ----- Dipole selection complete ----- %

%% Compute MNE inverse solution

% Lets compute the point spread function
PSF = zeros(num_dipoles, 1);  % Size is equal to the number of dipoles
BIAS = zeros(num_dipoles, 1);

% Noise standard deviation
sigma_n = 0.2 * abs(max(L(:, 1)));

fInfos = [];
%K = 2; % number of active dipoles
for i = 1:length(indices_in_cone)
    % Create noise to be added to the measurements
	noise = sigma_n .* randn(size(L(:, indices_in_cone(i))));
	%noise = zeros(size(L(:, i)));

    %active_idx = randperm(num_dipoles, K);
    %measurements = sum(L(:, active_idx), 2) + noise; % dipole sources at active indices are all set to 1

    % Create measurements for unit dipoles, which is the same as the lead-field vector at that point
    measurements = L(:, indices_in_cone(i)) + noise;

    [B,FitInfo] = lasso(L, measurements);
    FitInfo.B = B;
    %FitInfo.I = active_idx;
    fInfos = [fInfos; FitInfo];
    disp(i);

    %figure;
    %[x,y,z] = sphere; x = x*92; y= y*92; z = z*92;
    %surface(x,y,z,'FaceColor', 'none','EdgeColor','k');
    %hold on;
    %est_active_idx = find(FitInfo.B(:,FitInfo.Index1SE));
    %scatter3(dipole_grid(est_active_idx,1),dipole_grid(est_active_idx,2),dipole_grid(est_active_idx,3), 'b'); % plot estimated dipole sources
    %%scatter3(sens.pnt(:,1), sens.pnt(:,2), sens.pnt(:,3));
    %scatter3(dipole_grid(active_idx,1),dipole_grid(active_idx,2),dipole_grid(active_idx,3), 20, 'r', 'filled'); % plot actual sources
end

% ----- MNE inverse solution complete ----- %

%% Save results
save('fInfos.mat', 'fInfos', 'dipole_grid', 'indices_in_cone', '-v7.3');

% ----- Done with simulation ----- %

break;

% %% Plot PSF values ------------------------------------------------------------
%
% figure;
%
% % Plot a scatter plot of dipole voxel points, with colour indicating
% % log-PSF values
% s0 = scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), 25, log10(PSF), 'filled');
%
% % Set title and axis labels
% title(strcat('Point spread function (on log-scale) for ', num2str(num_sensors), ' sensors'));
% xlabel('x');
% ylabel('y');
% zlabel('z');
%
% % Create colorbar
% colormap(jet);
% cb = colorbar;
%
% % Set colorbar ticks manually, for log-scale values
% % Old non-working API
% % ticks = get(cb, 'YTick');
% % new_ticks = 10 .^ ticks;
% % set(cb, 'YTick', new_ticks);
% % set(cb, 'TickLabelsMode', 'manual');
% % ticks = get(cb, 'ticks');
% % tick_labels = {};
% % for i = 1:length(ticks)
% %     tick_labels{i} = [num2str(10.^ticks(i)) 'mm'];
% % end
% % set(cb, 'TickLabels', tick_labels);
%
% hold on;
%
% % Plot sensor positions
% s = scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 'filled', 'k');
% set(s, 'sizeData', 5);
%
% %% Plot BIAS values -----------------------------------------------------------
%
% figure;
%
% % Plot a scatter plot of dipole voxel points, with colour indicating
% % log-bias values
% s0 = scatter3(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), 25, log10(BIAS), 'filled');
%
% % Set title and axis labels
% title(strcat('Bias (on log-scale) for ', num2str(num_sensors), ' sensors'));
% xlabel('x');
% ylabel('y');
% zlabel('z');
%
% % Create colorbar
% colormap(jet);
% cb = colorbar;
%
% % Set colorbar ticks manually, for log-scale values
% % Old non-working API
% % ticks = get(cb, 'YTick');
% % new_ticks = 10 .^ ticks;
% % set(cb, 'YTick', new_ticks);
% % New MATLAB graphics API:
% % set(cb, 'TickLabelsMode', 'manual');
% % ticks = get(cb, 'ticks');
% % tick_labels = {};
% % for i = 1:length(ticks)
% %     tick_labels{i} = [num2str(10.^ticks(i)) 'mm'];
% % end
% % set(cb, 'TickLabels', tick_labels);
%
% hold on;
%
% % Plot sensor positions
% s = scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 'filled', 'k');
% set(s, 'sizeData', 5);
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
% %% Compute reconstruction for one dipole --------------------------------------
%
% %dipole_loc = 1000;
%
% %% Find inverse solution
% %a = iL * L(:, dipole_loc);
% %% a = a;
%
% %% Plot reconstruction --------------------------------------------------------
%
% %figure;
% %% [f, v, ~] = surf2patch(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), 'triangles');
% %tr = delaunay(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3));
% %%h = plot_mesh(v, f)
% %%hold on;
%
% %% tr = triangulation(f, v);
% %h = trisurf(tr, dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), a, 'linestyle', 'none');
% %set(h,'FaceVertexCData', a);
% %set(h, 'FaceAlpha', .2)
%
% %hold on;
%
% %caxis([-max(abs(a)), max(abs(a))]);
% %colormap(jet);
% %cb = colorbar;
%
% %s = scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 'filled', 'k');
% %s2 = scatter3(dipole_grid(dipole_loc, 1), dipole_grid(dipole_loc, 2), dipole_grid(dipole_loc ,3), 'filled', 'b');
%
% %set(s, 'sizeData', 5);
% %set(s2, 'sizeData', 30);
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
% %% Read data again, since this is also the normal to the surface
% %% No need to use Ted's patch-based method here, because we have a simplistic
% %% head model
% %normals = dlmread('points-252.out')
% %normals = normals(:, 3:5);
%
% %L = zeros(size(sens.pnt, 1), size(dipole_grid, 1));
% %for i = 1:size(dipole_grid, 1)
% %    forward_matrix = lead_field.leadfield{i};
% %    forward_matrix = forward_matrix * normals(i, :)';
% %    forward_matrices(:, i) = forward_matrix;
% %end
%
% %%% TODO: Figure out what on earth lst is!! - Done!
% %%figure;
% %%p=patch('Faces',head_model.head.faces,'Vertices',head_model.head.vertices);
% %%for idx=1:4
% %%    p=reducepatch(p, .25);  % Oh! This is a fancy way of taking only some
% %%                            % sensors! Keep reducing patch size, so you can
% %%                            % look at different scales. We can just forget this
% %%                            % whole thing.
% %%    lst{idx}=find(ismember(sens.pnt,p.vertices,'rows'));
% %%    label{idx}=[num2str(length(lst{idx})) '-electrodes'];
% %%end
% %%close
%
% %% There really shouldn't be any nans, right?
% %L(find(isnan(L))) = 0;
%
% %% Lets compute the point spread function
% %% Let's not do this right off the bat, though.
% %PSF = zeros(size(L,2));
% %BIAS = zeros(size(L,2));
%
% %iL = pinv(L);
% %for i = 1:size(L, 2)
% %    disp(i);
% %    a = iL * L(:, idx);
% %    if(max(a) > 0)
% %        a = a./max(a);
% %        d = sqrt(sum((head_model.white.vertices-ones(size(L,2),1)*head_model.white.vertices(idx,:)).^2,2));
% %        PSF(idx,idx2)=max(d(find(a>exp(-1))));
% %        BIAS(idx,idx2)=mean(d(find(a==1)));
% %    else
% %        PSF(idx,idx2)=NaN;
% %        BIAS(idx,idx2)=NaN;
% %    end
% %end
%
% %% Find inverse solution
% %a = iL * L(:, idx);
%
% %figure;
%
% %[f, v, ~] = surf2patch(dipole_grid(:, 1), dipole_grid(:, 2), dipole_grid(:, 3), 'triangles');
% %%h = plot_mesh(v, f)
% %%hold on;
%
% %tr = triangulation(f, v);
% %h = trimesh(tr);
% %set(h,'FaceVertexCData', a);
%
% %%caxis([-log10(max(a)), log10(max(a))]);
% %%colormap(jet);
% %%cb = colorbar;
%
% %s = scatter3(sens.pnt(:,1), sens.pnt(:, 2), sens.pnt(: ,3), 'filled', 'k')
% %set(s, 'sizeData', 5)
%
