function test(username, argnum)

fieldtrip_path = sprintf('/afs/ece.cmu.edu/usr/%s/Public/condor/fieldtrip-20150308/', username);
addpath(fieldtrip_path);
ft_defaults;
prep_partial_leadfield(argnum);
quit;
