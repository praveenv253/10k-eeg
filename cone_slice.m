function [indices_in_cone, dipoles_in_cone] = cone_slice(dipole_grid, cone_central_vector, cone_half_angle)
%% Select dipoles within a cone

num_dipoles = size(dipole_grid, 1);

% Cone parameters
if (nargin < 2) || (all(size(cone_central_vector) ~= [1, 3]))
	cone_central_vector = [1, 0, 0];
end
cone_central_vector = cone_central_vector / norm(cone_central_vector);
if nargin < 3
	cone_half_angle = 20;   % In degrees
end
cone_half_angle = cone_half_angle * pi / 180;   % Convert degrees to radians

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
%disp(length(indices_in_cone))

% Scatter plot the dipole the grid to see if the indexing worked correctly
%scatter3(dipoles_in_cone(:, 1), dipoles_in_cone(:, 2), dipoles_in_cone(:, 3), 30, sqrt(sum(dipoles_in_cone.^2, 2)), 'filled');
%axis equal;
%break;
