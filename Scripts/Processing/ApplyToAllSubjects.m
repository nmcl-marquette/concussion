% Load all subject RRs arrays, perform a process, and save them.

clc;clear;close all;

%AnalysisStage = "Inspect";
%AnalysisStage = "Model";
%AnalysisStage = "Ledger and Cogstate";
AnalysisStage = "LastHalfModel";

switch AnalysisStage
	case "Inspect"
		InputFile = "RRs.mat";
		OutputFile = "RRs_Inspected.mat";
		Process = {@(obj)obj.RobotGUI};
		OverwriteOutput = false;
	case "Model"
		InputFile = "RRs_Inspected.mat";
		OutputFile = "RRs_Modeled.mat";
		Process = {@(obj)obj.PopModelData};
		OverwriteOutput = true;
	case "Ledger and Cogstate"
		InputFile = "RRs_Modeled.mat";
		OutputFile = "RRs_Complete.mat";
		Process = {@(obj)obj.PopLedgerCogState, @(obj)obj.LoadClinical};
		OverwriteOutput = true;
	case "LastHalfModel"
		InputFile = "RRs_Complete.mat";
		OutputFile = "RRs_CompleteLastHalf.mat";
		Process = {@(obj)obj.PopModelData2};
		OverwriteOutput = true;
end

SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
Subs = dir(fullfile(SubjectDataFolder, "Sub*"));
Subs = string({Subs.name})';

for sub = Subs'
	fprintf("Starting analysis for %s.\n", sub)
	% First check if the ouput already exists
	if ~OverwriteOutput && exist(fullfile(SubjectDataFolder, sub, OutputFile), "file")
		continue
	end
	try
		S = load(fullfile(SubjectDataFolder, sub, InputFile));
	catch
		warning("Could not load data for %s (%s).", sub, InputFile)
		continue
	end
	RRs = S.RRs;
	for sess = 1:length(RRs)
		for ThisProcess = 1:length(Process)
			RRs(sess) = Process{ThisProcess}(RRs(sess));
		end
	end
	save(fullfile(SubjectDataFolder, sub, OutputFile), "RRs")
end
