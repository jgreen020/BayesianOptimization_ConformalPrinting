function newpt=IVR2(prediction,tested,gpr)
    x_min=min(prediction.x);
    x_max=max(prediction.x);
    y_min=min(prediction.y);
    y_max=max(prediction.y);
    [x,y]=meshgrid(linspace(x_min,x_max,50),linspace(y_min,y_max,50));
    init=table(x(:),y(:),'VariableNames',{'x','y'});
    pt1=table2array(IVR(init,[],gpr));
    A=[];B=[];Aeq=[];Beq=[];lb=[x_min y_min];ub=[x_max y_max];nonlin=[];
    opts=optimoptions("fmincon",...
        "Algorithm","interior-point",...
        "MaxFunctionEvaluations",10000000,...
        "ConstraintTolerance",.00001,...
        "OptimalityTolerance",0.00001,...
        'Display','none');
    fun=@(x)IVRfmincon(x,gpr);
    [pt2,~]=fmincon(fun,pt1,A,B,Aeq,Beq,lb,ub,nonlin,opts);
    newpt=table(pt2(1),pt2(2),'VariableNames',{'x','y'});
end

function J=IVRfmincon(x,gpr)
    prediction=table(x(1), x(2),'VariableNames',{'x','y'});
    [~,zBpsd,~] = predict(gpr,prediction);    
    kfcn = gpr.Impl.Kernel.makeKernelAsFunctionOfXNXM(gpr.Impl.ThetaHat);
    f=@(a,b)reshape(kfcn(x,[reshape(a,[],1),reshape(b,[],1)]),size(a,1),size(a,2));
    intval=integral2(f,-999,999,-999,999);
    J = zBpsd^(-2)*intval;
end