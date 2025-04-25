%% Inputs.m
% Author: Jake Colwell 
% Created: January 24, 2025 
% Last Modified: March 14, 2025 
% Contains many settings that can be used to modify the behavior of main.m 

% Notes on several inputs:
%   Surface data (SurfA and SurfB) must be in .csv format where each row is an (x,y,z) order pair representing a datapoint
%   Curve Parameterization Functions (Curve) must be a function: [x,y]=Curve(t)
%       where t, x, y are in [0,1]. t, x, y can be scalar or vectors
%   Aquisition Functions (A) must be a function: newpt=A(prediction,tested,gpr)
%       prediction is table of points from predict(gpr)
%       tested is a iterx3 array of coordinates
%       gpr is a trained Gaussian Process Regression object from fitrgp

%% Inputs
% Global Settings
res_s = 300; % Resolution of Plotted Surfaces (number of points in one direction)
res_c = res_s^2; % Resolution of plotted curves
x_lim = [-30 30]; % Range of x
y_lim = [-30 30]; % Range of y
pad=0.7; % mm to cut off from scan on each side
doaprint=false; % Is TCS being performed (true) or is this a simulation only (false)
savedata=false; % Save data from the run
stoppingcriteria=true; % Stop BO loop when stopping critria has been met 
cmax=0.165; % Maximum Deviation (mm), sets the maximum for colormaps
criticalNumber2=0.115; % Critiral number of stopping critiria

% Local Settings (can be set by an external script if the variable 'bulk' exists)
if ~exist('bulk','var')

    % Surfaces and Curves
    SurfA='Surf1a.csv'; % Name of the file containing the CT scan data for Surface A
    SurfB='Surf1b.csv'; % Name of the file containing the CT scan data for Surface B
    Curve=@Hybrid; % Curve Parameterizaion
    
    % Surface Fitting Settings
    method=2; % Which surface fitting method to use. 
              % 1) Bézier Surface Fitting
              % 2) Naive Bayesian Optimization
              % 3) Bayesian Optimization with prior trained on SurfA
    if method==1
        n=3; % Grid size of sampling points for Bezier Fitting (n x n grid, n > 3)
        m=15; % If doing a simulation, program will test bezier fitting for n:1:m in parallel
    elseif method==2 || method==3
        n=10; % Number of points to sample before starting Bayesian Optimization
        m=225; % Final number of points for Bayesian Optimization
        A=@LCB_exp; % Aquisition Function to use
    else
        disp('ERROR: Invalid Method Number')
        return
    end
end

% Break out the x and y mins and maxes for readability
x_min = min(x_lim); x_max = max(x_lim); x_rng=x_max-x_min;
y_min = min(y_lim); y_max = max(y_lim); y_rng=y_max-y_min;
z_min = -10; z_max=20; z_rng=z_min-z_max;