%% Show images from small set

if size(images,4)>20
    disp('STOP WTF')
    return
end

if ~exist('f','var')
f=figure('Position',[0 0 1000 500]);
end
tiledlayout
for i=1:size(images,4)
    nexttile
    imshow(images(:,:,i)~=0)
    nexttile
    imshow(targets(:,:,i))
end

%% Show random images from large set
if exist('images','var')
    if size(images,4)<1000
        load("Data/M4/surf_dataset3.mat")
    end
else 
    load("Data/M4/surf_dataset3.mat")
end

ims=randperm(size(images,4),4);

if ~exist('f','var')
close all
f=figure('Position',[0 0 1000 668]);
end

tiledlayout(2,4)
for i=1:size(ims,2)
    nexttile
    imshow(images(:,:,:,ims(i))~=0)
    title(strcat("Image ",string(ims(i))))
    nexttile
    imshow(targets(:,:,:,ims(i)))
    title(strcat("Target ",string(ims(i))))
end
fontsize(scale=1.5)
saveas(f,'Data/M4/surf_dataset_Surf1a_n255.fig')
exportgraphics(f,'Data/M4/surf_dataset_Surf1a_n255.png')
exportgraphics(f,'Data/M4/surf_dataset_Surf1a_n255.eps')