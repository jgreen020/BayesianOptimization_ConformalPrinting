function med_val = get_median_dt(time_steps)
% GET_MEDIAN_DT Calculates the median of time step data.
%   med_val = get_median_dt(time_steps) takes a vector of time differences
%   (delta t) and returns the median value in seconds.

    if isempty(time_steps)
        warning('Input time step vector is empty.');
        med_val = 0;
    else
        med_val = median(time_steps);
    end
end