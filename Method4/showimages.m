if size(images,3)>10
    disp('STOP WTF')
    return
end

figure('WindowStyle','docked')
tiledlayout
for i=1:size(ctrlPts,2)
    nexttile
    imshow(images(:,:,i)~=0)
    nexttile
    imshow(targets(:,:,i))
end