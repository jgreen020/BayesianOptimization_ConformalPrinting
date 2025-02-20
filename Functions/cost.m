function J = cost(u,v,P,P_i)
    J = sum(vecnorm(bezierSurf(u,v,P)-reshape(P_i,[],3), 2, 2).^2);
end