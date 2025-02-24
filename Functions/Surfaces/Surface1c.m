function z = Surface1c(x,y)
% Define grid
%[x, y] = meshgrid(0:1:60, 0:1:60);  % Grid spans 0 to 60 mm in both x and y directions

% Parameters
maxHeight = 18;  % Maximum height change
slope = -maxHeight / 22;  % Slope of the linear gradient

% Calculate z values for the adjusted gradually curving down surface
z_linear = slope * (x - 30);  % Linear gradient along x direction, centered at x=30
r_squared = (x - 30).^2 + (y - 30).^2;  % Distance squared from the center (30, 30)
smooth_decay = exp(-r_squared / (2 * (30^2)));  % Smooth decay function
z = z_linear .* smooth_decay;

% Ensure minimum height is zero
%z = z - min(z(:));
end