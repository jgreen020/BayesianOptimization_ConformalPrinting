function z = Surface3b(x,y)
% Define grid
%[x, y] = meshgrid(-X:1:X, -Y:1:Y);

% Parameters
maxHeight = 10.5;  % Maximum height

% Calculate z values
A = .25 * maxHeight;  % Adjusted amplitude to ensure max height is 6.5 mm
lambda = 25;  % Wavelength
z = A * sin(1.5 * pi * x / lambda) .* sin(0.9 * pi * y / lambda) + 3.25;

% Shift the surface so that minimum is at zero
%z = z - min(z(:));
end







