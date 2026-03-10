%% Figure 6: Automated plotting for all simulation trials
close all; clear; clc;

% --- Configuration ---
% --- List of all trial filenames from your simulation study ---
addpath(genpath(fullfile(pwd)));
addpath(genpath(fullfile(pwd)))
basepath = "Data/Results/20250423_SimStudy4/";
dirnames = dir(basepath+"*sim*");
trial_filenames = {dirnames.name};

%% --- Master Loop for All Trials ---
for k = 1:numel(trial_filenames)
    current_trial = trial_filenames{k};
    fprintf('Processing trial: %s\n', current_trial);
    
    % --- Load the .mat file for the current trial ---
    load([current_trial, '.mat']);
    
    % --- Start of Plotting Logic for a Single Trial ---
    fig = figure('Visible', 'off'); % Create a new, invisible figure for each trial

    % Define the number of testpoints for each column of the figure
    if method == 1 && contains(SurfB, "Surf1")
        testpoint_counts = [3, 4, 5, 6, 15];
    elseif method == 1 && contains(SurfB, "Surf2")
        testpoint_counts = [3, 8, 9, 10, 15];
    elseif method == 1 && contains(SurfB, "Surf3")
        testpoint_counts = [3, 11, 12, 13, 15]; 
    elseif (method == 2 || method == 3) && contains(SurfB, "Surf1")
        testpoint_counts = [10, 14, 15, 16, 225];
    elseif (method == 2 || method == 3) && contains(SurfB, "Surf2")
        testpoint_counts = [20, 40, 50, 60, 225];
    elseif (method == 2 || method == 3) && contains(SurfB, "Surf3")
        testpoint_counts = [40, 60, 70, 80, 225];
    end
    
    set(fig, 'Position',  [100, 100, 850, 350]);
    
    original_testpoints = testpoints;
    original_mask = mask;
    
    ax = gobjects(3, numel(testpoint_counts));
    
    % --- Inner Loop for Plotting Columns ---
    for j = 1:numel(testpoint_counts)
        num_points = testpoint_counts(j);
        
        zBp = zBp_all{num_points};
        plotabsError = abs(zB - zBp);
        
        current_testpoints = original_testpoints(1:num_points, :);
        current_mask = original_mask(1:num_points);

        % Plot 1 (Top Row)
        row = 1;
        ax(row, j) = subplot(3, 5, (row-1)*5 + j);
        hold(ax(row, j), 'on');
        surf(xBp, yBp, zBp, plotabsError, 'LineStyle', 'none');
        axis(ax(row, j), 'equal', [-30 30 -30 30 -1 20]);
        view(ax(row, j), 3);
        clim(ax(row, j), [0 0.165]);
        colormap(ax(row, j), 'viridis');
        if method == 1
            title(ax(row, j), sprintf('n = %d', num_points^2));
        else
            title(ax(row, j), sprintf('n = %d', num_points));
        end
        if j == 1
            zlabel(ax(row, j), 'z (mm)');
        else
            zticklabels([])
        end
        xticklabels([])
        yticklabels([])

        % Plot 2 (Middle Row)
        row = 2;
        ax(row, j) = subplot(3, 5, (row-1)*5 + j);
        hold(ax(row, j), 'on');
        surf(xBp, yBp, zBp, plotabsError, 'LineStyle', 'none');
        if method == 1
            grid_dim = num_points;
            [X_grid, Y_grid] = meshgrid(linspace(x_min, x_max, grid_dim), linspace(y_min, y_max, grid_dim));
            Z_grid_constant = ones(size(X_grid)) * 30; 
            plot3(ax(row, j), X_grid(:), Y_grid(:), Z_grid_constant(:), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 5, 'MarkerEdgeColor', 'red');
        elseif method == 2 || method == 3
            plot3(ax(row, j), current_testpoints(current_mask,1), current_testpoints(current_mask,2), current_testpoints(current_mask,3), 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 5, 'MarkerEdgeColor', 'red');
        end
        axis(ax(row, j), 'equal', [-30 30 -30 30 -1 35]);
        view(ax(row, j), 2);
        clim(ax(row, j), [0 0.165]);
        colormap(ax(row, j), 'viridis');
        if j == 1
            ylabel(ax(row, j), 'y (mm)');
        else
            yticklabels([])
        end
        xticklabels([])

        % Plot 3 (Bottom Row)
        row = 3;
        ax(row, j) = subplot(3, 5, (row-1)*5 + j);
        hold(ax(row, j), 'on');
        if method == 1
            [u_c, v_c] = Curve(linspace(0, 1, res_c+1)');
            
            P_o1 = bezMdls{num_points};
            wypts1 = zeros(length(u_c), 3);
            for a = 1:length(u_c)
                wypts1(a, :) = bezierSurf(u_c(a), v_c(a), P_o1);
            end
            x_c1 = wypts1(:, 1); y_c1 = wypts1(:, 2); z_c1 = wypts1(:, 3);

            P_o2 = bezMdls{15};
            wypts2 = zeros(length(u_c), 3);
            for b = 1:length(u_c)
                wypts2(b, :) = bezierSurf(u_c(b), v_c(b), P_o2);
            end
            x_c2 = wypts2(:, 1); y_c2 = wypts2(:, 2); z_c2 = wypts2(:, 3);

            delta_z = z_c1 - z_c2;
        elseif method == 2 || method == 3
            gprMdl = gprMdls{num_points};
            curve_coords = table2array(curve_pts);
            x_c = curve_coords(:, 1); y_c = curve_coords(:, 2);
            curve_pts_table = table(x_c, y_c, 'VariableNames', {'x', 'y'});
            [z_c, ~, ~] = predict(gprMdl, curve_pts_table);
            gprMdl_reference = gprMdls{225};
            [zB_under_curve, ~, ~] = predict(gprMdl_reference, curve_pts_table);
            delta_z = z_c - zB_under_curve;
        end
        is_green = (abs(delta_z) <= 0.33);
        run_starts = [1; find(diff(is_green)) + 1];
        run_ends = [find(diff(is_green)); length(is_green)];
        for i = 1:length(run_starts)
            segment = run_starts(i):run_ends(i);
            if is_green(run_starts(i))
                plot3(ax(row, j), x_c(segment), y_c(segment), z_c(segment), 'Color', '#0072B2', 'LineWidth', 2);
            else
                plot3(ax(row, j), x_c(segment), y_c(segment), z_c(segment), 'Color', '#D55E00', 'LineWidth', 2);
            end
        end
        axis(ax(row, j), 'equal', [-30+pad 30-pad -30+pad 30-pad]);
        view(ax(row, j), 2);
        if j == 1
            ylabel(ax(row, j), 'y (mm)');
        else
            yticklabels([])
        end
        xlabel(ax(row, j), 'x (mm)');
    end
    
    % --- Final Layout for the Current Figure ---
    uniform_colorbar_width = 0.015;
    horizontal_gap = 0.01;        
    pos1 = get(ax(1,5), 'Position'); 
    pos2 = get(ax(2,5), 'Position'); 
    uniform_colorbar_left = pos1(1) + pos1(3) + horizontal_gap; 
    cb1 = colorbar(ax(1,5)); 
    cb1.Label.String = 'Absolute Error (mm)';
    cb1_height = (pos1(2) + pos1(4)) - pos2(2); 
    cb1.Position = [uniform_colorbar_left, pos2(2), uniform_colorbar_width, cb1_height];
    pos3 = get(ax(3,5), 'Position'); 
    c_ax = axes('Position', [uniform_colorbar_left, pos3(2), uniform_colorbar_width, pos3(4)], 'Visible', 'off');
    colormap(c_ax, [0.8353 0.3686 0; 0 0.4471 0.6980]); 
    cb2 = colorbar(c_ax);
    cb2.Label.String = 'Curve Condition';
    cb2.Ticks = [0.25, 0.75];
    cb2.TickLabels = {'Bad', 'Good'};
    cb2.Position = [uniform_colorbar_left, pos3(2), uniform_colorbar_width, pos3(4)];
    uniform_font_size = 10; 
    all_axes = findall(fig, 'type', 'axes');
    set(all_axes, 'FontSize', uniform_font_size);
    set(cb1, 'FontSize', uniform_font_size);
    set(cb2, 'FontSize', uniform_font_size);
    
    % --- SAVE FIGURES (Updated Method) ---
    % 1. Save as MATLAB Figure (.fig)
    saveas(fig, basepath+current_trial+'/'+current_trial+'_progression.fig');

    % 2. Save as PNG (Raster)
    exportgraphics(fig, basepath+current_trial+'/'+current_trial+'_progression.png', 'Resolution', 300);

    % 3. Save as EPS (Vector)
    % exportgraphics(fig, basepath+current_trial+'/'+current_trial+'_progression.eps', 'ContentType','vector');

    fprintf('Saved: %s (.fig, .png, .eps)\n', current_trial);

    close(fig); % Close the figure to free up memory
end

fprintf('All trials have been processed and saved.\n');

%% --- Just Paper Figure 6 ---
close all
trial_filenames = {'20250423_194156_Surf2b_M1_sim',...
    '20250423_202116_Surf2b_M2_LCB_exp_sim',...
    '20250423_205721_Surf2a_Surf2b_M3_LCB_exp_sim'};
figures_filenames = basepath + trial_filenames + "/" + trial_filenames + "_progression.fig";
new_filenames = {'Surf2b_M1_sim', 'Surf2b_M2_sim','Surf2b_M3_sim'};
new_path = "Paper Figures/6 Method Comparison/";
fig_new = figure('Units','inches',"Position",[0 0 6 11.5]);
t = tiledlayout(fig_new,3,1,'TileSpacing','compact','Padding','tight');
for k = 1:numel(trial_filenames)
    fig_old = openfig(figures_filenames{k});
    set(fig_old, 'Visible', 'on')
    axesHandles = findobj(fig_old, 'Type', 'axes');
    t0 = tiledlayout(t,3,1,'TileSpacing','compact','Padding','tight');
    t0.Layout.Tile = k;
    t1 = tiledlayout(t0,2,5,'TileSpacing','compact','Padding','tight');
    t1.Layout.Tile = 1;
    t1.Layout.TileSpan = [2 1];
    t2 = tiledlayout(t0,1,5,'TileSpacing','compact','Padding','tight');
    t2.Layout.Tile = 3;
    axesOrder = reshape(reshape(flip(1:15),5,3)',[],1);
    for i=2:length(axesHandles)
        if axesOrder(i-1) <= 10
            axesHandles(i).Parent = t1;
            axesHandles(i).Layout.Tile = axesOrder(i-1);
        else
            axesHandles(i).Parent = t2;
            axesHandles(i).Layout.Tile = axesOrder(i-1)-10;
        end
    end
    close(fig_old)
    cbar = findobj(t1, 'Type', 'colorbar');
    cbar.Layout.Tile = 'east';
    fontsize(fig_new, 12,'points')
    tile = nexttile(t2,5);
    colormap(tile,[0.8353 0.3686 0; 0 0.4471 0.6980]); 
    cb2 = colorbar(tile);
    % cb2.Label.String = 'Curve Condition';
    cb2.Ticks = [0.25, 0.75];
    cb2.TickLabels = {'AE>\alpha', 'AE<\alpha'};
    cb2.Layout.Tile = 'east';
end

for k = 1:3
    tiles = flip(t.Children);
    title(tiles(k),"M"+string(k),'fontsize', 20, 'fontweight','bold')
end

saveas(fig_new,new_path+"Figure6.fig");
exportgraphics(fig_new,new_path+"Figure6.png", 'Resolution', 300);
exportgraphics(fig_new,new_path+"Figure6.eps", 'ContentType','vector');