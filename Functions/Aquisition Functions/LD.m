% Activation Function
function newpt=LD(prediction,tested,gpr)
    [~,dist]=dsearchn(tested,table2array(prediction));
    newpt=prediction(dist==min(-dist),:);
end