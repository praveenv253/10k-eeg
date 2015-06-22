function test(username, num_sensors, num_dipoles, argnum)

fieldtrip_path = sprintf('/afs/ece.cmu.edu/usr/%s/Public/condor/fieldtrip-20150308/', username);
addpath(fieldtrip_path);
ft_defaults;

min_dipole_num = 100 * arg + 1;
max_dipole_num = min(100 * arg + 100, size(dipole_grid, 1));

prep_partial_leadfield();
quit;
