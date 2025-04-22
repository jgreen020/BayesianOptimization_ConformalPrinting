%% makeSurfDataset_CT.m
% Author: Jake Colwell
% Created: 4/13/2025
% Generate a large dataset of random surfaces that can be used to train a 
% Convolutional Auto-Encoder Network on a Super-Resolution Problem

clearvars -except lastload data nameB;clc;close all;
%% Inputs
im_size = 128;
num_surfs = 150; % Number of surfaces to generate of each grid size
ctrlPts = 1:1:4; % Grid sizes of control points to test (e.g. n=2 produces 2x2=4 control points)
num_rot = 4; % Number of ways to rotate the surface
num_noise = 3; % Number of times to add independent noise to a surface
noise_m = 0.01; % Mean magnitude of noise to add to the surface
noise_v = 0.002; % Varaince of magnitude of added noise
sample_sizes = 15^2; % Input sampling size to test
num_samps = 4; % Number of times to take a random sample
split = 0.8; % Fraction of data to keep for training

SurfB = 'Surf1a.csv'; % Name of the file containing the CT scan data

dataset_size = num_surfs*size(ctrlPts,2)*num_noise*size(sample_sizes,2)*num_rot*num_samps

bulk=1;
Inputs

% transformation=@images.geotrans.PiecewiseLinearTransformation2D;
%% Calculations
images = zeros(im_size, im_size, 1, dataset_size);
targets = images;

%Make Original Into an Image
if ~exist('data','var') || ~exist('lastload','var')
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tImporting ', SurfB,' ...\n'])
[data, ~, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
lastload=SurfB;
end
if ~matches(lastload,SurfB)
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tImporting ', SurfB,' ...\n'])
[data, ~, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
lastload=SurfB;
end
dataB=table2array(data(1:20:end,:));
target=pc2im(dataB,[x_min+pad x_max-pad y_min+pad y_max-pad],res_im);
close all
figure('Position',[0 0 786 241])
tiledlayout(1,3)
nexttile(1)
imshow(target)
title('Original Data')

% pt = randi([22 106],[6 2]);
% d = randi([-5 5],[6 2]);
% movingPoints = [1 1; 1 128; 128 1; 128 128; pt];
% fixedPoints = [-1 -1; -1 130; 130 -1; 130 130; pt+d];
% tform = transformation(movingPoints,fixedPoints);
% im_warped = imwarp(target,tform);
% im_warped(~any(im_warped,2),:)=[]; im_warped(:,~any(im_warped,1),:)=[];
% im_warped = imcrop(im_warped,centerCropWindow2d(size(im_warped),[res_im res_im]));
% im_warped = imgaussfilt(im_warped,1);
ctrlPt=3;
[bound_x, bound_y] = meshgrid(linspace(x_min+pad, x_max-pad,10),linspace(y_min+pad, y_max-pad,10));
select = (bound_x<x_min+pad+0.1) | (bound_x>x_max-pad-0.1) | (bound_y<y_min+pad+0.1) | (bound_y>y_max-pad-0.1);
bound_x=bound_x(select); bound_y=bound_y(select);
[ctrl_x, ctrl_y] = meshgrid(linspace(x_min+pad, x_max-pad,ctrlPt+2),linspace(y_min+pad, y_max-pad,ctrlPt+2));
select = (ctrl_x<x_min+pad+0.1) | (ctrl_x>x_max-pad-0.1) | (ctrl_y<y_min+pad+0.1) | (ctrl_y>y_max-pad-0.1);
ctrl_x=ctrl_x(~select); ctrl_y=ctrl_y(~select);
ctrl_x=cat(1,ctrl_x(:),bound_x(:)); ctrl_y=cat(1,ctrl_y(:),bound_y(:));
ctrlmags = cat(1,2/ctrlPt*randn(ctrlPt^2,3),zeros(size(bound_x(:),1),3));
size_quiv=30;
[x_quiv,y_quiv]=meshgrid(linspace(x_min+pad, x_max-pad,size_quiv),linspace(y_min+pad, y_max-pad,size_quiv));
x=dataB(:,1); y=dataB(:,2); z=dataB(:,3);
x_mag_quiv=griddata(ctrl_x,ctrl_y,ctrlmags(:,1),x_quiv(:),y_quiv(:),'v4');
y_mag_quiv=griddata(ctrl_x,ctrl_y,ctrlmags(:,2),x_quiv(:),y_quiv(:),'v4');
z_mag_quiv=griddata(ctrl_x,ctrl_y,ctrlmags(:,3),x_quiv(:),y_quiv(:),'v4');
x_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,1),x(:),y(:),'v4');
y_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,2),x(:),y(:),'v4');
z_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,3),x(:),y(:),'v4');
data_warp=(dataB+[x_mag y_mag z_mag]);
target_warp=pc2im(data_warp,[x_min+pad x_max-pad y_min+pad y_max-pad],res_im);

nexttile(2)
hold off
quiver3(x_quiv(:),y_quiv(:),zeros(size_quiv^2,1),x_mag_quiv,y_mag_quiv,z_mag_quiv,'off')
hold on
scatter3(ctrl_x,ctrl_y,zeros(size(ctrl_x,1)))
quiver3(ctrl_x,ctrl_y,zeros(size(ctrl_x,1),1),ctrlmags(:,1),ctrlmags(:,2),ctrlmags(:,3),'off')
view(2)
axis equal
axis off
title('Random Warping')

nexttile(3)
hold off
imshow(target_warp)
title('Warped Image')

f=gcf;
fontsize(scale=1.5)
saveas(f,'Data/M4/makeSurfDataset_CT.fig')
exportgraphics(f,'Data/M4/makeSurfDataset_CT.png')
exportgraphics(f,'Data/M4/makeSurfDataset_CT.eps')

%%
count=0;
[bound_x, bound_y] = meshgrid(linspace(x_min+pad, x_max-pad,10),linspace(y_min+pad, y_max-pad,10));
select = (bound_x<x_min+pad+0.1) | (bound_x>x_max-pad-0.1) | (bound_y<y_min+pad+0.1) | (bound_y>y_max-pad-0.1);
bound_x=bound_x(select); bound_y=bound_y(select);
        
for ctrlPt=ctrlPts
    for j=1:num_surfs
        % Generate Surface
        [ctrl_x, ctrl_y] = meshgrid(linspace(x_min+pad, x_max-pad,ctrlPt+2),linspace(y_min+pad, y_max-pad,ctrlPt+2));
        select = (ctrl_x<x_min+pad+0.1) | (ctrl_x>x_max-pad-0.1) | (ctrl_y<y_min+pad+0.1) | (ctrl_y>y_max-pad-0.1);
        ctrl_x=ctrl_x(~select); ctrl_y=ctrl_y(~select);
        ctrl_x=cat(1,ctrl_x(:),bound_x(:)); ctrl_y=cat(1,ctrl_y(:),bound_y(:));
        ctrlmags = cat(1,2/ctrlPt*randn(ctrlPt^2,3),zeros(size(bound_x(:),1),3));
        x=dataB(:,1); y=dataB(:,2); z=dataB(:,3);
        x_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,1),x(:),y(:),'v4');
        y_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,2),x(:),y(:),'v4');
        z_mag=griddata(ctrl_x,ctrl_y,ctrlmags(:,3),x(:),y(:),'v4');
        data_warp=(dataB+[x_mag y_mag z_mag]);

        mini=num_noise*size(sample_sizes,2)*num_rot*num_samps;
        images_mini=zeros(im_size,im_size,1,mini);
        targets_mini=images_mini;
        count_mini=1;
        for rot=1:num_rot
            data_rot=data_warp*rot_mat(0,0,(rot-1)*pi/2);
            target=pc2im(data_rot,[x_min+pad x_max-pad y_min+pad y_max-pad],res_im);
            
            if any(isnan(target),"all")
                error('NaN Detected')
            end

            for i=1:num_noise
                for sample_size=sample_sizes
                    for samps=1:num_samps   
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
save(strcat("Data/M4/surf_dataset_",nameB,"_n",string(max(sample_sizes)),".mat"),'-v7.3')
disp('Complete.')