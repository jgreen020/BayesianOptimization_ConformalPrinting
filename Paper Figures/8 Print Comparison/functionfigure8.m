function functionfigure8(trial_files, complete_data_files, image_files, figure_name, fontSize)
    % Creates a 3x3 figure and saves it as both PNG and EPS.
    
    fig8 = figure('Name', figure_name, 'Visible', 'on', 'Units', 'pixels', 'Position', [100, 100, 850, 800]);
    
    % --- Manual Layout Calculation ---
    left_margin = 0.025; right_margin = 0.125; bottom_margin = 0.05;
    top_margin = 0.03; h_spacing = 0.0; v_spacing = 0.1; 
    row_height_ratios = [0.28, 0.28, 0.44];
    total_plot_width = 1 - left_margin - right_margin - 2*h_spacing;
    subplot_width = total_plot_width / 3;
    total_plot_height = 1 - bottom_margin - top_margin - 2*v_spacing;
    subplot_heights = total_plot_height * row_height_ratios;
    pos_bottom(3) = bottom_margin;
    pos_bottom(2) = pos_bottom(3) + subplot_heights(3) + v_spacing;
    pos_bottom(1) = pos_bottom(2) + subplot_heights(2) + v_spacing;
    pos_left(1) = left_margin;
    pos_left(2) = pos_left(1) + subplot_width + h_spacing;
    pos_left(3) = pos_left(2) + subplot_width + h_spacing;
    ax_handles = gobjects(3, 3);
    for row = 1:3
        for col = 1:3
            ax_pos = [pos_left(col), pos_bottom(row), subplot_width, subplot_heights(row)];
            ax_handles(row, col) = axes('Position', ax_pos);
        end
    end
    % --- ROW 1: Surface Plots ---
    for k = 1:3
        ax = ax_handles(1, k);
        load(trial_files{k});
        hold(ax, 'on');
        
        surf(ax, xBp, yBp, zBp, plotabsError, 'LineStyle', 'none');
        plot3(ax, testpoints(:,1),testpoints(:,2),testpoints(:,3) + 5, 'r.', 'MarkerSize', 5);
        
        title(ax, sprintf('Method %d', k), 'FontSize', fontSize);
        set(ax, 'FontSize', fontSize);
        
        axis(ax, [-30 30 -30 30]);
        axis(ax, 'square');
        set(ax, 'XTick', -30:15:30);
        set(ax, 'YTick', -30:15:30);
        
        view(ax, 2);
        clim(ax, [0 0.165]);
        colormap(ax, 'viridis');
    end
    % --- ROW 2: Curve Plots ---
    for k = 1:3
        ax = ax_handles(2, k);
        load(trial_files{k});
        hold(ax, 'on');
        num_points = size(testpoints, 1);
        
        set(ax, 'FontSize', fontSize);
        if method == 1
            [u_c1, v_c1] = Curve(linspace(0, 1, res_c+1)'); P_o = bezMdls{sqrt(num_points)};
            wypts1=zeros(length(u_c1),3); for a=1:length(u_c1), wypts1(a,:)=bezierSurf(u_c1(a),v_c1(a),P_o); end
            load(complete_data_files{k}, 'bezMdls'); P_o15 = bezMdls{15};
            wypts2=zeros(length(u_c1),3); for b=1:length(u_c1), wypts2(b,:)=bezierSurf(u_c1(b),v_c1(b),P_o15); end
            delta_z = wypts1(:, 3) - wypts2(:, 3); x_c = wypts1(:, 1); y_c = wypts1(:, 2); z_c = wypts1(:, 3);
        else
            gprMdl = gprMdls{num_points - 1};
            curve_coords=table2array(curve_pts); x_c=curve_coords(:,1); y_c=curve_coords(:,2);
            curve_pts_table=table(x_c,y_c,'VariableNames',{'x','y'}); z_c=predict(gprMdl,curve_pts_table);
            load(complete_data_files{k},'gprMdls'); gprMdl_reference=gprMdls{225};
            zB_under_curve=predict(gprMdl_reference,curve_pts_table); delta_z=z_c-zB_under_curve;
        end
        
        is_green = (abs(delta_z) <= 0.33);
        run_starts = [1; find(diff(is_green)) + 1]; run_ends = [find(diff(is_green)); length(is_green)];
        for i = 1:length(run_starts)
            segment = run_starts(i):run_ends(i);
            if is_green(run_starts(i)), color = 'g'; else, color = 'r'; end
            plot3(ax, x_c(segment), y_c(segment), z_c(segment), color, 'LineWidth', 2);
        end
        
        axis(ax, [-30 30 -30 30]);
        axis(ax, 'square');
        set(ax, 'XTick', -30:15:30);
        set(ax, 'YTick', -30:15:30);
        
        view(ax, 2);
    end
    % --- ROW 3: Image Plots ---
    for k = 1:3
        ax = ax_handles(3, k);
        try
            imshow(imread(image_files{k}), 'Parent', ax);
        catch ME
            text(0.5, 0.5, 'Image not found', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', fontSize);
            warning('Could not read image file: %s. Error: %s', image_files{k}, ME.message);
        end
    end
    % --- ALIGNED ROW LABELS ---
    label_ax = axes('Position', [0 0 1 1], 'Visible', 'off');
    y_pos1 = pos_bottom(1) + subplot_heights(1)/2;
    y_pos2 = pos_bottom(2) + subplot_heights(2)/2;
    y_pos3 = pos_bottom(3) + subplot_heights(3)/2;
    x_pos = left_margin - 0.0;
    
    name_parts = strsplit(figure_name, ' - ');
    raw_surface_label = name_parts{2}; 
    surface_label = regexprep(raw_surface_label, 'surf', 'Surface', 'ignorecase'); 
    
    text(label_ax, x_pos, y_pos1, surface_label, 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    text(label_ax, x_pos, y_pos2, 'Curve', 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    text(label_ax, x_pos, y_pos3, 'Print', 'Rotation', 90, 'FontSize', fontSize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % --- COLORBARS ---
    cb1 = colorbar(ax_handles(1,3));
    cb1.Label.String = 'Absolute Error';
    cb1.Label.FontSize = fontSize;
    cb1.FontSize = fontSize - 1;
    cb1.Limits = [0 0.165];
    cb1.Ticks = linspace(0, 0.15, 4);
    
    c_ax = axes('Visible', 'off');
    colormap(c_ax, [1 0 0; 0 1 0]); 
    cb2 = colorbar(c_ax, 'Ticks', [0.25, 0.75], 'TickLabels', {'Bad', 'Good'});
    cb2.Label.String = 'Curve Condition';
    cb2.Label.FontSize = fontSize;
    cb2.FontSize = fontSize - 1;
    
    cb_left = pos_left(3) + subplot_width + 0.01;
    cb_width = 0.02;
    pos1 = get(ax_handles(1,3), 'Position');
    set(cb1, 'Position', [cb_left, pos1(2), cb_width, pos1(4)]);
    pos2 = get(ax_handles(2,3), 'Position');
    set(cb2, 'Position', [cb_left, pos2(2), cb_width, pos2(4)]);
    
    % --- SAVE FIGURE ---
    % Create a base filename without extension
    output_basename = strrep(figure_name, ' ', '_');
    
    % Save as PNG
    png_filename = [output_basename, '.png'];
    print(fig8, png_filename, '-dpng', '-r300');
    fprintf('Saved PNG: %s\n', png_filename);
    
    % Save as EPS
    eps_filename = [output_basename, '.eps'];
    print(fig8, eps_filename, '-depsc'); % -depsc is for color EPS
    fprintf('Saved EPS: %s\n', eps_filename);
end

