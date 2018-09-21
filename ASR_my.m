% run ICA_my.m first:

% load a fragment of EEG with a blink
start_s = 99;
fin_s = 104;
start = start_s * EEG.srate;
fin = fin_s * EEG.srate;
x = EEG.data(:,start:fin);
% x = highpassFIR(x, EEG.srate, 1, 2, 0);

% we either use the eig function on the data covariance matrix, or the svd
% function to get the same eigenvectors:
% https://www.quora.com/What-is-an-intuitive-explanation-of-the-relation-between-PCA-and-SVD
[V,D] = eig(x*x');
% sort the eigenvenctors and eigenvalues in descending order (eig doesn't do it by default):
[d,ind] = sort(diag(D), 'descend');
D = D(ind,ind);
V = V(:,ind);

% [V,S,U] = svd(x);

%% checking validity:
clc
M = x;
C = M*M';
[W,D] = eig(C);
% sort the eigenvenctors and eigenvalues in descending order (eig doesn't do it by default):
[d,ind] = sort(diag(D), 'descend');
D = D(ind,ind);
W = W(:,ind);
% M*v = d*v by the definition of eigenvectors/values
err1 = sum(C * W(:,1) - D(1,1) * W(:,1));
disp(err1)

% using svd (produces a smaller error):
clc
M = x;
[V,S,U] = svd(M);
% M'*v = s*u by the definition of SVD
err2 = sum(M' * V(:,1) - S(1,1) * U(:,1)); % The non-zero singular values 
                                               % of M (found on the diagonal entries of ?) 
                                               % are the square roots of the non-zero 
                                               % eigenvalues of both M?M and MM?.
disp(err2)
%%

% project our data from the sensor space into the source (PCs, or eigenvectors) space.
% Plot the first seven largest components: 
% principal components:
C = V'*x;
figure
for i = 1:7
    plot(C(i,:))
    hold on
end
title('The first seven PCs')

% replace the first component (whose variance is out of tolerance)
% with a linear combination of all the others:
C(1,:) = sum(C(2:end,:),1);
% V(:,1) = sum(V(:,2:end),2);

% back-project the changed components into the channel space:
x_hat = V' * C; % V' could as well be inv(V), since V is orthogonal

figure
for i = 1:7
    subplot(7,1,i)
    plot(x(i,:))
    hold on
    plot(x_hat(i,:))
end
title('Original EEG, and Org.-1 eyblink component')
ASR_CLEANED = EEG;
ASR_CLEANED.data(:,start:fin) = x_hat;
pop_eegplot(ASR_CLEANED, 1, 0, 1);

    