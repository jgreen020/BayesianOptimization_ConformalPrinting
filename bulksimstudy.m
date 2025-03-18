%% bulksimstudy.m
% Author: Jake Colwell
% Created: March 1, 2025
% Last Modified: March 15, 2025
% Run main.m for all surfaces, methods, and aquisition functions

clear;clc;close all
addpath(genpath(fullfile(pwd)))
bulk=1;

surfnames= ...
   {'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};
AFs={@LD,@LCB_exp,@IVR2};

Curve=@Hybrid; % Curve Parameterizaion

Inputs

for i=9%1:size(surfnames,2)
    SurfB=surfnames{i};
    % method=1;
    % n=3;
    % m=15;
    [dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
    % main
    % 
    % method=2;
    n=13;
    m=225;
    % for j=1:size(AFs,2)
    %     A=AFs{j};
    %     main
    % end

    method=3;
    [~,name,ext]=fileparts(SurfB);
    SurfA=strcat(name(1:5),'a',ext);
    if SurfA(1:6)==SurfB(1:6)
        dataA=dataB;
        fA=fB;
        nameA=nameB;
    else
        [dataA, fA, nameA]=importCTdata(SurfA,y_lim,x_lim,pad);
    end
    for j=1:size(AFs,2)
        A=AFs{j};
        main
    end
end