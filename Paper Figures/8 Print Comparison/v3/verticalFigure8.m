%% Combine Saved Figure Images into a Single Vertical Plot
close all; clear; clc;

% --- Define the filenames of the figures to combine ---
% This script assumes the images are in the same directory as the script.
image_files = {
    'Figure_8_-_Surf1b.png';
    'Figure_8_-_Surf2b.png';
    'Figure_8_-_Surf3b.png'
};

% --- Read all images into memory ---
num_images = length(image_files);
images = cell(num_images, 1);
heights = zeros(num_images, 1);
widths = zeros(num_images, 1);

fprintf('Loading images...\n');
for i = 1:num_images
    try
        images{i} = imread(image_files{i});
        [heights(i), widths(i), ~] = size(images{i});
    catch ME
        error('Failed to read image: %s. Please ensure it is in the correct folder. Error: %s', image_files{i}, ME.message);
    end
end
fprintf('Images loaded successfully.\n');

% --- Prepare the combined canvas ---
total_height = sum(heights);
max_width = max(widths);
combined_image = 255 * ones(total_height, max_width, 3, 'like', images{1});

% --- Place each image onto the canvas ---
current_y = 1;
for i = 1:num_images
    img = images{i};
    h = heights(i);
    w = widths(i);
    
    y_range = current_y : (current_y + h - 1);
    x_offset = floor((max_width - w) / 2);
    x_range = (1:w) + x_offset;
    
    combined_image(y_range, x_range, :) = img;
    current_y = current_y + h;
end

% --- Display and Save the Final Combined Image ---
% Define output filenames without extensions
output_basename = 'Combined_Figure_8_Vertical';
png_output_filename = [output_basename, '.png'];
eps_output_filename = [output_basename, '.eps'];

% Create a figure window to hold the combined image
fig = figure('Name', 'Combined Result', 'Position', [100, 100, max_width*0.8, total_height*0.8]);
imshow(combined_image);
title('Vertically Combined Figures');

% Save as PNG
% imwrite(combined_image, png_output_filename);
fprintf('Successfully saved PNG as "%s"\n', png_output_filename);

% Save as EPS
% The 'print' command saves the content of the figure window
% print(fig, eps_output_filename, '-depsc');
fprintf('Successfully saved EPS as "%s"\n', eps_output_filename);

