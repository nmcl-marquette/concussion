function FillEnvelope(XArray,TopSig,BottomSig,Color,Alpha)
%FILLENVELOPE

if nargin == 3
    Color = 'b';
    Alpha = 0.2;
end

% Is limited to NaN handling. Remove NaN tail.
NaNArray = isnan(XArray + TopSig + BottomSig);
FirstNaN = find(NaNArray,1,'first')-1;

if isempty(FirstNaN);FirstNaN=length(XArray);
    
XArray=XArray(1:FirstNaN);
TopSig=TopSig(1:FirstNaN);
BottomSig=BottomSig(1:FirstNaN);

patch(gca,[XArray flip(XArray)],[TopSig flip(BottomSig)],Color,...
    'facealpha',Alpha,'edgecolor','none');

end

