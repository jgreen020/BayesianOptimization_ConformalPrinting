% This script is unfinished
close all; clc;

qqq = figure;
set(qqq, 'WindowStyle', 'Docked');
plot3(testpoints(:, 1), testpoints(:, 2), testpoints(:, 3), 'o', LineWidth=3);
grid on
axis equal
view(2)
% d
    