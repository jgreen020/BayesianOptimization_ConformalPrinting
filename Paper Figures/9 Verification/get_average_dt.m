function avg_val = get_average_dt(time_steps)
% GET_AVERAGE_DT Calculates the mean of time step data.
%   avg_val = get_average_dt(time_steps) takes a vector of time differences
%   (delta t) and returns the average value in seconds.

    if isempty(time_steps)
        warning('Input time step vector is empty.');
        avg_val = 0;
    else
        avg_val = mean(time_steps);
    end
end