function OutType = isFunction(FilePath)
% Input is a file path with extension. Only works for .m files.
% Output is one of the following:
%   1   Function
%   0   Script

FileID = fopen(FilePath);

ThisString = fscanf(FileID,'%s',1); % Scan the first word of the document
% The first word should be "function"

if strcmp(ThisString,'function')
    OutType = true;
else
    OutType = false;
end

fclose(FileID);

end

