% NOTE: Running this code requires the function 'surfature', download it here:
% https://www.mathworks.com/matlabcentral/fileexchange/11168-surface-curvature
% and place it anywhere in the working directory

clear; clc; close all;
syms x y
surfs = {Surface1a(x,y), Surface1b(x,y), Surface1c(x,y); ...
         Surface2a(x,y), Surface2b(x,y), Surface2c(x,y); ...
         Surface3a(x,y), Surface3b(x,y), Surface3c(x,y)} ;

thresh=[10,30,100];
xr=linspace(-30,30,200);
yr=xr;
[xr2,yr2]=meshgrid(xr,yr);

for i=1:3
for j=1:3
    surf_ij = surfs(i,j);
    dx = diff(surf_ij,x);
    dy = diff(surf_ij,y);
    same_counter=0;
    for k = 1:500
        sol = vpasolve([dx,dy],[x,y],[-30 30; -30 30],'Random',true);
        if ~exist('sol_all','var')
            sol_all = sol;
            sol_all.xy = [sol.x;sol.y];
        elseif isempty(sol.x) && isempty(sol.y)
            same_counter = same_counter+1 ;
        elseif ~any(all(abs(double(sol_all.xy-[sol.x;sol.y]))<1e-5,1))
            sol_all.xy = [sol_all.x, sol.x; sol_all.y, sol.y];
            sol_all.x = [sol_all.x, sol.x];
            sol_all.y = [sol_all.y, sol.y];
        else
            same_counter = same_counter+1 ;
        end
        if same_counter>=thresh(i)
            break
        end
    end
    ds = [double(subs(dx,{x,y},{sol_all.x,sol_all.y}));double(subs(dy,{x,y},{sol_all.x,sol_all.y}))];
    cp = sum(all(abs(ds)<1e-5));
    cps(i,j)=cp;

    [K, H, P1, P2]=surfature(xr2,yr2,double(subs(surf_ij,{x,y},{xr2,yr2})));
    K_range = range(K,"all") ;
    K_ranges(i,j) = K_range ;
    
    if j~=1
    err = double(subs(surfs(i,1),{x,y},{xr2,yr2}))-double(subs(surf_ij,{x,y},{xr2,yr2}));
    MAE = mean(abs(err),'all');
    else
    MAE = 0;
    end
    MAEs(i,j) = MAE;
    letters = {'A','B','C'};
    disp('Finished Surface'+string(i)+letters{j})
end
end
%%
SurfStats = table("N",0,0,'VariableNames',{'Surface','Critical Points','Devation'});
counter = 1;
for i=1:3
for j=1:3
    SurfStats(counter,:) = {string(i)+letters{j}, cps(i,j), MAEs(i,j)};
    counter = counter+1 ;
end
end
disp(SurfStats)
writetable(SurfStats,'Paper Figures/3 Surfaces/SurfaceStats.csv')