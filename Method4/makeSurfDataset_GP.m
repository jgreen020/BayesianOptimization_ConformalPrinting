%% makeSurfDataset_GP.m
% Author: Jake Colwell
% Created: 4/18/2025
% Generate a large dataset of random surfaces that can be used to train a 
% Convolutional Auto-Encoder Network on a Super-Resolution Problem

clear;clc;close all;
%% Inputs
im_size = 128;
num_samp = 2;%10; % Number times to resample the data per number of control points
num_surfs = 5; % Number of time to sample each GP
ctrlPts = 40; % Grid sizes of control points to test (e.g. n=2 produces 2x2=4 control points)
num_noise = 1;%2; % Number of times to add independent noise to a surface
mags = 1/1000;%[1/1000 1/1500 1/2000]; % Different Noise Magnitudes to try
sample_sizes = 15;%(2:15).^2; % Different input sampling sizes to test

Surf = 'Surf3a.csv'; % Name of the file containing the CT scan data

dataset_size = num_samp*num_surfs*size(ctrlPts,2)*num_noise*size(mags,2)*size(sample_sizes,2)
%% Calculations

bulk=1;
Inputs

[dataB, ~, ~]=importCTdata(Surf,y_lim,x_lim,pad);
dataB=table2array(dataB(randperm(size(dataB,1),floor(size(dataB,1)/16)),:));

p = sobolset(2,'Skip',1e3,'Leap',1e2); 
p = scramble(p,'MatousekAffineOwen');

x=linspace(x_min+pad, x_max-pad, im_size);
y=linspace(y_min+pad, y_max-pad, im_size);
[x, y]=meshgrid(x,y);
x=x(:);
y=y(:);

%%
images = zeros(im_size, im_size, 1, dataset_size);
targets = images;
n_old=0;
count=0;
for ctrlPt=ctrlPts
    for j=1:num_samp
        % Generate Surface
        train_sobol = p(n_old+1:n_old+1+ctrlPt,:);
        n_old=n_old+1+ctrlPt;
        xt = train_sobol(:,1)*(x_lim(2)-x_lim(1)-2*pad)-(x_lim(2)-x_lim(1)-2*pad)/2; 
        yt = train_sobol(:,2)*(y_lim(2)-y_lim(1)-2*pad)-(y_lim(2)-y_lim(1)-2*pad)/2;
        [initindex, dist]=dsearchn(dataB(:,1:2),[xt yt]);
        pts=dataB(initindex,:);
        gpr=fitrgp(pts(:,1:2),pts(:,3),'KernelParameters',[20,0.01],"Sigma",1e-2,"SigmaLowerBound",1e-2-0.0011);
        [pred,covmat] = predictExactWithCov(gpr.Impl,[x y],0.1);
        T = cholcov(covmat);
        pred_rand = pred + T'*randn(im_size^2,num_surfs);
        
        for k=1:num_surfs
        target = reshape(rescale(pred_rand(:,k)),im_size,im_size);
        
        mini=num_noise*size(mags,2)*size(sample_sizes,2);
        images_mini=zeros(im_size,im_size,1,mini);
        targets_mini=images_mini;
        count_mini=1;
        for mag=mags
            for i=1:num_noise
                for sample_size=sample_sizes
                    % Downsample and add noise
                    idx = round(p(n_old+1:n_old+1+sample_size)*(im_size-1)+1);
                    n_old=n_old+1+sample_size;
                    while full(any(sparse(idx(:,1),idx(:,2),1,im_size,im_size)>1,'all'))
                        idx = round(p(n_old+1:n_old+1+sample_size)*(im_size-1)+1);
                        n_old=n_old+1+sample_size;
                    end
                    idx_mat = sparse(idx(:,1),idx(:,2),true,im_size,im_size);
                    target = target+randn(im_size)*mag;
                    image = zeros(im_size);
                    image(idx_mat)=target(idx_mat);
                    
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
        disp(count/(length(ctrlPts)*num_samp*num_surfs))
    end
end

perm = randperm(dataset_size);
images=images(:,:,:,perm);
targets=targets(:,:,:,perm);

%save('Method4/surf_dataset.mat','images','targets','-v7.3')