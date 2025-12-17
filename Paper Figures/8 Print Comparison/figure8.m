%% Figure 8: Automated Plotting for All Surface Trials
close all; clear; clc;
addpath(genpath(pwd))

blank = true;

% --- List of all trial filenames ---
trials = {
    '20250515_225518_Surf1b_M1_real.mat', ...
    '20250515_192421_Surf1b_M2_LCB_exp_real.mat', ...
    '20250515_205608_Surf1a_Surf1b_M3_LCB_exp_real.mat';
    '20250517_001949_Surf2b_M1_real.mat', ...
    '20250516_174734_Surf2b_M2_LCB_exp_real.mat', ...
    '20250516_220758_Surf2a_Surf2b_M3_LCB_exp_real.mat';
    '20250923_213409_Surf3b_M1_real.mat', ...
    '20250923_172121_Surf3b_M2_LCB_exp_real.mat', ...
    '20250923_184535_Surf3a_Surf3b_M3_LCB_exp_real.mat'};

% --- List of print images ---
surf_images = {'s1m1.png', 's1m2.png', 's1m3.png';
    's2m1.png', 's2m2.png', 's2m3.png';
    's3m1.png', 's3m2.png', 's3m3.png'};

if ~all(size(trials)==size(surf_images),"all")
    error('Variables surf_images and trials are not the same size')
end

% --- Generate, Display, and Save Figure ---
sNames = regexp(trials,'Surf\d[a-z]','match') ;
mNames = regexp(trials,'M\d','match') ;
for i = 1:size(sNames,1)
for j = 1:size(sNames,2)
    sNames{i,j} = upper(extractAfter(sNames{i,j}(end),4)) ;
    tNames{i,j} = sNames{i,j}+", "+mNames{i,j};
end
end

% Creates a 3x3 figure and saves it as both PNG and EPS.
nplots = 2 ;
figsize = size(trials);
figsize(1) = figsize(1)*nplots;
fig8 = figure('Name', 'Physical Validation', 'Visible', 'on', 'Units', 'pixels', 'Position', [-250 1074 591 715]);
t1 = tiledlayout(size(surf_images,1),size(surf_images,2),'TileSpacing','tight','Padding','tight');
count = 1;
for j=1:3
for k=1:3
load(trials{j,k},'testpoints','modelPerformance');
ax = nexttile(t1,(j-1)*(size(surf_images,1))+k);
hold(ax, 'on');

try
    img = imread(strcat("print ims/marked up/",surf_images{j,k}));
catch ME
    text(0.5, 0.5, 'Image not found', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', fontSize);
    warning('Could not read image file: %s. Error: %s', surf_images{j,k}, ME.message);
end

if blank
    img = ones(2,2,3);
end
image('CData',img,'XData',[-30 30],'YData',[30 -30])

%scatter(ax, testpoints(:,1),testpoints(:,2), 5, 'r','o','MarkerEdgeAlpha',.5);

axis(ax, [-30 30 -30 30]);
axis(ax, 'square');
set(ax, 'XTick', -30:15:30);
set(ax, 'YTick', -30:15:30);

% if k~=1 || j~=3
    yticklabels({});
    xticklabels({});
% end

if j==1
    title("Method "+string(k));
end
if k==1
    ylabel("Surface "+sNames{j,k},"FontWeight","bold")
end

ax = nexttile(t1,'south');
hold on
C = orderedcolors('gem') ;
colors = dictionary(["1B","2B","3B"],{C(1,:),C(2,:),C(3,:)});
markers = dictionary(["M1","M2","M3"],["o","^","s"]);
plot(modelPerformance.n,modelPerformance.CV.MAE,'LineWidth',1.5,'DisplayName',tNames{j,k},'Marker',markers(mNames{j,k}),'MarkerSize',6)
yscale('log')
ylabel('MAE_{CV} [mm]')
xscale('log')
xlabel('Number of Sampled Points, n')
end
end
l=legend('NumColumns',2);
l.Layout.Tile = 'south';

if blank
% --- SAVE FIGURE ---
fname = 'Paper Figures/8 Print Comparison/Figure8';

% Save as PNG
png_filename = [fname, '.png'];
exportgraphics(fig8, png_filename, 'Resolution', 300);
fprintf('Saved PNG: %s\n', png_filename);

% Save as EPS
eps_filename = [fname, '.eps'];
exportgraphics(fig8, eps_filename, 'ContentType','vector'); % -depsc is for color EPS
fprintf('Saved EPS: %s\n', eps_filename);
end