%% main.m
% Authors: Jake Colwell and Zyaire Howard
% Created: January 15, 2025
% Last Major Modification: April 17, 2025
% Fit a model of a surface to a sparse point cloud and generate a path to be printed
% Accompanies the paper: (INSERT DOI AFTER PUBLISHING)
% Reccomended toolboxes: Parallel Computing Toolbox

% This is a massive Frankenstein's monster of code that combines 3 different
% surface mapping methods including:
%   (1) Fitting Bezier surfaces (based on methods from [1])
%   (2) Bayesian Experiment with default priors (based on methods from [2] 
%       and functions from [3])
%   (3) Bayesian Experiment with priors trained on CT scanned data of 
%       other surfaces (expanding upon [2])
% as well as settings to enable/disable certain functions of the code:
%   (1) doaprint: Controls if the current run to be simulated using the CT
%       scan data (False) or if this run is to use data aquired from TCS (True)
%   (2) savedata: Controls if the plots and workspace of the run are to be 
%       saved to Data/Results (True) or not (False). When true, all
%       variables from the workspace except figures and loaded data will be
%       saved to a .m file, all figures will be saved as .fig, .png, and .eps, 
%       the visual plots of the optimization will be saved to .tiff stacks,
%       and the command window log will be saved to a .txt file
%   (3) bulk: is not set directly in Inputs.m or main.m, but can be created
%       in an external script in order to allow the user to run main.m or 
%       Inputs.m inside of a loop without clearing important variables. This
%       allows scripts to be created that can loop these scripts over different 
%       parameters while preserving the ability to run them as individual scripts.
%       See bulksimstudy.m for an example of such a script.
% which results in a massive and confusing series of if statements. This
% worked well for our precise purposes in this study, but if you are trying
% to adapt this work for yourself, I wish you luck.

% Before running this script you must:
%   (1) Set desired settings in Inputs.m
%   (2) Ensure data for the surface(s) exists in '/Data/CT Scans'
%   (3) Enure an initial sampling for your desired settings exists in
%       '/Initial Samplings'. If it does not, then run generateInitialSamplings.m
%   (4) If using method 3, ensure a trained prior exists in '/TrainedPriors'. 
%       If it does not, then run trainPriors.m

%% Setup and Inputs
% Close all figures, clear command window
close all;clc
% Clear the workspace, but if calling from an external script, 
% do not clear some important variables
if ~exist('bulk','var')
    clear
    % Add all current folders to the path
    addpath(genpath(fullfile(pwd)))
else
    clearvars -except bulk f fA fB dataA dataB nameA nameB m n t2ns ...
        Curve doaprint savedata surfnames SurfA SurfB AFs A method safeloopvar
end

% Start a timer
timer=tic;

% Record the start time to a string to use in the filename
starttime=string(datetime('now','Format','yyyyMMdd_HHmmss'));

% Disable warnings about gprMdlCV in parfor 
warning('off','all')

% Run the script containing input settings (Inputs.m)
Inputs

% Find the name of Surface B to use in filenames
[~, nameB,~]=fileparts(SurfB);

% Create a filename to write all the data with
if doaprint; type='real'; else; type='sim'; end
if method==1
    fname0=strcat(starttime,'_',nameB,'_','M',num2str(method),'_',type);
elseif method==2
    fname0=strcat(starttime,'_',nameB,'_','M',num2str(method),'_',func2str(A),'_',type);
elseif method==3
    [~, nameA,~]=fileparts(SurfA);
    fname0=strcat(starttime,'_',nameA,'_',nameB,'_','M',num2str(method),'_',func2str(A),'_',type);
end
fname=strcat(fullfile(pwd,'/Data'),'/Results/',fname0,'/',fname0); % Filename to write to

% If saving data, make a new folder with the filename and add it to the path
if savedata
    mkdir('./Data/Results', fname0)
    % Enable logging of the command window to save as a .txt file
    diary(strcat(fname,'.txt'))
end

% Import CT scan data, but only if not doing a bulk run to save time
if ~exist('bulk','var')
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tImporting Surface B ...\n'])
[dataB, fB, nameB]=importCTdata(SurfB,y_lim,x_lim,pad,res_s);
if method==3
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tImporting Surface A ...\n'])
[dataA, fA, nameA]=importCTdata(SurfA,y_lim,x_lim,pad,res_s);
end
end

%% Calculations
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tPerforming Initial Calculations ...\n'])

% Generate high-resolution x and y vectors for surface plotting / prediction
x=linspace(x_min+pad, x_max-pad, res_s);
y=linspace(y_min+pad, y_max-pad, res_s);

% Generate the high-resolution grid of these (x,y) points
[xBp, yBp]=meshgrid(x,y);
% Reform them into lists of x and y coordinates
xd=xBp(:);
yd=yBp(:);

% Interpolate Z-Values at the specified resolution
if method==3
    zA=reshape(fA([xd,yd]),res_s,res_s);
end
zB=reshape(fB([xd,yd]),res_s,res_s);
zBl=zB(:);

% Call Initial Sampling generated with 'generateInitialSamplings.m'
% Create the filename that matches the current settings
if method==1
    type=1;
elseif method==2 || method==3
    type=2;
end
if doaprint
    word='TCS';
else
    word='CT';
end

% This is not important, it is just to make Matlab happy
t=zeros(m,1); % These values will get overwritten when the data is loaded
testpoints=zeros(m,1); % ... But Matlab throws warnings if these aren't pre-allocated

% Load the initial sampling
load(strcat(fullfile(pwd,'/Initial Samplings'),'/',word,'_t',num2str(type),...
    '_',nameB,'_n',num2str(n),'.mat'))

% Check that all the intial sampling settings match the current settings
if all(x_lim == x_lim_in) && all(y_lim == y_lim_in) && (pad == pad_in) && (res_in == res_s)
    fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\t  ... Initial sampling successfully recovered.\n'])
else
    disp(['ERROR: Inputs do not match saved sampling. Either create a new' ...
        ' sampling with these inputs or change your inputs to match the initial sampling.'])
    return
end

% Generate the iteration vector for the main for loop, ensuring that the 
% inputted m and n values make sense
if doaprint && method==1
    % If doing a print with Method 1, it should only run once
    iter=n;
else
    if m>=n
        iter=n:m;
    elseif m<n
        disp('Error: Final number of points (m) must be greater than or equal to n')
        return
    end
end

% Perform pre-loop actions like table initialization, that vary by method
if method==1
    % Make a cell array to store trained models at each iteration
    bezMdls=cell(m,1);
    % Create inputs and settings for fmincon
    A=[];B=[];Aeq=[];Beq=[];lb=[];ub=[];nonlin=[];
    opts=optimoptions("fmincon",...
        "Algorithm","interior-point",...
        "MaxFunctionEvaluations",10000000,...
        "ConstraintTolerance",.00001,...
        "OptimalityTolerance",0.00001,...
        'Display','none');
elseif method==2
    % Make a cell arrays to store trained GPR models and predictions at each iteration
    gprMdls=cell(m,1);
    zBp=cell(m,1);
    zBpCImx=zBp;
    zBpCImn=zBp;
    plotabsError=zBp;
    fB_p=zBp;
elseif method==3
    % Make a cell arrays to store trained GPR models and predictions at each iteration
    gprMdls=cell(m,1);
    zBp=cell(m,1);
    zBpCImx=zBp;
    zBpCImn=zBp;
    plotabsError=zBp;

    % Load a previously trained GPR to serve as a prior and validate settings
    load(strcat(fullfile(pwd,'/TrainedPriors'),'/',nameA,'.mat'))
    if ~(all(x_lim == x_lim_pri) && all(y_lim == y_lim_pri) && (pad == pad_pri))
        disp(['ERROR: Inputs do not match saved prior. Either create a new' ...
            ' prior with these inputs or change your inputs to match the initial sampling.'])
        return
    end

    % Load the prior model into the cell array as the (n-1)th model
    gprMdls{n-1}=gprMdlA;
end

% Initialize tables to store model performance metrics at each iteration
Train = table(zeros(m,1),zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'pv','ME','MAE','RMSE'});
CV = table(zeros(m,1),zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'pv','ME','MAE','RMSE'});
Test = table(zeros(m,1),zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'pv','ME','MAE','RMSE'});
modelPerformance=table(Train, CV, Test, zeros(m,1),zeros(m,1),'VariableNames',{'Train','CV','Test','MaxCIWidth','C-RMSE'});
modelPerformance(n,:).("C-RMSE")=NaN;

% Create a figure to plot too
if method~=1 || savedata==true
f(1)=figure('position',[1 1 950 500]);
f(2)=figure('position',[1 501 950 500]);
end

% Enter the main loop
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tEntering the main loop ...\n'])
if method==1
    parfor iter=iter
        fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\t  ... Calculating Bézier Surface for iter=%i\n'],iter)
        
        % Jafari and Gans simulation for iter=n:1:m
        initialsampling{iter} = load(strcat(fullfile(pwd,'/Initial Samplings')...
            ,'/',word,'_t',num2str(type),'_',nameB,'_n',num2str(iter),'.mat'));
        if ~(all(x_lim == initialsampling{iter}.x_lim_in) && all(y_lim == initialsampling{iter}.y_lim_in) && (pad == initialsampling{iter}.pad_in) && (res_s == initialsampling{iter}.res_in))
            disp(['ERROR: Inputs do not match saved sampling. Either create a new' ...
                ' sampling with these inputs or change your inputs to match the initial sampling.'])
        end
        
        P_i=reshape(initialsampling{iter}.testpoints,[iter, iter, 3]);
        u=linspace(0,1,iter);
        v=linspace(0,1,iter);
        fun=@(P)cost(u,v,P,P_i);
        [P_o{iter},J]=fmincon(fun,P_i,A,B,Aeq,Beq,lb,ub,nonlin,opts);

        % Predict surface at higher resolution
        train_pred=bezierSurf(u,v,P_o{iter});
        test=bezierSurf(rescale(x),rescale(y),P_o{iter});
        fB_p{iter}=scatteredInterpolant(test(:,1:2),test(:,3),'natural');

        % Correct for Nozzel Width
        if doaprint
            testpoints_corr=tcscorrect(xBp,yBp,reshape(test(:,3),res_s,res_s),testpoints)
            P_i=reshape(testpoints_corr,[iter, iter, 3]);
            [P_o{iter},J]=fmincon(fun,P_i,A,B,Aeq,Beq,lb,ub,nonlin,opts);
    
            % Predict surface at higher resolution
            train_pred=bezierSurf(u,v,P_o{iter});
            test=bezierSurf(rescale(x),rescale(y),P_o{iter});
            fB_p{iter}=scatteredInterpolant(test(:,1:2),test(:,3),'natural');
        end

        zBp{iter}=reshape(test(:,3),res_s,res_s);
        
        % Bézier Cross-Validation
        cvError=zeros(iter-2,iter);
        zBcv=zeros((iter-2)*2,iter);
        index=1;
        for i=2:iter-1
            fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\t  ... Beginning Bézier Cross-Validation for iter=%i, i=%i\n'],iter,i)
            rows=setdiff(1:iter,i);
            for j=[true false]
                if j
                    fun=@(P)cost(u,v(rows),P,P_i(rows,:,:));
                else
                    fun=@(P)cost(u(rows),v,P,P_i(:,rows,:));
                end
                [P_cv,J]=fmincon(fun,P_i,A,B,Aeq,Beq,lb,ub,nonlin,opts);
                SB_cv=bezierSurf(linspace(0,1,res_s),linspace(0,1,res_s),P_cv);
                fB_cv=scatteredInterpolant(SB_cv(:,1:2),SB_cv(:,3),'natural');
                if j
                    SB_cv2=bezierSurf(u,v(i),P_o{iter});
                else
                    SB_cv2=bezierSurf(u(i),v,P_o{iter});
                end
                zBcv(index,:)=fB_cv(SB_cv2(:,1:2));
                cvError(index,:)=SB_cv2(:,3)'-zBcv(index,:);
                index=index+1;
            end
        end

        % Error Calculation
        trainError = fB_p{iter}(initialsampling{iter}.testpoints(:,1:2))-initialsampling{iter}.testpoints(:,3);
        trainabsError = abs(trainError);
        cvError=cvError(:);
        cvabsError = abs(cvError);
        alldata=dataB; % This assignment avoids a warning about broadcast variable
        if ~doaprint
        testdata=alldata(setdiff(1:size(dataB,1),initialsampling{iter}.initindex),:);
        else
        testdata=alldata;
        end
        testError = fB_p{iter}(table2array(testdata(:,{'x','y'})))-testdata.z;
        testabsError = abs(testError);
        fB2=fB; % This assignment avoids a warning about broadcast variable
        plotabsError{iter}=abs(fB(xBp,yBp)-zBp{iter});
        
        % Calculate Metrics
        modelPerformance(iter,:).Train.pv = max(trainabsError);
        modelPerformance(iter,:).Train.ME = mean(trainError);
        modelPerformance(iter,:).Train.MAE = mean(trainabsError);
        modelPerformance(iter,:).Train.RMSE = std(trainError);
        modelPerformance(iter,:).CV.pv = max(cvabsError);
        modelPerformance(iter,:).CV.ME = mean(cvError);
        modelPerformance(iter,:).CV.MAE = mean(cvabsError);
        modelPerformance(iter,:).CV.RMSE = std(cvError);
        modelPerformance(iter,:).Test.pv = max(testabsError);
        modelPerformance(iter,:).Test.ME = mean(testError);
        modelPerformance(iter,:).Test.MAE = mean(testabsError);
        modelPerformance(iter,:).Test.RMSE = std(testError);
        modelPerformance(iter,:).MaxCIWidth = NaN;
    end
    for i=min(iter)+1:max(iter)
        modelPerformance(i,:).("C-RMSE")=rmse(zBp{i},zBp{i-1},'all');
    end
    for iter=iter
        if savedata
        % Plot surface to make animation
        figure(f(1))
        % Test points on Surface B
        plot3(initialsampling{iter}.testpoints(:,1),initialsampling{iter}.testpoints(:,2),initialsampling{iter}.testpoints(:,3),'LineStyle','none','MarkerSize',5,'Marker','o', ...
        'MarkerEdgeColor','white','MarkerFaceColor','black','LineWidth',2);
        hold on
        % Mean Surface
        surf(xBp,yBp,zBp{iter},reshape(plotabsError{iter},res_s,res_s),'LineStyle','none');
        % Make plot pretty 
        xlabel('x (mm)')
        ylabel('y (mm)')
        zlabel('z (mm)')
        axis equal
        axis([x_min x_max y_min y_max z_min z_max])
        view(3)
        e=colorbar;
        e.Label.String='Absolute Error (mm)';
        clim([0 cmax])
        title({strcat('Bézier Surface Fit, n=m=',num2str(iter))}) 
        legend('Tested Points','Bézier Surface Prediction','Orientation','horizontal','Location','southoutside')
        colormap('viridis')
        fontsize(f(1), scale=2)
        hold off
        drawnow

        %Save frame to an image stack
        frame = getframe(f(1));
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        imwrite(imind,cm,strcat(fname,'_view3.tiff'),'tiff','WriteMode','append');
        
        view(2)
        set(legend(gca),'Orientation','vertical','Location','southwestoutside')
        frame = getframe(f(1));
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        imwrite(imind,cm,strcat(fname,'_view2.tiff'),'tiff','WriteMode','append');
        clear im imind cm frame
        end
    end
    iter=max(iter);
    zBp_all=zBp;
    zBp=zBp{iter};
    plotabsError=plotabsError{iter};
    bezMdls=P_o;
    P_o=P_o{iter};
    testpoints=initialsampling{iter}.testpoints;
elseif method==2 || method==3
    % Main BO Loop 
    for iter=iter 
        % Create a table of the training and test data
        train=table(testpoints(1:iter,1),testpoints(1:iter,2),testpoints(1:iter,3),'VariableNames',{'x', 'y','z'});
        
        % Train a GPR on surface B
        gprMdl_prior=gprMdls{iter-1};
        if method == 2 && isempty(gprMdl_prior)
            gprMdlB = fitrgp(train,'z');
        else
            gprMdlB = fitrgp(train,'z', ...
                'Basis',gprMdl_prior.BasisFunction,...
                'Beta',gprMdl_prior.Beta,...
                'Sigma',gprMdl_prior.Sigma,...
                'SigmaLowerBound',max(min(gprMdl_prior.Sigma-0.001,1e-3),1e-7),...
                'KernelFunction',gprMdl_prior.KernelFunction,...
                'KernelParameters',gprMdl_prior.KernelInformation.KernelParameters);
        end
        gprMdls{iter}=gprMdlB;
    
        % Use the GPR to predict surface B at higher resolution
        prediction=table(xd,yd,'VariableNames',{'x','y'});
        [zBpl,zBpsd,zBpCI] = predict(gprMdlB,prediction,'Alpha',0.1);

        zBp{iter}=reshape(zBpl,res_s,res_s);
        
        if doaprint
            testpoints_corr=tcscorrect(xBp,yBp,reshape(test(:,3),res_s,res_s),testpoints);
            train=table(testpoints_corr(1:iter,1),testpoints_corr(1:iter,2),testpoints_corr(1:iter,3),'VariableNames',{'x', 'y','z'});
            if method == 2 && isempty(gprMdl_prior)
                gprMdlB = fitrgp(train,'z');
            else
                gprMdlB = fitrgp(train,'z', ...
                    'Basis',gprMdl_prior.BasisFunction,...
                    'Beta',gprMdl_prior.Beta,...
                    'Sigma',gprMdl_prior.Sigma,...
                    'SigmaLowerBound',max(min(gprMdl_prior.Sigma-0.001,1e-3),1e-7),...
                    'KernelFunction',gprMdl_prior.KernelFunction,...
                    'KernelParameters',gprMdl_prior.KernelInformation.KernelParameters);
            end

            gprMdls{iter}=gprMdlB;

            % Use the GPR to predict surface B at higher resolution
            prediction=table(xd,yd,'VariableNames',{'x','y'});
            [zBpl,zBpsd,zBpCI] = predict(gprMdlB,prediction,'Alpha',0.1);

            zBp{iter}=reshape(zBpl,res_s,res_s);
        end

        % Caluculate the lower and upper bounding surfaces from the coinfidence interval
        zBpCImx{iter}=reshape(zBpCI(:,2),res_s,res_s);
        zBpCImn{iter}=reshape(zBpCI(:,1),res_s,res_s);

        % Leave-One Out Cross-Validation
        cvError=zeros(iter,1);
        zBcv=zeros(iter,1);
        parfor i=1:iter
            warning('off','all')
            mat=train;
            % Create a table of the training and test data
            train_cv=train((1:iter)~=i,:);
            % Train a GPR on surface B
            if method == 2 && isempty(gprMdl_prior)
                gprMdlB_cv = fitrgp(train_cv,'z');
            else
                gprMdlB_cv = fitrgp(train_cv,'z', ...
                    'Basis',gprMdl_prior.BasisFunction,...
                    'Beta',gprMdl_prior.Beta,...
                    'Sigma',gprMdl_prior.Sigma,...
                    'SigmaLowerBound',max(min(gprMdl_prior.Sigma-0.001,1e-3),1e-7),...
                    'KernelFunction',gprMdl_prior.KernelFunction,...
                    'KernelParameters',gprMdl_prior.KernelInformation.KernelParameters);
            end
            zBcv(i)=predict(gprMdlB_cv,train(i,{'x','y'}));
            cvError(i)=table2array(train(i,'z'))-zBcv(i);
        end

        % Error Calculation
        trainError = table2array(predict(gprMdlB,train(:,{'x','y'}))-train(:,'z'));
        trainabsError = abs(trainError);
        plotabsError{iter}=abs(zBp{iter}-zB);
        cvabsError = abs(cvError);
        if ~doaprint
        testdata=dataB(setdiff(1:size(dataB,1),initindex),:);
        else
        testdata=dataB;
        end
        testError = table2array(predict(gprMdlB,testdata(:,{'x','y'}))-testdata(:,'z'));
        testabsError = abs(testError);

        % Calculate metrics
        modelPerformance.Train.pv(iter) = max(trainabsError);
        modelPerformance.Train.ME(iter) = mean(trainError);
        modelPerformance.Train.MAE(iter) = mean(trainabsError);
        modelPerformance.Train.RMSE(iter) = std(trainError);
        modelPerformance.CV.pv(iter) = max(cvabsError);
        modelPerformance.CV.ME(iter) = mean(cvError);
        modelPerformance.CV.MAE(iter) = mean(cvabsError);
        modelPerformance.CV.RMSE(iter) = std(cvError);
        modelPerformance.Test.pv(iter) = max(testabsError);
        modelPerformance.Test.ME(iter) = mean(testError);
        modelPerformance.Test.MAE(iter) = mean(testabsError);
        modelPerformance.Test.RMSE(iter) = std(testError);
        modelPerformance.MaxCIWidth(iter) = max(abs((zBpCI(:,2)-zBpCI(:,1))/2));
        if ~isempty(zBp{iter-1})
        modelPerformance.("C-RMSE")(iter)=rmse(zBp{iter},zBp{iter-1},'all');
        end
        
        if iter~=m
            % Find a new point to test
            newpt=table2array(A(prediction,testpoints(:,1:2),gprMdls{iter}));
            
            % Observe it and add it to the training data
            testpoints(iter+1,1:2)=newpt(1:2);
            if doaprint
                % TCS ON MRD
                testpoints(iter+1,3)=mrdtcs(newpt(1), newpt(2));
                t(iter)=toc(timer);
            else
                newpt_id=dsearchn(table2array(dataB(:,{'x','y'})),newpt);
                testpoints(iter+1,:)=table2array(dataB(newpt_id,:));
                initindex = [initindex; newpt_id];
            end
        end

        % Record and display information
        % Plot surface to make animation
        figure(f(1))
        % Test points on Surface B
        plot3(testpoints(1:iter,1),testpoints(1:iter,2),testpoints(1:iter,3),'LineStyle','none','MarkerSize',5,'Marker','o', ...
        'MarkerEdgeColor','white','MarkerFaceColor','black','LineWidth',2);
        hold on
        % Test points on Surface B
        if iter~=m
            plot3(testpoints(iter+1,1),testpoints(iter+1,2),...
                predict(gprMdlB,table(testpoints(iter+1,1),testpoints(iter+1,2),'VariableNames',{'x','y'}))+0.1,...
                'LineStyle','none','LineWidth',2,...
                'MarkerSize',5,'Marker','*','MarkerEdgeColor','red');
        end
        % Mean Surface
        surf(xBp,yBp,zBp{iter},plotabsError{iter},'LineStyle','none');
        % Surface B
        % surf(x,y,zB,'FaceAlpha',.1,'FaceColor',[.5 0 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
        % Maximum Surface
        surf(xBp,yBp,zBpCImx{iter}, ...
            'FaceAlpha',.1,'FaceColor',[.5 .5 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
        % Minimum Surface
        surf(xBp,yBp,zBpCImn{iter}, ...
            'FaceAlpha',.1,'FaceColor',[.5 .5 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
        % Make plot pretty 
        xlabel('x (mm)')
        ylabel('y (mm)')
        zlabel('z (mm)')
        axis equal
        axis([x_min x_max y_min y_max z_min z_max])
        view(3)
        e=colorbar;
        e.Label.String='Absolute Error (mm)';
        clim([0 cmax])
        title({strcat('Bayesian Experiment, n=',num2str(iter))}) 
        if iter~=m
        legend('Tested Points','Next Point to Test','Mean GPR Prediction','99% CI','Orientation','horizontal','Location','southoutside')
        elseif iter==m
        legend('Tested Points','Mean GPR Prediction','99% CI','Orientation','horizontal','Location','southoutside')
        end
        colormap('viridis')
        fontsize(f(1), scale=2)
        hold off
        drawnow

        
        %Save frame to an image stack 
        if savedata
        frame = getframe(f(1));
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        imwrite(imind,cm,strcat(fname,'_view3.tiff'),'tiff','WriteMode','append');
        
        view(2)
        set(legend(gca),'Orientation','vertical','Location','southwestoutside')
        frame = getframe(f(1));
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        imwrite(imind,cm,strcat(fname,'_view2.tiff'),'tiff','WriteMode','append');
        clear im imind cm frame
        end

        t(iter)=toc(timer);
        fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\t  ... Completed BO iteration for iter=%i\n'],iter)
    end
    zBp_all=zBp;
    zBp=zBp{iter};
    plotabsError=plotabsError{iter};
    zBpCImx=zBpCImx{iter}; 
    zBpCImn=zBpCImn{iter};
    clear trainError trainabsError cvabsError testdata testError testabsError
end

if method == 1
modelPerformance.n = ((1:m).^2)';
modelPerformance = modelPerformance(modelPerformance.n>=n^2,:);
elseif method == 2 || method == 3
modelPerformance.n = (1:m)';
modelPerformance = modelPerformance(modelPerformance.n>=n,:);
end

%% Curve Mapping
% Create the desired curve
[u_c, v_c] = Curve(linspace(0, 1, res_c+1)');
if method == 1
    wypts=zeros(length(u_c),3);
    for a=1:length(u_c)
        wypts(a,:)=bezierSurf(u_c(a),v_c(a),P_o);
    end
    x_c=wypts(:,1);
    y_c=wypts(:,2);
    z_c=wypts(:,3);
elseif method == 2 || method == 3
    % Use direct projection on the curve (map parameter space to real space)
    x_c = (x_max - x_min) * u_c + x_min;
    y_c = (y_max - y_min) * v_c + y_min;
    
    % Create a table for the curve points to predict deformation using GPR
    curve_pts = table(x_c, y_c, 'VariableNames', {'x', 'y'});
    
    % Predict the deformation values (phi) for the curve points using the GPR model
    [z_c, ~, ~] = predict(gprMdlB, curve_pts);
    % Assemble the points
    wypts=[x_c,y_c,z_c];
end

if doaprint
    wypts=printcorrect(xBp,yBp,zBp,wypts);
end

%% Plotting
close all
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tCreating Plots ...\n'])

if size(modelPerformance,1)==1; fignum=4; else; fignum=6; end

f=gobjects(fignum,1);
for l=1:size(f,1)
    if ~savedata
        f(l)=figure('WindowStyle','docked');
    else
        f(l)=figure(figure('Position',[250*(l-1) 600 750 750]));
    end
end

% Figure 1: Plot of Surface A, Surface B, the training data
figure(f(1))
hold on
mask=~all(testpoints==0,2);
if method==3
    % Surface A
    surf(x,y,zA,'FaceAlpha',.1,'FaceColor',[1 .5 0],'EdgeColor',[1 .5 0],'LineStyle','none');
    % Phi
    quiver3(testpoints(mask,1),testpoints(mask,2),fA(testpoints(mask,1),testpoints(mask,2)),zeros(iter,1),zeros(iter,1),testpoints(mask,3)-fA(testpoints(mask,1),testpoints(mask,2)),0)
    % Test points on Surface A
    plot3(testpoints(mask,1),testpoints(mask,2),fA(testpoints(mask,1),testpoints(mask,2)),'LineStyle','none','Marker','.')
end
% Surface B
surf(x,y,zB,'FaceAlpha',.1,'FaceColor',[.5 0 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
% Test points on Surface B
plot3(testpoints(mask,1),testpoints(mask,2),testpoints(mask,3),'LineStyle','none','Marker','*')
% Make Plot Pretty
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis equal
axis([-30 30 -30 30 0 20])
if method==3
legend('Surface A','Surface B','\phi','f_A(x,y)','f_{B}(x,y)',Location='northeast')
else
legend('Surface B','f_{B}(x,y)',Location='northeast')
end
view(3)
fontsize(gcf, scale=1.5)


% Figure 2: Plot of predicted surface and heatmap of conidence interval width
figure(f(2))
if method == 2 || method == 3
    subplot(2,1,1)
end
hold on
% Mean Surface
surf(xBp,yBp,zBp,plotabsError,'LineStyle','none');
% Surface B
% surf(x,y,zB,'FaceAlpha',.1,'FaceColor',[.5 0 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
if method ==1
    title({'Bézier Surface Model','of a Freeform Surface'})
elseif method == 2 || method == 3
    % Maximum Surface
    surf(xBp,yBp,zBpCImx, ...
        'FaceAlpha',.1,'FaceColor',[.5 .5 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
    % Minimum Surface
    surf(xBp,yBp,zBpCImn, ...
        'FaceAlpha',.1,'FaceColor',[.5 .5 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
    title({'Gaussian Process Regression Model','of a Freeform Surface'})
end
% Make plot pretty
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis equal
axis([-30 30 -30 30 0 20])
view(3)
e=colorbar;
e.Label.String='Absolute Error (mm)';
clim([0 cmax])
colormap('viridis')

if method == 2 || method == 3
    subplot(2,1,2)
    % Confidence Interval Heatmap
    contourf(xBp,yBp,reshape((zBpCI(:,2)-zBpCI(:,1))/2,res_s,res_s),n,'LineStyle','none')
    % Make plot pretty
    axis([-30+pad 30-pad -30+pad 30-pad])
    axis equal
    xlabel('x(mm)')
    ylabel('y(mm)')
    c=colorbar;
    c.Label.String='90% CI Width (mm)';
    clim([0 cmax])
    title('\phi(x,y) 90% Confidence Interval Width')
end
fontsize(gcf, scale=1.5) % Note that fontsize increase affects entie figure


% Figure 3: Printability Evaluation
figure(f(3))
if method == 2 || method == 3
    subplot(2,1,1)
end
% Plot of area where the mean surface is within the maximum deviation from the mean
canitprint=abs(zBp-zB)<cmax;
contourf(xBp,yBp,reshape(canitprint,res_s,res_s),[-.01 .99],'LineStyle','none')
% Make plot pretty
axis equal
xlabel('x(mm)')
ylabel('y(mm)')
c=colorbar;
c.Label.String='False - True';
clim([0 1])
c.Ticks=[0 1];
title({'Is the mean prediction within tolerance?','|f_{A''}(x,y)-f_B(x,y)|<d_{max}'})
double=viridis(5);
colormap(gca,[double(1,:); double(end,:)])

if method == 2 || method == 3
    subplot(2,1,2)
    % Plot of where the confidence interval is smaller than the max deviation
    canitprint=abs(zBpCI(:,1)-zBpCI(:,2))/2<cmax;
    contourf(xBp,yBp,reshape(canitprint,res_s,res_s),[-.01 .99],'LineStyle','none')
    % Make plot pretty
    axis equal
    xlabel('x(mm)')
    ylabel('y(mm)')
    c=colorbar;
    c.Label.String='False - True';
    clim([0 1])
    c.Ticks=[0 1];
    title({'Is the CI smaller than the max deviation?','u_{90%}(x,y)<d_{max}'})
    double=viridis(5);
    colormap(gca,[double(1,:); double(end,:)])
end
fontsize(gcf, scale=1.5)

% Figure 4: Presentation Plots
figure(f(4))
hold on
% Mean Surface
surf(xBp,yBp,zBp,plotabsError,'LineStyle','none');
% Test points on Surface B
plot3(testpoints(mask,1),testpoints(mask,2),testpoints(mask,3),'LineStyle','none','MarkerSize',5,'Marker','o', ...
    'MarkerEdgeColor','red','LineWidth',2)
% Mapped Curve
plot3(x_c,y_c,z_c,'LineWidth',2,'Color','red')
% Make plot pretty
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis equal
axis([-30 30 -30 30 0 20])
view(3)
e=colorbar;
e.Label.String='Absolute Error (mm)';
clim([0 cmax])
title('Predicted Surface')
colormap('viridis')
fontsize(gcf, scale=1.5)

% Figure 5 Error Metric Plots
if n~=m
figure(f(5))
subplot(2,2,1)
hold on

errmat=[table2array(modelPerformance.Train(:,{'MAE','pv','RMSE'})),table2array(modelPerformance.Test(:,{'MAE','pv','RMSE'})),table2array(modelPerformance.CV(:,{'MAE','pv','RMSE'})),modelPerformance.MaxCIWidth];
errmax=10^ceil(log10(max(errmat(errmat~=0),[],'all')));
errmin=10^floor(log10(min(errmat(errmat~=0),[],'all')));
axvec=[min(modelPerformance.n) max(modelPerformance.n) errmin errmax];
plot(modelPerformance.n,modelPerformance.Test.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('pv_{test}','pv_{train}','pv_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Maximum Absolute Error','(mm)'})
axis(axvec)

subplot(2,2,2)
hold on
plot(modelPerformance.n,modelPerformance.Test.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('MAE_{test}','MAE_{train}','MAE_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Mean Absolute Error','(mm)'})
axis(axvec)

subplot(2,2,3)
hold on
plot(modelPerformance.n,modelPerformance.Test.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle',':','LineWidth',2)
% plot(modelPerformance.n,modelPerformance.("C-RMSE"),'Color',[0.4660 0.6740 0.1880],'LineStyle','-.','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('RMSE_{test}','RMSE_{train}','RMSE_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Root Mean Square Error', '(mm)'})
axis(axvec)

subplot(2,2,4)
hold on
plot(modelPerformance.n,modelPerformance.MaxCIWidth,'Color',[0.3010 0.7450 0.9330],'LineStyle','-','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('Maximum CI Width','Location','southoutside','Orientation','horizontal') 
ylabel({'Maximum 90% Confidence', 'Interval Width (mm)'})
axis(axvec)
if method==1
    text(10^mean(log10(axvec(1:2))),10^mean(log10(axvec(3:4))),'N/A','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',30)
end

han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
xlabel(han,'Number of Points (n)')
title(han,'Model Performance Evaluation')
fontsize(gcf, scale=1.5)
end

% Figure 6 Error Metric Plot
if n~=m
figure(f(6))
hold on
plot(modelPerformance.n,modelPerformance.Test.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.pv,'Color',[0.8500 0.3250 0.0980],'LineStyle',':','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Test.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.MAE,'Color',[0.9290 0.6940 0.1250],'LineStyle',':','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Test.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
plot(modelPerformance.n,modelPerformance.Train.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle','--','LineWidth',2)
plot(modelPerformance.n,modelPerformance.CV.RMSE,'Color',[0.4940 0.1840 0.5560],'LineStyle',':','LineWidth',2)
plot(modelPerformance.n,modelPerformance.MaxCIWidth,'Color',[0.3010 0.7450 0.9330],'LineStyle','-','LineWidth',2)
% plot(modelPerformance.n,modelPerformance.("C-RMSE"),'Color',[0.4660 0.6740 0.1880],'LineStyle','-.','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
axis(axvec)
legend('pv_{test}','pv_{train}','pv_{CV}','MAE_{test}','MAE_{train}','MAE_{CV}',...
    'RMSE_{test}','RMSE_{train}','RMSE_{CV}','Maximum CI Width','NumColumns',4,'Location','southoutside') 
xlabel('Number of Points (n)')
ylabel('Metric Value (mm)')
title('Model Performance Evaluation')
fontsize(gcf, scale=1.5)
end
%% Outputs
if savedata 
    savefig(f,strcat(fname,'.fig'))
    for figiter=1:max(size(f))
        exportgraphics(f(figiter),strcat(fname,"_f",num2str(figiter),".eps"))
        exportgraphics(f(figiter),strcat(fname,"_f",num2str(figiter),".png"))
    end
    save(strcat(fname,'.mat'),'-regexp','^(?!(f.?|data.)$).')
end
elapsedtime = toc(timer);
fprintf([char(datetime('now','Format','(HH:mm:ss)')),'\tDone :)\nCompleted: ',...
    char(datetime('now','Format','MM/dd/yyyy HH:mm:ss')),'\tElapsed Time: %.2f sec (%.2f min)\n'],...
    elapsedtime,elapsedtime/60);
diary off