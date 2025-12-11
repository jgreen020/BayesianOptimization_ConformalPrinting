%% Figure 8: Automated Plotting for All Surface Trials
close all; clear; clc;
addpath(genpath(pwd))

% --- EDIT THIS VARIABLE TO CHANGE FONT SIZE ---
fontSize = 20 ;

% --- List of all trial filenames ---
% surf1b_trial = {
%     '20250515_225518_Surf1b_M1_real.mat', ...
%     '20250515_192421_Surf1b_M2_LCB_exp_real.mat', ...
%     '20250515_205608_Surf1a_Surf1b_M3_LCB_exp_real.mat'
% };
% surf2b_trial = {
%     '20250517_001949_Surf2b_M1_real.mat', ...
%     '20250516_174734_Surf2b_M2_LCB_exp_real.mat', ...
%     '20250516_220758_Surf2a_Surf2b_M3_LCB_exp_real.mat'
% };
% surf3b_trial = {
%     '20250923_213409_Surf3b_M1_real.mat', ...
%     '20250923_172121_Surf3b_M2_LCB_exp_real.mat', ...
%     '20250923_184535_Surf3a_Surf3b_M3_LCB_exp_real.mat'
% };

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
% surf1b_images = {'s1m1.JPG', 's1m2.JPG', 's1m3.JPG'};
% surf2b_images = {'s2m1.JPG', 's2m2.JPG', 's2m3.JPG'};
% surf3b_images = {'s3m1.JPG', 's3m2.JPG', 's3m3.JPG'};

surf_images = {'s1m1.JPG', 's1m2.JPG', 's1m3.JPG';
    's2m1.JPG', 's2m2.JPG', 's2m3.JPG';
    's3m1.JPG', 's3m2.JPG', 's3m3.JPG'};

if ~all(size(trials)==size(surf_images),"all")
    error('Variables surf_images and trials are not the same size')
end

% --- Generate, Display, and Save All Figures ---
% functionfigure8(surf1b_trial, CompleteSurf1bData, surf1b_images, 'Figure 8 - Surf1b', fontSize); 
% functionfigure8(surf2b_trial, CompleteSurf2bData, surf2b_images, 'Figure 8 - Surf2b', fontSize);
% functionfigure8(surf3b_trial, CompleteSurf3bData, surf3b_images, 'Figure 8 - Surf3b', fontSize);

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
fig8 = figure('Name', 'Physical Validation', 'Visible', 'on', 'Units', 'pixels', 'Position', [100, 100, 1000/figsize(1)*figsize(2), 1000]);
t1 = tiledlayout(size(surf_images,1)+1,size(surf_images,2),'TileSpacing','tight','Padding','tight');
count = 1;
for j=1:3
for k=1:3
t1_tile = nexttile(t1,count);
count = count+1;
% --- ROW 1: Data Points ---
t2 = tiledlayout(t1,nplots,1,'TileSpacing','tight','Padding','tight');
ax = nexttile(t2,1);
load(trials{j,k},'testpoints','modelPerformance');
hold(ax, 'on');

plot(ax, testpoints(:,1),testpoints(:,2), 'r.', 'MarkerSize', 5);

axis(ax, [-30 30 -30 30]);
axis(ax, 'square');
set(ax, 'XTick', -30:15:30);
set(ax, 'YTick', -30:15:30);
if k~=1
    yticklabels({});
else
    ylabel('y [mm]')
end
if j~=3
    xticklabels({});
else
    xlabel('x[mm]')
end
if j==1;    title("Method "+string(k));     end

% --- ROW 2: Image Plots ---
ax = nexttile(t2,2);
try
    imshow(imread(surf_images{j,k}), 'Parent', ax);
catch ME
    text(0.5, 0.5, 'Image not found', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', fontSize);
    warning('Could not read image file: %s. Error: %s', surf_images{j,k}, ME.message);
end

nexttile(t1,(size(surf_images,1)+1)*size(surf_images,2)-2,[1,3])
hold on
C = orderedcolors('gem') ;
colors = dictionary(["1B","2B","3B"],{C(1,:),C(2,:),C(3,:)});
markers = dictionary(["M1","M2","M3"],["o","^","s"]);
plot(modelPerformance.n,modelPerformance.CV.MAE,'LineWidth',1.5,'DisplayName',tNames{j,k},'Marker',markers(mNames{j,k}),'MarkerSize',3)
yscale('log')
ylabel('MAE_{CV} [mm]')
xscale('log')
xlabel('Number of Sampled Points, n')
legend('Location','southoutside','NumColumns',3,'Orientation','horizontal')
end
end
% --- ALIGNED ROW LABELS ---
% label_ax = axes('Position', [0 0 1 1], 'Visible', 'off');
% y_pos1 = pos_bottom(1) + subplot_heights(1)/2;
% y_pos2 = pos_bottom(2) + subplot_heights(2)/2;
% y_pos3 = pos_bottom(3) + subplot_heights(3)/2;
% x_pos = left_margin - 0.0;
% 
% name_parts = strsplit(figure_name, ' - ');
% raw_surface_label = name_parts{2}; 
% surface_label = regexprep(raw_surface_label, 'surf', 'Surface', 'ignorecase'); 
% 
% text(label_ax, x_pos, y_pos1, surface_label, 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
% text(label_ax, x_pos, y_pos2, 'Curve', 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
% text(label_ax, x_pos, y_pos3, 'Print', 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');


% % --- SAVE FIGURE ---
% % Create a base filename without extension
% output_basename = strrep(figure_name, ' ', '_');
% 
% % Save as PNG
% png_filename = [output_basename, '.png'];
% print(fig8, png_filename, '-dpng', '-r300');
% fprintf('Saved PNG: %s\n', png_filename);
% 
% % Save as EPS
% eps_filename = [output_basename, '.eps'];
% print('-vector',fig8, eps_filename, '-depsc'); % -depsc is for color EPS
% fprintf('Saved EPS: %s\n', eps_filename);