function Out = MatchList(CellTable, Entry)
%% MatchList.m
% This function takes a Mx2 cell array 'CallTable' filled with strings and
% searches for the 'Entry' string in the table; regardless of which column
% it is in. The function then returns the alternative column of the same
% row that contained 'Entry'.
%
% Variables:
%   CellTable   [Mx2] cell (strings)
%   Entry       string
%   Out         string

Index = strcmp(CellTable,Entry); % Index is a 2D logical of same size CellTable
if ~any(any(Index))
    % No Entry was found in CellTable
    error('%s was not found in the cell table.',Entry)
end
ActiveCol = any(Index); % Collapses rows to yield which column the Entry was found in
ActiveCol = ~ActiveCol; % bitwise 'not' to change index to fetching column
ActiveRow = any(Index,2); % Collapses columns to yield the row the Entry was found in
Out = CellTable{ActiveRow,ActiveCol};


end

