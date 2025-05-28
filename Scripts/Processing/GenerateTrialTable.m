clc;clear

%% Load Data
RRs = GetRRs("Verbose",true);

%% Build Table
% Rows for each trial
% Column for trial number, hpert, and each subject's output series

data = table([21:220]', RRs.AllRRs(1,1).HPerts(21:220)', 'VariableNames',["Trial", "SpringStrength [N/m]"]);

% Append each subject's data to table
for sub = 1:height(RRs)
    for sess = 1:3
        ReachData = NaN(200,1); % init data
        % Reach reach errors
        ReachErrors = RRs.AllRRs(sub,sess).ReachErrors';
        % NaN any bad data
        ReachErrors(~RRs.AllRRs(sub,sess).GoodTrials) = NaN;
        % Trim practice trials
        ReachErrors(1:20) = [];
        % Overlay reach errors onto data array
        ReachData(1:length(ReachErrors)) = ReachErrors;
        data.(sprintf("%s_S%d [m]",RRs.SubIDs(sub),sess)) = ReachData;
    end
end

%% Export to excel
writetable(data,fullfile("Output","TrialData.xlsx"))
