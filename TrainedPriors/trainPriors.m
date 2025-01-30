%% Training a Gaussian Process Regression on Surface A to serve as a prior for surface fitting
%% Jake Colwell and Zyaire Howard
%% January 16, 2025

%% Setup 
% Delete all figures (including the pesky image viewer), clear workspace and command window
all_figs = findobj(0, 'type', 'figure');delete(all_figs);clear;clc;
% Add all current folders to the path
addpath(genpath(fullfile(pwd)))
priortime=string(datetime('now','Format','yyyyMMdd_HHmmss'));

%% Inputs
Inputs
% Surface Fitting Settings
res_a=2000; % Number of points to train from Surface A, if using method 3

%% Calculations
p = sobolset(2,'Skip',1e3,'Leap',1e2); % Generate a semi-random Sobol sequence to sample Surface A
p = scramble(p,'MatousekAffineOwen'); % Scrable the Sobol sequence

trainindex= (p(1:res_a,:)-.5)*(x_lim(2)-x_lim(1)-2*pad); % Scale values from 0-1 to the size of the surface
[trainindex, dist]=dsearchn(table2array(dataA(:,{'x','y'})),trainindex);
trainA=dataA(trainindex,:); %Assemble a table of the data to train the model
tic
gprMdlA = fitrgp(trainA,'z','OptimizeHyperparameters','all'); % Fit a GPR to the data, allowing it to perform Bayseian Optimization to select optimal hyperparameters
priorFitTime=toc;
%% Outputs
x_lim_pri = x_lim;
y_lim_pri = y_lim;
pad_pri = pad;

save(strcat(fullfile(pwd,'/TrainedPriors'),'/',nameA,'.mat'),"gprMdlA","priorFitTime","priortime","x_lim_pri","y_lim_pri","pad_pri") % Save the model to be called later


