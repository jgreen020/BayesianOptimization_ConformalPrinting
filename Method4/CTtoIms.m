clear; clc; close all;
bulk = 1;
surfnames= ...
   {'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};

Inputs

if ~exist('f','var')
f=figure('Position',[0 0 1000 1000]);
end
tiledlayout(3,3)

targets = zeros(res_im,res_im,1,max(size(surfnames)));
for loop = 1:max(size(surfnames))
    SurfB=surfnames{loop};
    fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tImporting ', SurfB,' ...\n'])
    [dataB, ~, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
    dataB=table2array(dataB);
    x=dataB(:,1); y=dataB(:,2); z=dataB(:,3);
    idx_x=round(rescale([x_min+pad; x_max-pad; x],1,res_im));
    idx_y=round(rescale([y_min+pad; y_max-pad; y],1,res_im));
    idx_x=idx_x(3:end); idx_y=idx_y(3:end);
    target=zeros(res_im);
    fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tBuilding Image ...\n'])
    for loop2 = 1:res_im
        for loop3 = 1:res_im
            data_pixel=z(idx_x==loop2 & idx_y==loop3);
            if ~isempty(data_pixel)
            target(loop2,loop3)=data_pixel(randi(max(size(data_pixel))));
            end
        end
    end
    targets(:,:,1,loop)=rescale(target);
    nexttile
    imshow(targets(:,:,1,loop))
end

for loop = 1:9
    nexttile
    imshow(targets(:,:,1,loop))
end
