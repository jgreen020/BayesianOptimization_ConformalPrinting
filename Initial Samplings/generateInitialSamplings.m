%% generateInitialSamplings.m
% Authors: Jake Colwell and Zyaire Howard
% Created: Between January 16th and February 24, 2025
% Last Modified: April 15, 2024
% Generate an initial sampling of data to be used by main.m

% Record the current date and time
sampletime=string(datetime('now','Format','yyyyMMdd_HHmmss'));
% Start a timer
tic

% Run Inputs.m
Inputs

% Break out the x and y mins and maxes for readability
x_min = min(x_lim); x_max = max(x_lim); x_rng=x_max-x_min;
y_min = min(y_lim); y_max = max(y_lim); y_rng=y_max-y_min;

% Find (x,y) locations of points to sample
% There are two types depending on the method:
%   Type 1: Uniform sampling of n^2 points for Method 1
%   Type 2: Sobol Sample n points for Methods 2, 3, and 4 

if method==1
    % Type 1, Uniform Sampling
    type=1;

    % find n evenly spaced values in the limits of x and y
    xt=linspace(x_min+pad, x_max-pad, n); 
    yt=linspace(y_min+pad, y_max-pad, n);
    % Generate all possible combinations of these x and y values
    [xt, yt]=meshgrid(xt,yt); 
    xt=xt(:);yt=yt(:); % Form them into vectors instead of matricies

    % Initialize arrays to record sampling times and values in the next step
    t=zeros(n^2,1); % Time vector
    testpoints=zeros(n^2,3); % Data array of tested points

elseif method==2 || method==3
    % Type 2, Sobol Sampling for Point Cloud
    type=2;
    
    % Generate and scramble a semi-random Sobol sequence to sample Surface A
    p = sobolset(2,'Skip',1e3,'Leap',1e2); 
    p = scramble(p,'MatousekAffineOwen');
    % Scale values from [0,1] to the size of the surface
    train_sobol = p(1:n,:); 
    xt = train_sobol(:,1)*(x_lim(2)-x_lim(1)-2*pad)-(x_lim(2)-x_lim(1)-2*pad)/2; 
    yt = train_sobol(:,2)*(y_lim(2)-y_lim(1)-2*pad)-(y_lim(2)-y_lim(1)-2*pad)/2; 

    % Initialize variables
    t=zeros(m,1);
    testpoints=zeros(m,3);
elseif method==4
    % Type 2, Sobol Sampling for Images
    type=3;
    %hey dummy make sure no points get double sampled
    % Generate and scramble a semi-random Sobol sequence
    p = sobolset(2,'Skip',1e3,'Leap',1e2); 
    p = scramble(p,'MatousekAffineOwen');
    % Scale values from [0,1] to the size of the surface
    train_sobol = p(1:n,:); 
    xt = train_sobol(:,1)*(x_lim(2)-x_lim(1)-2*pad)-(x_lim(2)-x_lim(1)-2*pad)/2; 
    yt = train_sobol(:,2)*(y_lim(2)-y_lim(1)-2*pad)-(y_lim(2)-y_lim(1)-2*pad)/2; 

    % Initialize variables
    t=zeros(n,1);
    testpoints=zeros(n,3);
end

% Sample the points selected above
% If using TCS, sampling will be performed on the mRD, but if doing a simulation,
% the sample will come from the CT scan data
if doaprint
    for i=1:size(xt)
        % Perform TCS on the mRD for each point
        ztB(i)=mrdtcs(xt(i), yt(i));

        % After each sample, record the current time
        t(i)=toc; 
    end
    % Set a flag that TCS was used, this will get written into the filename
    word='TCS';
else
    % Find all the points in the CT data closest to the selected points
    if ~exist('bulk','var')
    [dataB, ~, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
    end
    [initindex, dist]=dsearchn(table2array(dataB(:,{'x','y'})),[xt yt]);
    xt=table2array(dataB(initindex,'x'));
    yt=table2array(dataB(initindex,'y'));
    ztB=table2array(dataB(initindex,'z'));

    % Record the time it took to find the initial points
    % Since all points were found simultaneously, write all values to the same number
    if method==1
        t(1:n^2+1)=toc;
    elseif method==2 || method==3
        t(1:n)=toc;
    end

    % Set the flag for the filename
    word='CT';
end

% *_in variables will be checked by main.m when loading the inital sampling
% to ensure that the inputs used to generate it are the same as the desired inputs
x_lim_in = x_lim;
y_lim_in = y_lim;
pad_in = pad;

% Combine the data into a single array
testpoints(1:size(xt,1),:)=[xt yt ztB];

% Save the points and sampling time to be called by main.m
save(strcat(fullfile(pwd,'/Initial Samplings'),'/',word,'_t',num2str(type),...
    '_',nameB,'_n',num2str(n),'.mat'),"testpoints","t","sampletime",...
    "x_lim_in","y_lim_in","pad_in","initindex") 