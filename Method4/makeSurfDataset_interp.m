%% makeSurfDataset.m
% Author: Jake Colwell
% Created: 4/13/2025
% Generate a large dataset of random surfaces that can be used to train a 
% Convolutional Auto-Encoder Network on a Super-Resolution Problem

clear;clc;close all;
%% Inputs
im_size = 128;
num_surfs = 331; % Number of surfaces to generate of each grid size
ctrlPts = 2:1:4; % Grid sizes of control points to test (e.g. n=2 produces 2x2=4 control points)
num_noise = 4; % Number of times to add independent noise to a surface
noise_m = 0.01; % Mean magnitude of noise to add to the surface
noise_v = 0.002; % Varaince of magnitude of added noise
sample_sizes = (6:15).^2; % Different input sampling sizes to test
split = 0.8; % Fraction of data to keep for training

dataset_size = num_surfs*size(ctrlPts,2)*num_noise*size(sample_sizes,2)

%% Calculations
images = zeros(im_size, im_size, 1, dataset_size);
targets = images;

count=0;
for ctrlPt=ctrlPts
    for j=1:num_surfs
        % Generate Surface
        [ctrl_x, ctrl_y] = meshgrid(linspace(0,1,ctrlPt),linspace(0,1,ctrlPt));
        ctrl_z = randn(ctrlPt);
        [x,y]=meshgrid(linspace(0,1,im_size),linspace(0,1,im_size));
        z=rescale(griddata(ctrl_x(:),ctrl_y(:),ctrl_z(:),x(:),y(:),'v4'));
        target = reshape(z,im_size,im_size);
        
        if any(isnan(target),"all")
            error('NaN Detected')
        end
        mini=num_noise*size(sample_sizes,2);
        images_mini=zeros(im_size,im_size,1,mini);
        targets_mini=images_mini;
        count_mini=1;
            for i=1:num_noise
                for sample_size=sample_sizes
                    % Downsample and add noise
                    idx = round(net(scramble(sobolset(2,'Skip',1e3,'Leap',1e2),'MatousekAffineOwen'),sample_size)*(im_size-1)+1);
                    while full(any(sparse(idx(:,1),idx(:,2),1,im_size,im_size)>1,'all'))
                        idx = round(net(scramble(sobolset(2,'Skip',1e3,'Leap',1e2),'MatousekAffineOwen'),sample_size)*(im_size-1)+1);
                    end
                    idx_mat = sparse(idx(:,1),idx(:,2),true,im_size,im_size);
                    noise=normrnd(0,normrnd(noise_m,noise_v), im_size);
                    target_noise=target+noise;
                    image = zeros(im_size);
                    image(idx_mat)=target_noise(idx_mat);
                    
                    if any(isnan(noise),"all")
                        error('NaN Detected in noise')
                    elseif any(isnan(target_noise),"all")
                        error('NaN Detected in target_noise')
                    elseif any(isnan(image),"all")
                        error('NaN Detected in image')
                    end

                    % Save
                    images_mini(:,:,:,count_mini)=image;
                    targets_mini(:,:,:,count_mini)=target_noise;
                    count_mini=count_mini+1;
                end
            end
        images(:,:,:,mini*count+1:mini*count+mini)=images_mini;
        targets(:,:,:,mini*count+1:mini*count+mini)=targets_mini;
        count=count+1;
        if mod(count,4)==0
        disp(count/max(size(ctrlPts))/num_surfs)
        end
    end
end

perm = randperm(dataset_size);
images=images(:,:,:,perm);
targets=targets(:,:,:,perm);

if any(isnan(images),"all")
    error('NaN Detected in images, presplit')
elseif any(isnan(targets),"all")
    error('NaN Detected in targets, presplit')
end

ValidationData = {images(:,:,:,ceil(dataset_size*split+1):end),targets(:,:,:,ceil(dataset_size*split+1):end)};
images = images(:,:,:,1:ceil(dataset_size*split));
targets = targets(:,:,:,1:ceil(dataset_size*split));

if any(isnan(images),"all")
    error('NaN Detected in images')
elseif any(isnan(targets),"all")
    error('NaN Detected in targets')
elseif any(isnan(ValidationData{1}),"all")
    error('NaN Detected in Validation images')
elseif any(isnan(ValidationData{2}),"all")
    error('NaN Detected in Validation targets')
end


disp('Saving ...')
save('Data/M4/surf_dataset3.mat','-v7.3')
disp('Complete.')