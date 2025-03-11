%% Code to import stls of samples from MicroCT
% Jake Colwell, June 2024
%
% Zyaire Howard, February 2025
%
% Inputs: An STL file
% Outputs: A .csv of points on the surface
%
% Instructions
% 1. Change the target variable to be a string with the exact name of the stl you wish to process
% 2. Run the code
% 3. A figure will open plotting the stl file. Select at least 3 points on the bottom surface of the sample.
% 4. Run Section III. using the 'Run Section' Button
% 5. A plane fit to the selected points will be plotted and you will be prompted to enter 1 or -1.
%       - Enter 1 if the plotted arrow is pointing from the plane to the surface
%       - Enter -1 if the plotted arrow is pointing from the plane away from the surface
% 6. A new plot will open that will show the STL rotated to lay flat but not square
% 7. Select at least 3 points on the front side face i.e. the face that would face you if you were performing a print on the MRD
% 8. Run Section IV. using the 'Run Section' Button
% 9. A plane fit to the selected points will be plotted and you will be prompted to enter 1 or -1.
%       - Enter 1 if the plotted arrow is pointing from the plane away from the sample
%       - Enter -1 if the plotted arrow is pointing from the plane into the sample
% 10. Ensure that the point cloud is appropriately square, if not, try again
% 11. Run Section V. using the 'Run Section' Button

clear;clc;close all;

%% I. Inputs
target='Surf3c_noise';

%% II. Loading and Plotting the STL

% Load the STL
stl=stlread(strcat(target,'.stl'));

% Extract the list of points from the STL
stlpts=stl.Points;

% Plot the STL
f1=figure('WindowStyle','docked');
trimesh(stl,'FaceColor',[1 .75 .75],'FaceAlpha',0.5,'LineStyle','none')
axis equal

% Prepare for the selection of datapoints
d=datacursormode(f1);

% End the Program
return

%% III. Laying the STL Flat

% Read all the currently displayed datatips
vals = getCursorInfo(d);

% Extract the point coordinates from the structure
pts = zeros(size(vals,2),3);
for i=1:size(vals,2)
    pts(i,:)=vals(1,i).Position;
end

% Create a point cloud object with the selected points
cld=pointCloud(pts);

% Fit a plane to the selected points
pln1=pcfitplane(cld,0.0001);

% Clear all the old datatips
dt = findobj(gca(),'Type','DataTip');
delete(dt);

% Plot the fitted plane and its normal
hold on
plot(pln1)
quiver3(0,0,0,pln1.Normal(1)*1500,pln1.Normal(2)*1500,pln1.Normal(3)*1500, 'MaxHeadSize',500)
axis([-3000 3000 -3000 3000 -3000 3000])

% Choose the direction of the normal
dir=input('Is the normal positive or negative? (Enter 1 or -1):\n')

% Create a point cloud from the points in the STL
cld=pointCloud(stl.Points);

% Transform the point cloud to be laying flat
tfrm=normalRotation(pln1,[0 0 dir]);
cld1=pctransform(cld,tfrm);

% Plot the flattened point cloud
f2=figure('WindowStyle','docked')
stl1=triangulation(stl.ConnectivityList,cld1.Location)
trimesh(stl1,'FaceColor',[.75 1 .75],'FaceAlpha',0.5,'LineStyle','none')
axis equal

% Prepare for data selection again
d1=datacursormode(f2);

% End the program again
return

%% IV. Squareing the STL Up

% Read all the currently displayed datatips
vals = getCursorInfo(d1);

% Extract the point coordinates from the structure
pts = zeros(size(vals,2),3);
for i=1:size(vals,2)
    pts(i,:)=vals(1,i).Position;
end

% Create a point cloud object with the selected points
cld=pointCloud(pts);

% Fit a plane to the selected points
pln2=pcfitplane(cld,0.0001);

% Note that I am ignoring the rotation that would undo the previous step
pln2=planeModel([pln2.Parameters(1) pln2.Parameters(2) 0 pln2.Parameters(4)]);

% Clear all the old datatips
dt = findobj(gca(),'Type','DataTip');
delete(dt);

% Plot the fitted plane and its normal
hold on
plot(pln2)
quiver3(0,0,0,pln2.Normal(1)*1500,pln2.Normal(2)*1500,pln2.Normal(3)*1500, 'MaxHeadSize',500)
axis([-3000 3000 -3000 3000 -3000 3000])

% Choose the direction of the normal
dir=input('Is the normal positive or negative? (Enter 1 or -1):\n')

% Create a point cloud from the points in the STL
cld=pointCloud(stl1.Points);

% Transform the point cloud to be laying flat
tfrm=normalRotation(pln2,[0 -dir 0]);
cld2=pctransform(cld,tfrm);

% Plot the new point cloud
f3=figure('WindowStyle','docked')
stl2=triangulation(stl1.ConnectivityList,cld2.Location)
trimesh(stl2,'FaceColor',[.75 .75 1],'FaceAlpha',0.5,'LineStyle','none')
axis equal

% Prepare for data selection again
d2=datacursormode(f3);

% End the program
return

%% Find center of STL in x axis

% Read all the currently displayed datatips
vals = getCursorInfo(d2);

% Extract the point coordinates from the structure
pts = zeros(size(vals,2),3);
for i=1:size(vals,2)
    pts(i,:)=vals(1,i).Position;
end

% Create a point cloud object with the selected points
cldcntrx=pointCloud(pts);

% Calculate center in x
cldcntrx = mean(cldcntrx.Location)

% Clear all the old datatips
dt = findobj(gca(),'Type','DataTip');
delete(dt);

% Prepare for data selection again
d3=datacursormode(f3);

% End the program
return

%% Find center of STL in y axis

% Read all the currently displayed datatips
vals = getCursorInfo(d3);

% Extract the point coordinates from the structure
pts = zeros(size(vals,2),3);
for i=1:size(vals,2)
    pts(i,:)=vals(1,i).Position;
end

% Create a point cloud object with the selected points
cldcntry=pointCloud(pts);

% Calculate center in y
cldcntry = mean(cldcntry.Location)

% Clear all the old datatips
dt = findobj(gca(),'Type','DataTip');
delete(dt);

% End the program
return

%% V. Extract the points on the top surface of the sample

% Scale the point cloud to be the expected size
cld2max=max(cld2.Location);
cld2min=min(cld2.Location);
cld2rng=cld2max-cld2min;
cld2rngavg=(cld2rng(1)+cld2rng(2))/2;
%cld2cntr=(cld2max+cld2min)/2;
tfrm=simtform3d(60/cld2rng(1),[1 0 0; 0 1 0; 0 0 1],[-cldcntrx(1) -cldcntry(2) -cld2min(3)]*60/cld2rng(1)+[0 0 -10.9])

cld3=pctransform(cld2,tfrm);

% Remove the screw holes from the point cloud
index_cut=findPointsInROI(cld3,[-27.2 27.2 -27.2 27.2 -50 -0.2]);
index_cut=setdiff(1:size(cld3.Location,1),index_cut);
cld4=select(cld3,index_cut);

% Extract the surface
index=findPointsInROI(cld4,[-30 30 -30 30 -0.2 30]);
export = select(cld4,index);
pcshow(export)

% Write the pointcloud to a CSV file with the same name as the STL
writematrix(export.Location,strcat(target,'.csv'))

%% Check

% Inputs
% Plotting settings
res_s = 500; % Resolution of Surfaces
res_c = res_s^2; % Resolution of curve
x_lim = [-30 30]; % Range of x
y_lim = [-30 30]; % Range of y
pad=2.5; % mm to cut off from scan on each side

% Surfaces and Curves
SurfA='Surf3c_noise.csv'; % Name of the file containing the CT scan data
SurfB=@Surface3c; % Surface Parameterization, Inputs: x,y (scalars in R^3), Outputs: z (height at the point (x,y)
Curve=@ArchSpiral; % Curve Parameterizaion, Inputs: t (scalar or vector in [0,1]), Outputs: u,v (scalars or vectors representing a point in U)

% Optimization Settings
n=2; % Grid size of initial sampling points
iter=14; % Final number of points

% Misc Variables
delta=0.001; % Used to approximate derivatives, smaller = better approximation (probably)
cmax=0.165; % Maximum Deviation (mm)

% Calculations
% range
x_min = x_lim(1); x_max = x_lim(2);
y_min = y_lim(1); y_max = y_lim(2);

% Generating x and y vectors 
x=linspace(x_lim(1)+pad, x_lim(2)-pad, res_s);
y=linspace(y_lim(1)+pad, y_lim(2)-pad, res_s);

% Generating a list of every (x,y) coordinate
[xc, yc]=meshgrid(x,y);
xd=xc(:);
yd=yc(:);

% Calculating the Surface B
zB=reshape(SurfB(xd,yd),res_s,res_s);
zBpts=[xd,yd,zB(:)];

% Data import for Surface A
data = readtable(SurfA);
data.Properties.VariableNames={'x','y','z'};
% Grabbing only data in the range specified by pad
data=data((abs(data.x)<=(max(x_lim)-pad+.2))&(abs(data.y)<=(max(y_lim)-pad+.2))&(data.z>=0),:);

% Regression model of the STL
f=scatteredInterpolant(data.x,data.y,data.z,'natural','none');
% Z-Values for Surface A at the same points as Surface B
zA=reshape(f([xd,yd]),res_s,res_s);

% Figure 1: Plot of Surface A, Surface B, the training data
f4=figure('WindowStyle','docked')
hold on
% Surface A
surf(x,y,zA,'FaceAlpha',.1,'FaceColor',[1 .5 0],'EdgeColor',[1 .5 0],'LineStyle','none');
% Surface B
surf(y,x,zB,'FaceAlpha',.1,'FaceColor',[.5 0 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
% Make Plot Pretty
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis equal
axis([-30 30 -30 30 0 20])
legend('Surface A','Surface B','\phi','f_A(x,y)','f_{A''}(x,y,z)',Location='northeast')
view(3)
fontsize(gcf, scale=1.5)