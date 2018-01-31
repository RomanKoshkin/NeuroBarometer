function [model,t,const] = mTRFtrain(stim,resp,Fs,dir,start,fin,lambda)
%mTRFtrain mTRF training function.
%   [MODEL,T,CONST] = MTRFTRAIN(STIM,RESP,FS,DIR,START,FIN) performs
%   multivariate ridge regression on the stimulus signal STIM and the
%   response data RESP to solve for the linear stimulus-response mapping
%   function MODEL. The time lags T should be set in milliseconds between
%   START and FIN and the sampling frequency FS should be defined in Hertz.
%   Pass in DIR==0 to map in the forward direction or DIR==1 to map
%   backwards.
%
%   [MODEL,T] = MTRFTRAIN(...,LAMBDA) sets the ridge parameter value to
%   LAMBDA for the regularisation step.
%
%   Inputs:
%   stim   - stimulus signal (time by observations)
%   resp   - response data (time by channels)
%   Fs     - sampling frequency (Hz)
%   dir    - direction of mapping (forward==0, backward==1)
%   start  - start time lag (ms)
%   fin    - finish time lag (ms)
%   lambda - ridge parameter
%
%   Outputs:
%   model  - linear stimulus-response mapping function (DIR==0: obs by lags
%            by chans, DIR==1: chans by lags by obs)
%   t      - vector of non-integer time lags (ms)
%   const  - regression constant
%
%   See README for examples of use.
%
%   See also LAGGEN MTRFPREDICT.

%   References:
%      [1] Lalor EC, Pearlmutter BA, Reilly RB, McDarby G, Foxe JJ (2006).
%          The VESPA: a method for the rapid estimation of a visual evoked
%          potential. NeuroImage, 32:1549-1561.
%      [2] Lalor EC, Power AP, Reilly RB, Foxe JJ (2009). Resolving precise
%          temporal processing properties of the auditory system using
%          continuous stimuli. Journal of Neurophysiology, 102(1):349-359.

%   Author: Edmund Lalor, Michael Crosse, Giovanni Di Liberto
%   Trinity College Dublin, IRELAND
%   Email: edmundlalor@gmail.com
%   Website: http://lalorlab.net/
%   April 2014; Last revision: 3 October 2015

% Convert time lags to samples
start = floor(start/1e3*Fs);
fin = ceil(fin/1e3*Fs);

% Define x and y
if dir == 0
    x = stim;
    y = resp;
elseif dir == 1
    x = resp;
        y = stim;
        [start,fin] = deal(-fin,-start);
end

% Generate lag matrix
X = lagGen(x,start:fin);
X = [ones(size(X,1),size(x,2)),X];

% Set up regularisation
dim = size(X,2);
if size(x,2) == 1
    d = 2*eye(dim,dim);d([1,end]) = 1;
    u = [zeros(dim,1),eye(dim,dim-1)];
    l = [zeros(1,dim);eye(dim-1,dim)];
    M = d-u-l;
else
    M = eye(dim,dim);
end

% Calculate model
% model = (X'*X)\(X'*y);            % without regularization
model = (X'*X + lambda*M)\(X'*y);   % with regularization

% Format outputs
const = model(1:size(x,2),:);
model = reshape(model(size(x,2)+1:end,:),size(x,2),length(start:fin),size(y,2));
t = (start:fin)/Fs*1e3;

end
