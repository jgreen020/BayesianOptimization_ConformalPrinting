function [Sx,Sy,Sz,C] = plotBezierSurf(res,P,Surface)
    %  Javier Martínez-Yubero;  March-13-2022
    % https://www.mathworks.com/matlabcentral/fileexchange/107884-beziersurfaceplot?s_tid=FX_rc2_behav
    t=0:1/ceil(res):1; %The value 1/500 can be reduced to obtain a less dense plot.
    l=length(t);
    S=bezierSurf(t,t,P);
    %plot3(S(:,1),S(:,2),S(:,3),'LineStyle','none','MarkerSize',6,'Marker','.','MarkerEdgeColor','blue')
    %plot3(S(:,1),S(:,2),S(:,3),'LineStyle','none','MarkerSize',6,'Marker','.','MarkerEdgeColor','blue')
    %End adapted code
    
    Sx=reshape(S(:,1),[l l]);
    Sy=reshape(S(:,2),[l l]);
    Sz=reshape(S(:,3),[l l]);
    
    C=abs(Sz-Surface(Sx,Sy));
    lim=[0 .165];
    map='viridis';

    surf(Sx,Sy,Sz,C,'LineStyle','none', FaceAlpha=0.2);
    colormap(map);
    c=colorbar;
    c.Label.String='Z-Direction Deviation (mm)';
    clim(lim);

    axis equal
end