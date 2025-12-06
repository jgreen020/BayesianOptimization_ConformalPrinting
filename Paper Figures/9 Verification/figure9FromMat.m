close all; clear; clc;

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

%% Figure 9
for i = 1:size(physicalStudyMethod2Trials, 2)
    
    % --- Physical Study ---
    load(physicalStudyMethod2Trials{i});
    Physical_CV_MAE = modelPerformance.CV.MAE;
    
    % Physical Study CV_MAE
    first_zero_index = find(Physical_CV_MAE == 0, 1, 'first');
    if ~isempty(first_zero_index)
        last_index_to_keep = first_zero_index - 1;          
        Physical_CV_MAE = Physical_CV_MAE(1:last_index_to_keep);
    end
   
    % Minimum TCS Points
    num_elements = length(Physical_CV_MAE);
    index_vector = 0 : (num_elements - 1);
    TCS_points = n + index_vector + 1;
    TCS_points = TCS_points'; 

    % MAE relative to n^*
    zBp_all = zBp_all(n:iter);
    reference_matrix = zBp_all{end};
    absolute_error_matrices_adv = cellfun(@(x) abs(reference_matrix - x), zBp_all, 'UniformOutput', false);
    MAE_n_star = cellfun(@(x) mean(x, 'all'), absolute_error_matrices_adv);
    
    % Time taken for physical study
    TCS_t = t;
    TCS_t = TCS_t(n:end);
    load(initial_sampling_time{i}, 't');
    initial_sampling_t = t;
    TCS_t = TCS_t + initial_sampling_t(end);
    All_t = vertcat(initial_sampling_t, TCS_t);
    All_t = All_t/60;


    % --- Verification Study ---
    load(verificationStudyMethod2Trials{i});
    Verification_CV_MAE = modelPerformance.CV.MAE;
    
    % 1. Clean Verification Data
    v_zero_idx = find(Verification_CV_MAE == 0, 1, 'first');
    if ~isempty(v_zero_idx)
        Verification_CV_MAE = Verification_CV_MAE(1:v_zero_idx-1);
    end

    % 2. Create matching X-axis for Verification
    TCS_points_ver = TCS_points(1:length(Verification_CV_MAE));


    % --- Plotting ---
    figure; 
    Fontsize = 16;
    
    plot(TCS_points, Physical_CV_MAE, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
    hold on;
    plot(TCS_points, MAE_n_star, 'ko-', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
    plot(TCS_points_ver, Verification_CV_MAE, 'go-', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
    
    % - Vertical Lines -
    max_TCS_points = max(TCS_points);
    
    % Stopping Criteria Line
    time_stop = All_t(max_TCS_points);
    label_stop = sprintf('Stopping Criteria\\newline(n=%d, t=%.0fminutes)', max_TCS_points, time_stop);
    xline(max_TCS_points, '--r', label_stop, 'LineWidth', 1.5, 'FontSize', 11);
    
    % New (Minimum) Criteria Line
    idx_min = minimum_TCS_points{i};
    time_min = All_t(idx_min);
    label_min = sprintf('New\\newline(n=%d, t=%.0fminutes)', idx_min, time_min);
    xline(idx_min, '--m', label_min, 'LineWidth', 1.5, 'FontSize', 11);
    
    hold off; 
    
    % - Axis and Label Formatting -
    xlim([0, max_TCS_points + 5]);
    set(gca, 'XTick', 0:5:max_TCS_points);
    set(gca, 'FontSize', 12); 
    title('MAE CV Data for Surf1', 'FontSize', Fontsize);
    grid on;
    legend('Physical CV MAE','MAE n*', 'Verification CV MAE', 'Location', 'northwest', 'FontSize', Fontsize);
   
    % Set the Tick Label Interpreter to LaTeX
    set(gca, 'TickLabelInterpreter', 'latex');
    
    % Get and filter current ticks
    current_ticks = get(gca, 'XTick');
    valid_mask = current_ticks > 0 & ...
                 current_ticks <= length(All_t) & ...
                 floor(current_ticks) == current_ticks;
    final_ticks = current_ticks(valid_mask);
    
    % Create centered LaTeX labels with Sans-Serif font (\sffamily)
    new_labels = cell(length(final_ticks), 1);
    for k = 1:length(final_ticks)
        idx = final_ticks(k);
        time_val = All_t(idx); 
        % Added \sffamily to both lines to match MATLAB's default font style
        new_labels{k} = sprintf('\\begin{tabular}{c} \\sffamily %d \\\\ \\sffamily \\textit{%.0fmin} \\end{tabular}', idx, time_val);
    end
    
    % Apply the new ticks and labels
    set(gca, 'XTick', final_ticks);
    set(gca, 'XTickLabel', new_labels);
    
    % Adjust X-Label position
    xl = xlabel('Number of Points (n)', 'FontSize', Fontsize);
    set(xl, 'Units', 'Normalized'); 
    pos = get(xl, 'Position');
    pos(2) = pos(2) - 0.08; 
    set(xl, 'Position', pos);
    set(xl, 'Units', 'data'); 
end

