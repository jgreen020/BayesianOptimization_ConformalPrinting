%% Appendix Plot
% Check if the NURBS toolbox is available
if exist('nrbmak', 'file') ~= 2
    error('NURBS toolbox not found. Download and install the NURBS toolbox for MATLAB.');
end

% Number of control points per curve
numPoints = 10;

% Number of curve sets (each set has an upper, middle, and lower curve)
numCurves = 9;

% Define X offsets for each curve set to space them out
xOffsets = linspace(-20, 20, numCurves); % Evenly distribute along X-axis

% Shift all curves up so the lowest curve ends at (y=10, z=0)
zShift = 8;  % Shift amount to move all curves up

% Define relative downward shifts for the middle and lower curves
zOffsetLower = -4 + zShift;   % Moves middle curves downward
zOffsetBottom = -8 + zShift;  % Moves bottom curves further downward
zOffsetUpper = 0 + zShift;    % Moves upper curves up

% Create figure
figure(1);
set(gcf, 'Name', 'Error Metrics Plot', 'WindowStyle', 'docked');
hold on;

% Loop through and generate each set of curves (upper, middle, bottom)
for i = 1:numCurves
    % Define Y values (evenly spaced from 0 to 10)
    y = linspace(0, 10, numPoints)';

    % Define base Z values for the upper curves
    z_upper = -y + 10 + zOffsetUpper;  % Shifted upper curves up
    z_lower = -y + 10 + zOffsetLower;  % Shifted middle curves
    z_bottom = -y + 10 + zOffsetBottom; % Shifted bottom curves

    % Randomly vary middle 8 Z values for all curves
    z_upper(2:end-1) = z_upper(2:end-1) + (rand(numPoints-2, 1) - 0.5) * 4; 
    z_lower(2:end-1) = z_lower(2:end-1) + (rand(numPoints-2, 1) - 0.5) * 4;
    z_bottom(2:end-1) = z_bottom(2:end-1) + (rand(numPoints-2, 1) - 0.5) * 4;

    % Define X values with offset
    x = ones(size(y)) * xOffsets(i);

    % Create and plot upper, middle, and bottom curves
    for j = 1:3
        if j == 1
            z = z_upper; % Upper curve
            color = 'r'; % Red color
            lineStyle = '-'; % Solid line
        elseif j == 2
            z = z_lower; % Middle curve
            color = 'b'; % Blue color
            lineStyle = '--'; % Dashed line
        else
            z = z_bottom; % Bottom curve
            color = 'k'; % Black color
            lineStyle = ':'; % Dotted line
        end

        % Combine into control points matrix
        controlPoints = [x'; y'; z'];

        % Define a uniform knot vector for a cubic NURBS curve (degree 3)
        degree = 3;
        knotVector = [zeros(1, degree+1), linspace(0, 1, numPoints-degree), ones(1, degree+1)];

        % Define uniform weights (NURBS becomes B-spline when all weights are 1)
        weights = ones(1, numPoints);

        % Create the NURBS curve
        nurbsCurve = nrbmak([controlPoints; weights], knotVector);

        % Evaluate the NURBS curve
        numEvalPoints = 100;  % Number of points to evaluate the curve
        evalParams = linspace(0, 1, numEvalPoints);  
        curvePoints = nrbeval(nurbsCurve, evalParams);

        % Plot the NURBS curve
        plot3(curvePoints(1, :), curvePoints(2, :), curvePoints(3, :), ...
            'Color', color, 'LineStyle', lineStyle, 'LineWidth', 2);
    end
end

% Set axis labels and title
xlabel('Surface (X-axis)');
ylabel('n [number of points] (Y-axis)');
zlabel('Error Metric [mm] (Z-axis)');
title('Method used');

% Flip the Y-axis in the plot
set(gca, 'YDir', 'reverse');

% Add legend
leg = legend({'Test', 'Train', 'CV'}, 'Location', 'northwest');

% Get current position of the legend
legendPos = leg.Position;  

% Move the legend down by 100 pixels (Y direction)
legendPos(2) = legendPos(2) - 0.2;  % Adjust this value as needed

% Apply new position to the legend
leg.Position = legendPos;
% Set custom X, Y, and Z limits
xlim([-20, 20]);
ylim([0, 10]);
zlim([-5, 20]);

% Label X-axis with custom tick labels
xticks(xOffsets);
xticklabels({'1a', '1b', '1c', '2a', '2b', '2c', '3a', '3b', '3c'});

% Set aspect ratio
pbaspect([3 1 1]);

% Set view for better visualization
view(3);

% Grid for clarity
grid on;
ax = gca;
ax.FontSize = 12;
% Set view for better visualization
view(3);  % Change if needed (e.g., view([angleX, angleY]))

% Grid for clarity
grid on;
ax = gca;
ax.FontSize = 16;

%% Acquisition Function Figure (6 plots)
% Average over the same surface complexity (over 1a, 1b, 1c)
close all; clear; clc;

% Load data
addpath(genpath(fullfile(pwd)))
basepath = "Data/Results/20250411_SimStudy2/";
dirnames = dir(basepath+"*sim*");

LD_Surf1 = [];
LCB_Surf1 = [];
IVR2_Surf1 = [];

LD_Surf2 = [];
LCB_Surf2 = [];
IVR2_Surf2 = [];

LD_Surf3 = [];
LCB_Surf3 = [];
IVR2_Surf3 = [];

% for i = 1:size(dirnames,1)
for i = 1:21
    % Load data
    dirname = basepath + "/" + dirnames(i).name;
    fname = dirname + "/" + dirnames(i).name + ".mat";
    load(fname, 'modelPerformance'); % ME is 0 over all simulation runs
    load(fname, 'n');
    load(fname, 'nameB');
    load(fname, 'method');
    if method ~= 1
        load(fname, 'A');
    
        % Remove number of initial points
        modelPerformance(1:n - 1, :) = [];
    
        % Remove number of initial points
        InitialSamplingPoints = n - 1;
        modelPerformance(1:InitialSamplingPoints, :) = [];
        SimulationIteration = size(modelPerformance, 1);
    
        % Error Metrics 
        % Root Mean Squared Error
        RMSE_test = table2array(modelPerformance.Test(:, 4));
        RMSE_train = table2array(modelPerformance.Train(:, 4));
        RMSE_CV = table2array(modelPerformance.CV(:, 4));
    
        AcquisitionFunction = func2str(A);
        % Plot Calculation
        if isequal(AcquisitionFunction,'LD') &&...
          (isequal(nameB, 'Surf1a') || isequal(nameB, 'Surf1b') || isequal(nameB, 'Surf1c'))
            LD_Surf1 = cat(2, LD_Surf1, RMSE_train);
        elseif isequal(AcquisitionFunction,'LD') &&...
          (isequal(nameB, 'Surf2a') || isequal(nameB, 'Surf2b') || isequal(nameB, 'Surf2c'))
            LD_Surf2 = cat(2, LD_Surf2, RMSE_train);
        elseif isequal(AcquisitionFunction,'LD') &&...
          (isequal(nameB, 'Surf3a') || isequal(nameB, 'Surf3b') || isequal(nameB, 'Surf3c'))
            LD_Surf3 = cat(2, LD_Surf3, RMSE_train);

        elseif isequal(AcquisitionFunction,'LCB') &&...
          (isequal(nameB, 'Surf1a') || isequal(nameB, 'Surf1b') || isequal(nameB, 'Surf1c'))
            LCB_Surf1 = cat(2, LCB_Surf1, RMSE_train);
        elseif isequal(AcquisitionFunction,'LCB') &&...
          (isequal(nameB, 'Surf2a') || isequal(nameB, 'Surf2b') || isequal(nameB, 'Surf2c'))
            LCB_Surf2 = cat(2, LCB_Surf2, RMSE_train);
        elseif isequal(AcquisitionFunction,'LCB') &&...
          (isequal(nameB, 'Surf3a') || isequal(nameB, 'Surf3b') || isequal(nameB, 'Surf3c'))
            LCB_Surf3 = cat(2, LCB_Surf3, RMSE_train);

        elseif isequal(AcquisitionFunction,'IVR2') &&...
          (isequal(nameB, 'Surf1a') || isequal(nameB, 'Surf1b') || isequal(nameB, 'Surf1c'))
            IVR2_Surf1 = cat(2, IVR2_Surf1, RMSE_train);
        elseif isequal(AcquisitionFunction,'IVR2') &&...
          (isequal(nameB, 'Surf2a') || isequal(nameB, 'Surf2b') || isequal(nameB, 'Surf2c'))
            IVR2_Surf2 = cat(2, IVR2_Surf2, RMSE_train);
        elseif isequal(AcquisitionFunction,'IVR2') &&...
          (isequal(nameB, 'Surf3a') || isequal(nameB, 'Surf3b') || isequal(nameB, 'Surf3c'))
            IVR2_Surf3 = cat(2, IVR2_Surf3, RMSE_train);
        end
    end
end



% % Number of iterations from simulation run
% iteration = linspace(n,...
%                      size(modelPerformance, 1) + InitialSamplingPoints,...
%                      size(modelPerformance, 1))';
% DeviationIteration = iteration;
% DeviationIteration(1) = [];
% 
% % Plot all curves in Figure 2 (docked)
% figure(1);
% set(gcf, 'Name', 'Acquesition Function Plot','WindowStyle', 'docked');
% plot(DeviationIteration, yy1 +20, 'b-', 'LineWidth', 2); hold on;
% plot(DeviationIteration, yy2 +20, 'r-', 'LineWidth', 2);
% plot(DeviationIteration, yy3 +20, 'k-', 'LineWidth', 2);
% 
% % standrnd deviation for error bars
% % errorbar(x, y1 +20, err, 'bo', 'MarkerFaceColor', 'b');
% % errorbar(x, y2 +20, err, 'ro', 'MarkerFaceColor', 'r');
% % errorbar(x, y3 +20, err, 'ko', 'MarkerFaceColor', 'k');
% xlim([n, inf]);
% legend('acquisition function 1', 'acquisition function 2', 'acquisition function 3', ...
%        'NumColumns',3,'Location','southoutside');
% xlabel('n [number of points]');
% ylabel('RMSE [mm]');
% title('Acquisition Functions Averaged Across Suface Diveation');
% fontsize(gcf, scale=1.5)
% grid on

%% Stopping Criteria Figures
clc; clear; close all;

% Load data
addpath(genpath(fullfile(pwd)))
basepath = "Data/Results/20250411_SimStudy2/";
dirnames = dir(basepath+"*sim*");

% for i = 1:size(dirnames,1)
for i = 63
    % Load data
    dirname = basepath + "/" + dirnames(i).name;
    fname = dirname + "/" + dirnames(i).name + ".mat";
    load(fname, 'modelPerformance'); % ME is 0 over all simulation runs
    load(fname, 'n');
    load(fname, 'SurfA');
    load(fname, 'SurfB');
    load(fname, 'method');
    if method ~= 1
        load(fname, 'zBpCI');
        load(fname, 'zBpsd');
        load(fname, 'zBpl');
        load(fname, 'zBp');
    end

    % Remove number of initial points
    modelPerformance(1:n - 1, :) = [];

    % Remove number of initial points
    InitialSamplingPoints = n - 1;
    modelPerformance(1:InitialSamplingPoints, :) = [];
    SimulationIteration = size(modelPerformance, 1);

    % Error Metrics
    % Mean Error
    ME_test = table2array(modelPerformance.Test(:, 2));
    ME_train = table2array(modelPerformance.Train(:, 2));
    ME_CV = table2array(modelPerformance.CV(:, 2));
    
    % Max Absolute Error
    MaxAE_test = table2array(modelPerformance.Test(:, 1));
    MaxAE_train = table2array(modelPerformance.Train(:, 1));
    MaxAE_CV = table2array(modelPerformance.CV(:, 1));

    % Mean Absolute Error
    MAE_test = table2array(modelPerformance.Test(:, 3));
    MAE_train = table2array(modelPerformance.Train(:, 3));
    MAE_CV = table2array(modelPerformance.CV(:, 3));

    % Root Mean Squared Error
    RMSE_test = table2array(modelPerformance.Test(:, 4));
    RMSE_train = table2array(modelPerformance.Train(:, 4));
    RMSE_CV = table2array(modelPerformance.CV(:, 4));

    % Comparative Root Mean Squared Error
    CRMSE = table2array(modelPerformance(:, 5));

    % Confidence Interval
    CI = table2array(modelPerformance(:, 4));
    

    % Ideal:
    % Gaurentee of Point Quality
    IdealGaurentee = MaxAE_test;
    
    % Confidence Testing
    K = 1;
    IdealConfidenceTesting = K*(RMSE_test) + ME_test;
    
    % Error Convergence
    ME_testOne = ME_test; ME_testOne(end) = [];
    ME_testTwo = ME_test; ME_testTwo(1) = [];

    MaxAE_testOne = MaxAE_test; MaxAE_testOne(end) = [];
    MaxAE_testTwo = MaxAE_test; MaxAE_testTwo(1) = [];

    MAE_testOne = MAE_test; MAE_testOne(end) = [];
    MAE_testTwo = MAE_test; MAE_testTwo(1) = [];

    RMSE_testOne = RMSE_test; RMSE_testOne(end) = [];
    RMSE_testTwo = RMSE_test; RMSE_testTwo(1) = [];

    CRMSE(1) = [];

    % IdealErrorConvergenceME = abs(ME_testTwo - ME_testOne);    
    IdealErrorConvergenceMaxAE = abs(MaxAE_testTwo - MaxAE_testOne);
    IdealErrorConvergenceMAE = abs(MAE_testTwo - MAE_testOne);
    IdealErrorConvergenceRMSE = abs(RMSE_testTwo - RMSE_testOne);
    IdealErrorConvergenceCRMSE = CRMSE;

    % Error Agreement    
    IdealErrorAgreement = abs(MaxAE_test - MaxAE_train);


    % Actual:
    % Gaurentee of Point Quality
    ActualGaurentee = MaxAE_CV;
    
    % Confidence Testing
    K = 1;
    ActualConfidenceTesting = K*(RMSE_CV) + ME_CV;
    
    % Error Convergence
    ME_CVOne = ME_CV; ME_CVOne(end) = [];
    ME_CVTwo = ME_CV; ME_CVTwo(1) = [];

    MaxAE_CVOne = MaxAE_CV; MaxAE_CVOne(end) = [];
    MaxAE_CVTwo = MaxAE_CV; MaxAE_CVTwo(1) = [];

    MAE_CVOne = MAE_CV; MAE_CVOne(end) = [];
    MAE_CVTwo = MAE_CV; MAE_CVTwo(1) = [];

    RMSE_CVOne = RMSE_CV; RMSE_CVOne(end) = [];
    RMSE_CVTwo = RMSE_CV; RMSE_CVTwo(1) = [];

    % ActualErrorConvergenceME = abs(ME_CVTwo - ME_CVOne);  
    ActualErrorConvergenceMaxAE = abs(MaxAE_CVTwo - MaxAE_CVOne);
    ActualErrorConvergenceMAE = abs(MAE_CVTwo - MAE_CVOne);
    ActualErrorConvergenceRMSE = abs(RMSE_CVTwo - RMSE_CVOne);
    ActualErrorConvergenceCRMSE = CRMSE;
    
    % Error Agreement    
    ActualErrorAgreement = abs(MaxAE_CV - MaxAE_train);


    % V2
    % Guarntee of Point Quality
    % GPR gives 90% CI

    % Confidence Testing
    V2ConfidenceTesting = CI; % 90% Confidence Interval

    

    % Error Convergence
    CI_One = CI; CI_One(end) = [];
    CI_Two = CI; CI_Two(1) = [];

    V2ErrorConvergenceCI = abs(CI_Two - CI_One);

    
    % Stopping Criteria Figure
    % Critical Numbers
    criticalNumber1 = 0.165;
    criticalNumber2 = 6e-4;
    criticalNumber3 = 0.5;

    
    % Identify Stopping Critiria number of points
    % Ideal Error Convergence (IEC)
    for j = 1:SimulationIteration-1
        MaxAE_IEC = IdealErrorConvergenceMaxAE(j);
        MAE_IEC = IdealErrorConvergenceMAE(j);
        RMSE_IEC = IdealErrorConvergenceRMSE(j);
        CRMSE_IEC = IdealErrorConvergenceCRMSE(j);

        if MaxAE_IEC < criticalNumber2 &&...
           MAE_IEC < criticalNumber2 &&...
           RMSE_IEC < criticalNumber2 &&...
           CRMSE_IEC < criticalNumber2
            printNumberIEC = j + InitialSamplingPoints;
            disp('Stopping Critiria has been satisfied')
            disp(printNumberIEC)
            break

        else
            disp('Stopping Critiria has not been satisfied')

        end
    end

    % Actual Error Convergence (AEC)
    for j = 1:SimulationIteration-1
        MaxAE_AEC = ActualErrorConvergenceMaxAE(j);
        MAE_AEC = ActualErrorConvergenceMAE(j);
        RMSE_AEC = ActualErrorConvergenceRMSE(j);
        CRMSE_AEC = ActualErrorConvergenceCRMSE(j);

        if MaxAE_AEC < criticalNumber2 &&...
           MAE_AEC < criticalNumber2 &&...
           RMSE_AEC < criticalNumber2 &&...
           CRMSE_AEC < criticalNumber2
            printNumberAEC = j + InitialSamplingPoints;
            disp('Stopping Critiria has been satisfied')
            disp(printNumberAEC)
            break

        else
            disp('Stopping Critiria has not been satisfied')

        end
    end

    % V2 Error Convergence (VEC)
    for j = 1:SimulationIteration-1
        CI_VEC = V2ErrorConvergenceCI(j);

        if CI_VEC < criticalNumber2
            printNumberVEC = j + InitialSamplingPoints;
            disp('Stopping Critiria has been satisfied')
            disp(printNumberVEC)
            break

        else
            disp('Stopping Critiria has not been satisfied')

        end
    end 

    % Plotting
    % Number of iterations from simulation run
    iteration = linspace(n,...
                         size(modelPerformance, 1) + InitialSamplingPoints,...
                         size(modelPerformance, 1))';
    DeviationIteration = iteration;
    DeviationIteration(1) = [];
 

    % Plotting Ideal Error Convergence
    figure(3);
    set(gcf, 'Name', 'Ideal Error Convergence','WindowStyle', 'docked');
    hold on
    plot(DeviationIteration, IdealErrorConvergenceMaxAE,...
        'Color',[0.8500 0.3250 0.0980], 'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, IdealErrorConvergenceMAE,...
        'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, IdealErrorConvergenceRMSE,...
        'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, IdealErrorConvergenceCRMSE,...
        'Color',[0.4660 0.6740 0.1880],'LineStyle','-','LineWidth',2)
    plot([printNumberIEC printNumberIEC], [1e-7, criticalNumber2],...
        'r--', 'LineWidth', 5);
    yline(criticalNumber2, 'k-', 'LineWidth', 3);
    set(gca,'YScale','log')
    % set(gca,'XScale','log')
    text(printNumberIEC, 1e-7, [' \leftarrow n^* = ' num2str(printNumberIEC)], ...
                                'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                                'FontSize', 12, 'Color', 'r', 'Rotation', 0);
    xlim([n inf]);  % Start x-axis at number of initial sampling points
    legend('MaxAE','MAE','RMSE','C-RMSE','n*','Critical #3',...
           'NumColumns',3,'Location','southoutside') 
    xlabel('Number of Points (n)')
    ylabel('Metric Value (mm)')
    title('Ideal Error Convergence')
    fontsize(gcf, scale=1.5)
    grid on 

    % Plotting Actual Error Convergence
    figure(4);
    set(gcf, 'Name', 'Actual Error Convergence','WindowStyle', 'docked');
    hold on
    plot(DeviationIteration, ActualErrorConvergenceMaxAE,...
        'Color',[0.8500 0.3250 0.0980], 'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, ActualErrorConvergenceMAE,...
        'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, ActualErrorConvergenceRMSE,...
        'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
    plot(DeviationIteration, ActualErrorConvergenceCRMSE,...
        'Color',[0.4660 0.6740 0.1880],'LineStyle','-','LineWidth',2)
    plot([printNumberAEC printNumberAEC], [1e-10, criticalNumber2],...
        'r--', 'LineWidth', 5);
    yline(criticalNumber2, 'k-', 'LineWidth', 3);
    set(gca,'YScale','log')
    % set(gca,'XScale','log')
    text(printNumberAEC, 1e-7, [' \leftarrow n^* = ' num2str(printNumberAEC)], ...
                                'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                                'FontSize', 12, 'Color', 'r', 'Rotation', 0);
    xlim([n inf]);  % Start x-axis at number of initial sampling points
    legend('MaxAE','MAE','RMSE','C-RMSE','n*','Critical #3',...
           'NumColumns',3,'Location','southoutside') 
    xlabel('Number of Points (n)')
    ylabel('Metric Value (mm)')
    title('Actual Error Convergence')
    fontsize(gcf, scale=1.5)
    grid on

    % Plotting V2 Error Convergence
    figure(5);
    set(gcf, 'Name', 'V2 Error Convergence','WindowStyle', 'docked');
    hold on
    plot(DeviationIteration, V2ErrorConvergenceCI,...
        'Color',[0.3010 0.7450 0.9330],'LineStyle','-','LineWidth',2)
    plot([printNumberVEC printNumberVEC], [1e-5, criticalNumber2],...
        'r--', 'LineWidth', 5);
    yline(criticalNumber2, 'k-');
    set(gca,'YScale','log')
    % set(gca,'XScale','log')
    text(printNumberIEC, 1e-5, [' \leftarrow n^* = ' num2str(printNumberIEC)], ...
                                'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                                'FontSize', 12, 'Color', 'r', 'Rotation', 0);
    xlim([n inf]);  % Start x-axis at number of initial sampling points
    legend('Maximum CI Width','Critical #3','NumColumns',3,'Location','southoutside') 
    xlabel('Number of Points (n)')
    ylabel('Metric Value (mm)')
    title('V2 Error Convergence')
    fontsize(gcf, scale=1.5)
    grid on

    % % Plotting Error Agreement
    % figure(5);
    % set(gcf, 'Name', 'Error Agreement','WindowStyle', 'docked');
    % loglog(iteration, IdealErrorAgreement, 'b-'); hold on;
    % loglog(iteration, ActualErrorAgreement, 'r-')
    % yline(criticalNumberThree, 'r--', 'Critical #3');
    % xlim([InitialSamplingPoints inf]);  % Start x-axis at number of initial sampling points
    % grid on
end

%% 
one1 = 1;

disp(one1)