modelPerformance.Train.MaxAE(iter) = max(trainabsError);
modelPerformance.Train.MAE(iter) = mean(trainabsError);
modelPerformance.Train.RMSE(iter) = std(trainError);
modelPerformance.CV.MaxAE(iter) = max(cvabsError);
modelPerformance.CV.MAE(iter) = mean(cvabsError);
modelPerformance.CV.RMSE(iter) = std(cvError);
modelPerformance.Test.MaxAE(iter) = max(testabsError);
modelPerformance.Test.MAE(iter) = mean(testabsError);
modelPerformance.Test.RMSE(iter) = std(testError);
if method==1
    modelPerformance.MaxCIWidth(iter) = NaN;
elseif method == 2 || method == 3
    modelPerformance.MaxCIWidth(iter) = max(abs((zBpCI(:,2)-zBpCI(:,1))/2));
end