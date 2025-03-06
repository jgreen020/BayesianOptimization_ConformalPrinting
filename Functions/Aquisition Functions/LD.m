% Activation Function
function newpt=LD(prediction,tested,gpr)
    [~,dist]=dsearchn(tested,table2array(prediction));
    newpt=prediction(abs(dist+min(-dist))<0.000000001,:);
end