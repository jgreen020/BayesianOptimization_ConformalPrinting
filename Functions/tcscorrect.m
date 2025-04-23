function corrected = tcscorrect(x,y,z,testpoints)
    pts = cat(3,x,y,z);
    [dx, dy, ~]=gradient(pts);
    N = cross(dx,dy,3);
    N = N./vecnorm(N,2,3);
    correction=N(:,:,1:2)*0.815/2;
    fx=scatteredInterpolant(x(:),y(:),reshape(correction(:,:,1),[],1));
    fy=scatteredInterpolant(x(:),y(:),reshape(correction(:,:,2),[],1));
    corrected=[testpoints(:,1:2)-[fx(testpoints(:,1),testpoints(:,2)),fy(testpoints(:,1),testpoints(:,2))], testpoints(:,3)];

    % figure
    % scatter3(testpoints(:,1),testpoints(:,2),testpoints(:,3),'Marker','o')
    % axis equal
    % hold on
    % scatter3(corrected(:,1),corrected(:,2),corrected(:,3),'Marker','*')
    % quiver3(testpoints(:,1),testpoints(:,2),testpoints(:,3),fx(testpoints(:,1),testpoints(:,2)),fy(testpoints(:,1),testpoints(:,2)),zeros(size(testpoints,1),1),'off')
    % surf(x,y,z,'LineStyle','none')
    % quiver3(x,y,z,N(:,:,1),N(:,:,2),N(:,:,3),'off')
end