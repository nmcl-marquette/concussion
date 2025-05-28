%% Satisficing Test
% Test script to evaluate the effectiveness of satisficing fitting.
% SatisficingFun(x,CenterY,CenterX,SatisficedRange,LowerSlope,UpperSlope)
%
%	Satisficing:
%			   /UpperSlope
%	 A________/
%	 /	  C   B
%	/LowerSlope
%
%	CenterX (C,x): is the x value of the ideal zero-error point
%	CenterY (C,y): is the y value of the ideal, unchanged, output
%	SatisficedRange (A-B): Acceptable range of x where no error is detected
%		Centered on CenterPoint.
%	LowerSlope and UpperSlope: Slope of tails (positive or negative)
%
%	This script generates an ideal and noisy set of data for the
%	satisficing fitting to be applied.

clc;clear;close all;

%% Define a simulation dataset with the following parameters:
True_CenterY = 40;
True_CenterX = 50;
True_SatisficedRange = 40;
True_LowerSlope = 1;
True_UpperSlope = 2;

NoiseGain = 50;

% Dummy x array
x = 1:100;
x(randperm(length(x))) = x;

% generate the true satisficing output
y_true = SatisficingFun(x,...
	True_CenterY,...
	True_CenterX,...
	True_SatisficedRange,...
	True_LowerSlope,...
	True_UpperSlope);

% Inject noise onto the true satisficing data (used to fit a line to)
y_noise = y_true + NoiseGain*(rand(1,length(x))-0.5);

%% Preparing fitting and Fit

% For no good reason, MATLAB's fittype rearranged the order of inputs!
% The order will always be:
% 'CenterX'        
% 'CenterY'        
% 'LowerSlope'     
% 'SatisficedRange'
% 'UpperSlope'     

% Starting points determine by:
% CenterX should be somewhere near the mean of the x data
% CenterY should be somewhere near the mean of the y data
% LowerSlope will start at 0 and bend as needed
% SatisficedRange will be estimated as 68.2% of x data (within +-1 SD of
%	mean)
% UpperSlope will start at 0 and bend as needed
FittingStartsNoise = [...
	mean(x),...
	mean(y_noise),...
	0,...
	2*std(x),...
	0];
FittingStartsTrue = [...
	mean(x),...
	mean(y_true),...
	0,...
	2*std(x),...
	0];

% Define lower bounds of the parameters
FittingLower = [-Inf, -Inf, -Inf, 0, -Inf];
% Define upper bounds of the parameters
FittingUpper = [Inf, Inf, Inf, Inf, Inf];

% Instantiate function to be used for fitting
ft=fittype('SatisficingFun(x,CenterY,CenterX,SatisficedRange,LowerSlope,UpperSlope)');

% Fit the data (x and y need to be transposed since fit wants column vectors)
[f_true,GOF_true,AlgoInfo_true] = fit(x',y_true',ft,...
	'startpoint',FittingStartsTrue,'lower',FittingLower,'upper',FittingUpper);
[f_noise,GOF_noise,AlgoInfo_noise] = fit(x',y_noise',ft,...
	'startpoint',FittingStartsNoise,'lower',FittingLower,'upper',FittingUpper);

%% Plot the noisy y fit

TrueParamTxt = sprintf('True: CtrX: %.2f, CtrY: %.2f, SatRng: %.2f, LSlp: %.2f, USlp: %.2f',...
	True_CenterX,True_CenterY,True_SatisficedRange,True_LowerSlope,True_UpperSlope);

NoiseFitParamTxt = sprintf('Noise Fit: CtrX: %.2f, CtrY: %.2f, SatRng: %.2f, LSlp: %.2f, USlp: %.2f',...
	f_noise.CenterX,f_noise.CenterY,f_noise.SatisficedRange,f_noise.LowerSlope,f_noise.UpperSlope);

TrueFitParamTxt = sprintf('True Fit: CtrX: %.2f, CtrY: %.2f, SatRng: %.2f, LSlp: %.2f, USlp: %.2f',...
	f_true.CenterX,f_true.CenterY,f_true.SatisficedRange,f_true.LowerSlope,f_true.UpperSlope);

figure('pos',[1 1 1100 900])
movegui('center')

% Plot noisy data fit
subplot(2,1,1)
plot(f_noise,x,y_noise)
% add true data
hold on
plot(x,y_true,'k.')
legend('Noisy Data','Satisficing Fit','True Data')
title({'Fitting of noisy data';TrueParamTxt;NoiseFitParamTxt})

% Plot true data fit
subplot(2,1,2)
plot(f_true,x,y_true)
legend('True Data','Satisficing Fit')
title({'Fitting of ideal data';TrueParamTxt;TrueFitParamTxt})


