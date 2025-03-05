%% Setting up inputs to the main code so they can be called in other scipts as well
%% Jake Colwell
%% January 24, 2025

%% Inputs
% Plotting settings
res_s = 500; % Resolution of Plotted Surfaces (number of points in one direction)
res_c = res_s^2; % Resolution of plotted curves
x_lim = [-30 30]; % Range of x
y_lim = [-30 30]; % Range of y
pad=0.7; % mm to cut off from scan on each side

if ~exist('bulk','var')

% Surfaces and Curves
SurfA='Surf1a.csv'; % Name of the file containing the CT scan data
SurfB='Surf1a.csv'; % Name of the file containing the CT scan data
Curve=@ArchSpiral; % Curve Parameterizaion, Inputs: t (scalar or vector in [0,1]), Outputs: u,v (scalars or vectors representing a point in U)

% Surface Fitting Settings
method=1; % Which surface fitting method to use. 
          % 1) Bézier Surface Fitting
          % 2) Naive Bayesian Optimization
          % 3) Bayesian Optimization with prior trained on SurfA
doaprint=false; % Is TCS being performed (true) or is this a simulation only (false)
savedata=false; % Save data from the run
if method==1
    n=3; % Grid size of sampling points for Bezier Fitting (n x n grid, n > 3)
    m=8; % If doing a simulation, program will test bezier fitting for n:1:m in parallel
elseif method==2 || method==3
    n=13; % Number of points to sample before starting Bayesian Optimization 
    % ^(DO NOT CHANGE)
    m=50; % Final number of points for Bayseian Optimization
    A=@IVR2; % Aquisition Function to use
else
    disp('Invalid Method Number')
    return
end

end

% Misc Variables
cmax=0.165; % Maximum Deviation (mm)