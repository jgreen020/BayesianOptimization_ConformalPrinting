%% 
close all; clear; clc;

% --- 1. Define the .fig files to process ---
filenames = {
    '20250515_192421_Surf1b_M2_LCB_exp_real.fig';
    '20250516_174734_Surf2b_M2_LCB_exp_real.fig';
    '20250923_172121_Surf3b_M2_LCB_exp_real.fig'
    };

% --- 2. Define the names for our final data structure ---
output_names = {
    'Surf1';
    'Surf2';
    'Surf3'
    };

% --- 3. Initialize a main structure to hold all results ---
all_data = struct();

% --- 4. Loop through each filename and process it ---
fprintf('Starting data extraction process...\n');
disp('------------------------------------');

for i = 1:length(filenames)
    current_file = filenames{i};
    current_output_name = output_names{i};
    
    fprintf('Processing file: %s\n', current_file);
    
    % Call our helper function to do the extraction
    data_from_file = extractDataFromSixthFig(current_file);
    
    % Store the returned data structure into our main structure
    if ~isempty(fieldnames(data_from_file))
        all_data.(current_output_name) = data_from_file;
        fprintf(' -> Successfully extracted and stored data for "%s".\n\n', current_output_name);
    else
        fprintf(' -> No data was extracted from "%s".\n\n', current_file);
    end
end

disp('------------------------------------');
disp('Data extraction for all files is complete.');


%%
% --- 1. PREPARATION ---
all_data_truncated = all_data;

fprintf('Starting truncation process for all extracted data...\n');
disp('----------------------------------------------------');

% --- 2. AUTOMATED TRUNCATION LOOP ---

% Get the names of the top-level fields (e.g., 'Surf1b', 'Surf2b', etc.)
file_fields = fieldnames(all_data);

% --- Outer Loop: Iterate through each file's data ---
for i = 1:length(file_fields)
    current_file_field = file_fields{i};
    
    % Get the names of the metric fields inside the current file's data
    metric_fields = fieldnames(all_data.(current_file_field));
    
    fprintf('Processing data for: %s\n', current_file_field);
    
    % --- Inner Loop: Iterate through each metric (line) ---
    for j = 1:length(metric_fields)
        current_metric_field = metric_fields{j};
        
        % Get the YData for the current metric
        YData_original = all_data.(current_file_field).(current_metric_field).YData;
        XData_original = all_data.(current_file_field).(current_metric_field).XData;
        
        % Find the index of the first zero in the YData
        first_zero_index = find(YData_original == 0, 1, 'first');
        
        % If a zero was found, perform the truncation
        if ~isempty(first_zero_index)
            % Determine the last index to keep (the element before the zero)
            last_index_to_keep = first_zero_index - 1;
            
            % Truncate both X and Y data arrays
            XData_new = XData_original(1:last_index_to_keep);
            YData_new = YData_original(1:last_index_to_keep);
            
            % Update the data in our NEW structure
            all_data_truncated.(current_file_field).(current_metric_field).XData = XData_new;
            all_data_truncated.(current_file_field).(current_metric_field).YData = YData_new;
            
            fprintf(' -> [%s] truncated from %d to %d points.\n', ...
                    current_metric_field, length(YData_original), length(YData_new));
        else
            % If no zero is found, we don't need to do anything,
            % as the original data is already in 'all_data_truncated'.
            fprintf(' -> [%s] has no zero entries, not truncated.\n', current_metric_field);
        end
    end
    fprintf('\n'); % Add a space for readability
end

% --- 3. FINALIZATION ---
disp('----------------------------------------------------');
disp('Truncation process complete.');
disp('The new, cleaned data is stored in the "all_data_truncated" structure.');

% Display the new structure to verify
disp(all_data_truncated);

%%
% --- PLOT 1: Data from Surf1 ---
figure; % Creates the first new figure window
set(gcf, 'Position', [100, 100, 1200, 600]); % Set figure size and position

% Extract data for clarity
x1 = all_data_truncated.Surf1.MAE__CV_.XData;
y1 = all_data_truncated.Surf1.MAE__CV_.YData;

% Plot using semilogy for an automatic log-scale y-axis
semilogy(x1, y1, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on; % Keep the plot active to add the line

% --- Add the vertical line ---
% Find the largest value in the x-data
maxX1 = max(x1); 
% Draw a dashed red vertical line at that x-position
xline(maxX1, '--r', 'Stopping Critiria', 'LineWidth', 1.5);
xline(14, '--g', 'New', 'LineWidth', 1.5);

hold off; % Release the plot

xlim([0, maxX1 + 5]);
% Add labels and title
title('MAE CV Data for Surf1');
xlabel('Number of Points (n)');
ylabel('Mean Absolute Error (log scale)');
grid on;
legend('MAE_CV', location='northwest');


% --- PLOT 2: Data from Surf2 ---
figure; % Creates the second new figure window
set(gcf, 'Position', [100, 800, 1200, 600]); % Set figure size and position

% Extract data
x2 = all_data_truncated.Surf2.MAE__CV_.XData;
y2 = all_data_truncated.Surf2.MAE__CV_.YData;

% Plot using semilogy
semilogy(x2, y2, 'bs-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on; % Keep the plot active to add the line

% --- Add the vertical line ---
% Find the largest value in the x-data
maxX2 = max(x2); 
% Draw a dashed red vertical line at that x-position
xline(maxX2, '--r', 'Stopping Critiria', 'LineWidth', 1.5);
xline(29, '--g', 'New', 'LineWidth', 1.5);

hold off; % Release the plot

xlim([0, maxX2 + 5]);
% Add labels and title
title('MAE CV Data for Surf2');
xlabel('Number of Points (n)');
ylabel('Mean Absolute Error (log scale)');
grid on;
legend('MAE_CV', location='northwest');


% --- PLOT 3: Data from Surf3 ---
figure; % Creates the third new figure window
set(gcf, 'Position', [100, 1500, 1200, 600]); % Set figure size and position

% Extract data
x3 = all_data_truncated.Surf3.MAE__CV_.XData;
y3 = all_data_truncated.Surf3.MAE__CV_.YData;

% Plot using semilogy
semilogy(x3, y3, 'bd-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on; % Keep the plot active to add the line

% --- Add the vertical line ---
% Find the largest value in the x-data
maxX3 = max(x3); 
% Draw a dashed red vertical line at that x-position
xline(maxX3, '--r', 'Stopping Critiria', 'LineWidth', 1.5);
xline(59, '--g', 'New', 'LineWidth', 1.5);

hold off; % Release the plot

xlim([0, maxX3 + 5]);
% Add labels and title
title('MAE CV Data for Surf3');
xlabel('Number of Points (n)');
ylabel('Mean Absolute Error (log scale)');
grid on;
legend('MAE_CV', location='northwest');

disp('Three figures have been generated.');

%% new lowest number of point
% surf1b  4 + 10 initial
% surf2b  9 + 20 initial
% surf3b 19 + 40 initial

%mae n* to past n's

%hypothises
%would like to see quility degridation of print at retroactive minimal
%wouls have to make trade off of time and print quility

%surf2 print on retroative minimal, if verify hypothieses do other surfaces, if not, do more on surf 2

% t stores time
% t initial samples is
% t main starts at last initial sample, tic starts when code is run

% total time, averge time to collect point
% every plot has total money cost on every time tick and printed surf n