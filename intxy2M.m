function [allCases,allCasesExpanded] =intxy2M(vx,vy,bx,by)
% This will calculate for each input line segment in vx,vy if there is
% intersection with at least one of the line segments in bx by.
%
% However, there is an interesting inherited convention for this function
% in the shape of the imorpnputs.
%
% The N test vectors (vx and vy coordinates) are organized into an input with
% 2N values, that is, the first vector is vx(1:2), second vx(3:4), third
% vx(5:6).
%
% The M target vectors (bx and by coordinates) are organized as sequential
% vertices that march around a closed contour. This means BOTH that the
% first vector is bx(1:2), second bx(2:3), third bx(3:4),
% AND
% bx(1)==bx(end)
%
%%
% there are two general classes for calculating the intersection of two
% line segments

% let line segment 1 be from p1 -> q1
% let line segment 2 be from p2 -> q2

% orientation can be clockwise (1), collinear (0), or counterclockwise (-10

% general case of intersection: not all collinear
% (p1, q1, p2) and (p1, q1, q2) have different orientations 
% AND
% (p2, q2, p1) and (p2, q2, q1) have different orientations

% special case of intersection: collinear and overlapping
% (p1, q1, p2), (p1, q1, q2), (p2, q2, p1), and (p2, q2, q1) are all collinear
% AND
% the x-projections of (p1, q1) and (p2, q2) intersect
% AND
% the y-projections of (p1, q1) and (p2, q2) intersect

%% start with assembling the faces
nVerticesTarget = size(bx,1); % the target vertices are connected i to i+1, i+1 to i+2, and closes back at the end
nVerticesTest = numel(vx); % the test vertices are connected only two at a time, no connection i+1 to i+2

% concatenate all vertices
allVerticesX = cat(1,bx(:),vx(:));
allVerticesY = cat(1,by(:),vy(:));

% line segments go p1->q1 (test), p2->q2 (target)
% p1 and q1 indices (test)
p1Indices = (nVerticesTarget+1):2:(nVerticesTarget+nVerticesTest);
q1Indices = (nVerticesTarget+2):2:(nVerticesTarget+nVerticesTest);

% p2 and q2 indices (target)
p2Indices = 1:(nVerticesTarget-1);
q2Indices = 2:(nVerticesTarget);

% grid of test points for vectorizing
[indexTestP1,indexTargetP2] = meshgrid(p1Indices,p2Indices);
[indexTestQ1,indexTargetQ2] = meshgrid(q1Indices,q2Indices);

% (p1, q1, p2) and (p1, q1, q2) have different orientations 
P1Q1P2 = [indexTestP1(:),indexTestQ1(:),indexTargetP2(:)];
P1Q1Q2 = [indexTestP1(:),indexTestQ1(:),indexTargetQ2(:)];

% (p2, q2, p1) and (p2, q2, q1) have different orientations
P2Q2P1 = [indexTargetP2(:),indexTargetQ2(:),indexTestP1(:)];
P2Q2Q1 = [indexTargetP2(:),indexTargetQ2(:),indexTestQ1(:)];


% build up the x,y,z coordinates of all the points
allPointsInput = allVerticesX(:)';
allPointsInput(2,:) = allVerticesY(:)';
allPointsInput(3,:) = 0;

% test the orientation of the point triples
P1Q1P2_orientation = calcInPlaneOrientation(allPointsInput, P1Q1P2);
P1Q1Q2_orientation = calcInPlaneOrientation(allPointsInput, P1Q1Q2);

P1Q1P2_ne_P1Q1Q2 = not(P1Q1P2_orientation==P1Q1Q2_orientation);

P2Q2P1_orientation = calcInPlaneOrientation(allPointsInput, P2Q2P1);
P2Q2Q1_orientation = calcInPlaneOrientation(allPointsInput, P2Q2Q1);

P2Q2P1_ne_P2Q2Q1 = not(P2Q2P1_orientation==P2Q2Q1_orientation);

generalCase = reshape(and(P2Q2P1_ne_P2Q2Q1,P1Q1P2_ne_P1Q1Q2),size(indexTestP1));
% generalCase = any(generalCase,1);

%% special case where everything is colinear

% special case of intersection: collinear and overlapping
% (p1, q1, p2), (p1, q1, q2), (p2, q2, p1), and (p2, q2, q1) are all collinear
% AND
% the x-projections of (p1, q1) and (p2, q2) intersect
% AND
% the y-projections of (p1, q1) and (p2, q2) intersect

isCollinear = and(and(P1Q1P2_orientation==0,P1Q1Q2_orientation==0),...
    and(P2Q2P1_orientation==0,P2Q2Q1_orientation==0));
% only check for projections if there are actually some collinear points,
% this seems like a quite rare occurence
specialCase = zeros(size(generalCase));
if any(isCollinear(:))
%     warning('checkForIntersections:collinearSegments', 'At least one set of collinear segments, checking for overlap.');
    listOfOverlapsToCheck = find(isCollinear);
    for jjOverlap = 1:numel(listOfOverlapsToCheck)
        p1Temp = allPointsInput(:,indexTestP1(listOfOverlapsToCheck(jjOverlap)));
        q1Temp = allPointsInput(:,indexTestQ1(listOfOverlapsToCheck(jjOverlap)));
        p2Temp = allPointsInput(:,indexTargetP2(listOfOverlapsToCheck(jjOverlap)));
        q2Temp = allPointsInput(:,indexTargetQ2(listOfOverlapsToCheck(jjOverlap)));
        
        % project along x,y and check for overlap there
        X1 = [min([p1Temp(1),q1Temp(1)]),max([p1Temp(1),q1Temp(1)])];
        X2 = [min([p2Temp(1),q2Temp(1)]),max([p2Temp(1),q2Temp(1)])];

        Y1 = [min([p1Temp(2),q1Temp(2)]),max([p1Temp(2),q1Temp(2)])];
        Y2 = [min([p2Temp(2),q2Temp(2)]),max([p2Temp(2),q2Temp(2)])];

        xOverlap = and(...
            or(ge(X2(1),X1(1)), ge(X2(2),X1(1)) ),...
            or(le(X2(1),X1(2)), le(X2(2),X1(2))));
            
        yOverlap = and(...
            or(ge(Y2(1),Y1(1)), ge(Y2(2),Y1(1)) ),...
            or(le(Y2(1),Y1(2)), le(Y2(2),Y1(2))));
        
        specialCase(listOfOverlapsToCheck(jjOverlap)) = double(and(xOverlap,yOverlap));
    end
    
end

allCases = double(any(or(generalCase,specialCase)));

if nargout>1
allCasesExpanded = or(generalCase,specialCase);
end

function inPlaneOrientation = calcInPlaneOrientation(pointsIn, facesIn)
% using the faces (or ordering of points), calculate if the points are
% clockwise (+1), counterclockwise (-1), or collinear (0)

% tolerance for calling collinear is comparing the magnitude of the face
% vector compared to the average length of the two edge lengths. 
TOL_COLLINEAR = 0.01;

if ne(any(pointsIn(3,:)),0)
    error('calcInPlaneOrientation:zPlaneNonZero', 'Some of the points do not lay at z=0.')
end

% vector from first vertex to second vertex in face
testA = pointsIn(:,facesIn(:,2))-...
    pointsIn(:,facesIn(:,1));

% vector from second vertex to third vertex in face
testB = pointsIn(:,facesIn(:,3))-...
    pointsIn(:,facesIn(:,2));

% face normal (according to sign convention)
normalFace = cross(testA,testB);

% project face normal onto the z axis but scale base on size of testA,
% testB
magnitude = (sqrt(sum(testA.^2))+sqrt(sum(testB.^2)))/2;
inPlaneOrientation = sign(normalFace(3,:)); % this has some tolerance/floating point issues

inPlaneOrientation(abs(normalFace(3,:)./magnitude)<TOL_COLLINEAR) = 0;

