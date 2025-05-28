%clc;clear;close all;

% Load a table from the data folder

% Compute z-scores for each cogstate test within each session relative to
% controls.

tests = ["DET","IDN","ONB","OCL"];
type = ["_Spd_lmn", "_Acc_asr"];

% Delete subjects that did not complete session 3
MT = MasterTable(MasterTable.DidComplete,:);

for sess = 1:4
    for tst = 1:length(tests)
        for tp = 1:length(type)
            TestCode = "c_" + tests(tst) + type(tp);
            % Get control values
            ControlVals = MT{MT.ConditionCode==0 & MT.Session==sess, TestCode};
            CtrMean = mean(ControlVals, 'omitnan');
            CtrStd = std(ControlVals,'omitnan');
            % Compute z-scores on all subjects within this session
            zdata = (MT{MT.Session==sess, TestCode} - CtrMean) ./ CtrStd;
            TestCode = char(TestCode);
            MT.(TestCode(1:10)+"Z")(MT.Session==sess) = zdata;
        end
    end
end
% Also compute composite scores within each task
for tst = 1:length(tests)
    TestCode = "c_" + tests(tst);
    % Average of timing and -accuracy
    MT.(TestCode + "_CompZ") = ...
        (MT.(TestCode+type(1)) - MT.(TestCode+type(2))) ./ 2;
end
% Also compute average reaction time score across all tasks
MT.c_AvgTimingZ = mean(MT{:,"c_"+tests+"_Spd_Z"},2,'omitnan');

% Save Table
OutputFile = "MasterTableZ";
SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
save(fullfile(SubjectDataFolder, OutputFile + ".mat"), "MT")
writetable(MT, fullfile(SubjectDataFolder, OutputFile + ".xlsx"),...
	"WriteRowNames",true)

