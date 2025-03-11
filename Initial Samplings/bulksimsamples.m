% surfnames={'Surf1a.csv','Surf1b.csv','Surf1c.csv',...
%     'Surf2a.csv','Surf2b.csv','Surf2c.csv',...
%     'Surf3a.csv','Surf3b.csv','Surf3c.csv'};
Inputs

surfnames={'Surf3c_noise.csv'};

bulk=1;
for i=1:length(surfnames)
    method=1;
    SurfB=surfnames{i};
    [dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad);
    for n=3:15
        generateInitialSamplings
        fprintf('complete:\tt1\ti=%i \tn=%i\n',i,n)
    end
    method=2;
    n=13;
    generateInitialSamplings
    fprintf('complete:\tt2\ti=%i \tn=%i\n',i,n)
end