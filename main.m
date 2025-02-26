%% Simulation and implementation of Bezier Surface Fitting (Jafari and Gans), Vanilla BO, and BO with a CT scan prior
%% Jake Colwell and Zyaire Howard
%% January 15, 2025

%% Setup 
% Delete all figures, clear workspace and command window
close all;clear;clc;
% Add all current folders to the path
addpath(genpath(fullfile(pwd)))
% Start a timer
tic
% Record the start time to a string to use in the filename
starttime=string(datetime('now','Format','yyyyMMdd_HHmmss'));

%% Inputs
Inputs
fname=strcat(fullfile(pwd,'/Data'),'/Results/',starttime,'_',nameA,'_',nameB,'_','M',num2str(method)); % Filename to write to

%% Calculations
% range
x_min = min(x_lim); x_max = max(x_lim); x_rng=x_max-x_min;
y_min = min(y_lim); y_max = max(y_lim); y_rng=y_max-y_min;

% Generating x and y vectors 
x=linspace(x_min+pad, x_max-pad, res_s);
y=linspace(y_min+pad, y_max-pad, res_s);

% Generating a list of every (x,y) coordinate
[xd, yd]=meshgrid(x,y);
xd=xd(:);
yd=yd(:);
xBp=reshape(xd,res_s,res_s);
yBp=reshape(yd,res_s,res_s);


% Interpolate Z-Values at the specified resolution
zA=reshape(fA([xd,yd]),res_s,res_s);
zB=reshape(fB([xd,yd]),res_s,res_s);
zBl=zB(:);

% Call Initial Sampling generated with 'generateInitialSamplings.m'
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

t=zeros(m,1); % These values will get overwritten when the data is loaded
testpoints=zeros(m,1); % ... But Matlab throws warnings if these aren't pre-allocated

load(strcat(fullfile(pwd,'/Initial Samplings'),'/',word,'_t',num2str(type),...
    '_',nameB,'_n',num2str(n),'.mat'))
if all(x_lim == x_lim_in) && all(y_lim == y_lim_in) && (pad == pad_in)
    disp('Initial sampling successfully recovered.')
else
    disp(['ERROR: Inputs do not match saved sampling. Either create a new' ...
        ' sampling with these inputs or change your inputs to match the initial sampling.'])
    return
end

if method==1
    if ~doaprint
        if m>n
            iter=n:m;
        elseif m<n
            disp('Error: Final number of points (m) must be greater than or equal to n')
            return
        else 
            iter = m;
        end
    elseif doaprint
        iter=n;
    end
elseif method==2 || method==3
    % Determine how many iterations the user specified, m will be the variable for the for loop
    if m>n
       iter=n:m;
    elseif m<n
       disp('Error: Final number of points (m) must be greater than or equal to n')
       return
    else 
       iter = m;
    end
end

% Perform pre-loop actions like table initialization, that vary by method

if method==1
    bezMdls=cell(m,1);
    A=[];B=[];Aeq=[];Beq=[];lb=[];ub=[];nonlin=[];
    opts=optimoptions("fmincon",...
        "Algorithm","interior-point",...
        "MaxFunctionEvaluations",10000000,...
        "ConstraintTolerance",.00001,...
        "OptimalityTolerance",0.00001,...
        'Display','none');
elseif method==2
    gprMdls=cell(m,1);
    zBp=cell(m,1);
    zBpCImx=zBp;
    zBpCImn=zBp;
    plotabsError=zBp;
elseif method==3
    gprMdls=cell(m,1);
    zBp=cell(m,1);
    zBpCImx=zBp;
    zBpCImn=zBp;
    plotabsError=zBp;
    % Load a previously trained GPR to serve as a Prior
    load(strcat(fullfile(pwd,'/TrainedPriors'),'/',nameA,'.mat'))
    if all(x_lim == x_lim_pri) && all(y_lim == y_lim_pri) && (pad == pad_pri)
        %Sick
    else
        disp(['ERROR: Inputs do not match saved prior. Either create a new' ...
            ' prior with these inputs or change your inputs to match the initial sampling.'])
        return
    end
    gprMdls{n-1}=gprMdlA;
end

% Initialize tables for the loop
Train = table(zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'MaxAE','MAE','RMSE'});
CV = table(zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'MaxAE','MAE','RMSE'});
Test = table(zeros(m,1),zeros(m,1),zeros(m,1),'VariableNames',{'MaxAE','MAE','RMSE'});
modelPerformance=table(Train, CV, Test, zeros(m,1),'VariableNames',{'Train','CV','Test','MaxCIWidth'});
cvtimes=zeros(m,1);
% Create a figure to plot too
if method~=1 || savedata==true
f0=figure('Position',[0 0 1000 600]);
end

disp('Entering the main loop')
if method==1
    if doaprint
        % Jafari and Gans w/ TCS for one number
        disp('ERROR: Printing Not Yet Implemented')
        return
    else
        parfor iter=iter
            fprintf('Calculating Bézier Surface for iter=%i\n',iter)
            % Jafari and Gans simulation for iter=n:1:m
            initialsampling{iter} = load(strcat(fullfile(pwd,'/Initial Samplings'),'/',word,'_t',num2str(type),...
                '_',nameB,'_n',num2str(iter),'.mat'));
            if all(x_lim == initialsampling{iter}.x_lim_in) && all(y_lim == initialsampling{iter}.y_lim_in) && (pad == initialsampling{iter}.pad_in)
            else
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
            fB_p=scatteredInterpolant(test(:,1:2),test(:,3),'natural');
            zBp{iter}=reshape(test(:,3),res_s,res_s);

            % Bézier Cross-Validation
            cvError=zeros(iter-2,iter);
            zBcv=zeros((iter-2)*2,iter);
            index=1;
            for i=2:iter-1
                fprintf('Beginning Bézier Cross-Validation for iter=%i, i=%i\n',iter,i)
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
            trainError = fB_p(initialsampling{iter}.testpoints(:,1:2))-initialsampling{iter}.testpoints(:,3);
            trainabsError = abs(trainError);
            cvError=cvError(:);
            cvabsError = abs(cvError);
            alldata=dataB; % This assignment avoids a warning about broadcast variable
            testdata=alldata(setdiff(1:size(dataB,1),initialsampling{iter}.initindex),:);
            testError = fB_p(table2array(testdata(:,{'x','y'})))-testdata.z;
            testabsError = abs(testError);
            plotabsError{iter}=abs(fB(xBp,yBp)-zBp{iter});
            
            % Calculate Metrics
            modelPerformance(iter,:).Train.MaxAE = max(trainabsError);
            modelPerformance(iter,:).Train.MAE = mean(trainabsError);
            modelPerformance(iter,:).Train.RMSE = std(trainError);
            modelPerformance(iter,:).CV.MaxAE = max(cvabsError);
            modelPerformance(iter,:).CV.MAE = mean(cvabsError);
            modelPerformance(iter,:).CV.RMSE = std(cvError);
            modelPerformance(iter,:).Test.MaxAE = max(testabsError);
            modelPerformance(iter,:).Test.MAE = mean(testabsError);
            modelPerformance(iter,:).Test.RMSE = std(testError);
            modelPerformance(iter,:).MaxCIWidth = NaN;
            
            if savedata
            % Plot surface to make animation
            figure(f0)
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
            axis([x_min x_max y_min y_max 0 20])
            view(3)
            e=colorbar;
            e.Label.String='Absolute Error (mm)';
            clim([0 cmax])
            title({strcat('Bézier Surface Fit, n=m=',num2str(iter))}) 
            legend('Tested Points','Bézier Surface Prediction','Orientation','horizontal','Location','southoutside')
            colormap('viridis')
            fontsize(f0, scale=2)
            hold off
            drawnow

            %Save frame to an image stack
            frame = getframe(f0);
            im = frame2im(frame);
            [imind,cm] = rgb2ind(im,256);
            if iter == n
                imwrite(imind,cm,strcat(fname,'.tiff'),'tiff');
            else
                imwrite(imind,cm,strcat(fname,'.tiff'),'tiff','WriteMode','append');
            end
            end
        end
        iter=max(iter);
        zBp=zBp{iter};
        plotabsError=plotabsError{iter};
        P_o=P_o{iter};
        testpoints=initialsampling{iter}.testpoints;
    end
elseif method==2 || method==3
    % Main BO Loop 
    for iter=iter 
        % Create a table of the training and test data
        train=table(testpoints(1:iter,1),testpoints(1:iter,2),testpoints(1:iter,3),'VariableNames',{'x', 'y','z'});
    
        % Train a GPR on surface B
        if method == 2
            gprMdlB = fitrgp(train,'z');
        elseif method == 3
            gprMdlB = fitrgp(train,'z', ...
                'FitMethod',gprMdlA.FitMethod,...
                'Basis',gprMdlA.BasisFunction,...
                'Beta',gprMdlA.Beta,...
                'Sigma',gprMdlA.Sigma,...
                'Standardize',gprMdlA.ModelParameters.Standardize,...
                'KernelFunction',gprMdlA.KernelFunction,...
                'KernelParameters',gprMdlA.KernelInformation.KernelParameters);
        end
        gprMdls{iter}=gprMdlB;
    
        % Use the GPR to predict surface B at higher resolution
        prediction=table(xd,yd,'VariableNames',{'x','y'});
        [zBpl,zBpsd,zBpCI] = predict(gprMdlB,prediction,'Alpha',0.1);

        if iter~=m
            % Find a new point to test
            newpt=table2array(A(prediction,testpoints(:,1:2),gprMdls{iter}));
            
            % Observe it and add it to the training data
            testpoints(iter+1,1:2)=newpt(1:2);
            if doaprint
                % TCS ON MRD
                testpoints(iter+1,3)=mrdtcs(newpt(1), newpt(2));
                t(iter)=toc;
            else
                testpoints(iter+1,:)=table2array(dataB(dsearchn(table2array(dataB(:,{'x','y'})),newpt),:));
            end
        end

        zBp{iter}=reshape(zBpl,res_s,res_s);
    
        % Caluculate the lower and upper bounding surfaces from the coinfidence interval
        zBpCImx{iter}=reshape(zBpCI(:,2),res_s,res_s);
        zBpCImn{iter}=reshape(zBpCI(:,1),res_s,res_s);

        % Leave-One Out Cross-Validation
        cvError=zeros(iter,1);
        zBcv=zeros(iter,1);
        parfor i=1:iter
            mat=train;
            % Create a table of the training and test data
            train_cv=train((1:iter)~=i,:);
            % Train a GPR on surface B
            if method==2
                gprMdlB_cv = fitrgp(train_cv,'z');
            elseif method == 3
                gprMdlB_cv = fitrgp(train_cv,'z', ...
                    'FitMethod',gprMdlA.FitMethod,...
                    'Basis',gprMdlA.BasisFunction,...
                    'Beta',gprMdlA.Beta,...
                    'Sigma',gprMdlA.Sigma,...
                    'Standardize',gprMdlA.ModelParameters.Standardize,...
                    'KernelFunction',gprMdlA.KernelFunction,...
                    'KernelParameters',gprMdlA.KernelInformation.KernelParameters);
            end
            zBcv(i)=predict(gprMdlB_cv,train(i,{'x','y'}));
            cvError(i)=table2array(train(i,'z'))-zBcv(i);
        end

        % Error Calculation
        trainError = table2array(predict(gprMdlB,train(:,{'x','y'}))-train(:,'z'));
        trainabsError = abs(trainError);
        plotabsError{iter}=abs(zBp{iter}-zB);
        cvabsError = abs(cvError);
        testdata=dataB(setdiff(1:size(dataB,1),initindex),:);
        testError = table2array(predict(gprMdlB,testdata(:,{'x','y'}))-testdata(:,'z'));
        testabsError = abs(testError);

        % Calculate metrics
        calcModelPerformance
        
        % Record and display information
        % Plot surface to make animation
        figure(f0)
        % Test points on Surface B
        plot3(testpoints(1:iter,1),testpoints(1:iter,2),testpoints(1:iter,3),'LineStyle','none','MarkerSize',5,'Marker','o', ...
        'MarkerEdgeColor','white','MarkerFaceColor','black','LineWidth',2);
        hold on
        % Test points on Surface B
        if iter~=m
            zplot=zBp{iter};
            plot3(testpoints(iter+1,1),testpoints(iter+1,2),...
                predict(gprMdlB,table(testpoints(iter,1),testpoints(iter,1),'VariableNames',{'x','y'})),...
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
        axis([x_min x_max y_min y_max 0 20])
        view(2)
        e=colorbar;
        e.Label.String='Absolute Error (mm)';
        clim([0 cmax])
        title({strcat('Bayesian Optimization, n=',num2str(iter))}) 
        if iter~=m
        legend('Tested Points','Next Point to Test','Mean GPR Prediction','99% CI','Orientation','horizontal','Location','southoutside')
        elseif iter==m
        legend('Tested Points','Mean GPR Prediction','99% CI','Orientation','horizontal','Location','southoutside')
        end
        colormap('viridis')
        fontsize(f0, scale=2)
        hold off
        drawnow

        
        %Save frame to an image stack 
        if savedata
        frame = getframe(f0);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        imwrite(imind,cm,strcat(fname,'.tiff'),'tiff','WriteMode','append');
        end

        t(iter)=toc;
        fprintf('# of pts: %i \tElapsed Time: %.4f \t\n',iter,t(iter))
    end
    zBp=zBp{iter};
    plotabsError=plotabsError{iter};
    zBpCImx=zBpCImx{iter}; 
    zBpCImn=zBpCImn{iter};
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

%% Plotting
close all

f1=figure('WindowStyle','docked');
f2=figure('WindowStyle','docked');
f3=figure('WindowStyle','docked');
f4=figure('WindowStyle','docked');
f5=figure('WindowStyle','docked');
f6=figure('WindowStyle','docked');

% Figure 1: Plot of Surface A, Surface B, the training data
figure(f1)
hold on
% Surface A
surf(x,y,zA,'FaceAlpha',.1,'FaceColor',[1 .5 0],'EdgeColor',[1 .5 0],'LineStyle','none');
% Surface B
surf(x,y,zB,'FaceAlpha',.1,'FaceColor',[.5 0 .5],'EdgeColor',[.5 0 .5],'LineStyle','none');
% Phi
quiver3(testpoints(:,1),testpoints(:,2),fA(testpoints(:,1),testpoints(:,2)),zeros(size(testpoints,1),1),zeros(size(testpoints,1),1),testpoints(:,3)-fA(testpoints(:,1),testpoints(:,2)),0)
% Test points on Surface A
plot3(testpoints(:,1),testpoints(:,2),fA(testpoints(:,1),testpoints(:,2)),'LineStyle','none','Marker','.')
% Test points on Surface B
plot3(testpoints(:,1),testpoints(:,2),testpoints(:,3),'LineStyle','none','Marker','*')
% Make Plot Pretty
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
axis equal
axis([-30 30 -30 30 0 20])
legend('Surface A','Surface B','\phi','f_A(x,y)','f_{B}(x,y)',Location='northeast')
view(3)
fontsize(gcf, scale=1.5)


% Figure 2: Plot of predicted surface and heatmap of conidence interval width
figure(f2)
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
figure(f3)
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
figure(f4)
hold on
% Mean Surface
surf(xBp,yBp,zBp,plotabsError,'LineStyle','none');
% Test points on Surface B
plot3(testpoints(:,1),testpoints(:,2),testpoints(:,3),'LineStyle','none','MarkerSize',5,'Marker','o', ...
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
figure(f5)
subplot(2,2,1)
hold on
if method == 1
    pts=(n:m).^2;
elseif method == 2 || method == 3
    pts=n:m;
end
errmat=[table2array(modelPerformance.Train),table2array(modelPerformance.Test),table2array(modelPerformance.CV),modelPerformance.MaxCIWidth];
errmax=10^ceil(log10(max(errmat(errmat~=0),[],'all')));
errmin=10^floor(log10(min(errmat(errmat~=0),[],'all')));
axvec=[min(pts) max(pts) errmin errmax];
plot(pts,(modelPerformance.Test.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('MaxAE_{test}','MaxAE_{train}','MaxAE_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Maximum Absolute Error','(mm)'})
axis(axvec)

subplot(2,2,2)
hold on
plot(pts,(modelPerformance.Test.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('MAE_{test}','MAE_{train}','MAE_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Mean Absolute Error','(mm)'})
axis(axvec)

subplot(2,2,3)
hold on
plot(pts,(modelPerformance.Test.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('RSME_{test}','RSME_{train}','RSME_{CV}','Location','southoutside','Orientation','horizontal') 
ylabel({'Root Mean Square Error', '(mm)'})
axis(axvec)

subplot(2,2,4)
hold on
plot(pts,(modelPerformance.MaxCIWidth(n:m)),'Color',[0.3010 0.7450 0.9330],'LineStyle','-','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
legend('Maximum CI Width','Location','southoutside','Orientation','horizontal') 
ylabel({'Maximum 90% Confidence', 'Interval Width (mm)'})
axis(axvec)
if method==1
    text(10^mean(log10(axvec(1:2))),10^mean(log10(axvec(3:4))),'N/A','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',30)
end

% plot(pts,(modelPerformance.Test.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle','-','LineWidth',2)
% plot(pts,(modelPerformance.Train.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle','--','LineWidth',2)
% plot(pts,(modelPerformance.CV.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle',':','LineWidth',2)
% plot(pts,(modelPerformance.Test.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle','-','LineWidth',2)
% plot(pts,(modelPerformance.Train.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle','--','LineWidth',2)
% plot(pts,(modelPerformance.CV.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle',':','LineWidth',2)

han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
xlabel(han,'Number of Points (n)')
title(han,'Model Performance Evaluation')
fontsize(gcf, scale=1.5)

% Figure 6 Error Metric Plot
figure(f6)
hold on
plot(pts,(modelPerformance.Test.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.MaxAE(n:m)),'Color',[0.8500 0.3250 0.0980],'LineStyle',':','LineWidth',2)
plot(pts,(modelPerformance.Test.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.MAE(n:m)),'Color',[0.9290 0.6940 0.1250],'LineStyle',':','LineWidth',2)
plot(pts,(modelPerformance.Test.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle','-','LineWidth',2)
plot(pts,(modelPerformance.Train.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle','--','LineWidth',2)
plot(pts,(modelPerformance.CV.RMSE(n:m)),'Color',[0.4940 0.1840 0.5560],'LineStyle',':','LineWidth',2)
plot(pts,(modelPerformance.MaxCIWidth(n:m)),'Color',[0.3010 0.7450 0.9330],'LineStyle','-','LineWidth',2)
% plot(pts,(modelPerformance.Test.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle','-','LineWidth',2)
% plot(pts,(modelPerformance.Train.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle','--','LineWidth',2)
% plot(pts,(modelPerformance.CV.TotAE(n:m)),'Color',[0 0.4470 0.7410],'LineStyle',':','LineWidth',2)
% plot(pts,(modelPerformance.Test.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle','-','LineWidth',2)
% plot(n:m,(modelPerformance.Train.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle','--','LineWidth',2)
% plot(pts,(modelPerformance.CV.R2(n:m)),'Color',[0.4660 0.6740 0.1880],'LineStyle',':','LineWidth',2)
set(gca,'YScale','log')
set(gca,'XScale','log')
axis(axvec)
legend('MaxAE_{test}','MaxAE_{train}','MaxAE_{CV}','MAE_{test}','MAE_{train}','MAE_{CV}',...
    'RSME_{test}','RSME_{train}','RSME_{CV}','Maximum CI Width','NumColumns',4,'Location','southoutside') 
xlabel('Number of Points (n)')
ylabel('Metric Value (mm)')
title('Model Performance Evaluation')
fontsize(gcf, scale=1.5)

if savedata
save(strcat(fname,'.mat'))
end