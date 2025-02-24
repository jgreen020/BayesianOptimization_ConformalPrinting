function z = Surface3c(x,y)
% Define grid
%[x, y] = meshgrid(-X:1:X, -Y:1:Y);

% Parameters
maxHeight = 15;  % Maximum height

% Calculate z values
A = .25 * maxHeight;  % Adjusted amplitude to ensure max height is 6.5 mm
lambda = 30;  % Wavelength
z = A * sin(0.75 * pi * x / lambda) .* sin(2.1 * pi * y / lambda) + 4;

% Shift the surface so that minimum is at zero
%z = z - min(z(:));
end