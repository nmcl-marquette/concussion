% This script performs the fminsearch of of the linear regression and
% satisficing models by minimizing the Sum of Squared Errors.
%
%   Linear Regression: 2 paremters
%   Satisficing: 5 parametes
%
%   Apply Minimum Descriptor Length (MDL) factor to unexplained variance to
%   account for number of model parameters (more parcimonious model is
%   favored)
%
% During optimization using fminsearch, the function will find a vector of
% parameters that minimize SSE. To do this, SSE also needs the x and y data
% set to compute SSE. x and y are constants during optimization. This is
% accomplished by creating 'opfun' anonymous function to hold x and y
% constant but only allow x0s vector to be modified.

%% Initialize
clc;clear;close all;

% get an x and y dataset from a subject
True_CenterY = 90;
True_CenterX = 100;
True_SatisficedRange = 60;
True_LowerSlope = 1;
True_UpperSlope = 2;
TrueParams = [True_CenterY,True_CenterX,True_SatisficedRange,True_LowerSlope,True_UpperSlope];
NoiseGain = 200;
% Dummy x array
x = 1:190;
% generate the true satisficing output
y_true = SatisficingFun(x,...
	True_CenterY,...
	True_CenterX,...
	True_SatisficedRange,...
	True_LowerSlope,...
	True_UpperSlope);

% Inject noise onto the true satisficing data (used to fit a line to)
y = y_true + NoiseGain*(rand(1,length(x))-0.5);

%% Optimize

% Approximate start parameters:
StartParams = [...
	mean(y),...
	mean(x),...
	2*std(x),...
	1,...
	1];
StartParams = StartParams*1; % Modulate coefficients to find other local minima

% Object Function - Function to minimize
%   This happens to be SatisficingFun.m
%   SatisficingFun also takes a dataset, x, which cannot be varied during
%   optimization. See Cost Function below.

% Cost Function - output to minimize (SSE)
% SSE = sum( (y-y_hat).^2 ), where y_hat is the Satisficing best fit line.
% CostFun only takes one input, Params, which is a 5 element vector of
% model parameters. x and y are constants during optimization (calculating
% SSE) and will be evaluated directly from the workspace.
CostFun = @(Params) sum((y-SatisficingFun(x,Params(1),Params(2),abs(Params(3)),Params(4),Params(5))).^2);

[Params,SSE] = fminsearch(CostFun, StartParams);

%% Plot
figure
plot(x,y,'b.')
hold on
plot(x,SatisficingFun(x,Params(1),Params(2),abs(Params(3)),Params(4),Params(5)),'r-')









