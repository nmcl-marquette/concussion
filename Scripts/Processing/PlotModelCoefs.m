clc;clear;close all;

%% Load all subject RR arrays that have at least three sessions.
InputFile = "RRs_Complete.mat";
SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
Subs = dir(fullfile(SubjectDataFolder, "Sub*"));
Subs = string({Subs.name})';
% Remove Sub C019 for two concussions
Subs(Subs == "SubC019") = [];

AllRRs = [];
for sub = Subs'
    fprintf("Collecting %s - ", sub)
    SubFilename = fullfile(SubjectDataFolder, sub, InputFile);
    S = load(SubFilename);
    RRs = S.RRs;
    if length(RRs) >= 3
        fprintf("Complete\n")
        AllRRs = [AllRRs; RRs(1:3)]; % Take first three sessions
    else
        fprintf("Not enough sessions\n")
    end
end

%% Run the within-subject model with session interactions

% CoefTbl is a table of columns:
%   Col 1, 2, and 3 are 1x3 arrays where each element is a session. Each
%   column is a coefficient.
%   Col 4, 5, 6 are 1x2 boolean array indicating if S1 or S2 (respectively) are
%   sig different from S3.
CoefTbl{1} = table(); % Healthy
CoefTbl{2} = table(); % Concussed
for s = 1:size(AllRRs,1)
    Cond = AllRRs(s,1).ConditionCode + 1; % Cond = 1 for healthy, 2 for concussed
    MDL = GetLM(AllRRs(s,:), "MLS", "FAVA");
    % Get S3 coefficients
    a1(3) = MDL.lm.Coefficients{"a1", "Estimate"};
    b0(3) = MDL.lm.Coefficients{"b0", "Estimate"};
    b1(3) = MDL.lm.Coefficients{"b1", "Estimate"};
    % Get S1 and S2 a1
    a1(1) = a1(3) + MDL.lm.Coefficients{"Session_1:a1", "Estimate"};
    a1(2) = a1(3) + MDL.lm.Coefficients{"Session_2:a1", "Estimate"};
    % Get S1 and S2 b0
    b0(1) = b0(3) + MDL.lm.Coefficients{"Session_1:b0", "Estimate"};
    b0(2) = b0(3) + MDL.lm.Coefficients{"Session_2:b0", "Estimate"};
    % Get S1 and S2 b1
    b1(1) = b1(3) + MDL.lm.Coefficients{"Session_1:b1", "Estimate"};
    b1(2) = b1(3) + MDL.lm.Coefficients{"Session_2:b1", "Estimate"};
    % Get sig diff coef flags
    a1_SigDiffCoef = MDL.lm.Coefficients{["Session_1:a1", "Session_2:a1"], "pValue"}';
    b0_SigDiffCoef = MDL.lm.Coefficients{["Session_1:b0", "Session_2:b0"], "pValue"}';
    b1_SigDiffCoef = MDL.lm.Coefficients{["Session_1:b1", "Session_2:b1"], "pValue"}';
    % Assemble table
    tempTbl = table(a1, b0, b1, a1_SigDiffCoef, b0_SigDiffCoef, b1_SigDiffCoef,...
        'RowNames', AllRRs(s,1).SubID,...
        'VariableNames',["a1s","b0s","b1s","a1_pVal","b0_pVal","b1_pVal"]);
    CoefTbl{Cond} = [CoefTbl{Cond}; tempTbl];
end

%% Begin Plotting
SigP = 0.05 ./ size(AllRRs,1); % Familywise error rate
MarkerSize = 6; % default is 6
LineWidth = 1;

figure('WindowState','maximized')

Coefs = ["a1", "b0", "b1"];
Groups = ["Healthy", "Concussed"];
AxH = gobjects(3,2);

for row = 1:length(Coefs)
    for col = 1:2
        LinInd = sub2ind([2,length(Coefs)], col, row);
        AxH(row,col) = subplot(3, 2, LinInd);
        % Draw connecting lines
        plot(1:3, CoefTbl{col}.(Coefs(row)+"s"), 'color', [0 0 0 0.5])
        hold on
        [Sig_pts, NoSig_pts] = deal(CoefTbl{col}.(Coefs(row)+"s")(:,1:2));
        Sig_pts(CoefTbl{col}.(Coefs(row)+"_pVal") > SigP) = NaN;
        %NoSig_pts(CoefTbl{1}.a1_pVal <= SigP) = NaN;
        plot(1:2, Sig_pts, 'r', 'linestyle','none','marker','*',...
            'MarkerSize', MarkerSize, 'LineWidth', LineWidth)
        if row == length(Coefs)
            xlabel("Session")
        end
        title(Groups(col)+" "+Coefs(row))
    end
end
set(AxH, 'xtick', [1 2 3], 'xlim', [0.5 3.5])
linkaxes(AxH(1,:), 'y')
linkaxes(AxH(2,:), 'y')
linkaxes(AxH(3,:), 'y')

% Healthy a1
% Ha1 = subplot(3,2,1);
% plot(1:3, CoefTbl{1}.a1s, 'color', [0 0 0 0.5]) % connecting lines
% hold on
% % Add markers for sig diffs
% [Sig_pts, NoSig_pts] = deal(CoefTbl{1}.a1s(:,1:2));
% Sig_pts(CoefTbl{1}.a1_pVal > SigP) = NaN;
% NoSig_pts(CoefTbl{1}.a1_pVal <= SigP) = NaN;
% plot(1:2, Sig_pts, 'r', 'linestyle','none','marker','*',...
%     'MarkerSize', MarkerSize, 'LineWidth', 1)
% % plot(1:2, NoSig_pts, 'k', 'linestyle','none','marker','x',...
%     'MarkerSize', MarkerSize, 'LineWidth', 1)








