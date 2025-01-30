surfnames={@Surface1a,@Surface1b,@Surface1c,...
    @Surface2a,@Surface2b,@Surface2c,...
    @Surface3a,@Surface3b,@Surface3c};
method=1;
for i=1:9
    SurfB=surfnames{i};
for n=2:15
    generateInitialSamplings
end
end

method=2;
n=13;
for i=1:9
    SurfB=surfnames{i};
    generateInitialSamplings
end