% Script operates on the MasterTable.mat
%	Removes tuples where subjects only attended two sessions.
%	Removes the fourth session.

clc;clear;close all;

OutputFile = "MasterTable4S3Corr.xlsx";

S = load(fullfile(RobotTrial4.CodePath, "Data", "MasterTable4.mat"));
MT = S.MasterTable; clear S;

GetSubjects = @(tbl)unique(tbl.SubID);

%% Remove subjects with 1 or 2 sessions
% for sub = GetSubjects(MT)'
% 	if height(MT(MT.SubID==sub, :)) <= 2
% 		% Remove this subject from analysis
% 		MT(MT.SubID==sub, :) = [];
% 	end
% end

%% Remove Session 4 for primary analysis
MT = MT(MT.Session ~= 4, :);
% If subjects with 1 or 2 sessions are removed, as well as 4 sessions, then
% all remaining subjects will have 3 sessions!

%% Create Table with numeric values subtracted by session 3

% Get Session 3 values for each subject
S3s = MT(MT.Session==3, :);
% Get data types
Tdt = string(cellfun(@class,table2cell(S3s(1,:)),'UniformOutput',false));
% All numeric data types
Ndt = contains(Tdt,["double","single"]);
% Omit session column subtraction
Ndt(matches(S3s.Properties.VariableNames, ["Session","ConditionCode"])) = false;

S3tbl = MT(MT.Session < 4, :);
for sub = GetSubjects(S3s)'
	S3vals = S3s{S3s.SubID==sub, Ndt};
	OutData = S3tbl{S3tbl.SubID==sub, Ndt} - S3vals;
	S3tbl{S3tbl.SubID==sub, Ndt} = OutData;
end

%% Save Session 3 Corrected

writetable(S3tbl, fullfile(RobotTrial4.CodePath, "Data", OutputFile))

