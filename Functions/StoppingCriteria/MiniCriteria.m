function [val,n_star] = MiniCriteria(modelPerformance,crit)
    MAE_test = modelPerformance.Test.MAE;
    val = MAE_test;
    resultIG = val < crit;
    n_star = modelPerformance.n(find(resultIG,1,"first"));
    if isempty(n_star); n_star=NaN; end
end