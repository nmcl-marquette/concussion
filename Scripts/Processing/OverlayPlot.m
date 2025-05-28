% Plots X subjects defined by PlotSubs string array:

% GC: C003, C004, C005, C009, C010, C021
% LC: C001, C006, C007, C008, C013, C014, C022

clc; clear; close all;

PlotSubs = ["N011","C007","C021"]; % paper figure
%PlotSubs = ["N003","N005","N010","N011","N012","N013"];
%PlotSubs = ["N010","N011","N012","N014","N015","N016","N017"];
%PlotSubs = ["C001", "C006", "C007", "C008", "C013", "C014", "C022"]; %LC
%PlotSubs = ["C003", "C010", "C021"]; % Good GCs
Session = 1;

RRs = GetRRs();

set(0, 'DefaultFigureRenderer', 'painters');
figure;
NumSubs = length(PlotSubs);
for s = 1:NumSubs
	% Get subject from master list
	ThisRR = RRs{RRs.SubIDs==PlotSubs(s),"AllRRs"}(Session);
	fprintf('%s:\n', ThisRR.SubID)
	fprintf('  Mean RE: %.3f\n', ThisRR.ReachErrorMean)
	fprintf('  StDev RE: %.3f\n', sqrt(ThisRR.ReachErrorVar))
	fprintf('  Mean TCT: %.3f\n', ThisRR.ReachTimeMean)
	fprintf('  StDev TCT: %.3f\n', sqrt(ThisRR.ReachTimeVar))
	subplot(2, NumSubs, s)
	PlotReachOverlay(ThisRR, gca, true)
	subplot(2, NumSubs, s+NumSubs)
	PlotErrorVsHPert(ThisRR, gca)
end