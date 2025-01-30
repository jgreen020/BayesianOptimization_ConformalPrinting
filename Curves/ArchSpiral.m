function [x,y] = ArchSpiral(t)
t=12*pi*t;
x=4*t.*cos(t);
y=4*t.*sin(t);
x=x(2:end);
y=y(2:end);
range_x=abs(max(x)-min(x));
range_y=abs(max(y)-min(y));
scl=0.4;
y=(y-min(y)-range_y/2)/range_x*scl+0.6;
x=(x-min(x)-range_x/2)/range_x*scl+0.4;
end

