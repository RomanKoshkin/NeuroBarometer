function [pred,rho,pVal,MSE] = mTRFpredict(stim,resp,model,Fs,dir,start,fin,const)
%mTRFpredict mTRF prediction function.
%   PRED = MTRFPREDICT(STIM,RESP,MTRF,FS,DIR,START,FIN,CONST) predicts the
%   outcome PRED of convolving the stimulus signal STIM or the response
%   data RESP with the linear stimulus-response mapping function MODEL.
%   Pass in DIR==0 to predict RESP or DIR==1 to predict STIM.
%
%   [PRED,RHO,PVAL,MSE] = MTRFPREDICT(...) also returns the correlation
%   coefficients RHO between the predicted and original signals, the
%   corresponding p-values PVAL and the mean squared error MSE.
%
%   Inputs:
%   stim   - stimulus signal (time by observations)
%   resp   - response data (time by channels)
%   model  - linear stimulus-response mapping function (DIR==0: obs by
%            lags by chans, DIR==1: chans by lags by obs)
%   Fs     - sampling frequency (Hz)
%   dir    - direction of mapping (forward==0, backward==1)
%   start  - start time lag (ms)
%   fin    - finish time lag (ms)
%   const  - regression constant
%
%   Outputs:
%   pred   - prediction (DIR==0: time by chans, DIR==1: time by obs)
%   rho    - correlation coefficients for each chan or obs
%   pVal   - calculated probabilities
%   MSE    - mean squared errors
%
%   See README for examples of use.
%
%   See also LAGGEN MTRFTRAIN.

%   Author: Michael Crosse, Giovanni Di Liberto
%   Trinity College Dublin, IRELAND
%   Email: edmundlalor@gmail.com
%   Website: http://lalorlab.net/
%   April 2014; Last revision: 18 August 2015

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

% Calculate prediction
model = [const;reshape(model,size(model,1)*size(model,2),size(model,3))];
pred = X*model;

% Calculate accuracy
if ~isempty(y)
    rho = zeros(size(y,2),1);
    pVal = zeros(size(y,2),1);
    MSE = zeros(size(y,2),1);
    for i = 1:size(y,2)
        [rho(i),pVal(i)] = corr(pred(:,i),y(:,i));
        MSE(i) = mean((y(:,i)-pred(:,i)).^2);
    end
end

end