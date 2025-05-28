function RRtlb = GetRRs(opts)

arguments
	opts.Sessions = [1 2 3]
	opts.FileName = "RRs_Complete.mat"
	opts.Verbose = false
end

% Load all subject RR arrays that have at least three sessions.
SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
Subs = dir(fullfile(SubjectDataFolder, "Sub*"));
Subs = string({Subs.name})';
% Remove Sub C019 for two concussions
Subs(Subs == "SubC019") = [];

AllRRs = [];
SubIDs = [];
Group = [];
for sub = Subs'
	if opts.Verbose; fprintf("Collecting %s - ", sub); end

	SubFilename = fullfile(SubjectDataFolder, sub, opts.FileName);
	S = load(SubFilename);
	RRs = S.RRs;

	if length(RRs) >= 3
		if opts.Verbose; fprintf("Complete\n"); end
		AllRRs = [AllRRs; RRs(1:3)]; % Take first three sessions
		SubIDs = [SubIDs; RRs(1).SubID];
		Group = [Group; RRs(1).Condition];
	else
		if opts.Verbose; fprintf("Not enough sessions\n"); end
	end

end

RRtlb = table(SubIDs, Group, AllRRs);

end

