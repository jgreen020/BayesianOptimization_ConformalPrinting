close all; clear; clc;

% --- 1. Configuration & Data Definition ---
batches = struct('init', {}, 'trials', {});

% Batch 1: Surf1b
batches(1).init = 'TCS_t2_Surf1b_n10';
batches(1).trials = {
    '20250515_225518_Surf1b_M1_real.mat', ...
    '20250515_192421_Surf1b_M2_LCB_exp_real.mat', ...
    '20250515_205608_Surf1a_Surf1b_M3_LCB_exp_real.mat'};

% Batch 2: Surf2b
batches(2).init = 'TCS_t2_Surf2b_n20';
batches(2).trials = {
    '20250517_001949_Surf2b_M1_real.mat', ...
    '20250516_174734_Surf2b_M2_LCB_exp_real.mat', ...
    '20250516_220758_Surf2a_Surf2b_M3_LCB_exp_real.mat'};

% Batch 3: Surf3b
batches(3).init = 'TCS_t2_Surf3b_n40';
batches(3).trials = {
    '20250923_213409_Surf3b_M1_real.mat', ...
    '20250923_172121_Surf3b_M2_LCB_exp_real.mat', ...
    '20250923_184535_Surf3a_Surf3b_M3_LCB_exp_real.mat'};

% Batch 4: Verification
batches(4).init = '';
batches(4).trials = {
    '20251122_013740_Surf1b_M2_LCB_exp_real', ...
    '20251121_171838_Surf2b_M2_LCB_exp_real', ...
    '20251121_231322_Surf3b_M2_LCB_exp_real'};

% --- 2. Data Processing ---
delta_accumulator = {};

for i = 1:length(batches)
    % Process Initial File
    if ~isempty(batches(i).init)
        dt = extract_deltas(batches(i).init);
        if ~isempty(dt), delta_accumulator{end+1} = dt; end
    end
    
    % Process Trial Files
    for j = 1:length(batches(i).trials)
        dt = extract_deltas(batches(i).trials{j});
        if ~isempty(dt), delta_accumulator{end+1} = dt; end
    end
end

% Flatten to master list
all_time_steps = vertcat(delta_accumulator{:});

% --- 3. Statistics & Reporting ---
if isempty(all_time_steps)
    error('No valid time data was processed.');
end

mean_dt = mean(all_time_steps);
med_dt  = median(all_time_steps);
std_dt  = std(all_time_steps);

fprintf('================================================\n');
fprintf('DATA ANALYSIS REPORT\n');
fprintf('================================================\n');
fprintf('Files Processed:      %d batches\n', length(batches));
fprintf('Total Time Steps:     %d\n', length(all_time_steps));
fprintf('------------------------------------------------\n');
fprintf('Std Dev:              %.6f s\n', std_dt);
fprintf('Min / Max Delta t:    %.6f s / %.6f s\n', min(all_time_steps), max(all_time_steps));
fprintf('================================================\n');

% --- 4. Visualization ---
close('all','force')
figure('Name', 'Sampling Interval Analysis', 'Color', 'w');

% CHANGED: 'BinWidth', 10 sets the exact width of each bar on the x-axis to 10 units.
histogram(all_time_steps, 'BinWidth', 2.5, 'EdgeColor', 'k');

grid on;
title(['Distribution of Time Steps (\Delta t) | Median: ' num2str(med_dt, '%.5f') 's']);
xlabel('Time Difference (seconds)');
ylabel('Frequency (Count)');
subtitle(sprintf('N = %d samples', length(all_time_steps)));

line([mean_dt mean_dt], [0 25])
line([med_dt med_dt], [0 25])
% -------------------------------------------------------------------------
% LOCAL HELPER FUNCTIONS
% -------------------------------------------------------------------------

function dt = extract_deltas(filename)
    % EXTRACT_DELTAS Loads a file, handles 'n' truncation, and returns diff(t).
    dt = [];
    
    % Robust file checking
    if exist(filename, 'file') ~= 2
        if exist([filename '.mat'], 'file') == 2
            filename = [filename '.mat'];
        else
            warning('File not found: %s', filename);
            return;
        end
    end
    
    data = load(filename);
    
    if ~isfield(data, 't')
        warning('Variable ''t'' missing in %s', filename);
        return;
    end
    
    t_vec = data.t;
    
    % Apply 'n' truncation
    if isfield(data, 'n')
        if data.n > 0 && data.n <= length(t_vec)
            t_vec = t_vec(data.n:end);
        end
    end
    
    % Calculate time steps within this vector only
    dt = diff(t_vec);
end