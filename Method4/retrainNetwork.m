clear;clc;close all
tic
network = 'Data/M4/trained_network5.mat';
fprintf('Loading Network ...\n')
load(network,"net")
fprintf('Loading Dataset ...\n')
Surf = 'Surf1a';
samps=225;
training_data=strcat("Data/M4/surf_dataset_",Surf,"_n",string(samps),".mat");
load(training_data,"images","targets","ValidationData","sample_sizes")
t_init = toc;
fprintf('Time to load dataset and create network: %.2f\n',t_init)
options = trainingOptions("adam",...
    "InitialLearnRate",0.001,...
    "LearnRateSchedule",exponentialLearnRate(DropFactor=0.9),...
    "MiniBatchSize",64,...
    "MaxEpochs",15,...
    "ExecutionEnvironment","auto",...
    'Plots','training-progress',...
    'ValidationData',ValidationData,...
    'OutputNetwork','last-iteration');
fprintf('Starting Training ...\n')
[trained_net, data] = trainnet(images,targets,net,@multiloss,options);

t_train = toc;
fprintf('Time to train network: %.f\n',t_train)

fnum=size(dir(strcat('Data/M4/train*',Surf,'*.mat')),1)+1;
fprintf('Saving ...\n')
clear images targets ValidationData
save(strcat("Data/M4/trained_network_",Surf,"_n",string(samps),".mat"),"-v7.3")
disp('Done.')