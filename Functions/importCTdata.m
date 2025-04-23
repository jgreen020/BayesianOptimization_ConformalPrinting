function [data, f, name]=importCTdata(Surf,y_lim,x_lim,pad,res)
    addpath(genpath(fullfile(pwd)))
    data = readtable(strcat(fullfile(pwd,'/Data'),'/CT Scans/',Surf));
    data.Properties.VariableNames={'x','y','z'};
    data=data((abs(data.x)<=(max(x_lim)-pad))&(abs(data.y)<=(max(y_lim)-pad))&(data.z>=0),:);
    data_filt=filterScattered(data,res);
    f=scatteredInterpolant(data_filt.x,data_filt.y,data_filt.z,'natural','none');
    [~, name,~]=fileparts(Surf);
end