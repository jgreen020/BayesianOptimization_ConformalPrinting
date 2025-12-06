function extracted_data = extractDataFromSixthFig(filename)
    % This function opens a .fig file, extracts all line data from the 6th
    % figure window, and returns it as a structure.

    % Initialize an empty structure to store the results
    extracted_data = struct();

    % Open the .fig file invisibly. This returns an array of handles.
    fig_handles = openfig(filename, 'invisible');

    % Ensure handles are closed automatically when the function finishes
    cleanupObj = onCleanup(@() close(fig_handles(isvalid(fig_handles))));

    % Check that at least 6 figures were opened
    if numel(fig_handles) >= 6
        % Directly select the handle for the 6th figure
        target_figure = fig_handles(6);

        % Find all 'line' objects plotted in that figure
        line_handles = findall(target_figure, 'Type', 'line');

        % Loop through each line to extract its data
        for i = 1:length(line_handles)
            current_line = line_handles(i);
            displayName = get(current_line, 'DisplayName');
            
            if ~isempty(displayName)
                x_data = get(current_line, 'XData');
                y_data = get(current_line, 'YData');
                
                % Create a valid field name from the legend entry
                valid_field_name = matlab.lang.makeValidName(displayName);
                
                % Store the data
                extracted_data.(valid_field_name).XData = x_data;
                extracted_data.(valid_field_name).YData = y_data;
            end
        end
    else
        warning('File "%s" does not contain at least 6 figures.', filename);
    end
end