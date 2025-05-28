function VersionVec = VersionString2Vec( VersionString )
%% Converts version string to a version vector
% Only supports 3-point version convention:
% Major.Minor.Update
%   Major	A critical update that requires rerunning all relevant
%           interactions. These updates include changing constructors of
%           objects or adding properties.
%   Minor   An update that will require some code to be rerun or given
%           special attention (such as a helper/converter script).
%   Update  A small update that does not impact interactions. These updates
%           are like GUI modifications that don't affect data.

Points = strfind(VersionString,'.');
VersionVec(1) = str2double(VersionString(1:Points(1)-1));
VersionVec(2) = str2double(VersionString(Points(1)+1:Points(2)-1));
VersionVec(3) = str2double(VersionString(Points(2)+1:end));
VersionVec = uint8(VersionVec);

end

