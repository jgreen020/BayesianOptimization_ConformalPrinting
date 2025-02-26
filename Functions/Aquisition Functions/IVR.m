% Activation Function, Least Confidence Bound with high exploration
function newpt=IVR(prediction,tested,gpr)
    [~,zBpsd,~] = predict(gpr,prediction);
    kfcn = gpr.Impl.Kernel.makeKernelAsFunctionOfXNXM(gpr.Impl.ThetaHat);
    n=size(prediction,1);
    arr=table2array(prediction);
    intval=zeros(n,1);
    for i=1:n 
        f=@(x,y)reshape(kfcn(arr(i,:),[reshape(x,[],1),reshape(y,[],1)]).^2,size(x,1),size(x,2));
        intval(i)=integral2(f,-999,999,-999,999);
    end
    vals = zBpsd.^(-2).*intval;
    newpt = prediction(abs(vals-min(vals))<1e-9,:);
    newpt = newpt(randperm(size(newpt,1)),:);
    newpt = newpt(1,:);
end