function [x,y] = SquareSpiral(t)
revs = 6;
shift=[0.5 0.5];
scale=[0.75 0.75];

t=t+1/(2*pi);

theta=revs*2*pi*t;
radius=t/2.*sec(theta-pi/2*floor((4*theta+pi)/(2*pi)));

x=radius.*cos(theta);
y=radius.*sin(theta);

x=scale(1)*x+shift(1);
y=scale(2)*y+shift(2);

end