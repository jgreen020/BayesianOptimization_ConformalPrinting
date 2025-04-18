%% bulksimsamples.m
% Author: Jake Colwell
% Created: ???
% Last modified: April 15, 2024
% Generate initial samplings for all simulated datasets

% All surfaces to be tested
surfnames={'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};
% Create bulk variable
bulk=1;

Inputs

% Loop through all surfaces
for i=1:length(surfnames)
    % Import the surface data
    SurfB=surfnames{i};
    [dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
    
    % Calculate all initial samplings for Method 1
    method=1;
    for n=3:15
        generateInitialSamplings
        fprintf('complete:\tt1\ti=%i \tn=%i\n',i,n)
    end

    % Calculate initial sampling for Methods 2 and 3
    method=2;
    ns=[10,10,10,20,20,20,40,40,40];
    n=ns(i);
    m=225;
    generateInitialSamplings
    fprintf('complete:\tt2\ti=%i \tn=%i\n',i,n)

    % Calculate initial sampling for Method 4
    method=4;
    for n=(3:15).^2
        generateInitialSamplings
        fprintf('complete:\tt3\ti=%i \tn=%i\n',i,n)
    end
end