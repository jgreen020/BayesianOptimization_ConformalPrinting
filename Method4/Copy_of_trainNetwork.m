clear;clc;close all
tic
fprintf('Making Network ...\n')
makeNetwork2re
fprintf('Loading Dataset ...\n')
training_data="Data/M4/surf_dataset3.mat";
load(training_data,"images","targets","ValidationData")
t_init = toc;
fprintf('Time to load dataset and create network: %.2f\n',t_init)
options = trainingOptions("adam",...
    "InitialLearnRate",0.001,...
    "LearnRateSchedule",exponentialLearnRate(DropFactor=0.9),...
    "MiniBatchSize",64,...
    "MaxEpochs",25,...
    "ExecutionEnvironment","auto",...
    'Plots','training-progress',...
    'ValidationData',ValidationData,...
    'OutputNetwork','best-validation');
fprintf('Starting Training ...\n')
[trained_net, data] = trainnet(images,targets,net,@multiloss,options);

t_train = toc;
fprintf('Time to train network: %.f\n',t_train)

fnum=size(dir('Data/M4/trained*.mat'),1)+1;
fprintf('Saving ...\n')
clear images targets ValidationData
save(strcat("Data/M4/trained_network",string(fnum),".mat"),"-v7.3")
disp('Done.')