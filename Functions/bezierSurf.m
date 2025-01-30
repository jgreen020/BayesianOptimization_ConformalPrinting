function S=bezierSurf(u,v,n,m,P)
    S = kron(bernsteinMatrix(n-1,u),bernsteinMatrix(m-1,v))*P;
end