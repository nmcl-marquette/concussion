%% Generate RR Objects
%	Generates RobotResults objects for each subject.
%	Prior to generating the RR object, a RobotTrial4 object will be
%	constructed for each trial of that subject's session.
%

% Subjects to analyze are based on subject folders in "Data"
SubjectDataFolder = fullfile(RobotTrial4.CodePath, "Data", filesep);
Subs = dir(fullfile(SubjectDataFolder, "Sub*"));
Subs = string({Subs.name})';

% For every subject, session, and trial, construct RobotTrial4 objects and
% place them in a RobotResults object. Collect an RR object for each
% session and create an array of RR objects for each subject. Save each
% subject RR array in their subject folder.
% If no parallel pool, create one
if isempty(gcp('nocreate'))
	parpool;
end
Save = @(file,RRs) save(file,"RRs");
parfor n = 1:length(Subs)
	sub = Subs(n);
	SubSessFolders = fullfile(SubjectDataFolder, sub);
	% Determine number of sessions this subject participated in.
	Sess = dir(fullfile(SubSessFolders, "Session*"));
	Sess = string({Sess.name})';
	RRs = [];
	% For every session, determine if robot data exists. If so, construct
	% RT objects. If not, skip.
	for sess = Sess'
		SubSessRobotFolder = fullfile(SubSessFolders, sess, "Robot", filesep);
		Trials = dir(fullfile(SubSessRobotFolder, "trial*.mat"));
		if isempty(Trials)
			% no data for this session
			continue
		end
		[~,index] = sortrows({Trials.date}.'); Trials = Trials(index); %clear index; % Sort Trials based on time
		Trials = string({Trials.name})';
		% determine last trial number
		LastTrialNum = double(extractBetween(Trials(end),"trial","_"));
		% Allocate at least this many trials
		RTs = RobotTrial4(extractAfter(sub,"Sub"), ...
			double(extractAfter(sess, "Session")),...
			1:LastTrialNum);
		% Load trial data into initialized objects
		RTs = RTs.PopData;
		% Build RR object for this session
		RRs = [RRs RobotResults2(RTs, 2)];
		fprintf("%s, %s complete\n", sub, sess)
	end
	% RR array is completed, distribute ledger data to each RR
	
	% Save this subject's RRs
	Save(fullfile(SubSessFolders, "RRs.mat"), RRs)
	fprintf("%s saved\n", sub)
end
fprintf('All subjects completed\n')



