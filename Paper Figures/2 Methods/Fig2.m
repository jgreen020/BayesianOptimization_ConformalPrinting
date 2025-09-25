%% Fig2.m
% Author(s): Jake Colwell
% Created: September 10, 2025
% Last Major Modification: 
% Script to generate illustrative plots for Figure 2 in the paper

clear; clc; close all
%% Figure 2a

% Photo of Surface 2a


%% Figure 2b, CT Scan Visualization
clear; clc; close all

% Process CT images to boost contrast and crop
files = dir("Data/CT Scans/Surf2a_ims/block*");
n=15;%size(files,1);
if n<size(files,1)
    start = 700; last = 3160;
    files = files(round(linspace(start,last,n)),:);
end
ims = cell(size(files,1),1); masks = cell(size(files,1),1);
% f = figure('WindowStyle','docked');
% tiledlayout()
min_all = inf; max_all=-inf;
for i=1:n
    im = double(imread(strcat(files(i).folder,'/',files(i).name)));
    ims{i}=im;
    mask = true(size(im));
    mask(im==0)=0;
    masks{i}=mask;
    im(~mask)=mean(im(mask),"all");
    minu = min(im(mask));
    maxu = max(im(mask));
    if minu < min_all
        min_all = minu;
    end
    if maxu > max_all
        max_all=maxu;
    end
end
for i=1:n
    % nexttile
    im=ims{i};
    mask = masks{i};
    im_masked = im(mask);
    im_scaled = (im_masked-min_all)/(max_all-min_all);
    im(mask)=im_scaled;
    % h=imshow(im);
    % set(h, 'AlphaData', mask);
    ims{i}=im;
end

% Calculate rotation of stack
angles = [270, 11.428, 0] ; % CW Rotation about x,y,z axes in degrees (default is straight up)

Rx = [1 0 0; 0 cosd(angles(1)) -sind(angles(1)); 0 sind(angles(1)) cosd(angles(1))];
Ry = [cosd(angles(2)) 0 sind(angles(2)); 0 1 0; -sind(angles(2)) 0 cosd(angles(2))];
Rz = [cosd(angles(3)) -sind(angles(3)) 0; sind(angles(3)) cosd(angles(3)) 0; 0 0 1];
R = Rz*Ry*Rx ;

corners = [0 1 0 1; 0 0 1 1; 0 0 0 0];
corners = R*corners;

f=figure('Color','white');
hold on
for i = 1:n
    im=ims{i};
    mask = double(masks{i})*0.1;
    mask(end, end)=1;
    thresh = 0.3;%mean(im,'all');
    mask(im>thresh)=1;
    mask(im<thresh & mask)=0.15;
    surf([corners(1,1:2); corners(1,3:4)],[corners(2,1:2); corners(2,3:4)],[corners(3,1:2); corners(3,3:4)],im,'LineStyle','none','FaceColor','texturemap','AlphaData',im,'FaceAlpha','texturemap')
    corners = corners + 1/n*R*[0; 0; 1] ;
end
colormap(f,"gray")
axis equal
axis off
view([45,35])
%savefig(f,'Paper Figures/2 Methods/b/Fig2b.fig','-v7.3')
exportgraphics(f,'Paper Figures/2 Methods/b/Fig2b.png','BackgroundColor','none')
exportgraphics(f,'Paper Figures/2 Methods/b/Fig2b.pdf','ContentType','vector','BackgroundColor','none')

%% Figure 2c, STL Point Cloud
clear; clc; close all

surfname='Surf2a.csv'; % Surface to plot
dataA = readtable(strcat('Data/CT Scans/',surfname)); % Read csv file
dataA.Properties.VariableNames={'x','y','z'}; % set variable names

x_lim = [-30 30]; % Range of x
y_lim = [-30 30]; % Range of y
pad=1.5; % mm to cut off from scan on each side
dec = 2000; % rate to decimate data by

%trim data according to limits
dataB=dataA((abs(dataA.x)<=(max(x_lim)-pad+.2))&(abs(dataA.y)<=(max(y_lim)-pad+.2))&(dataA.z>=0),:);

% decimate data
numB=floor(size(dataB,1)/dec);
vec = 1:dec:(numB*dec);
pts = vec + randi(dec,1,numB)-1;
dataB=dataB(pts,:);

% plot and save
f=figure('Color','none','Name','Figure 2c');
hold on
scatter3(dataB,'x','y','z','ColorVariable','z','SizeData',4,'MarkerFaceColor','flat')
axis equal
axis([x_lim y_lim [min(dataB.z) max(dataB.z)]])
axis off
view([45,35])
savefig('Paper Figures/2 Methods/c/Fig2c.fig')
exportgraphics(f,'Paper Figures/2 Methods/c/Fig2c.png','BackgroundColor','none')
exportgraphics(f,'Paper Figures/2 Methods/c/Fig2c.eps','ContentType','vector','BackgroundColor','none')
set(f,'Color','white')

%% Figure 2d and h, Bezier Surface
clear;clc;close all
addpath(genpath(fullfile(pwd)))
bulk=1;

Curve=@Hybrid; % Curve Parameterizaion

Inputs

surfnames = {'Surf2a.csv','Surf2b.csv'};
method=1;
n=6;
m=6;
AFs = ['d','h'];

for safeloopvar = [1,2]
    SurfB=surfnames{safeloopvar};
    
    [dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad,res_s);
    main
    
    close all
    
    % Compress point cloud for visualization
    P_o_comp = P_o(:,:,3);
    P_o_comp = P_o_comp(:);
    z_max = max(zBp,[],'all');
    z_min = min(zBp,[],'all');
    P_o_comp(P_o_comp>z_max) = (P_o_comp(P_o_comp>z_max)-z_max)/10 + z_max ;
    P_o_comp(P_o_comp<z_min) = (P_o_comp(P_o_comp<z_min)-z_min)/10 + z_min ;
    P_o_comp = reshape(P_o_comp, [n,n]);
    
    f=figure('Color','none','Name',['Figure 2',AFs(safeloopvar)],'Position',[0,0,560,420]);
    hold on
    surfaceplot = surf(xBp,yBp,zBp, LineStyle='none');
    testpointsplot = scatter3(testpoints(:,1),testpoints(:,2),testpoints(:,3),4,'black',Marker="o",MarkerFaceColor='black');
    ctrlpointsplot = scatter3(P_o(:,:,1),P_o(:,:,2),P_o_comp,Marker="o",MarkerEdgeColor='red',LineWidth=3);
    ctrllinesplot = surf(P_o(:,:,1),P_o(:,:,2),P_o_comp, FaceAlpha=0,Marker="o",EdgeColor='red',LineStyle='--',LineWidth=3);
    axis equal
    axis off
    view([45,35])
    clim([z_min z_max])
    
    savefig(['Paper Figures/2 Methods/',AFs(safeloopvar),'/Fig2',AFs(safeloopvar),'.fig'])
    exportgraphics(f,['Paper Figures/2 Methods/',AFs(safeloopvar),'/Fig2',AFs(safeloopvar),'.png'],'BackgroundColor','none')
    
    delete(ctrllinesplot)
    exportgraphics(f,['Paper Figures/2 Methods/',AFs(safeloopvar),'/Fig2',AFs(safeloopvar),'_1.eps'],'ContentType','vector','BackgroundColor','none')
    
    lines = zeros(1,2,3);
    P_o2 = P_o;
    P_o2(:,:,3) = P_o_comp;
    for i = 1:size(P_o2,1)
        for j = 1:size(P_o2,2)
            pt = P_o2(i,j,:);
            if i<size(P_o2,1)
                pt2 = P_o2(i+1,j,:);
                lines = cat(1,lines,[pt pt2]);
            end
            if j<size(P_o2,2)
                pt2 = P_o2(i,j+1,:);
                lines = cat(1,lines,[pt pt2]);
            end
        end
    end
    lines = lines(2:end,:,:);
    
    res_l = 100;
    for k = 1:size(lines,1)
        line = lines(k,:,:);
        pt = line(1,1,:);
        pt2 = line(1,2,:);
        line = [linspace(pt(1,1,1),pt2(1,1,1),res_l)', linspace(pt(1,1,2),pt2(1,1,2),res_l)', linspace(pt(1,1,3),pt2(1,1,3),res_l)'];
        above = line(:,3) > fB_p{n}(line(:,1),line(:,2));
        edges = diff([false; above; false]);
        starts = find(edges == 1);
        ends = find(edges == -1) - 1;
        blocks = [starts' ends'];
        if ~isempty(blocks)
        for l = 1:size(blocks,1)
            block = blocks(l,:);
            segment = [line(block(1),:); line(block(2),:)];
            plot3(segment(:,1),segment(:,2),segment(:,3),Marker='none',Color='red',LineWidth=3,LineStyle='--')
        end
        end
    end
    
    delete(surfaceplot); delete(ctrlpointsplot); delete(testpointsplot);
    exportgraphics(f,['Paper Figures/2 Methods/',AFs(safeloopvar),'/Fig2',AFs(safeloopvar),'_2.eps'],'ContentType','vector','BackgroundColor','none')
end
%% Figure 2e, GPR plot
clear;clc;close all
addpath(genpath(fullfile(pwd)))

res = 100;
load('TrainedPriors/Surf2a.mat')
x = gprMdlA.X.x;
y = gprMdlA.X.y;
z = gprMdlA.Y;
[x2, y2] = meshgrid(linspace(x_lim_pri(1),x_lim_pri(2),res),linspace(y_lim_pri(1),y_lim_pri(2),res));
z2 = predict(gprMdlA,table(x2(:),y2(:),'VariableNames',{'x','y'}));

f=figure('Color','none','Name','Figure 2e');
hold on
surf(x2,y2,reshape(z2,[res res]), LineStyle='none',FaceAlpha=1)
idxs = randi(size(z,1),ceil(size(z,1)/500));
scatter3(x(idxs),y(idxs),z(idxs),4,'black','o',MarkerFaceColor='black')

%kfcn = gprMdlA.Impl.Kernel.makeKernelAsFunctionOfXNXM(gprMdlA.Impl.ThetaHat);
%K = kfcn(sort(x),sort(x));
%scatter3(sort(x),sort(x),K,2)

axis equal
axis off
view([45,35])

savefig('Paper Figures/2 Methods/e/Fig2e.fig')
exportgraphics(f,'Paper Figures/2 Methods/e/Fig2e.png','BackgroundColor','none')
exportgraphics(f,'Paper Figures/2 Methods/e/Fig2e.eps','ContentType','vector','BackgroundColor','none')
set(f,'Color','white')

%% Figure 2f

% Photo of Surface 2b


%% Figure 2g

% Photo of Surface 2b being scanned with TCS


%% Figure 2h

% Handled Above


%% Figure 2i and j, GPR plot, low n and high n, surface B
clear;clc;close all
addpath(genpath(fullfile(pwd)))

res = 100;
load('Data/Results/20250423_SimStudy4/20250423_202116_Surf2b_M2_LCB_exp_sim/20250423_202116_Surf2b_M2_LCB_exp_sim.mat')

target_n = [20, 150];
letters = ['i','j'];
for i = 1:2
    gpr = gprMdls{target_n(i)};
    x = gpr.X.x;
    y = gpr.X.y;
    z = gpr.Y;
    [x2, y2] = meshgrid(linspace(x_lim(1),x_lim(2),res),linspace(y_lim(1),y_lim(2),res));
    z2 = predict(gpr,table(x2(:),y2(:),'VariableNames',{'x','y'}));
    
    f(i)=figure('Color','none','Name',['Figure 2',letters(i)]);
    hold on
    surf(x2,y2,reshape(z2,[res res]), LineStyle='none',FaceAlpha=1)
    scatter3(x,y,z,4,'black','o','MarkerFaceColor','flat')
    
    %kfcn = gprMdlA.Impl.Kernel.makeKernelAsFunctionOfXNXM(gprMdlA.Impl.ThetaHat);
    %K = kfcn(sort(x),sort(x));
    %scatter3(sort(x),sort(x),K,2)
    
    axis equal
    axis off
    view([45,35])
    
    savefig(f(i),['Paper Figures/2 Methods/',letters(i),'/Fig2',letters(i),'.fig'])
    exportgraphics(f(i),['Paper Figures/2 Methods/',letters(i),'/Fig2',letters(i),'.png'],'BackgroundColor','none')
    exportgraphics(f(i),['Paper Figures/2 Methods/',letters(i),'/Fig2',letters(i),'.eps'],'ContentType','vector','BackgroundColor','none')
    set(f(i),'Color','white')
end