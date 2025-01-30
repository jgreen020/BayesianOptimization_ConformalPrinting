%% Setting up inputs to the main code so they can be called in other scipts as well
%% Jake Colwell
%% January 24, 2025

%% Inputs
% Plotting settings
res_s = 1000; % Resolution of Plotted Surfaces (number of points in one direction)
res_c = res_s^2; % Resolution of plotted curves
x_lim = [-30 30]; % Range of x
y_lim = [-30 30]; % Range of y
pad=4; % mm to cut off from scan on each side

% Surfaces and Curves
SurfA='Surf1a.csv'; % Name of the file containing the CT scan data
SurfB='Surf1a.csv'; % Name of the file containing the CT scan data
Curve=@ArchSpiral; % Curve Parameterizaion, Inputs: t (scalar or vector in [0,1]), Outputs: u,v (scalars or vectors representing a point in U)

% Surface Fitting Settings
method=3; % Which surface fitting method to use. 
          % 1) Bezier Fitting
          % 2) Naive Bayesian Optimization
          % 3) Bayesian Optimization with prior trained on SurfA
doaprint=false; % Is TCS being performed (true) or is this a simulation only (false)
if method==1
    n=2; % Grid size of sampling points for Bezier Fitting (n x n grid)
    m=14; % If doing a simulation, program will test bezier fitting for n:1:m sequencially
elseif method==2 || method==3
    n=13; % Number of points to sample before starting Bayesian Optimization 
    % ^(DO NOT CHANGE)
    m=100; % Final number of points for Bayseian Optimization
else
    disp('Invalid Method Number')
    return
end

% Misc Variables
cmax=0.165; % Maximum Deviation (mm)

%% Importing Specified Surfaces
% Data import for Surfaces
dataA = readtable(SurfA);
dataA.Properties.VariableNames={'x','y','z'};
dataB = readtable(SurfB);
dataB.Properties.VariableNames={'x','y','z'};

% Grabbing only data in the range specified by pad
dataA=dataA((abs(dataA.x)<=(max(x_lim)-pad+.2))&(abs(dataA.y)<=(max(y_lim)-pad+.2))&(dataA.z>=0),:);
dataB=dataB((abs(dataB.x)<=(max(x_lim)-pad+.2))&(abs(dataB.y)<=(max(y_lim)-pad+.2))&(dataB.z>=0),:);

% Set up a scattered interpolant to interpolate data
fA=scatteredInterpolant(dataA.x,dataA.y,dataA.z,'natural','none');
fB=scatteredInterpolant(dataB.x,dataB.y,dataB.z,'natural','none');

%Separating Filenames
[~, nameA,~]=fileparts(SurfA);
[~, nameB,~]=fileparts(SurfB);