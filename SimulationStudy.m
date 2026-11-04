%% SimulationStudy.m
% Author: Jake Colwell
% Created: March 1, 2025
% Last Modified: November 4th 2026
% Run main.m for all surfaces, methods, and aquisition functions, 5 times

clear;clc;close all
addpath(genpath(fullfile(pwd)))
bulk=1;

% Surfaces
surfnames= ...
   {'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};

% Acquisition Functions
AFs={@LD,...
    @LCB_exp,...
    @IVR2...
    };

% Initial Sampling Sizes
t2ns=[10,10,10,20,20,20,40,40,40];

% Trained priors for M3
priorFolders = {'20250314','20261102_1','20261102_2','20261102_3','20261102_4'};

% Initial Samplings
samplingFolders = {'20250428','20261102_1','20261102_2','20261102_4','20261102_4'};

% Simulated measurement noise and bias
noise_magnitude = 0;
bias_magnitude = 0;

% Curve Parameterizaion
Curve=@Hybrid; 

% Take the remaining settings from Inputs.m
Inputs

% Iterate over the surfaces to avoid reloading the CT data every iteration
for safeloopvar=1:size(surfnames,2)
    SurfB=surfnames{safeloopvar};

    % Run the simulation once for each set of priors and initial samplings
    for safeloopvar3 = 1:size(priorFolders,1)
        priorFolder = priorFolders{safeloopvar3};
        samplingFolder = samplingFolders{safeloopvar3};

        % Run M1
        method=1;
        n=3;
        m=15;
        [dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad,res_s);
        main
        
        % Run M2 for each acquisition function
        method=2;
        n=t2ns(safeloopvar);
        m=225;
        for safeloopvar2=1:size(AFs,2)
            A=AFs{safeloopvar2};
            main
        end
        
        % Run M3 for each acquisition function
        method=3;
            % Find and load Surface A
        [~,name,ext]=fileparts(SurfB);
        SurfA=strcat(name(1:5),'a',ext);
        if SurfA(1:6)==SurfB(1:6)
            dataA=dataB;
            fA=fB;
            nameA=nameB;
        else
            [dataA, fA, nameA]=importCTdata(SurfA,y_lim,x_lim,pad,res_s);
        end
            % Run
        for safeloopvar2=1:size(AFs,2)
            A=AFs{safeloopvar2};
            main
        end
    end

end