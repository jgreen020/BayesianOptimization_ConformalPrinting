function [drdu, drdv]=BezDiff(u,v,n,m,P)
    % h=0.001;
    % X=zeros(3);
    % Y=X;
    % Z=X;
    % for a=-1:1
    %     for b=-1:1
    %         p=bezierSurf(u+a*h,v+b*h,n,m,P);
    %         X(a+2,b+2)=p(1);
    %         Y(a+2,b+2)=p(2);
    %         Z(a+2,b+2)=p(3);
    %     end
    % end
    
    S=bezierSurf(u,v,n,m,P);
    X=reshape(S(:,1),[n m]);
    Y=reshape(S(:,2),[n m]);
    Z=reshape(S(:,3),[n m]);
    cnt=0;

    [dXdu,dXdv]=gradient(X);
    [dYdu,dYdv]=gradient(Y);
    [dZdu,dZdv]=gradient(Z);
    
    %quiver3(X,Y,Z,dXdu,dYdu,dZdu)
    %quiver3(X,Y,Z,dXdv,dYdv,dZdv)

    dXdu = dXdu(:);   dYdu = dYdu(:);   dZdu = dZdu(:); 
    dXdv = dXdv(:);   dYdv = dYdv(:);   dZdv = dZdv(:); 

    drdu=[dXdu dYdu dZdu];
    drdv=[dXdv dYdv dZdv];
end