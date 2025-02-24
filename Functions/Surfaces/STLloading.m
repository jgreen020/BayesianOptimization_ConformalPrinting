%% Code to import stls of samples from MicroCT
% Jake Colwell, June 2024
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
target='Surf1a';

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

% Direct repeat of the above section to fit a plane to selected points
vals = getCursorInfo(d1);
pts = zeros(size(vals,2),3);
for i=1:size(vals,2)
    pts(i,:)=vals(1,i).Position;
end
cld=pointCloud(pts);
pln2=pcfitplane(cld,0.0001);
% Note that I am ignoring the rotation that would undo the previous step
pln2=planeModel([pln2.Parameters(1) pln2.Parameters(2) 0 pln2.Parameters(4)]);
dt = findobj(gca(),'Type','DataTip');
delete(dt);
hold on
plot(pln2)
quiver3(0,0,0,pln2.Normal(1)*1500,pln2.Normal(2)*1500,pln2.Normal(3)*1500, 'MaxHeadSize',500)
axis([-3000 3000 -3000 3000 -3000 3000])
dir=input('Is the normal positive or negative? (Enter 1 or -1):\n')
cld=pointCloud(stl1.Points);
tfrm=normalRotation(pln2,[0 -dir 0]);
cld2=pctransform(cld,tfrm);

% Scale the point cloud to be the expected size
cld2max=max(cld2.Location);
cld2min=min(cld2.Location);
cld2rng=cld2max-cld2min;
cld2rngavg=(cld2rng(1)+cld2rng(2))/2;
cld2cntr=(cld2max+cld2min)/2;
tfrm=simtform3d(60/cld2rngavg,[1 0 0; 0 1 0; 0 0 1],[-cld2cntr(1) -cld2cntr(2) -cld2min(3)]*60/cld2rngavg-[0 0 10])

cld2=pctransform(cld2,tfrm);

% Plot the new point cloud
f3=figure('WindowStyle','docked')
stl2=triangulation(stl1.ConnectivityList,cld2.Location)
trimesh(stl2,'FaceColor',[.75 .75 1],'FaceAlpha',0.5,'LineStyle','none')
axis equal

% End the program
return

%% V. Extract the points on the top surface of the sample

% Remove the screw holes from the point cloud
index_cut=findPointsInROI(cld2,[-27.2 27.2 -27.2 27.2 -50 .8]);
index_cut=setdiff(1:size(cld2.Location,1),index_cut);
cld3=select(cld2,index_cut);

% Extract the surface
index=findPointsInROI(cld3,[-30 30 -30 30 0 30]);
export = select(cld3,index);
pcshow(export)

% Write the pointcloud to a CSV file with the same name as the STL
writematrix(cld3.Location,strcat(target,'.csv'))
