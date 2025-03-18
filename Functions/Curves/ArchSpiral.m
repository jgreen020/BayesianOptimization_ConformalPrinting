function [x,y] = ArchSpiral(t)
revs = 6;
shift=[0.5 0.5];
scale=[0.75 0.75];

t=t+1/(2*pi);

radius=t/2;
theta=2*pi*revs*t;

x=scale(1)*radius.*cos(theta)+shift(1);
y=scale(2)*radius.*sin(theta)+shift(2);

end

