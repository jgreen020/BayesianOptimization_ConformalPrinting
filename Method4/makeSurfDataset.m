%% makeSurfDataset.m
% Author: Jake Colwell
% Created: 4/13/2025
% Generate a large dataset of random surfaces that can be used to train a 
% Convolutional Auto-Encoder Network on a Super-Resolution Problem

clear;clc;close all;
%% Inputs
im_size = 128;
num_surfs = 200; % Number of surfaces to generate of each grid size
ctrlPts = 2:1:5; % Grid sizes of control points to test (e.g. n=2 produces 2x2=4 control points)
num_noise = 2; % Number of times to add independent noise to a surface
mags = [1/1000 1/1500 1/2000]; % Different Hurst Parameters to try
sample_sizes = (2:15).^2; % Different input sampling sizes to test

dataset_size = num_surfs*size(ctrlPts,2)*num_noise*size(mags,2)*size(sample_sizes,2)

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
        
        mini=num_noise*size(mags,2)*size(sample_sizes,2);
        images_mini=zeros(im_size,im_size,1,mini);
        targets_mini=images_mini;
        count_mini=1;
        for mag=mags
            for i=1:num_noise
                for sample_size=sample_sizes
                    % Downsample and add noise
                    idx = round(net(scramble(sobolset(2,'Skip',1e3,'Leap',1e2),'MatousekAffineOwen'),sample_size)*(im_size-1)+1);
                    while full(any(sparse(idx(:,1),idx(:,2),1,im_size,im_size)>1,'all'))
                        idx = round(net(scramble(sobolset(2,'Skip',1e3,'Leap',1e2),'MatousekAffineOwen'),sample_size)*(im_size-1)+1);
                    end
                    idx_mat = sparse(idx(:,1),idx(:,2),true,im_size,im_size);
                    image = zeros(im_size);
                    image(idx_mat)=target(idx_mat)+randn(sample_size,1)*mag;
                    
                    % Save
                    images_mini(:,:,:,count_mini)=image;
                    targets_mini(:,:,:,count_mini)=target;
                    count_mini=count_mini+1;
                end
            end
        end
        images(:,:,:,mini*count+1:mini*count+mini)=images_mini;
        targets(:,:,:,mini*count+1:mini*count+mini)=targets_mini;
        count=count+1;
    end
end

perm = randperm(dataset_size);
images=images(:,:,:,perm);
targets=targets(:,:,:,perm);

%save('Method4/surf_dataset.mat','images','targets','-v7.3')