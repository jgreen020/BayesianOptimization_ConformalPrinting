function [val,n_star] = ConfidenceTesting(modelPerformance,type,crit)
    
    if nargin<3
        crit=0.165/3;
    end
    
    if matches(type,'Ideal')
        col='Test';
        val = modelPerformance.(col).MAE;
    elseif matches(type,'Actual')
        col='CV';
        val = modelPerformance.(col).MAE;
    elseif matches(type,'V2')
        col='MaxCIWidth';
        val = modelPerformance.(col);
    end

    resultIG = val < crit;
    n_star = modelPerformance.n(find(resultIG,1,"first"));
    if isempty(n_star); n_star=NaN; end
end