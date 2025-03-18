%% generateInitialSamplings.m
% Authors: Jake Colwell and Zyaire Howard
% Created: Between January 16th and February 24, 2025
% Last Modified: March 14, 2024
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
%   Type 2: Nested 3x3 and 2x2 uniform samplings (13 points) for Methods 2 and 3 
if method==1

    % Type 1, Bezier Surface Fitting
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
    % Type 2, BO
    type=2;

    % Generate a 3x3 grid of points in the limits of x and y
    xt1=linspace(x_min+pad, x_max-pad, 3);
    yt1=linspace(y_min+pad, y_max-pad, 3);
    [xt1, yt1]=meshgrid(xt1,yt1);

    % Generate a 2x2 grid of points where each point is the center of a square
    % formed by the 3x3 grid
    xt2=linspace(x_min+pad+(x_rng-2*pad)/4, x_max-pad-(x_rng-2*pad)/4, 2);
    yt2=linspace(y_min+pad+(y_rng-2*pad)/4, y_max-pad-(y_rng-2*pad)/4, 2);
    [xt2, yt2]=meshgrid(xt2,yt2);

    % Combine the two grids
    xt=[xt1(:);xt2(:)];
    yt=[yt1(:);yt2(:)];

    % Initialize variables
    t=zeros(m,1);
    testpoints=zeros(m,3);
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