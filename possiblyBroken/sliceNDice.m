function [endInt,periphInt,centInt,midInt] = sliceNDice(cellData,isNormalized);
% old format
if size(cellData,2) == 19
    cellData(:,9:20) = cellData(:,8:19);
    cellData(:,8) = nan;
end
% ends
endInt = cellData(:,10)+cellData(:,12);

% periphery
periphInt = cellData(:,10)+cellData(:,12)+...
    cellData(:,15)+cellData(:,19);

% middles
midInt = cellData(:,18);
centInt = cellData(:,14);

% total (includes over counting)
totalRegInt = cellData(:,10) + cellData(:,12) + ...
    cellData(:,16) + cellData(:,20) + ...
    cellData(:,14) + cellData(:,18);

if isNormalized
    endInt = endInt.*cellData(:,3)./cellData(:,7);
    midInt = midInt.*cellData(:,3)./cellData(:,7);
    centInt = centInt.*cellData(:,3)./cellData(:,7);
    periphInt = periphInt.*cellData(:,3)./cellData(:,7);
else
%     endInt = endInt.*cellData(:,7);
%     midInt = midInt.*cellData(:,7);
%     centInt = centInt.*cellData(:,7);
%     periphInt = periphInt.*cellData(:,7);
end

