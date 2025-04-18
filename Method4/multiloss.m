function val = multiloss(Y,T)
% Evaluate multiscale monitoring loss.

% Inputs:
%          Y - Formatted dlarray of predictions
%          T - Formatted dlarray of targets
%
% Outputs:
%           val - Metric value
%
% Define the metric function here.

alpha = 0.03;

weights = [1; 0.5; 0.25];

full_err=Y(:,:,1,:)-T;
half_err=imresize(Y(:,:,2,:),0.5,"nearest")-imresize(T,0.5,"nearest");
quart_err=imresize(Y(:,:,3,:),0.25,"nearest")-imresize(T,0.25,"nearest");

mse = [mean((full_err).^2,'all');...
    mean((half_err).^2,'all');...
    mean((quart_err).^2,'all')];

pv = [max(abs(full_err),[],'all');...
    max(abs(half_err),[],'all');...
    max(abs(quart_err),[],'all')];

val = sum(weights.*(mse+alpha*pv),'all');
end