%% Splitting of initial sampling generation so that sampling does not need to be repeated
%clear;clc;

sampletime=string(datetime('now','Format','yyyyMMdd_HHmmss'));
tic
Inputs

x_min = min(x_lim); x_max = max(x_lim); x_rng=x_max-x_min;
y_min = min(y_lim); y_max = max(y_lim); y_rng=y_max-y_min;

if method==1
    type=1;
    xt=linspace(x_min+pad, x_max-pad, n);
    yt=linspace(y_min+pad, y_max-pad, n);
    [xt, yt]=meshgrid(xt,yt);
    xt=xt(:);yt=yt(:);
    t=zeros(n^2,1);
elseif method==2 || method==3
    type=2;
    xt1=linspace(x_min+pad, x_max-pad, 3);
    yt1=linspace(y_min+pad, y_max-pad, 3);
    [xt1, yt1]=meshgrid(xt1,yt1);
    xt2=linspace(x_min+pad+(x_rng-2*pad)/4, x_max-pad-(x_rng-2*pad)/4, 2);
    yt2=linspace(y_min+pad+(y_rng-2*pad)/4, y_max-pad-(y_rng-2*pad)/4, 2);
    [xt2, yt2]=meshgrid(xt2,yt2);
    xt=[xt1(:);xt2(:)];
    yt=[yt1(:);yt2(:)];
    t=zeros(m,1);
end

if doaprint
    for i=1:size(xt)
        % TCS ON MRD
        ztB(i)=mrdtcs(xt(i), yt(i));
        t(i)=toc; 
    end
    word='TCS';
else
    [initindex, dist]=dsearchn(table2array(dataB(:,{'x','y'})),[xt yt]);
    [xt, yt, ztB]=table2array(dataB(initindex,:));
    % Record the time it took to find the initial points
    t(1:n^2+1)=toc;
    word='CT';
end

x_lim_in = x_lim;
y_lim_in = y_lim;
pad_in = pad;

% Creating a matrix of test points
testpoints=[xt yt ztB];

% Save the points and sampling time to be called later
save(strcat(fullfile(pwd,'/Initial Samplings'),'/',word,'_t',num2str(type),...
    '_',func2str(SurfB),'_n',num2str(n),'.mat'),"testpoints","t","sampletime","x_lim_in","y_lim_in","pad_in") 