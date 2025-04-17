function [val,n_star] = Guarantee(modelPerformance,type,crit)
    
    if nargin<3
        crit=0.165;
    end
    
    if matches(type,'Ideal')
        col='Test';
        val = modelPerformance.(col).pv;
    elseif matches(type,'Actual')
        col='CV';
        val = modelPerformance.(col).pv;
    elseif matches(type,'V2')
        col='MaxCIWidth';
        val = modelPerformance.(col)/3.2897*5.1517;
    end
    
    resultIG = val < crit;
    n_star = modelPerformance.n(find(resultIG,1,"first"));
    if isempty(n_star); n_star=NaN; end
end