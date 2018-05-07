% X = EEG.data(:,181*EEG.srate:189*EEG.srate);
% X = highpassFIR(X, EEG.srate, 1, 2, 0);
clearvars -except EEG ALLCOM ALLEEG CURRENTSET CURRENTSTUDY LASTCOM PLUGINLIST STUDY x_hat
X = x_hat;

for i = 1:size(EEG.data,1)
    Y(i,:) = circshift(X(i,:),-1);
end
C_xx = X*X';
C_xy = X*Y';
C_yy = Y*Y';
C_yx = Y*X';
M = inv(C_xx)*C_xy*inv(C_yy)*C_yx;

%% check:
% dat = randi(10,5, 100); % uncomment if you want toy data
clc
C = M*M';
[W,D] = eig(C);
% sort the eigenvenctors and eigenvalues in descending order (eig doesn't do it by default):
[d,ind] = sort(diag(D), 'descend');
D = D(ind,ind);
W = W(:,ind);
% M*v = d*v by the definition of eigenvectors/values
err1 = sum(C * W(:,1) - D(1,1) * W(:,1));
disp('eig')
disp(err1)

% using svd (produces a smaller error):
[U,S,V] = svd(M);
% M'*v = s*u by the definition of SVD
err2 = sum(M * V(:,1) - S(1,1) * U(:,1));
disp('svd')
disp(err2)
%%
% project our data onto the first seven largest eigenvectors to get its 
% principal components:
COMPS = U'*X;

figure
for i = 1:30
    comps_plot(i,:) = COMPS(i,:) - 100*i;
    plot(comps_plot(i,:))
    hold on
end
title('BSS-CCA computed source activations: least auto-correlated at the bottom')

% zero out the least auto-correlated component:
COMPS(29:30,:) = zeros(2,length(COMPS));

% back-project the components into the channel space:
x_hat = U' * COMPS; % U' could as well be inv(V), since V is orthogonal

figure
for i = 1:30
    x_hat_plot(i,:) = x_hat(i,:) - 200*i;
    X_plot(i,:) = X(i,:) - 200*i;
    plot(X_plot(i,:), 'LineWidth', 0.5, 'Color', 'k');
    plot(x_hat_plot(i,:), 'LineWidth', 2, 'Color', 'r');
    hold on
end