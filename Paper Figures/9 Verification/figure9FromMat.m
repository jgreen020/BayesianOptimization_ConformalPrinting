clear; clc; close all;
addpath(genpath(pwd))

%% 1. Manual Constants (Visual Configuration)
% Adjust these values to control the appearance of the output figures
figSize          = [0, 1, 15, 5.25];            % Figure Size [Left Bottom Width Height] in inches
imageRowWeight   = 1.25;                     % Image Size Control: 1.0 = equal to plot. <1.0 = smaller, >1.0 = bigger.
axisFontSize     = 12;                      % Font size for axis ticks and labels
legendFontSize   = 12;                      % Font size for the legend
plotLineWidth    = 1.5;                     % Line width for the data plots
connectLineWidth = 1.5;                     % Line width for the red/magenta connecting lines

%% 2. Data Definitions
physicalStudyMethod2Trials = {
    '20250515_192421_Surf1b_M2_LCB_exp_real', ...
    '20250516_174734_Surf2b_M2_LCB_exp_real', ...
    '20250923_172121_Surf3b_M2_LCB_exp_real'
};

verificationStudyMethod2Trials = {
    '20251122_013740_Surf1b_M2_LCB_exp_real', ...
    '20251121_171838_Surf2b_M2_LCB_exp_real', ...
    '20251121_231322_Surf3b_M2_LCB_exp_real'
};

initial_sampling_time = {
    'TCS_t2_Surf1b_n10', ...
    'TCS_t2_Surf2b_n20', ...
    'TCS_t2_Surf3b_n40'
};

minimum_TCS_points = {15, 30, 60};

imageVector = "printims/cropped/" + {
    's1m2v.png', ...
    's1m2p.png', ...
    's2m2v.png', ...
    's2m2p.png', ...
    's3m2v.png', ...
    's3m2p.png'
};

% Initialize array to track the figures created by this script
numTrials = size(physicalStudyMethod2Trials, 2);

% --- Figure Creation ---
f = figure('Units','inches','Position', figSize, 'Color', 'w', 'Name', ['Trial ' num2str(i)]);
figsToKeep = f; 

% --- GRID SPANNING SETUP ---
gridResolution = 20;
bottomPadding = 3;

% Calculate rows for images vs plot based on weight
imgFraction = imageRowWeight / (1 + imageRowWeight);
imgRows = round(gridResolution * imgFraction);
imgRows = max(1, min(gridResolution-2, imgRows)); % Safety clamp
plotRows = gridResolution - imgRows;

% Create a tiledlayout container with an invisible axis at the bottom
% (creates enough space for the custom axis labels)
tile = tiledlayout(gridResolution+bottomPadding, numTrials*2, 'TileSpacing', 'compact','Padding','tight');

ax = nexttile(tile,gridResolution*numTrials*2+1,[bottomPadding,numTrials*2]);
ax.Visible='off';

%% 3. Loop and Plot Generation
for i = 1:numTrials
    
    % --- Data Processing ---
    load(physicalStudyMethod2Trials{i});
    Physical_CV_MAE = modelPerformance.CV.MAE;
    
    first_zero_index = find(Physical_CV_MAE == 0, 1, 'first');
    if ~isempty(first_zero_index)
        last_index_to_keep = first_zero_index - 1;          
        Physical_CV_MAE = Physical_CV_MAE(1:last_index_to_keep);
    end
   
    num_elements = length(Physical_CV_MAE);
    index_vector = 0 : (num_elements - 1);
    TCS_points = n + index_vector + 1;
    TCS_points = TCS_points'; 

    zBp_all = zBp_all(n:iter);
    reference_matrix = zBp_all{end};
    absolute_error_matrices_adv = cellfun(@(x) abs(reference_matrix - x), zBp_all, 'UniformOutput', false);
    MAE_n_star = cellfun(@(x) mean(x, 'all'), absolute_error_matrices_adv);
    
    TCS_t = t;
    TCS_t = TCS_t(n:end);
    load(initial_sampling_time{i}, 't');
    initial_sampling_t = t;
    TCS_t = TCS_t + initial_sampling_t(end);
    All_t = vertcat(initial_sampling_t, TCS_t);
    All_t = All_t/60;

    load(verificationStudyMethod2Trials{i});
    Verification_CV_MAE = modelPerformance.CV.MAE;
    
    v_zero_idx = find(Verification_CV_MAE == 0, 1, 'first');
    if ~isempty(v_zero_idx)
        Verification_CV_MAE = Verification_CV_MAE(1:v_zero_idx-1);
    end

    TCS_points_ver = TCS_points(1:length(Verification_CV_MAE));
    
    % --- Top Row: Images ---
    idx1 = (i-1)*2 + 1; 
    idx2 = (i-1)*2 + 2;
    
    wState = warning('off', 'MATLAB:imagesci:imjpgbaselineinfo:noncompliance');

    % Span the top tiles (imgRows tall, 1 column wide)
    ax1 = nexttile(tile,2*i-1,[imgRows, 1]); 
    if isfile(imageVector{idx1})
        imshow(imageVector{idx1}, 'InitialMagnification', 'fit');
        title('Physical Setup', 'Interpreter', 'none', 'FontWeight', 'bold');
    else
        text(0.5, 0.5, 'Image Not Found', 'HorizontalAlignment', 'center');
        axis off; 
    end
    idx_min = minimum_TCS_points{i};
    time_min = All_t(idx_min);
    title(sprintf('$n_{min}$=%d', idx_min),'Interpreter','latex','FontName','Helvetica')
    fontsize(axisFontSize,'points')
    
    ax2 = nexttile(tile,2*i, [imgRows, 1]); 
    if isfile(imageVector{idx2})
        imshow(imageVector{idx2}, 'InitialMagnification', 'fit');
        title('Verification Setup', 'Interpreter', 'none', 'FontWeight', 'bold');
    else
        text(0.5, 0.5, 'Image Not Found', 'HorizontalAlignment', 'center');
        axis off;
    end
    
    max_TCS_points = max(TCS_points);
    time_stop = All_t(max_TCS_points);
    title(sprintf('$n^*$=%d', max_TCS_points),'Interpreter','latex')
    fontsize(axisFontSize,'points')
    warning(wState);

    % --- Bottom Row: Data Plot ---
    % Span the bottom tile (plotRows tall, 2 columns wide)
    ax3 = nexttile(tile,2*numTrials*imgRows+2*i-1,[plotRows, 2]); 
    
    plot(TCS_points, Physical_CV_MAE, 'bo-', 'LineWidth', plotLineWidth, 'MarkerFaceColor', 'b');
    hold on;
    plot(TCS_points, MAE_n_star, 'ko-', 'LineWidth', plotLineWidth, 'MarkerFaceColor', 'k');
    plot(TCS_points_ver, Verification_CV_MAE, 'go-', 'LineWidth', plotLineWidth, 'MarkerFaceColor', 'g');
    
    % Stopping Criteria Line
    label_stop = [];%'$n^*$';
    xline(max_TCS_points, '--r', label_stop, 'LineWidth', plotLineWidth, 'FontSize', axisFontSize-1, 'Interpreter', 'latex');
    
    % New (Minimum) Criteria Line
    label_min = [];%"$n_{min}$";
    xline(idx_min, '--m', label_min, 'LineWidth', plotLineWidth, 'FontSize', axisFontSize-1, 'Interpreter', 'latex');
    
    hold off; 
    
    % --- Axis Formatting ---
    xlim([0, max_TCS_points + 5]);
    ylim([1e-3,1e0])
    yscale('log')

    % Y-Axis Label
    if i==1
    ylabel('Mean Absolute Error, mm', 'FontSize', axisFontSize, 'Interpreter', 'tex');
    else
    yticklabels([])
    end

    % Legend
    if i==1
    l = legend({'Physical CV MAE','MAE n*', 'Verification CV MAE'}, ...
        'Location', 'southoutside', 'FontSize', legendFontSize,...
        'Interpreter', 'tex','Orientation','horizontal','Color','red');
    l.Layout.Tile = 'south';
    end

    grid on;
    
    axis(ax3)
    set(gca, 'FontSize', axisFontSize); 
    set(gca, 'TickLabelInterpreter', 'tex');
    
    % --- Custom X-Ticks and Labels ---
    set(gca, 'XTick', 0:5:max_TCS_points);
    
    current_xticks = get(gca, 'XTick');
    valid_mask = current_xticks > 0 & ...
                 current_xticks <= length(All_t) & ...
                 floor(current_xticks) == current_xticks;
    final_xticks = current_xticks(valid_mask);
    
    % Hide default XTickLabels
    set(gca, 'XTickLabel', []);
    
    % Draw Manual Text Labels for Ticks
    y_limits = ylim;
    y_range = log10(y_limits(2)) - log10(y_limits(1));
    y_tick_pos = 10^(log10(y_limits(1)) - (y_range * 0.02)); 
    
    for k = 1:length(final_xticks)
        idx = final_xticks(k);
        time_val = All_t(idx); 
        
        % Top: n value. Bottom: time value (italicized), removed 'min' text.
        str_content = {num2str(idx), ['\it ' num2str(time_val, '%.0f')]};
        
        text(idx, y_tick_pos, str_content, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ...
            'FontSize', axisFontSize, ...
            'Interpreter', 'tex', ...
            'Clipping', 'off'); 
    end
    
    % --- X-Axis Main Labels (Double Stacked) ---
    x_center = mean(xlim);
    y_label_pos = 10^(log10(y_limits(1)) - (y_range * 0.3)); 
    
    % Only the word "min" is italicized
    text(x_center, y_label_pos, {'Number of Points, \itn'; 'Time Elapsed (min)'}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontSize', axisFontSize, ...
        'FontWeight', 'normal', ...
        'Interpreter', 'tex', ...
        'Clipping', 'off'); 

    % --- Connecting Lines ---
    drawnow; 
    
    posImg1 = get(ax1, 'Position'); 
    posImg2 = get(ax2, 'Position'); 
    posPlot = get(ax3, 'Position'); 
    
    img1_CenterX = posImg1(1) + posImg1(3)/2;
    img1_BottomY = posImg1(2);
    
    img2_CenterX = posImg2(1) + posImg2(3)/2;
    img2_BottomY = posImg2(2);
    
    valTarget1 = idx_min;
    valTarget2 = max_TCS_points;
    
    xLimits = xlim(ax3);
    dataRange = xLimits(2) - xLimits(1);
    
    target1_NormX = posPlot(1) + ((valTarget1 - xLimits(1)) / dataRange) * posPlot(3);
    target2_NormX = posPlot(1) + ((valTarget2 - xLimits(1)) / dataRange) * posPlot(3);
    
    plotTopY = posPlot(2) + posPlot(4); 
    midY = (img1_BottomY + plotTopY) / 2;

    target1_NormX = max(0, min(1, target1_NormX));
    target2_NormX = max(0, min(1, target2_NormX));
    midY = max(0, min(1, midY));
    
    annotation('line', [img1_CenterX, img1_CenterX], [img1_BottomY, midY], 'Color', 'm', 'LineWidth', connectLineWidth);
    annotation('line', [img1_CenterX, target1_NormX], [midY, midY], 'Color', 'm', 'LineWidth', connectLineWidth);
    annotation('line', [target1_NormX, target1_NormX], [midY, plotTopY], 'Color', 'm', 'LineWidth', connectLineWidth);
    
    annotation('line', [img2_CenterX, img2_CenterX], [img2_BottomY, midY], 'Color', 'r', 'LineWidth', connectLineWidth);
    annotation('line', [img2_CenterX, target2_NormX], [midY, midY], 'Color', 'r', 'LineWidth', connectLineWidth);
    annotation('line', [target2_NormX, target2_NormX], [midY, plotTopY], 'Color', 'r', 'LineWidth', connectLineWidth);

end

% --- SAVE FIGURE ---
savefig(f,'Figure9.fig')
exportgraphics(f,'Figure9.png','Resolution',600);
exportgraphics(f,'Figure9.eps','ContentType','vector')

% 4. Final Cleanup (Smart Close)
% Find all open figures
allFigs = findall(0, 'Type', 'figure');

% Identify figures that are NOT in the 'figsToKeep' list
unwantedFigs = setdiff(allFigs, figsToKeep);

% Force close any unwanted figures
if ~isempty(unwantedFigs)
    close(unwantedFigs, 'force');
end