function BezierSurfacePlot(m,n,P)
%  Javier Martínez-Yubero;  March-13-2022
 t=0:1/500:1; %The value 1/500 can be reduced to obtain a less dense plot.
 B1=bernsteinMatrix(m,t);
 B2=bernsteinMatrix(n,t);
 A=kron(B1,B2);
 S = A*P;
 plot3(S(:,1),S(:,2),S(:,3))