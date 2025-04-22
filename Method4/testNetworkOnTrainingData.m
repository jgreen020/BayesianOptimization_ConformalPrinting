Inputs

if ~exist('trained_net','var')
    load("Data/M4/trained_network5.mat")
end
if ~exist('images','var')
    load(training_data,"images","targets","ValidationData")
end

ims=randperm(size(images,4),6);

if ~exist('f','var')
f(1)=figure('Position',[0 0 1000 500]);
end
tiledlayout(3,6)
for i=1:size(ims,2)
    nexttile
    imshow(images(:,:,:,ims(i))~=0)
    title(strcat("Thresholded Input (image ",string(ims(i)),')'))
    nexttile
    imshow(targets(:,:,:,ims(i)))
    title(strcat("Target (image ",string(ims(i)),')'))
    nexttile
    pred_all=predict(trained_net,full(images(:,:,:,ims(i))));
    imshow(pred_all(:,:,1));
    title(strcat("Prediction (image ",string(ims(i)),')'))
end

x_im=linspace(x_min+pad,x_max-pad,res_im);
y_im=linspace(y_min+pad,y_max-pad,res_im);
[x_im, y_im]=meshgrid(x_im, y_im);

%%
if ~exist('f','var')
f(2)=figure('Position',[0 0 1000 500]);
end
tiledlayout(3,2)
for i=1:size(ims,2)
    nexttile
    hold on
    surf(x_im,y_im,20*images(:,:,:,ims(i)),'LineStyle','none','FaceAlpha',0.3)
    surf(x_im,y_im,20*targets(:,:,:,ims(i)),'LineStyle','none','FaceAlpha',0.3)
    pred_all=predict(trained_net,full(images(:,:,:,ims(i))));
    surf(x_im,y_im,pred_all(:,:,1),'LineStyle','none','FaceAlpha',0.3)
    title(strcat("Surface View (image ",string(ims(i)),')'))
    nexttile
    imshow(20*targets(:,:,:,ims(i)))
    title(strcat("Target (image ",string(ims(i)),')'))
    nexttile
    pred_all=predict(trained_net,full(images(:,:,:,ims(i))));
    imshow(pred_all(:,:,1));
    title(strcat("Prediction (image ",string(ims(i)),')'))
end