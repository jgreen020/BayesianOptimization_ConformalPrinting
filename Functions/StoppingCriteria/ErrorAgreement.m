function [val,n_star] = ErrorAgreement(modelPerformance,type,crit)
    
    if nargin<3
        crit=0.165;
    end
    
    if matches(type,'Ideal')
        col='Test';
    elseif matches(type,'Actual')
        col='CV';
    elseif matches(type,'V2')
        error('ERROR: Error Agreement metric not defined for type V2')
    end
    
    val = abs(modelPerformance.(col).MAE-modelPerformance.Train.MAE);
    resultIG = val < crit;
    n_star = modelPerformance.n(find(resultIG,1,"first"));
    if isempty(n_star); n_star=NaN; end
end