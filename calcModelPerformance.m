modelPerformance.Train.TotAE(iter) = sum(trainabsError);
modelPerformance.Train.MaxAE(iter) = max(trainabsError);
modelPerformance.Train.MAE(iter) = mean(trainabsError);
modelPerformance.Train.RMSE(iter) = std(trainError);
%modelPerformance.Train.R2(iter) = 1-sum(trainError.^2)/sum((testpoints(:,3)-mean(testpoints(:,3))).^2);
modelPerformance.CV.TotAE(iter) = sum(cvabsError);
modelPerformance.CV.MaxAE(iter) = max(cvabsError);
modelPerformance.CV.MAE(iter) = mean(cvabsError);
modelPerformance.CV.RMSE(iter) = std(cvError);
%modelPerformance.CV.R2(iter) = 1-sum(cvError.^2)/sum((zBl-mean(zBl)).^2);
modelPerformance.Test.TotAE(iter) = sum(testabsError);
modelPerformance.Test.MaxAE(iter) = max(testabsError);
modelPerformance.Test.MAE(iter) = mean(testabsError);
modelPerformance.Test.RMSE(iter) = std(testError);
%modelPerformance.Test.R2(iter) = 1-sum(testError.^2)/sum((zBl-mean(zBl)).^2);
if method==1
    modelPerformance.MaxCIWidth(iter) = NaN;
elseif method == 2 || method == 3
    modelPerformance.MaxCIWidth(iter) = max(abs((zBpCI(:,2)-zBpCI(:,1))/2));
end