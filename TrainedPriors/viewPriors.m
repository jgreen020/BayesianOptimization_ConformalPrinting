clear;clc;close all
res_s=200;
fname='TrainedPriors/Surf2a.mat';
load(fname)
figure('units','normal','position',[0 .5 .6 .5],'Color','white');
hold on
scatter3(gprMdlA.X.x,gprMdlA.X.y,gprMdlA.Y,1,'MarkerEdgeColor','red','MarkerFaceColor','red')
x=linspace(x_lim_pri(1)+pad_pri,x_lim_pri(2)-pad_pri,res_s);
y=linspace(y_lim_pri(1)+pad_pri,y_lim_pri(2)-pad_pri,res_s);
[x, y]=meshgrid(x,y);
z=predict(gprMdlA,table(x(:),y(:),'VariableNames',{'x','y'}),'Alpha',0.1);
surf(x,y,reshape(z,res_s,[]),'LineStyle','none')
colormap('viridis')
axis equal
axis off
axis([-30 30 -30 30 0 20])
view(3)
set(gca,'GridLineStyle','none')
fontsize("scale",1.5)
spinningGIF('priorfig.gif')