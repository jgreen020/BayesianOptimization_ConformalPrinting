function image = pc2im(pc,lim,res_im)
x=pc(:,1); y=pc(:,2); z=pc(:,3);
x_min=lim(1);x_max=lim(2);y_min=lim(3);y_max=lim(4);
idx_x=round(rescale([x_min; x_max; x],1,res_im));
idx_y=round(rescale([y_min; y_max; y],1,res_im));
idx_x=idx_x(3:end); idx_y=idx_y(3:end);
accum_ind=sub2ind([res_im res_im],idx_x,idx_y);
image=reshape(accumarray(accum_ind,z,[res_im^2 1],@mean),res_im,res_im);
image=rescale(image);
end