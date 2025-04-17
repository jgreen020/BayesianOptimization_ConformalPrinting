function [data, f, name]=importCTdata(Surf,y_lim,x_lim,pad)
    addpath(genpath(fullfile(pwd)))
    data = readtable(strcat(fullfile(pwd,'/Data'),'/CT Scans/',Surf));
    data.Properties.VariableNames={'x','y','z'};
    data=data((abs(data.x)<=(max(x_lim)-pad))&(abs(data.y)<=(max(y_lim)-pad))&(data.z>=0),:);
    f=scatteredInterpolant(data.x,data.y,data.z,'natural','none');
    [~, name,~]=fileparts(Surf);
end