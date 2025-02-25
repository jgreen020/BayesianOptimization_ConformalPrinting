% Activation Function
function newpt=A2(prediction,tested,gpr)
    [~,zBpsd,~] = predict(gpr,prediction);
    flatness=rmse(zBpsd,mean(zBpsd)*ones(size(zBpsd)));
    if flatness>1e-3
        newpt = prediction(abs(zBpsd-min(-zBpsd))<1e-4,:);
        newpt = newpt(randperm(size(newpt,1)),:);
        newpt = newpt(1,:);
    else
        [~,dist]=dsearchn(tested,table2array(prediction));
        newpt=prediction(dist==max(dist),:);
    end
end