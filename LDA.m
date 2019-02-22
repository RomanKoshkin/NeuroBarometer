%% SEE Treder et al. (2016). LDA beamformer...
mu1 = [3; 6];
C1 = [1 0.5; 0.5 1];
mu2 = [0; 4];
C2 = [1 0.5; 0.5 1];

p = mu2 - mu1;
C = C1;

rng default
X1 = mvnrnd(mu1,C1,1000)';
X2 = mvnrnd(mu2,C2,1000)';

subplot(1,2,1)
plot(X1(1,:), X1(2,:),'+')
hold on
plot(X2(1,:), X2(2,:),'+')
hold on
ax = gca; ax.XLim = [mu1(1)-10 mu2(1)+10]; ax.YLim = [mu1(2)-10 mu2(2)+10];
vline(mu1(1)); hline(mu1(2))
vline(mu2(1)); hline(mu2(2))
% plot decision boundary:
% the decision boundary is a vector (goes through origin and its
% coordinates). It's slope is y/x. To plot the vector on which to project
% the data, we raise/or lower it (keeping the same slope) so that it goes
% through the point (mu1(1) + p(1), mu1(2)+p(2)) (i.e. the coordinates of
% average of means)

CC = cov(X1')+cov(X2');
% CC = C1;
w = inv(CC)*p*inv(p'*inv(CC)*p);
w = inv(CC) * p;

slope = w(2)/w(1);
intercept = mu1(2) + p(2) - slope * (mu1(1) + p(1));
x = linspace(-5,7,10);
l1 = slope*x + intercept;
plot(x,l1)
title(['slope: ', num2str(slope)])
% the decision boundary is perpindicular to the projection vector:
% mdl = fitcdiscr(X',Y);
% co = mdl.Coeffs(1,2).Linear;
% slope = co(2)/co(1);
% intercept = mdl.Coeffs(1,2).Const;
% l2 = slope * x + intercept;
% plot(x, l2);
grid on

subplot(1,2,2)
X1_proj = w' * X1;
X2_proj = w' * X2;
histogram(X1_proj,10)
hold on
histogram(X2_proj,10)