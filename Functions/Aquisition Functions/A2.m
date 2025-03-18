% Activation Function
function newpt=A2(prediction,tested,gpr)
    [~,zBpsd,~] = predict(gpr,prediction);
    flatness=rmse(zBpsd,mean(zBpsd)*ones(size(zBpsd)));
    if flatness>1e-3
        newpt = LCB_exp(prediction,tested,gpr);
    else
        newpt = LD(prediction,tested,gpr);
    end
end