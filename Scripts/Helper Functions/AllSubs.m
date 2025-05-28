function  Subjects = AllSubs(Type)
%% AllSubs.m
% Returns a cell array of subject IDs based on the type specified.
% Type is an optional cell array argument containing the group identifier
% of a subject (the first character) which is either 'C', 'N', or 'R'.

% Check if all subjects are desired
slh = OSSyntax;
ScriptLoc = mfilename('fullpath');
Levels = strfind(ScriptLoc,slh);
Root = ScriptLoc(1:Levels(end-2));

Files = dir([Root slh 'Data' slh]);
Subjects = {}; % Reset Subjects cell array
% Auto build a Subjects cell array from Data directory
for n = 1:length(Files)
    if ~isempty(strfind(Files(n).name,'Sub')) && length(Files(n).name)==7
        Subjects = [Subjects {Files(n).name(4:end)}];
    end
end

% Use only Type subjects (if any)
UseArray = false(1,length(Subjects));
if nargin == 1
    for n = 1:length(Type)
        FoundArray = strfind(Subjects,Type(n));
        for f = 1:length(FoundArray)
            if isempty(FoundArray{f}) && ~UseArray(f)
                UseArray(f) = false;
            else
                UseArray(f) = true;
            end
        end
    end
    Subjects(~UseArray) = [];
end

end

