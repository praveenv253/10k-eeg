function test(num_sensors, num_dipoles, argnum)

% Assumes fieldtrip is within path
ft_defaults;

min_dipole_num = 100 * arg + 1;
max_dipole_num = min(100 * arg + 100, size(dipole_grid, 1));

prep_partial_leadfield(num_sensors, num_dipoles, min_dipole_num, max_dipole_num);
quit;
