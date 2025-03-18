close all
t=linspace(0,1,50000);
[x,y]=ArchSpiral(t);
[x2,y2]=SquareSpiral(t);
[x3,y3]=Hybrid(t);
f=figure('WindowStyle','docked');
plot(x,y,x2,y2,x3,y3)
axis equal
axis([0 1 0 1])
xlabel x
ylabel y
