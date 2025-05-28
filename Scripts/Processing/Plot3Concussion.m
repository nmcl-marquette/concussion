%clc;clear;

S = load("Data/MasterTableFromSPSS.mat");
MT = S.MT;
clear S

var1 = "DaysPostInjury";
%var2 = "c_AvgTimingZ";
var2 = "Pre_Sum";
var3 = "scat_Sum";

% Filter and split based on TAU
ConS1 = MT(MT.Session==1 & MT.ConditionCode==1, :);
ConS1TauPos = ConS1(ConS1.GroupSplit == 2, :);
ConS1TauNeg = ConS1(ConS1.GroupSplit == 1, :);

figure
h_taupos = plot3(ConS1TauPos, var1, var2, var3, ...
    "Color", 'r', 'markerfacecolor', 'r');
hold on
h_tauneg = plot3(ConS1TauNeg, var1, var2, var3, ...
    "Color", 'b', 'markerfacecolor', 'b');
set([h_taupos h_tauneg], 'linestyle', 'none', 'marker', 'o')
grid on
legend("\tau+","\tau-")

