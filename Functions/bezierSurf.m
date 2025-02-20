function S=bezierSurf(u,v,P)
    [n,m]=size(P,[1 2]);
    S = kron(bernsteinMatrix(n-1,u),bernsteinMatrix(m-1,v))*reshape(P,[],3);
end