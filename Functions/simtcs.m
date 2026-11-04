function [x,y,z] = simtcs(point_cloud,query_points,noise_magnitude,bias_vector)
% simtcs.m
% Simulate TCS with noise and bias
% Jake Colwell, November 4th 2026

% Inputs
    % point_cloud: table with columns {'x','y','z'}
    % query_points: (:,2) array of x-y coordinates
    % noise_magnitude: scalar, standard deviation of normally distributed noise added to z-value
    % bias_magnitude: scalar, euclidean distance to offset sample
    % bias_direction: length-3 vector, unit vector in the direction of bias

% Outputs
    % x,y,z: (:,1) vectors
    
[initindex, ~]=dsearchn(table2array(point_cloud(:,{'x','y'})),query_points);
x=table2array(dataB(initindex,'x'));
y=table2array(dataB(initindex,'y'));
z=table2array(dataB(initindex,'z'));

if noise_magnitude>0
    z = z+normrnd(0,noise_magnitude);
end

if vecnorm(bias_vector)>0
    x = x+bias_vector(1);
    y = y+bias_vector(2);
    z = z+bias_vector(3);
end