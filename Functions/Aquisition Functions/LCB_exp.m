% Activation Function, Least Confidence Bound with high exploration
function newpt=LCB_exp(prediction,tested,gpr)
    [~,zBpsd,~] = predict(gpr,prediction);
    newpt = prediction(abs(zBpsd-min(-zBpsd))<1e-9,:);
    newpt = newpt(randperm(size(newpt,1)),:);
    newpt = newpt(1,:);
end