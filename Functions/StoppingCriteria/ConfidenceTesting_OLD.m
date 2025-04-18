function [val,n_star] = ConfidenceTesting(modelPerformance,type,crit)
    
    if nargin<3
        crit=0.5;
    end
    
    K = 3.2897;

    if matches(type,'Ideal')
        col='Test';
        val = K*modelPerformance.(col).RMSE;
    elseif matches(type,'Actual')
        col='CV';
        val = K*modelPerformance.(col).RMSE;
    elseif matches(type,'V2')
        col='MaxCIWidth';
        val = modelPerformance.(col);
    end

    resultIG = val < crit;
    n_star = modelPerformance.n(find(resultIG,1,"first"));
    if isempty(n_star); n_star=NaN; end
end