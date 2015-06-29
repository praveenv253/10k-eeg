sensors = [92, 252, 492, 1212, 6252];
d = 17256;

figure;
for s = sensors
	disp(s);
	load(sprintf('psfs_%d_%d.mat', s, d));
	plot(x, y, 'LineWidth', 2);
	xlabel('Depth (mm)');
	ylabel('Point spread function width (mm)');
	title('PSF-width decreases at all depths with more sensors');
	set(gca, 'FontSize', 12);
	hold on;
end
