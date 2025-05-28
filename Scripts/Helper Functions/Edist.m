function dis = Edist(A,B)
    % Computes the Euclidean distance between two numbers or vectors
    error('Use EDist2')
    if nargin == 1
        % Only A is provided. Using Edist to compute distance between two
        % values in an array A
        dis = sqrt(A(:,1).^2 + A(:,2).^2);
    else
        % Compute distance between two arrays
        dis = sqrt(A.^2 + B.^2);
    end
end