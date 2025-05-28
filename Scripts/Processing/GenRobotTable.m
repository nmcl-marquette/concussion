% Generates a data table for the concussion study
%	Load each subject's RRs_Complete.mat, call GenTableLong, and append it
%	to a master table.

clc;clear;close all;

InputFile = "RRs_Complete.mat";
OutputFile = "MasterTable";
TableSet = {'k','lm','c','scat'};
%TableSet = {'lm'};

% Subjects to analyze are based on subject folders in "Data"
SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
Subs = dir(fullfile(SubjectDataFolder, "Sub*"));
Subs = string({Subs.name})';

MasterTable = [];
for sub = Subs'
	fprintf("Collecting %s\n", sub)
	SubFilename = fullfile(SubjectDataFolder, sub, InputFile);
	S = load(SubFilename);
	RRs = S.RRs;
	MasterTable = [MasterTable; RRs.GenTableLong(TableSet)];
end

GetSubjects = @(tbl)unique(tbl.SubID);
for sub = GetSubjects(MasterTable)'
	if height(MasterTable(MasterTable.SubID==sub, :)) <= 2
		% Mark this as incomplete
		MasterTable.DidComplete(MasterTable.SubID==sub) = false;
	else
		% Mark this as complete
		MasterTable.DidComplete(MasterTable.SubID==sub) = true;
	end
end
MasterTable = movevars(MasterTable,"DidComplete",'after',"Session");

% Apply special corrections:
% Exclude C019 (two concussions)
MasterTable(MasterTable.SubID == "C019", :) = [];
% Drop C005's CogState IDN accuracy
%MasterTable{MasterTable.SubID == "C005" & MasterTable.Session == 1, ["c_IDN_Acc_asr", "c_IDN_Acc_per"]} = NaN;
% C5's IDN was manually corrected in RRs_Completed

save(fullfile(SubjectDataFolder, OutputFile + ".mat"), "MasterTable")
writetable(MasterTable, fullfile(SubjectDataFolder, OutputFile + ".xlsx"),...
	"WriteRowNames",true)
