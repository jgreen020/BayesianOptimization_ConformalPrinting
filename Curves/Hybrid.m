function [x,y] = Hybrid(t)
t=12*pi*t+pi;
x=t.*cos(t);
y=t.*sin(t);

idx=y>0;
t_i=t(idx);
x(idx)=max([t_i );
y(idx)=-t_i.*(abs(cos(t_i+pi/4)).*cos(t_i+pi/4)-abs(sin(t_i+pi/4)).*sin(t_i+pi/4));

% range_x=abs(max(x)-min(x));
% range_y=abs(max(y)-min(y));
% y=(y-min(y)-range_y/2)/range_x+0.5;
% x=(x-min(x)-range_x/2)/range_x+0.5;
end

