function [x,y] = Hybrid(t)
[x,y] = ArchSpiral(t);
[x(y<0.5), y(y<0.5)]=SquareSpiral(t(y<0.5));
end