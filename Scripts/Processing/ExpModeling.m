% This script performs steps for time series modeling across sessions to
% find time constants of recovery/novelty learning.

clc;clear;close all;

DependentVar = "lm3_a1_Estimate";
TimeVar = "DaysPostS1";
SHOW_FIG = true;

MT = load("MasterTable.mat");
MT = MT.MasterTable;

% Only use first three sessions and complete subjects
MT = MT(MT.DidComplete & (MT.Session < 4), :);
MT(MT.SubID=="C013", :) = [];

% Sub List
SubList = unique(MT{MT.Condition == "Concussed", "SubID"});
SubList = unique(MT{:, "SubID"});
%SubList = "C005";

% Get Session 3 healthy mean (used across subjects)
HealthyS3 = mean(MT.(DependentVar)(MT.Session == 3), 'omitnan');
% NL Model
modelFun = @(b,x) b(1).*x(:,1).*exp(-x(:,2).*b(2)) + HealthyS3;

modelFunAll = @(b,x) b(1).*x(:,1).*exp(-x(:,2).*(b(2)+x(:,3).*b(3))) + HealthyS3;
AllTbl = MT; AllTbl.scat_Sum(AllTbl.Condition=="Concussed") = ...
	fillmissing(AllTbl.scat_Sum(AllTbl.Condition=="Concussed"), "previous");
mdlAll = fitnlm(AllTbl, modelFunAll, ...
		[1 5 0.5], ...
		"PredictorVars", {'scat_Sum', char(TimeVar), 'ConditionCode'}, ...
		"ResponseVar", DependentVar);

AllMdls = table();
if SHOW_FIG
	figure
	axes()
	hold on
	ylabel(DependentVar)
	xlabel(TimeVar)
	yline(HealthyS3, 'k:', "Healthy S3")
end
for Sub = SubList'
	% Get this subject's data table
	ThisTbl = MT(MT.SubID==Sub, :);
	ThisTbl.scat_Sum = fillmissing(ThisTbl.scat_Sum, "nearest"); % Distribute scat_Sum to all sessions (constant)
	if ThisTbl.Condition(1) == "Healthy"
		% Change SCAT5 scores to zero
		ThisTbl.scat_Sum = fillmissing(ThisTbl.scat_Sum, "constant", 1);
	end
	if all(isnan(ThisTbl.scat_Sum))
		% Cannot process this subject
		continue
	end

	% Add Plot
	if SHOW_FIG
		% Real Data
		if ThisTbl.Condition(1) == "Healthy"
			plot(ThisTbl.(TimeVar), ThisTbl.(DependentVar), '-', ...
				'linewidth', 2, 'color', [0 0 1 0.4])
		else
			plot(ThisTbl.(TimeVar), ThisTbl.(DependentVar), '-', ...
				'linewidth', 2, 'color', [1 0 0 0.4])
		end
	end

	mdl = fitnlm(ThisTbl, modelFun, ...
		[1 5 0.5], ...
		"PredictorVars", {'scat_Sum', char(TimeVar)}, ...
		"ResponseVar", DependentVar);

	if length(SubList) == 1
		preRange = mdl.Variables.DaysPostS1(1):0.1:mdl.Variables.DaysPostS1(end);
		PredTbl = table(repmat(mdl.Variables.scat_Sum(1), length(preRange), 1),...
			preRange', 'variablenames', {'scat_Sum', char(TimeVar)});
		[ypred, yci] = predict(mdl, PredTbl);
		plot(preRange, ypred , '-b', 'linewidth', 1)
		legend("Data", "Fit (95% CI)")
	end

	tmpTbl = table();
	ctab = mdl.Coefficients; % Get linear model coefficient table
	for row = ctab.Properties.RowNames'
		temptab = ctab(row{1}, :); % Get row of the table
		% Change variable names to represent coefficent
		% and remove the row name
		temptab.Properties.VariableNames = ...
			strcat([row{1} '_'], ...
			temptab.Properties.VariableNames);
		temptab.Properties.RowNames = {};
		tmpTbl = [tmpTbl, temptab];
	end
	tmpTbl.SubID = Sub;
	tmpTbl.Condition = ThisTbl.Condition(1);
	AllMdls = [AllMdls; tmpTbl];
end
% Grab model equation from last used model (they should all be the same)
if SHOW_FIG; title({"Exponential Model Fit"; mdl.Formula.Expression}); end

