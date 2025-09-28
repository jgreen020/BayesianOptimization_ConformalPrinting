%% Figure 8: Automated Plotting for All Surface Trials
close all; clear; clc;

% --- EDIT THIS VARIABLE TO CHANGE FONT SIZE ---
fontSize = 20 ;

% --- List of all trial filenames ---
surf1b_trial = {
    '20250515_225518_Surf1b_M1_real.mat', ...
    '20250515_192421_Surf1b_M2_LCB_exp_real.mat', ...
    '20250515_205608_Surf1a_Surf1b_M3_LCB_exp_real.mat'
};
surf2b_trial = {
    '20250517_001949_Surf2b_M1_real.mat', ...
    '20250516_174734_Surf2b_M2_LCB_exp_real.mat', ...
    '20250516_220758_Surf2a_Surf2b_M3_LCB_exp_real.mat'
};
surf3b_trial = {
    '20250923_213409_Surf3b_M1_real.mat', ...
    '20250923_172121_Surf3b_M2_LCB_exp_real.mat', ...
    '20250923_184535_Surf3a_Surf3b_M3_LCB_exp_real.mat'
};

% --- List of complete datasets for curve calculation ---
CompleteSurf1bData = {
    '20250411_110658_Surf1b_M1_sim', ...
    '20250411_114352_Surf1b_M2_LCB_exp_sim', ...
    '20250411_121826_Surf1a_Surf1b_M3_LCB_exp_sim'
};
CompleteSurf2bData = {
    '20250411_173343_Surf2b_M1_sim', ...
    '20250411_185048_Surf2b_M2_LCB_exp_sim', ...
    '20250411_200024_Surf2a_Surf2b_M3_LCB_exp_sim'
};
CompleteSurf3bData = {
    '20250412_002059_Surf3b_M1_sim', ...
    '20250412_005932_Surf3b_M2_LCB_exp_sim', ...
    '20250412_013719_Surf3a_Surf3b_M3_LCB_exp_sim'
};

% --- List of print images ---
surf1b_images = {'s1m1.JPG', 's1m2.JPG', 's1m3.JPG'};
surf2b_images = {'s2m1.JPG', 's2m2.JPG', 's2m3.JPG'};
surf3b_images = {'s3m1.JPG', 's3m2.JPG', 's3m3.JPG'};

%% --- Generate, Display, and Save All Figures ---
functionfigure8(surf1b_trial, CompleteSurf1bData, surf1b_images, 'Figure 8 - Surf1b', fontSize); 
functionfigure8(surf2b_trial, CompleteSurf2bData, surf2b_images, 'Figure 8 - Surf2b', fontSize);
functionfigure8(surf3b_trial, CompleteSurf3bData, surf3b_images, 'Figure 8 - Surf3b', fontSize);

fprintf('All figures generated, displayed, and saved.\n');