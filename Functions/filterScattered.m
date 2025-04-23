function filtered = filterScattered(pc,res)
pc=table2array(pc);
x=pc(:,1); y=pc(:,2); z=pc(:,3);
idx_x=round(rescale(x,1,res));
idx_y=round(rescale(y,1,res));
accum_ind=sub2ind([res res],idx_x,idx_y);
z_filt=accumarray(accum_ind,z,[res^2 1],@median,NaN);
[x_filt, y_filt]=meshgrid(linspace(min(x),max(x),res),linspace(min(x),max(x),res));
x_filt=x_filt'; y_filt=y_filt';
filtered = table(x_filt(:), y_filt(:), z_filt(:),'VariableNames',{'x','y','z'});
filtered(isnan(filtered.z),:)=[];
end