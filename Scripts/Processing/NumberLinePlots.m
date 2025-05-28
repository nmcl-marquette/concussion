clc;clear;close all;

S = load("MasterTable.mat");
MT = S.MasterTable;
MT = MT(MT.Session ~= 4, :); % remove S4
MT = MT(MT.DidComplete, :); % Only use subs that did all three sessions
MT(MT.SubID == "C019", :) = []; % Remove sub C019 since they recieved two concussions

% Concussed S1 only
CS1 = MT(MT.Session==1 & MT.Condition=="Concussed", :);
HS1 = MT(MT.Session==1 & MT.Condition=="Healthy", :);

VarsOfInterest = ["c_DET"];
VarsOfInterest = ["c_DET", "c_IDN", "c_ONB", "c_OCL"];
VarsOfInterest = compose("%s_Spd", VarsOfInterest);

SEM = @(data) std(data) ./ sqrt(length(data));

yRange = [-1 1];
AddRect = @(data) rectangle("Position",[mean(data)-SEM(data) yRange(1) SEM(data)*2 diff(yRange)],...
		'facecolor',[0 0 0 0.1], 'edgecolor','none');

for n = VarsOfInterest
	figure
	
	% Raw Value
	subplot(2,1,1)
	hold on
	% healthy reference
	HD = HS1.(n + "_ms");
	xline(mean(HD), 'k-', 'linewidth', 2, 'label', "Healthy Mean (SEM)", ...
		'LabelOrientation', 'horizontal')
	AddRect(HD)
	% Concussed Data
	CD = CS1.(n + "_ms");
	[CD, idx] = sort(CD);
	plot(CD, zeros(size(CD)), 'o')
	SubNames = CS1.SubID(idx);
	text(CD(1:2:end), zeros(size(CD(1:2:end)))+0.2, SubNames(1:2:end), ...
		'HorizontalAlignment','center','Rotation', 0)
	text(CD(2:2:end), zeros(size(CD(2:2:end)))-0.2, SubNames(2:2:end), ...
		'HorizontalAlignment','center','Rotation', 0)
	% Plot Labels
	title(strrep(n,'_',' '))
	xlabel('Time (ms)')
	set(gca, 'ytick', 0, 'yticklabel', "Raw Data")

	% Transformed Value
	subplot(2,1,2)
	hold on
	% healthy reference
	HD = HS1.(n + "_lmn");
	xline(mean(HD), 'k-', 'linewidth', 2, 'label', "Healthy Mean (SEM)", ...
		'LabelOrientation', 'horizontal')
	AddRect(HD)
	% Concussed Data
	CD = CS1.(n + "_lmn");
	[CD, idx] = sort(CD);
	plot(CD, zeros(size(CD)), 'o')
	SubNames = CS1.SubID(idx);
	text(CD(1:2:end), zeros(size(CD(1:2:end)))+0.1, SubNames(1:2:end), ...
		'HorizontalAlignment','center','Rotation', 0)
	text(CD(2:2:end), zeros(size(CD(2:2:end)))-0.1, SubNames(2:2:end), ...
		'HorizontalAlignment','center','Rotation', 0)
	% Plot Labels
	xlabel('Time (log_1_0(ms))')
	set(gca, 'ytick', 0, 'yticklabel', "Transformed")
end






