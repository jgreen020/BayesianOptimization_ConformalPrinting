% All surfaces to be tested
clear;clc
surfnames={'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
    'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
    'Surf3a.csv','Surf3b.csv','Surf3c_holes.csv'};
% Create bulk variable
bulk=1;
Inputs

% Import the surface data
SurfB=surfnames{4};
[dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);

%%
close all

L=2000;
filt = 1;
Fs = L/(x_lim(2)-x_lim(1)-2*pad);
T = 1/Fs;
x=linspace(x_lim(1)+pad,x_lim(2)-pad,L);
y=linspace(y_lim(1)+pad,y_lim(2)-pad,L);
[x, y]=meshgrid(x,y);
Z = reshape(fB(x(:),y(:)),L,[]);
F = fft2(Z);
F_filt=F;
F_filt(ceil(L*filt):end,ceil(L*filt):end)=0;
Z_filt=abs(ifft2(F_filt));
figure('WindowStyle','docked')
surf(x,y,Z,'LineStyle','none','FaceColor','b','FaceAlpha',0.2)
hold on
surf(x,y,Z_filt,'LineStyle','none','FaceColor','r','FaceAlpha',0.2)
axis equal
F2=abs(fftshift(F/L));
figure('WindowStyle','docked')
imagesc(F2)
colorbar

x_slice=x(L/2,:);
Z_slice=Z(L/2,:);
f=Fs*(linspace(-L/2,L/2,L))/L;
F_slice = fft(Z_slice);
F_slice_filt = F_slice;
F_slice_filt(abs(F_slice_filt/L)<0.001)=0;
Z_slice_filt = ifft(F_slice_filt);

figure('WindowStyle','docked')
subplot(2,1,1)
plot(x_slice,Z_slice)
hold on
plot(x_slice,Z_slice_filt)

subplot(2,1,2)
plot(f,abs(fftshift(F_slice/L)))
