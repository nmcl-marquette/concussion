function Distance = EDist2(Cord1,Cord2)
% Computes the euclidean distance between two 2D coordinate vectors
% Distance of Cord2 from Cord1 (Cord2 - Cord1)
% Cord1 and Cord2 can be vectors
% Cord1 can be a 1x2 or mx2 vector while Cord2 can be mx2
% Subtracts the two vectors and computes the remaining net vector.

ResultingCord = NaN(max([size(Cord1,1),size(Cord2,1)]), 2);

ResultingCord(:,1) = Cord2(:,1) - Cord1(:,1); % Remove X offset
ResultingCord(:,2) = Cord2(:,2) - Cord1(:,2); % Remove Y offset

Distance = sqrt(sum(ResultingCord.^2,2)); % Compute the distance for each row

end

