%%
function [spine,xyRibEnds,spineCurvature] = spineNribs(Xcont,Ycont)

% replicate the contour to deal with edge effects
nPoints = length(Xcont);
tempContX = Xcont;
tempContY = Ycont;
tempContX = repmat(tempContX,3,1);
tempContY = repmat(tempContY,3,1);
% add in an arbitrary z value for algorithms that require 3D curves
tempContZ = zeros(size(tempContX));
% estimate curvature along the contour, poles will be near high curvature
curvatureEstimate = abs(signedCurvature([tempContX,tempContY,tempContZ],3));

[xOut, yOut, peakpos] = peakfind(1:length(curvatureEstimate),curvatureEstimate);

% remove peaks that are in the replicated set
peakpos(peakpos<=nPoints) = [];
peakpos(peakpos>=(2*nPoints+1)) = [];
% 

% % keep the ones that are high in curvature and close to half a cell apart
% the top two are not always the poles, it would be nice to have a more
% nuanced version where they should be roughly half a cell apart
peakDist = pdist2(peakpos(:),peakpos(:));
idealDist = nPoints/2;
peakDist = abs(peakDist-idealDist)./idealDist;
peakDist(peakDist>0.25) = nan;
[kappaCopy1,kappaCopy2] = meshgrid(curvatureEstimate(peakpos),curvatureEstimate(peakpos));
kappaSum = kappaCopy1+kappaCopy2;
kappaSum(isnan(peakDist))= nan;
% find the max summed curvature for two peaks that are about half a cell
% apart
if isnan(max(kappaSum(:)))
    [~,peakIdx] = sort(curvatureEstimate(peakpos),'descend');
    peakpos = peakpos(peakIdx(1:2));
else
    [~,keptPair] = max(kappaSum(:));
    [keptPairI,keptPairJ] = ind2sub(size(kappaSum),keptPair);
    peakpos = [peakpos(keptPairI),peakpos(keptPairJ)];
end

% set up the length for a 'neighborhood' near the pole
s = max(4,round(nPoints/8));
s = min(8,s);
s = -s:s;


% set up an index/counter to loop over for center of the neighborhood
% positions
counter = 0;

for kk = min(s):max(s)
    counter = counter+1;
    % pull out a small neighbohood around a potential pole location
    xNeighborhood = tempContX(peakpos(1)+s+kk);
    yNeighborhood = tempContY(peakpos(1)+s+kk);
    
    
    % attempt 3, look for the "symmetrical triangular bisector" where two 
    % tangent lines on the periphery make an isoscles triangle
    xLeftEnd = xNeighborhood(1:3);
    yLeftEnd = yNeighborhood(1:3);
    xRightEnd = xNeighborhood(end-2:end);
    yRightEnd = yNeighborhood(end-2:end);
    
    % make two lines
    leftPoly = polyfit(xLeftEnd,yLeftEnd,1);
    rightPoly = polyfit(xRightEnd,yRightEnd,1);
    
    leftPolyVal = polyval(leftPoly,xNeighborhood);
    rightPolyVal = polyval(rightPoly,xNeighborhood);

    % find their intersection
    xIntersect = (leftPoly(2)-rightPoly(2))/(rightPoly(1)-leftPoly(1));
    yIntersect = polyval(leftPoly,xIntersect);
    
    % draw a new line to the point of the 'chord' that connects to the two
    % end points of the neighborhood
    midPointX = (xNeighborhood(1)+xNeighborhood(end))/2;
    midPointY = (yNeighborhood(1)+yNeighborhood(end))/2;
    
    % calculate the length of these legs of the triangle
    sideC = norm([xNeighborhood(1)-xIntersect,yNeighborhood(1)-yIntersect]);
    sideB = norm([midPointX-xIntersect,midPointY-yIntersect]);
    sideA = norm([xNeighborhood(1)-midPointX,yNeighborhood(1)-midPointY]);
    
    % record the deviation from normal, to later minimize
    thetaC(counter) = abs(90-acosd((sideC^2-sideA^2-sideB^2)/(-2*sideA*sideB)));
end

% take the argmin of this 'deviation from normal'
[~,minIdx] = min(thetaC);
bestOffset = minIdx+min(s)-1;

% add this as an offset to the position that had high curvature
peakpos(1) = peakpos(1)+bestOffset;


%%
% set up an index/counter to loop over for center of the neighborhood
% positions
counter = 0;

for kk = min(s):max(s)
    counter = counter+1;
    % pull out a small neighbohood around a potential pole location
    xNeighborhood = tempContX(peakpos(2)+s+kk);
    yNeighborhood = tempContY(peakpos(2)+s+kk);
    
    
    % attempt 3, look for the "symmetrical triangular bisector" where two 
    % tangent lines on the periphery make an isoscles triangle
    xLeftEnd = xNeighborhood(1:3);
    yLeftEnd = yNeighborhood(1:3);
    xRightEnd = xNeighborhood(end-2:end);
    yRightEnd = yNeighborhood(end-2:end);
    
    % make two lines
    leftPoly = polyfit(xLeftEnd,yLeftEnd,1);
    rightPoly = polyfit(xRightEnd,yRightEnd,1);
    
    leftPolyVal = polyval(leftPoly,xNeighborhood);
    rightPolyVal = polyval(rightPoly,xNeighborhood);

    % find their intersection
    xIntersect = (leftPoly(2)-rightPoly(2))/(rightPoly(1)-leftPoly(1));
    yIntersect = polyval(leftPoly,xIntersect);
    
    % draw a new line to the point of the 'chord' that connects to the two
    % end points of the neighborhood
    midPointX = (xNeighborhood(1)+xNeighborhood(end))/2;
    midPointY = (yNeighborhood(1)+yNeighborhood(end))/2;
    
    % calculate the length of these legs of the triangle
    sideC = norm([xNeighborhood(1)-xIntersect,yNeighborhood(1)-yIntersect]);
    sideB = norm([midPointX-xIntersect,midPointY-yIntersect]);
    sideA = norm([xNeighborhood(1)-midPointX,yNeighborhood(1)-midPointY]);
    
    % record the deviation from normal, to later minimize
    thetaC(counter) = abs(90-acosd((sideC^2-sideA^2-sideB^2)/(-2*sideA*sideB)));
end

% take the argmin of this 'deviation from normal'
[~,minIdx] = min(thetaC);
bestOffset = minIdx+min(s)-1;

% add this as an offset to the position that had high curvature
peakpos(2) = peakpos(2)+bestOffset;

% centerlines aka spines
% try 1: smoothly interpolate xy as a function of fractional length to the
% other pole.

% calculate 's' the length along the contour
if peakpos(1)<peakpos(2)
else
    peakpos = [peakpos(1),peakpos(2)+nPoints];
end

leftArmX = tempContX(peakpos(1):peakpos(2));
leftArmY = tempContY(peakpos(1):peakpos(2));

rightArmX = tempContX(peakpos(2):(peakpos(1)+nPoints));
rightArmY = tempContY(peakpos(2):(peakpos(1)+nPoints));

diffLeft = sqrt(diff(leftArmX).^2+diff(leftArmY).^2);
sLeft = [0;cumsum(diffLeft)];

diffRight = sqrt(diff(rightArmX).^2+diff(rightArmY).^2);
sRight =[0; cumsum(diffRight)];

sRight = 1-sRight./max(sRight);
sLeft = sLeft./max(sLeft);

% estimate smoothing length
h = 2/nPoints;
hprime = 1/(1+(h^3)/60);
% smooth harder
hprime = (1 - hprime)*2+1;

% calculate cubic smoothing splines for X and Y
pp1X = csaps([sLeft;sRight],[leftArmX;rightArmX],hprime);
pp1Y = csaps([sLeft;sRight],[leftArmY;rightArmY],hprime);

% resample along this smoothed spine
newS = linspace(0,1,1000);
newX = fnval(pp1X,newS);
newY = fnval(pp1Y,newS);

diffCenterline = sqrt(diff(newX).^2+diff(newY).^2);
sCenterline = [0,cumsum(diffCenterline)];
nCenterlinePoints = round(sCenterline(end));
newX = fnval(pp1X,linspace(0,1,nCenterlinePoints));
newY = fnval(pp1Y,linspace(0,1,nCenterlinePoints));

% calculate a subregion surrounding the outline of the cell to calculate
% the new spine

% calculate a distance to the cell outline as an energy
% make a new bounding box
smallBoxSizeX = max(tempContX)-min(tempContX);
smallBoxSizeY = max(tempContY)-min(tempContY);

% extract the contour in a smaller box
tempContX2 = tempContX-min(tempContX)+0.25*smallBoxSizeX;
tempContY2 = tempContY-min(tempContY)+0.25*smallBoxSizeY;
smallBox = zeros(round(1.5*smallBoxSizeY),round(1.5*smallBoxSizeX));
smallBox(sub2ind(size(smallBox),round(tempContY2),round(tempContX2))) = 1;

% calculate distance to the contour
M3=bwdist(smallBox).^2;

% shift the smoothed centerline to this new coordinate system
CLtemp = [newX'-min(tempContX)+0.25*smallBoxSizeX,...
    newY'-min(tempContY)+0.25*smallBoxSizeY];

% use this smoothed centerline as the input into an active contour
% algorithm
CLtemp(:,3) = 2;
M3 = cat(3,-1*ones(size(M3)),M3,-1*ones(size(M3)));
CLind=sub2ind(size(M3),round(CLtemp(:,2)),round(CLtemp(:,1)),CLtemp(:,3));

M3=M3/max(M3(CLind));

% set up the parameters for the active contour
cline_para.CLbeta = 1;
cline_para.CLalpha = 0.1;
cline_para.show_flag = 0;
cline_para.gamma = 10;
cline_para.gradient_force = .01;
cline_para.iterations = 200;
cline_para.kappa = 2;
CLfit = ActiveContourFit(M3, cline_para, CLtemp);

% shift the spine back into the coordinate system of the cell outline
% contour
CLfit = CLfit(:,[1,2]);
CLfit(:,1) = CLfit(:,1)+min(tempContX)-0.25*smallBoxSizeX;
CLfit(:,2) = CLfit(:,2)+min(tempContY)-0.25*smallBoxSizeY;

% sample at roughly one pixel spacing density along the centerline
sCL = [0;cumsum(sqrt(sum(diff(CLfit).^2,2)))];
nPointsCenterline = round(max(sCL));
sSampling = linspace(0,sCL(end),nPointsCenterline);
spine = [interp1(sCL,CLfit(:,1),sSampling'),...
    interp1(sCL,CLfit(:,2),sSampling')];

spine(1,:) = [tempContX(peakpos(1)),tempContY(peakpos(1))];
spine(end,:) = [tempContX(peakpos(2)),tempContY(peakpos(2))];

% estimate the curvature of this centerline 
spineCurvature = Curvature([spine(:,1),spine(:,2),zeros(size(spine,1),1)],3);
if isempty(spineCurvature)
   spineCurvature = nan(size(spine,1),1);
end


%% find rib lengths
leftRibs(1,:) = [spine(1,:),spine(1,:)];
rightRibs(1,:) = [spine(1,:),spine(1,:)];
% extract original contours
Xcont = tempContX(peakpos(1):(peakpos(1)+nPoints));
Ycont = tempContY(peakpos(1):(peakpos(1)+nPoints));

% make sure they wrap around
if not(isequal(Xcont(1),Xcont(end)))
    Xcont = [Xcont;Xcont(1)];
end

if not(isequal(Ycont(1),Ycont(end)))
    Ycont = [Ycont;Ycont(1)];
end
nPoints = size(Ycont,1)-1;

% how many points are there in the cell outline contour
jjContour = nPoints;

% how many points are there along the cell centerline spine
nPointsCenterline = size(spine,1);

% start at one pole and march opposite directions toward the other end
leftRibContourIndex = 2;
rightRibContourIndex = nPoints;
for kkRib = 2:(nPointsCenterline-1)   
    % find the initial point on the centerline
    spineLocation = spine(kkRib,:);
    
    % find the tangent line near this point
    spineTangent = spine(kkRib+1,:)-spine(kkRib-1,:);
    
    % calculate the orientation of the ribs
    ribOrientation = pi/2+atan2(spineTangent(2),spineTangent(1));
    
    % on the left side, check to see if "normal" happens between these next
    % two contour points
    isNextLeft = true;
    while isNextLeft                
        thetaTest = ribOrientation;
        theta0 = atan2((Ycont(leftRibContourIndex)-spineLocation(2)),...
            (Xcont(leftRibContourIndex)-spineLocation(1)));
        theta1 = atan2((Ycont(leftRibContourIndex+1)-spineLocation(2)),...
            (Xcont(leftRibContourIndex+1)-spineLocation(1)));
        
        % calculate the signed directional difference between these
        % orientations
        % see https://stackoverflow.com/questions/1878907/the-smallest-difference-between-2-angles
        diff0test = atan2(sin(theta0-thetaTest), cos(theta0-thetaTest));
        diff1test = atan2(sin(theta1-thetaTest), cos(theta1-thetaTest));
        diff01test = atan2(sin(theta1-theta0), cos(theta1-theta0));
        
        % is there an edge/corner case where this doesn't behave?
        if (diff01test-(diff0test+diff1test))>0.05
            % sum in different order
            thetaTest = thetaTest+2*pi;
            diff0test = atan2(sin(theta0-thetaTest), cos(theta0-thetaTest));
            diff1test = 2*pi-atan2(sin(theta1-thetaTest), cos(theta1-thetaTest));
            diff01test = atan2(sin(theta1-theta0), cos(theta1-theta0));
            % throw an error if there is an issue
            if (diff01test-(diff0test+diff1test))>0.05
                error('morphometrics:spineNribs:leftArm','unknown angular sum.');
            end
        end
        
        % if the sign of these angle differences changes, then one has
        % passed through the normal
       if sign(diff0test*diff1test)<1
          isNextLeft = false;
          m1 = ((Ycont(leftRibContourIndex+1)-Ycont(leftRibContourIndex))/(Xcont(leftRibContourIndex+1)-Xcont(leftRibContourIndex)));
          m2 = tan(ribOrientation);
          y = @(x) m1*(x-Xcont(leftRibContourIndex))+Ycont(leftRibContourIndex);
          xIntersect = (spineLocation(2)-Ycont(leftRibContourIndex)+m1*Xcont(leftRibContourIndex)-m2*spineLocation(1))/(m1-m2);
          leftRibs(kkRib,:) = [spineLocation,xIntersect,y(xIntersect)];
       else % move on to the next one
           leftRibContourIndex = leftRibContourIndex+1;
       end
       
       
    end
    
    
    % on the right side, check to see if "normal" happens between these next
    % two contour points
    isNextRight = true;
    while isNextRight               
        thetaTest = ribOrientation;
        theta0 = atan2((Ycont(rightRibContourIndex)-spineLocation(2)),...
            (Xcont(rightRibContourIndex)-spineLocation(1)));
        theta1 = atan2((Ycont(rightRibContourIndex-1)-spineLocation(2)),...
            (Xcont(rightRibContourIndex-1)-spineLocation(1)));
        
        % calculate the signed directional difference between these
        % orientations
        % see https://stackoverflow.com/questions/1878907/the-smallest-difference-between-2-angles
        diff0test = atan2(sin(theta0-thetaTest), cos(theta0-thetaTest));
        diff1test = atan2(sin(theta1-thetaTest), cos(theta1-thetaTest));
        diff01test = atan2(sin(theta1-theta0), cos(theta1-theta0));
        
        % is there an edge/corner case where this doesn't behave?
        if (diff01test-(diff0test+diff1test))>0.05
            % sum in different order
            thetaTest = thetaTest+2*pi;
            diff0test = atan2(sin(theta0-thetaTest), cos(theta0-thetaTest));
            diff1test = 2*pi-atan2(sin(theta1-thetaTest), cos(theta1-thetaTest));
            diff01test = atan2(sin(theta1-theta0), cos(theta1-theta0));
            if (diff01test-(diff0test+diff1test))>0.05
                error('morphometrics:spineNribs:rightArm','unknown angular sum.');
            end
            
        end
        
        % if the sign of these angle differences changes, then one has
        % passed through the normal
       if sign(diff0test*diff1test)<1
          isNextRight = false;
          m1 = ((Ycont(rightRibContourIndex-1)-Ycont(rightRibContourIndex))/(Xcont(rightRibContourIndex-1)-Xcont(rightRibContourIndex)));
          m2 = tan(ribOrientation);
          y = @(x) m1*(x-Xcont(rightRibContourIndex))+Ycont(rightRibContourIndex);
          xIntersect = (spineLocation(2)-Ycont(rightRibContourIndex)+m1*Xcont(rightRibContourIndex)-m2*spineLocation(1))/(m1-m2);
        
          rightRibs(kkRib,:) = [spineLocation,xIntersect,y(xIntersect)];

       else
           rightRibContourIndex = rightRibContourIndex-1;
       end
       
       
    end
    
end

% add the pole positions back in to the end of the spine
leftRibs(end+1,:) = [spine(end,:),spine(end,:)];
rightRibs(end+1,:) = [spine(end,:),spine(end,:)];

%% march along the rib ends and see if any ends are in the "wrong" order
xyRibEnds = cat(1, leftRibs(2:end,[3,4]),flip(rightRibs(2:(end-1),[3,4]),1));

for jjRibEnd = 1:size(xyRibEnds,1);
    distancesToOutline = sqrt(sum(bsxfun(@minus,xyRibEnds(jjRibEnd,:),[Xcont,Ycont]).^2,2));
    [~,tempOutlineIndex] = min(distancesToOutline);
    % check to see if it is closer to +1 or -1
    if distancesToOutline(tempOutlineIndex-1)>distancesToOutline(tempOutlineIndex+1)
        normalizeDistance = sqrt(sum(diff(...
            [Xcont(tempOutlineIndex:tempOutlineIndex+1),...
            Ycont(tempOutlineIndex:tempOutlineIndex+1)]).^2));
        sOutlineIndex(jjRibEnd) = tempOutlineIndex + distancesToOutline(tempOutlineIndex)/normalizeDistance;
        
    else
        normalizeDistance = sqrt(sum(diff(...
            [Xcont(tempOutlineIndex-1:tempOutlineIndex),...
            Ycont(tempOutlineIndex-1:tempOutlineIndex)]).^2));
        sOutlineIndex(jjRibEnd) = tempOutlineIndex - distancesToOutline(tempOutlineIndex)/normalizeDistance;
        
    end
    
end
% reorder
[sortValues,sortIdx] = sort(sOutlineIndex,'ascend');
xyRibEnds = xyRibEnds(sortIdx,:);

% split into left and right
leftRibs(2:(end-1),[3,4]) = xyRibEnds(1:(nPointsCenterline-2),:);
rightRibs(2:(end-1),[3,4]) = flip(xyRibEnds((nPointsCenterline):(end),:));

% concatenate
xyRibEnds = [leftRibs(:,3:4),rightRibs(:,3:4)];

end
    %%
 

 