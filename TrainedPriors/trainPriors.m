%% trainPriors.m
% Authors: Jake Colwell and Zyaire Howard
% Created: January 16, 2025
% Last modified: March 14, 2025
% Train a Gaussian Process Regression (GPR) on Surface A to serve as a prior for BO

%% Setup 
% Start a timer
tic

% List the surfaces to be used
surfnames={'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};

% Add all folders subfolders to the path
addpath(genpath(fullfile(pwd)))

% Record the current date and time
priortime=string(datetime('now','Format','yyyyMMdd_HHmmss'));

% Create the bulk variable to avoid overwriting other important variables
bulk=1;

%% Inputs
% Run Inputs.m
Inputs

% Assign other settings specific to fitting priors
% Surface Fitting Settings
res_1=750; % Number of points to let BO select optimal hyperparameters for the GPR
res_a=20000; % Number of points to train the final GPR on

%% Calculations
% Use a parallel for loop to train priors for all surfaces simultaneously 
% (Parallel Computing requires the Parallel Computing Toolbox, otherwise 
% parfor will act like for)

parfor i=1:length(surfnames)
    % Select the surface
    Surf = cell2mat(surfnames(i));
    % Import the data for that surface
    [dataA, fA, nameA] = importCTdata(Surf,y_lim,x_lim,pad);
    
    % Train a GPR on a relatively small amount of data, using the 
    % 'OptimizeHyperparameters' argument to select optimal hyperparameters
    % for the GPR
    % Generate and scramble a semi-random Sobol sequence to sample Surface A
    p = sobolset(2,'Skip',1e3,'Leap',1e2); 
    p = scramble(p,'MatousekAffineOwen');
    % Scale values from to the size of the surface
    train_sobol = (p(1:res_1,:)-.5)*(x_lim(2)-x_lim(1)-2*pad); 
    % Select the data closest to each point in the Sobol sequence
    [trainindex, ~] = dsearchn(table2array(dataA(:,{'x','y'})),train_sobol); 
    trainA = dataA(trainindex,:);
    % Fit the model
    gprMdl1 = fitrgp(trainA,'z','OptimizeHyperparameters',...
        {'BasisFunction','KernelFunction','KernelScale','Sigma'});
    
    % Using the optimal hyperparameters from before, train a new GPR on a 
    % much larger amount of data to get a more accurate final result
    train_sobol = (p(res_1:(res_a+res_1),:)-.5)*(x_lim(2)-x_lim(1)-2*pad);
    [trainindex, ~] = dsearchn(table2array(dataA(:,{'x','y'})),train_sobol);
    trainA = dataA(trainindex,:);
    gprMdlA = fitrgp(trainA,'z', ...
                'Basis',gprMdl1.BasisFunction,...
                'Beta',gprMdl1.Beta,...
                'Sigma',gprMdl1.Sigma,...
                'SigmaLowerBound',gprMdl1.Sigma-0.001,...
                'KernelFunction',gprMdl1.KernelFunction,...
                'KernelParameters',gprMdl1.KernelInformation.KernelParameters,...
                'PredictMethod','exact');
    
    % Record how long it took to fit this prior
    priorFitTime=toc;

    % *_pri values will be checked by main.m to ensure they match the 
    % settings in Inputs.m
    x_lim_pri = x_lim;
    y_lim_pri = y_lim;
    pad_pri = pad;

    % Save the results to a .m file to be called later by main.m
    s=struct("gprMdlA",gprMdlA,"priorFitTime",priorFitTime,"priortime",priortime,...
        "x_lim_pri",x_lim_pri,"y_lim_pri",y_lim_pri,"pad_pri",pad_pri);
    save(strcat(fullfile(pwd,'/TrainedPriors'),'/',nameA,'.mat'),'-fromstruct',s)
end