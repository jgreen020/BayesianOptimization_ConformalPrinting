function [Sx,Sy,Sz,C] = plotBezierSurf(res,n,m,P,Surface)
    %  Javier Martínez-Yubero;  March-13-2022
    % https://www.mathworks.com/matlabcentral/fileexchange/107884-beziersurfaceplot?s_tid=FX_rc2_behav
    t=0:1/ceil(res):1; %The value 1/500 can be reduced to obtain a less dense plot.
    l=length(t);
    S=bezierSurf(t,t,n,m,P);
    %plot3(S(:,1),S(:,2),S(:,3),'LineStyle','none','MarkerSize',6,'Marker','.','MarkerEdgeColor','blue')
    %plot3(S(:,1),S(:,2),S(:,3),'LineStyle','none','MarkerSize',6,'Marker','.','MarkerEdgeColor','blue')
    %End adapted code
    
    Sx=reshape(S(:,1),[l l]);
    Sy=reshape(S(:,2),[l l]);
    Sz=reshape(S(:,3),[l l]);

    % [K,H,Pmax,Pmin] = surfature(Sx,Sy,Sz);
    % C=K;
    % h=max(abs(min(C,[],'all')), abs(max(C,[],'all')));
    % lim=[-h h];
    % c=[0 30 125; 0 0 255; 0 255 255; 50 180 50; 255 255 0; 255 0 0; 125 30 0]/255;
    % resm=20;
    % cnt=1;
    % for a=1:size(c,1)-1
    %     d=(c(a+1,:)-c(a,:))/resm;
    %     map(cnt,:)=c(a,:);
    %     cnt=cnt+1;
    %     for b=2:resm
    %         map(cnt,:)=map(cnt-1,:)+d;
    %         cnt=cnt+1;
    %     end
    % end
    
    C=abs(Sz-Surface(Sx,Sy));
    lim=[0 .3];
    map='turbo';

    surf(Sx,Sy,Sz,C,'LineStyle','none')
    colormap(map)
    c=colorbar;
    c.Label.String='Z-Direction Deviation (mm)';
    clim(lim)
end