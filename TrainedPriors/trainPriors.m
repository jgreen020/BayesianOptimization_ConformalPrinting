%% Training a Gaussian Process Regression on Surface A to serve as a prior for surface fitting
%% Jake Colwell and Zyaire Howard
%% January 16, 2025

%% Setup 
tic
surfnames={'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c.csv'};
addpath(genpath(fullfile(pwd)))
priortime=string(datetime('now','Format','yyyyMMdd_HHmmss'));
bulk=1;

%% Inputs
Inputs
% Surface Fitting Settings
res_1=500;
res_a=20000; % Number of points to train from Surface A, if using method 3
parfor i=1:length(surfnames)
    Surf=cell2mat(surfnames(i));
    [dataA, fA, nameA]=importCTdata(Surf,y_lim,x_lim,pad);

    p = sobolset(2,'Skip',1e3,'Leap',1e2); % Generate a semi-random Sobol sequence to sample Surface A
    p = scramble(p,'MatousekAffineOwen'); % Scrable the Sobol sequence
    trainindex= (p(1:res_1,:)-.5)*(x_lim(2)-x_lim(1)-2*pad); % Scale values from 0-1 to the size of the surface
    [trainindex, ~]=dsearchn(table2array(dataA(:,{'x','y'})),trainindex);
    trainA=dataA(trainindex,:); %Assemble a table of the data to train the model
    gprMdl1 = fitrgp(trainA,'z','OptimizeHyperparameters',{'BasisFunction','KernelFunction','KernelScale','Sigma'}); % Fit a GPR to the data, allowing it to perform Bayseian Optimization to select optimal hyperparameters
    
    p = sobolset(2,'Skip',1e3,'Leap',1e2); % Generate a semi-random Sobol sequence to sample Surface A
    p = scramble(p,'MatousekAffineOwen'); % Scrable the Sobol sequence
    trainindex= (p(1:res_a,:)-.5)*(x_lim(2)-x_lim(1)-2*pad); % Scale values from 0-1 to the size of the surface
    [trainindex, ~]=dsearchn(table2array(dataA(:,{'x','y'})),trainindex);
    trainA=dataA(trainindex,:); %Assemble a table of the data to train the model
    gprMdlA = fitrgp(trainA,'z', ...
                'Basis',gprMdl1.BasisFunction,...
                'Beta',gprMdl1.Beta,...
                'Sigma',gprMdl1.Sigma,...
                'KernelFunction',gprMdl1.KernelFunction,...
                'KernelParameters',gprMdl1.KernelInformation.KernelParameters);
    priorFitTime=toc;

    % Outputs
    x_lim_pri = x_lim;
    y_lim_pri = y_lim;
    pad_pri = pad;
    s=struct("gprMdlA",gprMdlA,"priorFitTime",priorFitTime,"priortime",priortime,...
        "x_lim_pri",x_lim_pri,"y_lim_pri",y_lim_pri,"pad_pri",pad_pri);
    save(strcat(fullfile(pwd,'/TrainedPriors'),'/',nameA,'.mat'),'-fromstruct',s) % Save the model to be called later
end