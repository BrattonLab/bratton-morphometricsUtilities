function deleteContours()
% this function is an accessory to morphometrics and allows users to remove
% specific regions.
% WARNING: this can easily lead to selection bias
% Release notes:
% 20170731 updated help text to correctly reflect the hotkeys

% define cell as a variable. It will be overwritten when the mat file is
% loaded. Otherwise the compiler treats the later call to "cell" as a
% reference to the function named cell

%%


if verLessThan('MATLAB','9.4')
    currentVersionString = ver('MATLAB');
warning('deleteContours:LegacyMode',...
    ['Current version of MATLAB (',currentVersionString.Version,...
    ') is less than expected (9.4). ',...
    'Some functionality may not be supported. ',...
    'Enabling legacy mode and silencing this warning.']);
warning('off','deleteContours:LegacyMode');

end
cell = [];
fileNames = {};
pathNames = {};
%Independent multifile selector
FolderPaths = uipickfiles('Prompt',...
    'Please select all folders containing *CONTOURS*.m files',...
    'FilterSpec','*CONTOURS*');
% check to see if this is a folder or single file
for i = 1:numel(FolderPaths)
    % ask for a directory listing to see if it is a file or folder
    tempDirListing = dir(FolderPaths{i});
    if length(tempDirListing)>1 % a directory will always have '.' '..'
        
        % list the contour files and add them to the growing cell array
        contoursList = dir([FolderPaths{i},filesep, '*CONTOURS.mat']);
        for j = 1:length(contoursList)
            fileNames{end+1} = contoursList(j).name;
            pathNames{end+1} = FolderPaths{i};
        end
    else % not a directory, split into path stem and file name
        [pathNames{end+1},tempName, tempExt] = fileparts(FolderPaths{i});
        fileNames{end+1} = [tempName, tempExt];
        
    end
end

% [fileNames,pathName] = uigetfile('*.mat','Please select contours file',...
%     'MultiSelect','on');

iiFile = 1;
jFrame = 1;
% first, assume that the mat file is in the same folder as the image
load(fullfile(pathNames{iiFile},fileNames{iiFile}));

iiFile = 1;

figHandle = figure('Tag','deleteContoursMainFigure');
axesHand = axes('tag','Axes.Main');
axes2 = axes('Units','normalized','Parent',figHandle,...
    'Position',[0.02,0.02,0.15,0.15],'tag','Axes.Overview');


if not(verLessThan('MATLAB','9.4'))
    % version 9.4 / R2018a compatibility
    axes2.Toolbar.Visible = 'off';
    axesHand.Toolbar.Visible = 'off';
end



try
    %     Try newest syntax (?R2014)
    xlimlistener = addlistener(axesHand,'XLim','PostSet',@limitsListener);
catch ME
    %     Catch legacy (?R2013)
    xlimlistener = handle.listener(axesHand,'XLim','PostSet',@limitsListener);
end
setappdata(figHandle, 'xlimlistener',xlimlistener );

try
    %     Try newest syntax (?R2014)
    ylimlistener = addlistener(axesHand,'YLim','PostSet',@limitsListener);
catch ME
    %     Catch legacy (?R2013)
    ylimlistener = handle.listener(axesHand,'YLim','PostSet',@limitsListener);
end
setappdata(figHandle, 'ylimlistener',ylimlistener );


setptr(figHandle,'arrow');
originalPointer = getptr(figHandle);
setappdata(figHandle,'originalPointer',originalPointer);
setappdata(figHandle,'axesHand',axesHand);
setappdata(figHandle,'isDefaultSelectMode',0);

% setup extra toolbar buttons
toolbarHandle = uitoolbar(figHandle);

p = uitoggletool(toolbarHandle,'TooltipString','Select partial regions?',...
    'ClickedCallback',...
    {@toggleSelectPartialRegion},'tag','Toolbar.PartialRegionSelect');

% Read an image
setappdata(figHandle,'selectPartialRegion',true);

% deal with a path setting where the icon is unavailable
filePathToDeleteContours = which('deleteContours');
[filePathToDeleteContours,~] = fileparts(filePathToDeleteContours);
[icon] = imread(fullfile(filePathToDeleteContours,'icons','selectPartialRegion.png'));

% Set the button icon
set(p,'CData',icon);

p2 = uitoggletool(toolbarHandle,'TooltipString','Screen individual regions?',...
    'ClickedCallback',...
    {@screenIndividualRegions},'tag','Toolbar.IndividualRegions');

% deal with a path setting where the icon is unavailable
filePathToDeleteContours = which('deleteContours');
[filePathToDeleteContours,~] = fileparts(filePathToDeleteContours);
[icon] = imread(fullfile(filePathToDeleteContours,'icons','screenIndividualRegions.png'));

% Set the button icon
set(p2,'CData',icon);

p3 = uitoggletool(toolbarHandle,'TooltipString','Display contour break point',...
    'ClickedCallback',...
    {@toggleDisplayContourBreak},'tag','Toolbar.ContourBreak');

setappdata(figHandle,'displayContourBreak',false);

% deal with a path setting where the icon is unavailable
filePathToExtractIntensities = which('extractIntensities');
[filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
[icon] = imread(fullfile(filePathToExtractIntensities,'icons','displayContourBreakOff.png'));

% Set the button icon
set(p3,'CData',icon);


hToolbar = findall(figHandle,'tag','FigureToolBar');
set(hToolbar,'Visible','off');
panHand = findall(hToolbar,'tag','Exploration.Pan');
zoomInHand = findall(hToolbar,'tag','Exploration.ZoomIn');
zoomOutHand = findall(hToolbar,'tag','Exploration.ZoomOut');
saveHand = findall(hToolbar,'tag','Standard.SaveFigure');
openHand = findall(hToolbar,'tag','Standard.FileOpen');




if isempty(panHand)
panHandCData = setptr('hand');
imagePanHand = panHandCData{4};
imagePanHand = imagePanHand-min(imagePanHand(:),[],'omitnan');
imagePanHand = imagePanHand./max(imagePanHand(:),[],'omitnan');
imagePanHand = repmat(imagePanHand,1,1,3);
else
    imagePanHand = get(panHand,'CData');
end

pan2 = uitoggletool(toolbarHandle,'TooltipString','Pan',...
    'ClickedCallback',{@togglePanMode,figHandle},...
    'Tag','Exploration.Pan',...
    'CData',get(panHand,'CData'));


if isempty(zoomInHand)

zoomInCData = setptr('glassplus');
imageZoomIn = zoomInCData{4};
imageZoomIn = imageZoomIn-min(imageZoomIn(:),[],'omitnan');
imageZoomIn = imageZoomIn./max(imageZoomIn(:),[],'omitnan');
imageZoomIn = repmat(imageZoomIn,1,1,3);
else
    imageZoomIn = get(zoomInHand,'CData');
end

zoomIn2 = uitoggletool(toolbarHandle,'TooltipString','ZoomIn',...
    'ClickedCallback',{@toggleZoomInMode,figHandle},...
    'Tag','Exploration.ZoomIn',...
    'CData',get(zoomInHand,'CData'));

if isempty(zoomOutHand)
zoomOutCData = setptr('glassminus');
imageZoomOut = zoomOutCData{4};
imageZoomOut = imageZoomOut-min(imageZoomOut(:),[],'omitnan');
imageZoomOut = imageZoomOut./max(imageZoomOut(:),[],'omitnan');
imageZoomOut = repmat(imageZoomOut,1,1,3);
else
    imageZoomOut = get(zoomOutHand,'CData');
end

zoomOut2 = uitoggletool(toolbarHandle,'TooltipString','ZoomOut',...
    'ClickedCallback',{@toggleZoomOutMode,figHandle},...
    'Tag','Exploration.ZoomOut',...
    'CData',get(zoomOutHand,'CData'));

save2 = uipushtool(toolbarHandle,'TooltipString','SaveContours',...
    'ClickedCallback',{@saveEdits},...
    'Tag','SaveContours',...
    'CData',get(saveHand,'CData'));


% store some initialized variables
setappdata(figHandle,'iiFile',1);
setappdata(figHandle,'jFrame',1);
setappdata(figHandle,'pathNames',pathNames);
setappdata(figHandle,'fileNames',fileNames);
setappdata(figHandle,'storedFrame',frame);
setappdata(figHandle,'filePathToDeleteContours',filePathToDeleteContours);
storedCell = cell;
setappdata(figHandle,'storedCell',storedCell);

% default colors
dispColor.outline = 'green';
dispColor.selected = 'red';
dispColor.highlight = 'blue';
dispColor.overview = [255,165,0]/255;

setappdata(figHandle,'dispColor',dispColor);

% set up the key/mouse hooks
set(figHandle,'WindowKeyPressFcn',@keyHookFunction);
set(figHandle,'WindowKeyReleaseFcn',@keyReleaseFunction);
set(figHandle,'WindowButtonDownFcn',@windowButtonDownCallback);

% how to handle figure window closures
set(figHandle,'CloseRequestFcn',@closeFigure);

% show the first file
displayCurrentImage(figHandle);

% turn off the contour breaks, this is the default setting
if getappdata(figHandle,'displayContourBreak')
else
    contourHandles = getappdata(figHandle,'contourHandles');
    set(contourHandles(:,4),'visible','off');
end

function windowButtonDownCallback(h,evd)
initialUnits = get(h,'Units');

% get the current point in axis units
axHand = gca;
cpAxisUnits = get(axHand, 'CurrentPoint');
xPos = cpAxisUnits(1,1);
yPos = cpAxisUnits(1,2);
cursorStartAxNorm = [xPos,yPos];

setappdata(h,'cursorStartAxNorm',cursorStartAxNorm )

%   Y = HGCONVERTUNITS(FIG, X, SRCUNITS, DESTUNITS, REF) converts
%   rectangle X in figure FIG from units SRCUNITS to DESTUNITS
%   using the object with handle REF as the reference container for
%   normalized units. REF can be the root object.
% y = hgconvertunits(ancestor(h,'figure'), [cursorStart, 0, 0], initialUnits,
currentPointFig = get(h,'CurrentPoint');
startPointFigNorm = hgconvertunits(h, [currentPointFig 0 0], get(h,'Units'), 'normalized', h);

% initialize the box
boxLine(1) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
boxLine(2) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
boxLine(3) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
boxLine(4) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);

% set the handles for the box like the full crosshair in ginput
set(boxLine, 'LineWidth', 1.5, 'Visible','off',...
    'HandleVisibility', 'off', ...
    'HitTest', 'off');

dispColor = getappdata(h,'dispColor');
switch get(gca,'tag')
    case 'Axes.Main'
        set(boxLine,'Color',dispColor.selected);
    case 'Axes.Overview'
        rectMark = getappdata(h,'rectMark');
        position = getPosition(rectMark);
        
        % check to see if it was in the rectangle
        inRectangle = cursorStartAxNorm(1)>=position(1)   && cursorStartAxNorm(1)<=(position(1)+position(3)) &&...
            cursorStartAxNorm(2)>=position(2) && cursorStartAxNorm(2)<=(position(2)+position(4));
        set(boxLine,'Color',dispColor.overview);
        
        if not(inRectangle)
            set(boxLine,'Color',dispColor.overview);
        else
            % intentionally hide lines
            set(boxLine,'userdata',1);
        end
        
end

% store some this data
setappdata(h,'startPointFigNorm',startPointFigNorm);
setappdata(h,'boxLine',boxLine);

% get the values and store them in the figure's appdata
props.WindowButtonMotionFcn = get(h,'WindowButtonMotionFcn');
props.WindowButtonUpFcn = get(h,'WindowButtonUpFcn');
props.Units = initialUnits;
setappdata(h,'TestGuiCallbacks',props);

% set the new values for the WindowButtonMotionFcn and
% WindowButtonUpFcn
hManager = uigetmodemanager(h);
try
    set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
catch
    [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
end
set(h,'WindowButtonMotionFcn',{@windowButtonMotionCallback})
set(h,'WindowButtonUpFcn',{@windowButtonUpCallback})


% ---------------------------
function windowButtonMotionCallback(h,evd)
% executes while the mouse moves

% get the starting point and the current point
startPointFigNorm = getappdata(h,'startPointFigNorm');
boxLine = getappdata(h,'boxLine');
currentPointFig = get(h,'CurrentPoint');
currentPointFigNorm = hgconvertunits(h, [currentPointFig 0 0], get(h,'Units'), 'normalized', h);

% each line needs to be updated to the new location of the corners
set(boxLine(1), 'X', [startPointFigNorm(1), startPointFigNorm(1)], ...
    'Y', [startPointFigNorm(2),currentPointFigNorm(2)]);
set(boxLine(2), 'X', [currentPointFigNorm(1), currentPointFigNorm(1)], ...
    'Y', [startPointFigNorm(2),currentPointFigNorm(2)]);
set(boxLine(3), 'X', [startPointFigNorm(1), currentPointFigNorm(1)], ...
    'Y', [startPointFigNorm(2),startPointFigNorm(2)]);
set(boxLine(4), 'X', [startPointFigNorm(1), currentPointFigNorm(1)], ...
    'Y', [currentPointFigNorm(2),currentPointFigNorm(2)]);

% make sure that the line is visible (unless intentionally hidden)
hideLineAsCell = get(boxLine,'userdata');
if hideLineAsCell{1}
    set(boxLine,'Visible','off','HandleVisibility', 'on', ...
        'HitTest', 'on');
else
    set(boxLine, 'Visible','on');
end
% ------
function typeOfClick = cData2cursorType(currentPointer,figHandle);
% this is one invariant of the pointers, the nanmean of the cData
% for pointers that don't use cdata, this just the nanmean of treating the
% string name as a number
numericPointerVersion = round(10000*mean(mean(currentPointer{2},'omitnan'),'omitnan'));
switch numericPointerVersion
    case 1110000; % arrow
        typeOfClick = 'normal';
    case 15408; % add
        typeOfClick = 'extend';
    case 15484; % add pole
        typeOfClick = 'alt';
    case 15888; % hand (convert back to arrow)
        typeOfClick = 'pan';
    case 1130000; %
        typeOfClick = 'adjustSizeVertical'; % bottom
    case 1101667;
        typeOfClick = 'adjustSizeVertical'; % top
    case 1067500;
        typeOfClick = 'adjustSizeHorizontal'; % left
    case 1084000;
        typeOfClick = 'adjustSizeHorizontal'; % right
    case 1117500;
        typeOfClick = 'adjustSizeUpperLeft'; % UL
    case 1132500;
        typeOfClick = 'adjustSizeUpperRight'; % UR
    case 1097500;
        typeOfClick = 'adjustSizeLowerRight'; % LR
    case 1082500;
        typeOfClick = 'adjustSizeLowerLeft'; % LL
    otherwise
        warning('morphometrics:deleteContours:unknownCursorMode','Unknown cursor mode.');
        setptr(figHandle,'arrow');
        typeOfClick = 'normal';
        return;
end

% ---------------------------
function windowButtonUpCallback(figHandle,evd)
% executes when the button is released

% grab the current pointer to see which it is
currentPointer = getptr(figHandle);

typeOfClick = cData2cursorType(currentPointer,figHandle);


% get the starting point and the current point in axes units
axHand = gca;
axTag = get(gca,'tag');



cpAxisUnits = get(axHand, 'CurrentPoint');
xPos = cpAxisUnits(1,1);
yPos = cpAxisUnits(1,2);
cursorEndAxNorm = [xPos,yPos];
cursorStartAxNorm = getappdata(figHandle,'cursorStartAxNorm');

% get the properties and restore them
props = getappdata(figHandle,'TestGuiCallbacks');
set(figHandle,props);

% remove the lines
boxLine = getappdata(figHandle,'boxLine');
if ishghandle(boxLine)
    delete(boxLine);
end

% check to see if this was a single click or something that should be
% intrepeted as a region
nRowsImage = getappdata(figHandle,'nRowsImage');
nColsImage = getappdata(figHandle,'nColsImage');
DISTANCE_THRESH = 3; % distance moved in pixels to define a single click

% process drawing depending on which axes was used
switch axTag
    case 'Axes.Overview'
        switch typeOfClick
            case 'normal'
                % get the position of the rectangle
                rectMark = getappdata(figHandle,'rectMark');
                position = getPosition(rectMark);
                
                % check to see if it was in the rectangle
                inRectangle = cursorStartAxNorm(1)>=position(1)   && cursorStartAxNorm(1)<=(position(1)+position(3)) &&...
                    cursorStartAxNorm(2)>=position(2) && cursorStartAxNorm(2)<=(position(2)+position(4));
                
                if inRectangle
                    % update based on coordinates of rectangle
                    updateZoomByImrect(figHandle);
                elseif sqrt(sum(cursorStartAxNorm-cursorEndAxNorm).^2)>DISTANCE_THRESH
                    
                    rectMark.setPosition([cursorStartAxNorm,...
                        -cursorStartAxNorm+cursorEndAxNorm]);
                    updateZoomByImrect(figHandle);
                    
                end
                
            case {'adjustSizeHorizontal','adjustSizeVertical',...
                    'adjustSizeUpperLeft','adjustSizeUpperRight',...
                    'adjustSizeLowerRight','adjustSizeLowerLeft'};
                % update based on coordinates of rectangle
                updateZoomByImrect(figHandle);
                
        end
        
    case 'Axes.Main'
        % get stored data values
        jFrame = getappdata(figHandle,'jFrame');
        storedFrame = getappdata(figHandle,'storedFrame');
        storedMask = getappdata(figHandle,'storedMask');
        contourHandles = getappdata(figHandle,'contourHandles');
        if isempty(contourHandles)
            return
        end
        dispColor = getappdata(figHandle,'dispColor');
        contourIndex = [];
        
        
        
        % single click
        if sqrt(sum(cursorStartAxNorm-cursorEndAxNorm).^2)<DISTANCE_THRESH
            if strcmp(typeOfClick,'extend');
                typeOfClick = 'extendToggle';
            end
            
            %ignore clicks outside the image
            if or(or(round(yPos)<0,round(xPos)<0),...
                    or(round(yPos)>nRowsImage,round(xPos)>nColsImage));
                return
            end
            
            % which cell was clicked?
            maskVal = storedMask(round(yPos),round(xPos));
            contourIndex = real(maskVal);
            
            % sometimes a cell is not actually clicked
            if not(contourIndex)
                return
            end
            
        else
            % region
            % retrieve the current image
            nRowsImage = getappdata(figHandle,'nRowsImage');
            nColsImage = getappdata(figHandle,'nColsImage');
            
            % deal with various directions and edge effects
            left = round(min(cursorStartAxNorm(1),cursorEndAxNorm(1)));
            left = max(left,1);
            left = min(left, nColsImage);
            
            right = round(max(cursorStartAxNorm(1),cursorEndAxNorm(1)));
            right = max(right,1);
            right = min(right, nColsImage);
            
            top = round(min(cursorStartAxNorm(2),cursorEndAxNorm(2)));
            top = max(top,1);
            top = min(top, nRowsImage);
            
            bottom = round(max(cursorStartAxNorm(2),cursorEndAxNorm(2)));
            bottom = max(bottom,1);
            bottom = min(bottom, nColsImage);
            % create a test mask, these are the pixels to compare with the full
            % mask to see if there are regions of overlap
            testMask = zeros(nRowsImage,nColsImage);
            testMask(top:bottom,left:right) = 1;
            
            % select partial regions?
            selectPartialRegion = getappdata(figHandle,'selectPartialRegion');
            if selectPartialRegion
                if size(testMask,1)>size(storedMask,1)
                    testMask = testMask(1:size(storedMask,1),:);
                end
                
                if size(testMask,2)>size(storedMask,2)
                    testMask = testMask(:,1:size(storedMask,2));
                end
                
                
                
                contourIndex = unique(testMask.*real(storedMask));
                % remove region 0, the background
                contourIndex(contourIndex==0) = [];
            else
                if size(testMask,1)>size(storedMask,1)
                    testMask = testMask(1:size(storedMask,1),:);
                end
                
                if size(testMask,2)>size(storedMask,2)
                    testMask = testMask(:,1:size(storedMask,2));
                end
                
                
                
                partialMask = testMask.*storedMask;
                contourIndex = unique(real(partialMask));
                contourIndex(contourIndex==0) = [];
                % check to see if all the pixels are highlighted
                for testContour = length(contourIndex):-1:1
                    a = real(partialMask)==contourIndex(testContour);
                    testSum = abs(sum(sum(imag(partialMask(a)))));
                    if testSum<0.999
                        contourIndex(testContour) = [];
                    end
                end
            end
        end
        
        if not(isempty(contourHandles))
            
            % figure out what to do with this new list of contours
            switch typeOfClick
                case {'open'} % double click does nothing
                case {'normal'} % single left click
                    
                    set(contourHandles(:,[1,3,4]),'Color',dispColor.outline);
                    contourHandles(:,2) = 0;
                    set(contourHandles(contourIndex ,[1,3,4]),'Color',dispColor.selected);
                    contourHandles(contourIndex,2) = 1;
                case 'extend'
                    set(contourHandles(contourIndex ,[1,3,4]),'Color',dispColor.selected);
                    contourHandles(contourIndex,2) = 1;
                case 'extendToggle' % shift click, either left or right, single cell
                    if contourHandles(contourIndex,2) == 1; % already selected, remove
                        set(contourHandles(contourIndex ,[1,3,4]),'Color',dispColor.outline);
                        contourHandles(contourIndex,2) = 0;
                    else
                        set(contourHandles(contourIndex ,[1,3,4]),'Color',dispColor.selected);
                        contourHandles(contourIndex,2) = 1;
                    end
                case 'alt' % right click
                    % remove region
                    set(contourHandles(contourIndex,[1,3,4]),'Color',dispColor.outline);
                    contourHandles(contourIndex,2)=0;
            end
            
            setappdata(figHandle,'contourHandles',contourHandles);
        end
end




% ---------------------------
function buttonDownFunction(src,evnt)


function selectAll(figHandle)
% this function should select all the contours
contourHandles = getappdata(figHandle,'contourHandles');
dispColor = getappdata(figHandle,'dispColor');

% check to see if everything is selected
if all(contourHandles(:,2))
    % deselect all
    set(contourHandles(:,[1,3,4]),'Color',dispColor.outline);
    contourHandles(:,2) = 0;
else
    % select all
    set(contourHandles(:,[1,3,4]),'Color',dispColor.selected);
    contourHandles(:,2) = 1;
end
setappdata(figHandle,'contourHandles',contourHandles);

function keyReleaseFunction(src,evnt)

% set the mouse pointer style back to the default
originalPointer = getappdata(src,'originalPointer');
set(src,originalPointer{:});
% update color of lines
boxLineColor = [1,0,0];
setappdata(src,'boxLineColor',boxLineColor);
boxLine = getappdata(src,'boxLine');
if ishghandle(boxLine)
    set(boxLine,'Color',boxLineColor);
end

function keyHookFunction(src,evnt,varargin)
switch evnt.Key
    case {'delete','backspace', 'x'}; % any version of delete
        removeSelectedRegions(src)
    case {'rightarrow'};
        nextFrame(src);
    case {'leftarrow'};
        prevFrame(src);
    case {'s'};
        if strcmp(evnt.Modifier,'control');
            saveEdits(src);
        end
    case {'h'};
        if or(strcmp(evnt.Modifier,'control'),...
                strcmp(evnt.Modifier,'command'));
            toggleContours(src);
        end
    case 'z';
        if any(strcmp(evnt.Modifier,'alt'))
            switchZoomModeOff(src);
        elseif any(strcmp(evnt.Modifier,'shift'))
            switchZoomModeOn(src,'out');
        else
            switchZoomModeOn(src,'in');
        end
    case 'c';
        if strcmp(evnt.Modifier,'alt')
            switchPanModeOff(src);
        else
            switchPanModeOn(src);
        end
        %         pause(0.1);
    case {'a'};
        disp(1)
        if or(strcmp(evnt.Modifier,'control'),...
                strcmp(evnt.Modifier,'command'));
            selectAll(src);
        end
    case {'shift'}
        if any(strcmp(evnt.Modifier,'control'));
            isDefaultSelectMode = getappdata(src,'isDefaultSelectMode');
            if isDefaultSelectMode
                setptr(src,'arrow');
                originalPointer = getptr(src);
                setappdata(src,'originalPointer',originalPointer);
                setappdata(src,'isDefaultSelectMode',0);
            else
                setptr(src,'add');
                originalPointer = getptr(src);
                setappdata(src,'originalPointer',originalPointer);
                setappdata(src,'isDefaultSelectMode',1);
            end
        else
            % update visual pointer
            originalPointer = getptr(src);
            setappdata(src,'originalPointer',originalPointer);
            setptr(src,'add');
        end
        % update color of lines
        boxLineColor = [1,0,0];
        setappdata(src,'boxLineColor',boxLineColor);
        boxLine = getappdata(src,'boxLine');
        if ishghandle(boxLine)
            set(boxLine,'Color',boxLineColor);
        end
        
    case {'control'};
        if any(strcmp(evnt.Modifier,'shift'));
            isDefaultSelectMode = getappdata(src,'isDefaultSelectMode');
            if isDefaultSelectMode
                setptr(src,'arrow');
                originalPointer = getptr(src);
                setappdata(src,'originalPointer',originalPointer);
                setappdata(src,'isDefaultSelectMode',0);
            else
                setptr(src,'add');
                originalPointer = getptr(src);
                setappdata(src,'originalPointer',originalPointer);
                setappdata(src,'isDefaultSelectMode',1);
            end
        else
            % update visual pointer
            originalPointer = getptr(src);
            setappdata(src,'originalPointer',originalPointer);
            setptr(src,'addpole');
        end
        
        % update color of lines
        boxLineColor = [0,1,0];
        setappdata(src,'boxLineColor',boxLineColor);
        boxLine = getappdata(src,'boxLine');
        if ishghandle(boxLine)
            set(boxLine,'Color',boxLineColor);
        end
    case {'f1','F1'};
        displayHelpScreen()
    otherwise
        
end

function  displayHelpScreen()
% write out a text document
helpPath = fullfile(tempdir,'deleteContoursHelp.txt');
fidA = fopen(helpPath,'w+');
fprintf(fidA,'Welcome to ''deleteCountours Help!''\r\n');
fprintf(fidA,'\r\n');
fprintf(fidA,'Key press combinations:\r\n');
fprintf(fidA,'F1 OR f1: open this help screen\r\n');
fprintf(fidA,'x OR backspace OR delete: remove selected regions\r\n');
fprintf(fidA,'right arrow: move to next file\r\n');
fprintf(fidA,'left arrow: move to prev file\r\n');
fprintf(fidA,'ctrl-s: save results (may not work on PC)\r\n');
fprintf(fidA,'ctrl-a OR cmd-a: select/deselect all\r\n');
fprintf(fidA,'ctrl-h: show/hide contours\r\n');
fprintf(fidA,'ctrl-shift: lock add mode on (like holding down shift)\r\n');
fprintf(fidA,'c: enable pan mode\r\n');
fprintf(fidA,'alt-c: disable pan mode, only works when ''c'' enabled pan\r\n');
fprintf(fidA,'z: enable zoom in mode\r\n');
fprintf(fidA,'shift-z: enable zoom out mode\r\n');
fprintf(fidA,'alt-z: disable zoom mode, only works when ''z'' enabled zoom\r\n');
fprintf(fidA,'\r\nRegion selection modes:\r\n');
fprintf(fidA,'Switch between partial and full selection mode using the toggle button on the menu.\r\n');
fprintf(fidA,'\r\nScreen individual regions:\r\n');
fprintf(fidA,'Opens a new popup window showing just the image and contours.\r\n');
fprintf(fidA,'+Right and left arrow to navigate between regions.\r\n');
fprintf(fidA,'+Up arrow to accept region and move to next.\r\n');
fprintf(fidA,'+Down arrow to veto region and move to next.\r\n');




fprintf(fidA,'\r\nKnown issues:\r\n');
fprintf(fidA,['+ Sometimes warning of ''Cannot access method ''ActionData'' in class ''matlab.ui.eventdata.ActionData''',...
    ' occurs when loading a file.\r\n']);
fprintf(fidA,['+ Prompts to save file occur even when no changes have been made.\r\n']);


fprintf(fidA,'\r\ndeleteContours Version: 0.3.12\r\n');

% display the contents of the text document
f = popupmessage(helpPath,'Help for deleteContours');
textboxHand = findall(f,'tag','textbox');
set(textboxHand,'fontsize',14);
% delete the text document
delete(helpPath);


function displayCurrentImage(figureHand)
% get stored data values
axesHand = getappdata(figureHand,'axesHand');
pathNames = getappdata(figureHand,'pathNames');
fileNames = getappdata(figureHand,'fileNames');
iiFile = getappdata(figureHand,'iiFile');
jFrame = getappdata(figureHand,'jFrame');

dispColor = getappdata(figureHand,'dispColor');
cell=[];
load(fullfile(pathNames{iiFile},fileNames{iiFile}));
iiFile = getappdata(figureHand,'iiFile');

storedFrame = frame;
storedCell = cell;
setappdata(figureHand,'storedFrame',storedFrame);
setappdata(figureHand,'storedCell',storedCell);
% load and show image
testString = '_CONTOURS_pill_MESH.mat';
tifFileName = strrep(fullfile(pathNames{iiFile},fileNames{iiFile}),testString,'.tif');
% check to see if it is a contours or contours_pill_mesh or something else
if strcmp(tifFileName,fullfile(pathNames{iiFile},fileNames{iiFile}));
    % if these are identical, it didn't replace the extension correctly
    testString = '_CONTOURS.mat';
    tifFileName = strrep(fullfile(pathNames{iiFile},fileNames{iiFile}),testString,'.tif');
    % if these are identical, it didn't replace the extension correctly
    if strcmp(tifFileName,fullfile(pathNames{iiFile},fileNames{iiFile}));
        testString = '_CONTOURS_SpineAndRibs.mat';
        tifFileName = strrep(fullfile(pathNames{iiFile},fileNames{iiFile}),testString,'.tif');
        % if these are identical, it didn't replace the extension correctly
        if strcmp(tifFileName,fullfile(pathNames{iiFile},fileNames{iiFile}));
            testString = '_CONTOURS_pill_MESH_SpineAndRibs.mat';
            tifFileName = strrep(fullfile(pathNames{iiFile},fileNames{iiFile}),testString,'.tif');
            % if these are identical, it didn't replace the extension correctly
            if strcmp(tifFileName,fullfile(pathNames{iiFile},fileNames{iiFile}));
                warning('morphometrics:deleteContours:contoursFileNameIssue','Countours file stem of unknown style. Original image file not found.');
                return;
            end
        end
    end
end

if exist(tifFileName,'file');
elseif exist([tifFileName(1:end-16),'.tif'],'file');
    % morphometrics 1.1 appends a date stamp to contours file names
    tifFileName = [tifFileName(1:end-16),'.tif'];
else
    warning('morphometrics:deleteContours:imageFileMissing',...
        ['Image file for ',pathNames{iiFile},' can not be found.']);
    return
end
readInImage = imread(tifFileName,'index',jFrame);


cla(axesHand);
imshowHand = imshow(readInImage,[],'Parent',axesHand,'initialMagnification','Fit');
xlim(axesHand,[1, size(readInImage,2)]);
ylim(axesHand,[1, size(readInImage,1)]);

set(axesHand,'Tag','Axes.Main');
overviewAxes = findall(figureHand,'tag','Axes.Overview');
if isempty(overviewAxes)
    overviewAxes = getappdata(figureHand,'overviewAxes');
end
imshow(readInImage,[],'Parent',overviewAxes);
set(overviewAxes,'Tag','Axes.Overview');

hold(overviewAxes,'on');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Left');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Right');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Top');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Bottom');
hold(overviewAxes,'off');

rectMark = imrect(overviewAxes,[1,1,size(readInImage,2)-1,size(readInImage,1)-1]);
fcn = makeConstrainToRectFcn('imrect',get(overviewAxes,'XLim'),get(overviewAxes,'YLim'));
setPositionConstraintFcn(rectMark,fcn);
hrectchild = get(rectMark, 'Children');
for iiChild = 1:numel(hrectchild)
    if strfind(get(hrectchild(iiChild),'tag'),'marker')
        set(hrectchild(iiChild),'Marker','.')
        set(hrectchild(iiChild),'MarkerFaceColor',dispColor.overview);
        set(hrectchild(iiChild),'MarkerEdgeColor',dispColor.overview);
        
        continue
    end
    if strfind(get(hrectchild(iiChild),'tag'),'wing')
        set(hrectchild(iiChild),'Visible','off')
        continue
    end
    try
        set(hrectchild(iiChild),'Color',dispColor.overview);
    catch ME
    end
end
set(hrectchild(15),'Visible','off');
set(hrectchild(14),'visible','off');

set(hrectchild,'UIContextMenu',[]);

setappdata(figureHand,'rectMark',rectMark);

% (rectMark,'deletable',false);
% keboard;

title([tifFileName,': Frame ',num2str(jFrame)],'Interpreter','none');
hold on;

% get mask ready for faster processing of selections
storedMask = zeros(size(readInImage));
nRowsImage = size(readInImage,1);
nColsImage = size(readInImage,2);
setappdata(figureHand,'nRowsImage',nRowsImage);
setappdata(figureHand,'nColsImage',nColsImage);

% check to make sure there are some objects
if isempty( storedFrame.object)
    warning('morphometrics:deleteContours:noObjects',['No contours in: ',fileNames{iiFile}]);
    
    % check to see if individual regions are being previewed
    p2 = findobj(figureHand,'TooltipString','Screen individual regions?');
    
    switch get(p2,'State')
        case 'on'
            try
                fig2 = getappdata(figureHand,'singleCellWindowHand');
                clf(fig2);
            catch ME
                fig2 = figure();
                setappdata(figureHand,'singleCellWindowHand',fig2);
            end
            
            
    end
    
    setappdata(figureHand,'contourHandles',[])
    
    return
end

% determine if there are pillMeshes to display
isPillMesh = isfield(storedFrame.object(1),'pill_mesh');
isSpineRibs = isfield(storedFrame.object(1),'spine');

% draw contours
progressbar('Loading image');
nObjects = size(storedFrame(jFrame).object,2);

for kObj = 1:nObjects
    % in lineaged samples, sometimes an object exists even when it is
    % empty. That is, if a cell of ID jj exists in frames ii and ii+2,
    % there may be an empty contour in frame ii+1
    if not(isempty(storedFrame(jFrame).object(kObj).Xcont))
        % close contours
        XcontTemp = storedFrame(jFrame).object(kObj).Xcont;
        YcontTemp = storedFrame(jFrame).object(kObj).Ycont;
        
        % in addition to sometimes being empty, sometimes in old format
        % contours files, the 'on_edge' flag is true and have their
        % contours oriented as rows instead of columns
        if isfield(storedFrame(jFrame).object(kObj),'on_edge');
            if storedFrame(jFrame).object(kObj).on_edge
                warning('deleteContours:onEdgeObjects',...
                    ['This file has objects with the ''on_edge'' flag',...
                    ' set to true. Please contact the developer for additional support options.']);
                contourHandles(kObj,1) = plot(nan,nan,'parent',axesHand);
                contourHandles(kObj,3) = plot(nan,nan,'parent',axesHand);
                contourHandles(kObj,4) = plot(nan,nan,'parent',axesHand);
                continue
            end
        end
        
        % in addition to sometimes being empty, sometimes contours are too
        % short (lesss than 9 points)
        if numel(XcontTemp)<9
            warning('deleteContours:smallObject',...
                ['This file has very small objects. Please contact the developer for additional support options.']);
            contourHandles(kObj,1) = plot(nan,nan,'parent',axesHand);
            contourHandles(kObj,3) = plot(nan,nan,'parent',axesHand);
            contourHandles(kObj,4) = plot(nan,nan,'parent',axesHand);
            continue
        end
        
        
        XcontTemp = [XcontTemp;XcontTemp(1)];
        YcontTemp = [YcontTemp;YcontTemp(1)];
        
        contourHandles(kObj,1) = plot(XcontTemp,...
            YcontTemp,'parent',axesHand);
        contourHandles(kObj,4) = plot(XcontTemp(1),...
            YcontTemp(1),'x','parent',axesHand);
        
        outlineX = (storedFrame(jFrame).object(kObj).Xcont);
        outlineY = (storedFrame(jFrame).object(kObj).Ycont);
        outlineX = round(interp(outlineX,2));
        outlineY = round(interp(outlineY,2));
        outlineIdx = sub2ind([nRowsImage,nColsImage],outlineY,outlineX);
        storedMask(outlineIdx) = kObj;
        
    else
        % make a null plotting object
        contourHandles(kObj,1) = plot(nan,nan,'parent',axesHand);
        contourHandles(kObj,4) = plot(nan,nan,'parent',axesHand);
        
    end
    
    if isSpineRibs
        if not(isnan(storedFrame(jFrame).object(kObj).spine))
            contourHandles(kObj,3) = plot(storedFrame(jFrame).object(kObj).spine(:,1),...
                storedFrame(jFrame).object(kObj).spine(:,2),'parent',axesHand,'linestyle',':','linewidth',2);
        else
            contourHandles(kObj,3) = plot(nan,nan,'parent',axesHand);
        end
    elseif isPillMesh
        if not(isempty(storedFrame(jFrame).object(kObj).centerline))
            contourHandles(kObj,3) = plot(storedFrame(jFrame).object(kObj).centerline(:,1),...
                storedFrame(jFrame).object(kObj).centerline(:,2),'parent',axesHand,'linestyle',':','linewidth',2);
        else
            contourHandles(kObj,3) = plot(nan,nan,'parent',axesHand);
        end
    else
        contourHandles(kObj,3) = plot(nan,nan,'parent',axesHand);
    end
    
    
    progressbar(kObj/nObjects);
    
end

contourHandles = double(contourHandles);
contourHandles(:,2) = 0;
set(contourHandles(:,[1,3,4]),'Color',dispColor.outline);

% fill in the mask
storedMask = imfill(storedMask,'holes');

% calculate total pixels in each cell
for kObj = 1:nObjects
    storedMask(real(storedMask)==kObj) = 1i/nnz(real(storedMask)==kObj)+kObj;
end

% store mask
setappdata(figureHand,'storedMask',storedMask);

% store raw image
setappdata(figureHand,'readInImage',readInImage);
% store contours
setappdata(figureHand,'contourHandles',contourHandles);

% check to see if individual regions are being previewed
p2 = findobj(figureHand,'TooltipString','Screen individual regions?');

switch get(p2,'State')
    case 'on'
        
        try
            fig2 = getappdata(figureHand,'singleCellWindowHand');
            setappdata(fig2,'kObj',1);
        catch ME
        end
        screenIndividualRegions(p2,[]);
        figure(figureHand);
        
end



% set(contourHandles(:,1),'ButtonDownFcn',@buttonDownFunction);

function removeSelectedRegions(figHandle)
% get stored data values
jFrame = getappdata(figHandle,'jFrame');
storedFrame = getappdata(figHandle,'storedFrame');
storedCell = getappdata(figHandle,'storedCell');
contourHandles = getappdata(figHandle,'contourHandles');
storedMask = getappdata(figHandle,'storedMask');

% loop over all the contours and see if they should be removed
for iContour = size(contourHandles,1):-1:1;
    if contourHandles(iContour,2)
        % if it is selected, remove the trace
        delete(contourHandles(iContour,[1,3,4]));
        contourHandles(iContour,:) = [];
        
        % remove it from stored frame
        if isfield(storedFrame(jFrame),'num_cells')
            % v0.97
            storedFrame(jFrame).num_cells = storedFrame(jFrame).num_cells -1;
        elseif isfield(storedFrame(jFrame),'num_objs')
            % v1.1
            storedFrame(jFrame).num_objs = storedFrame(jFrame).num_objs -1;
        else
            error('morphometrics:deleteContours:numObjFieldName','Unclear what field name contains the number of objects in this frame');
        end
        storedFrame(jFrame).object(iContour) = [];
        
        % remove it from the mask
        storedMask(real(storedMask)==iContour) = 0;
        storedMask(real(storedMask)>iContour) = storedMask(real(storedMask)>iContour)-1;
        
        
        % remove it from saved cell
        % loop over each cell in cell
        for iiCell = size(storedCell,2):-1:1;
            % loop over each frame that cell  is in
            for ijFrame = size(storedCell(iiCell).frames,1):-1:1
                % is this a cell that exists in the current frame?
                try
                    if storedCell(iiCell).frames(ijFrame) == jFrame
                        
                        % cell of a higher number, reduce its index and
                        % remove it from mask
                        if storedCell(iiCell).bw_label(ijFrame)>iiCell
                            storedCell(iiCell).bw_label(ijFrame) = storedCell(iiCell).bw_label(ijFrame)-1;
                            % cell being deleted
                        elseif storedCell(iiCell).bw_label(ijFrame)==iiCell
                            storedCell(iiCell).bw_label(ijFrame) = [];
                            storedCell(iiCell).frames(ijFrame) = [];
                        end
                    end
                catch ME
                    % storedCell(iiCell).bw_label(ijFrame) = [];
                    % storedCell(iiCell).frames(ijFrame) = [];
                end
                
            end
        end
        
    end
end
setappdata(figHandle,'contourHandles',contourHandles);
setappdata(figHandle,'storedFrame',storedFrame);
setappdata(figHandle,'storedCell',storedCell);
setappdata(figHandle,'storedMask',storedMask);

function nextFrame(figHandle)
% get stored data values
pathNames = getappdata(figHandle,'pathNames');
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');
jFrame = getappdata(figHandle,'jFrame');
storedFrame = getappdata(figHandle,'storedFrame');

% define as blank for jit issues
cell = [];
load(fullfile(pathNames{iiFile},fileNames{iiFile}));
iiFile = getappdata(figHandle,'iiFile');
% check to see if there is an available frame
if iiFile==size(fileNames,2)
    if jFrame==size(storedFrame,2);
        [statusOut] = checkForUnsavedChanges(figHandle);
        disp(['That was the last frame silly willy. Finished at ',datestr(now),'.']);
        beep();
        pause(0.2);
        beep();
        pause(0.2);
        beep();
        
        
        % no later frames available
        return
    end
end

% check for unsaved changes
[statusOut] = checkForUnsavedChanges(figHandle);

if statusOut==1;
    % move to next frame
    if jFrame==size(storedFrame,2);
        setappdata(figHandle,'jFrame',1);
        setappdata(figHandle,'iiFile',iiFile+1);
    else
        setappdata(figHandle,'jFrame',jFrame+1);
    end
    
    % display the image
    displayCurrentImage(figHandle)
    
    % turn off the contour breaks, this is the default setting
    if getappdata(figHandle,'displayContourBreak')
    else
        contourHandles = getappdata(figHandle,'contourHandles');
        set(contourHandles(:,4),'visible','off');
    end
else
    % error in checking for changes or user cancelled
end

% % remove single cell focus window if it exists
% if isappdata(figHandle,'singleCellWindowHand')
%    try
%        close(getappdata(figHandle,'singleCellWindowHand'))
%    catch ME
%    end
%    rmappdata(figHandle,'singleCellWindowHand');
% end

function prevFrame(figHandle)
% get stored data values
pathNames = getappdata(figHandle,'pathNames');
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');
jFrame = getappdata(figHandle,'jFrame');

% define as blank for jit issues
cell = [];
load(fullfile(pathNames{iiFile},fileNames{iiFile}));
iiFile = getappdata(figHandle,'iiFile');
% check to see if there is an available frame
if iiFile==1
    if jFrame==1;
        % no earlier frames available
        return
    end
end

% check for unsaved changes
[statusOut] = checkForUnsavedChanges(figHandle);

if statusOut==1;
    % move to prev frame
    if jFrame==1;
        setappdata(figHandle,'iiFile',iiFile-1);
        % find out how many frames in that image
        load(fullfile(pathNames{iiFile-1},fileNames{iiFile-1}));
        iiFile = getappdata(figHandle,'iiFile');
        setappdata(figHandle,'jFrame',size(frame,2));
    else
        setappdata(figHandle,'jFrame',jFrame-1);
    end
    
    % display the image
    displayCurrentImage(figHandle)
    
    % turn off the contour breaks, this is the default setting
    if getappdata(figHandle,'displayContourBreak')
    else
        contourHandles = getappdata(figHandle,'contourHandles');
        set(contourHandles(:,[4]),'visible','off');
    end

else
    % error in checking for changes or user cancelled
end
%
% % remove single cell focus window if it exists
% if isappdata(figHandle,'singleCellWindowHand')
%    try
%        close(getappdata(figHandle,'singleCellWindowHand'))
%    catch ME
%    end
%    rmappdata(figHandle,'singleCellWindowHand');
% end

function [statusOut] = checkForUnsavedChanges(figHandle);
% get stored data values
pathNames = getappdata(figHandle,'pathNames');
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');
jFrame = getappdata(figHandle,'jFrame');
storedFrame = getappdata(figHandle,'storedFrame');
storedCell = getappdata(figHandle,'storedCell');

% define as blank for jit issues
cell = [];

% check to see if there are unsaved changes
load(fullfile(pathNames{iiFile},fileNames{iiFile}));
iiFile = getappdata(figHandle,'iiFile');
% check to see if there are changes that have been made
if isequal(storedFrame,frame);
    if isempty(cell);
        isChanges = false;
    elseif  isequal(storedCell(jFrame),cell(jFrame));
        isChanges = false;
    else
        isChanges = true;
    end
else
    isChanges = true;
end

% if there were changes, ask what to do with them
if isChanges
    
    isContinue = questdlg('There are unsaved changes. Do you want to continue',...
        'Unsaved changes','Continue','Save and continue','Cancel','Cancel');
    switch isContinue
        case 'Continue'
            % just continue, don't save changes
            statusOut = 1;
        case 'Save and continue'
            % run save function and then continue
            saveEdits(figHandle);
            statusOut = 1;
        case 'Cancel'
            % return immediately
            statusOut = 0;
    end
else
    statusOut = 1;
end

function saveEdits(figHandle,varargin)
disp('Saving');
if ~strcmp(class(figHandle),'matlab.ui.Figure')
    figHandle = get(get(figHandle,'Parent'),'Parent');
    
end
% get stored data values
pathNames = getappdata(figHandle,'pathNames');
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');
storedFrame = getappdata(figHandle,'storedFrame');
storedCell = getappdata(figHandle,'storedCell');

% define as blank for jit issues
cell = [];

% check to see if there are unsaved changes
load(fullfile(pathNames{iiFile},fileNames{iiFile}));
iiFile = getappdata(figHandle,'iiFile');
setappdata(0,'tempString',fullfile(pathNames{iiFile},fileNames{iiFile}));
cell = storedCell;
frame = storedFrame;

clear figHandle storedCell storedFrame pathNames fileNames iFile iiFile varargin;
save(getappdata(0,'tempString'));
rmappdata(0,'tempString');

function toggleContours(figHandle)
contourHandles = getappdata(figHandle,'contourHandles');

% are they currently visible?
switch get(contourHandles(1),'Visible')
    case 'on'
        set(contourHandles(:,[1,3,4]),'Visible','off');
    case 'off'
        if getappdata(figHandle,'displayContourBreak')
            set(contourHandles(:,[4]),'Visible','on')
        else
            set(contourHandles(:,[4]),'Visible','off')
        end
        set(contourHandles(:,[1,3]),'Visible','on');
end
updateIndividualRegions(figHandle)


function closeFigure(figHandle,varargin)

% check for unsaved changes
[statusOut] = checkForUnsavedChanges(figHandle);
if statusOut==1;
    % check to see if small window is open
    if isappdata(figHandle,'singleCellWindowHand')
        singleCellWindowHand = getappdata(figHandle,'singleCellWindowHand');
        try
            close(singleCellWindowHand);
        catch ME5
        end
    end
    delete(figHandle);
else
    % error in checking for changes or user cancelled
end

function toggleSelectPartialRegion(src,evt)

figHand = get(get(src,'parent'),'parent');
selectPartialRegion = getappdata(figHand,'selectPartialRegion');
filePathToDeleteContours = getappdata(figHand,'filePathToDeleteContours');

if selectPartialRegion
    % switch to select all
    setappdata(figHand,'selectPartialRegion',false);
    
    % Read an image
    [icon] = imread(fullfile(filePathToDeleteContours,'icons','selectWholeRegion.png'));
    set(src,'Cdata',icon);
else
    % switch to select region
    setappdata(figHand,'selectPartialRegion',true);
    % Read an image
    [icon] = imread(fullfile(filePathToDeleteContours,'icons','selectPartialRegion.png'));
    set(src,'Cdata',icon);
end

function toggleDisplayContourBreak(src,evt)

figHand = get(get(src,'parent'),'parent');
displayContourBreak = getappdata(figHand,'displayContourBreak');
filePathToExtractIntensities = getappdata(figHand,'filePathToExtractIntensities');

contourHandles = getappdata(figHand,'contourHandles');
if displayContourBreak
    % switch to select all
    setappdata(figHand,'displayContourBreak',false);
    
    % Read an image
    [icon] = imread(fullfile(filePathToExtractIntensities,'icons','displayContourBreakOff.png'));
    set(src,'Cdata',icon);
else
    % switch to select region
    setappdata(figHand,'displayContourBreak',true);
    % Read an image
    [icon] = imread(fullfile(filePathToExtractIntensities,'icons','displayContourBreak.png'));
    set(src,'Cdata',icon);
end

if and(any(strcmp(get(contourHandles(:,[1]),'Visible'),'on')),getappdata(figHand,'displayContourBreak'));
    set(contourHandles(:,[4]),'Visible','on')
else
    set(contourHandles(:,[4]),'Visible','off')
end
updateIndividualRegions(figHand);

% --------------------------------------------------------------------
function switchPanModeOn(figureHandle)
% % hObject    handle to uitoggletool3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
handles.figure1 = figureHandle;
panMode = pan(handles.figure1);

if strcmp(panMode.Enable,'off');
    pan(handles.figure1,'on');
    
    % This should work in both HG1 and HG2:
    hManager = uigetmodemanager(handles.figure1);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
    end
    set(handles.figure1, 'WindowKeyPressFcn', []);
    set(handles.figure1, 'KeyPressFcn',{@keyHookFunction,handles});  % ok!
else
end

function togglePanMode(hObject,evnt,figureHandle,varargin)
hToolbar = get(hObject,'parent');
figureHandle = get(hToolbar,'Parent');
panHand = findall(hToolbar,'tag','Exploration.Pan');
if strcmp(    get(panHand(1),'State'),'on')
    switchPanModeOn(figureHandle);
else
    switchPanModeOff(figureHandle);
end

function switchPanModeOff(figureHandle)
% % hObject    handle to uitoggletool3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
handles.figure1 = figureHandle;
panMode = pan(handles.figure1);

if strcmp(get(panMode,'Enable'),'off');
else
    pan(handles.figure1,'off');
    
    % This should work in both HG1 and HG2:
    hManager = uigetmodemanager(handles.figure1);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'on');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(true);  % HG2
    end
    set(handles.figure1, 'WindowKeyPressFcn', @keyHookFunction);
    set(handles.figure1, 'KeyPressFcn',[]);  % ok!
    set(handles.figure1,'WindowKeyReleaseFcn',@keyReleaseFunction);
    set(handles.figure1,'WindowButtonDownFcn',@windowButtonDownCallback);
    
    isDefaultSelectMode = getappdata(handles.figure1,'isDefaultSelectMode');
    if isDefaultSelectMode
        setptr(handles.figure1,'add');
    else
        setptr(handles.figure1,'arrow');
    end
    
    originalPointer = getptr(handles.figure1);
    setappdata(handles.figure1,'originalPointer',originalPointer);
    
end
%------------
function toggleZoomInMode(hObject,evnt,figureHandle,varargin)
hToolbar = get(hObject,'parent');
figureHandle = get(hToolbar,'Parent');
zoomInHand = findall(hToolbar,'tag','Exploration.ZoomIn');
if strcmp(    get(zoomInHand(1),'State'),'on')
    switchZoomModeOn(figureHandle,'in');
else
    switchZoomModeOff(figureHandle);
end

function toggleZoomOutMode(hObject,evnt,figureHandle,varargin)
hToolbar = get(hObject,'parent');
figureHandle = get(hToolbar,'Parent');
zoomInHand = findall(hToolbar,'tag','Exploration.ZoomOut');
if strcmp(    get(zoomInHand(1),'State'),'on')
    switchZoomModeOn(figureHandle,'out');
else
    switchZoomModeOff(figureHandle);
end

function switchZoomModeOn(figureHandle,direction)
% % hObject    handle to uitoggletool3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
if nargin<2
    direction = 'in';
end
handles.figure1 = figureHandle;
zoomMode = zoom(handles.figure1);
setAllowAxesZoom(zoomMode,findobj(handles.figure1,'tag','Axes.Overview'),false)

if strcmp(get(zoomMode,'Enable'),'off');
    zoom(handles.figure1,'on');
    set(zoomMode,'Direction',direction);
    
    % This should work in both HG1 and HG2:
    hManager = uigetmodemanager(handles.figure1);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
    end
    set(handles.figure1, 'WindowKeyPressFcn', []);
    set(handles.figure1, 'KeyPressFcn',{@keyHookFunction,handles});  % ok!
else
    set(zoomMode,'Direction',direction);
end

function switchZoomModeOff(figureHandle)
% % hObject    handle to uitoggletool3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
handles.figure1 = figureHandle;
zoomMode = zoom(handles.figure1);

if strcmp(get(zoomMode,'Enable'),'off');
else
    zoom(handles.figure1,'off');
    
    % This should work in both HG1 and HG2:
    hManager = uigetmodemanager(handles.figure1);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'on');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(true);  % HG2
    end
    set(handles.figure1, 'WindowKeyPressFcn', @keyHookFunction);
    set(handles.figure1, 'KeyPressFcn',[]);  % ok!
    set(handles.figure1,'WindowKeyReleaseFcn',@keyReleaseFunction);
    set(handles.figure1,'WindowButtonDownFcn',@windowButtonDownCallback);
    
    isDefaultSelectMode = getappdata(handles.figure1,'isDefaultSelectMode');
    if isDefaultSelectMode
        setptr(handles.figure1,'add');
    else
        setptr(handles.figure1,'arrow');
    end
    
    originalPointer = getptr(handles.figure1);
    setappdata(handles.figure1,'originalPointer',originalPointer);
    
end



%--------------------------------------------------------------------------
function limitsListener(~, evt)
% Update the display of the subimage for moving around large format images
axesHand = evt.AffectedObject;
figureHand = get(axesHand,'Parent');

dispColor = getappdata(figureHand,'dispColor');

% find the children that are the subimage and labels
leftEdge = findall(figureHand,'tag','RegionMark.Left');
rightEdge = findall(figureHand,'tag','RegionMark.Right');
topEdge = findall(figureHand,'tag','RegionMark.Top');
bottomEdge = findall(figureHand,'tag','RegionMark.Bottom');


mainAxes = getappdata(figureHand,'axesHand');
axes(mainAxes);
overviewAxes = findall(figureHand,'tag','Axes.Overview');
if not(isempty(overviewAxes))
    setappdata(figureHand,'overviewAxes',overviewAxes);
else
    overviewAxes = getappdata(figureHand,'overviewAxes');
end
try
    xlimits = xlim(mainAxes);
    ylimits = ylim(mainAxes);
    
    % set the limits of the displayed region
    set(leftEdge,'Xdata',[xlimits(1),xlimits(1)],'Ydata',ylimits,'Color',dispColor.overview);
    set(rightEdge,'Xdata',[xlimits(2),xlimits(2)],'Ydata',ylimits,'Color',dispColor.overview);
    set(topEdge,'Xdata',[xlimits],'Ydata',[ylimits(1),ylimits(1)],'Color',dispColor.overview);
    set(bottomEdge,'Xdata',[xlimits],'Ydata',[ylimits(2),ylimits(2)],'Color',dispColor.overview);
    
    % find the imrect for region selection
    rectMark = getappdata(figureHand,'rectMark');
    setPosition(rectMark,[xlimits(1),ylimits(1),...
        xlimits(2)-xlimits(1),ylimits(2)-ylimits(1)]);
    
    
catch ME
    
end

function updateIndividualRegions(hObj)

if isappdata(hObj,'mainFigHandle')
    mainFigHandle = getappdata(hObj,'mainFigHandle');
else
    mainFigHandle = hObj;
end

contourBreakHand = findall(mainFigHandle,'tag','Toolbar.ContourBreak');
singleCellHand = findall(mainFigHandle,'tag','Toolbar.IndividualRegions');

isSingleCellDisplayed = get(singleCellHand,'State');

switch isSingleCellDisplayed
    
    case 'on'
        % find the handle to the single cell window
        singleCellWindowHand = getappdata(mainFigHandle,'singleCellWindowHand');
        p1 = getappdata(singleCellWindowHand,'p1');
        
        
        % check to see if any contours should be shown
        contourHandles = getappdata(mainFigHandle,'contourHandles');
        if any(strcmp(get(contourHandles(:,[1]),'Visible'),'on'))
            set(p1,'Visible','on')
            % check to see if contour breaks should be shown
            
            % as of 20190131: for minor window, there are three display objects,
            % main contour, centerline, main contour break
            set(p1([3]),'visible',get(contourBreakHand,'State'))
            
            
        else
            % don't check for contour breaks if all contours are off
            set(p1,'Visible','off')
            
        end
        
        
    case 'off'
        % don't change visibility if single cell display isn't being used
        
end


function screenIndividualRegions(hObj,eventdata);



if strcmpi(get(hObj,'type'),'Figure')
    % %     % this was called from somewhere that doesn't know about the
    % %     % parent window, go and find it
    % %     figHand = findobj(groot,'type','figure','tag','deleteContoursMainFigure');
    figHand =  getappdata(hObj,'mainFigHandle');
    
    
else
    
    figHand = get(get(hObj,'Parent'),'Parent');
    switch get(hObj,'State')
        case 'on'
            filePathToDeleteContours = which('deleteContours');
            [filePathToDeleteContours,~] = fileparts(filePathToDeleteContours);
            [icon] = imread(fullfile(filePathToDeleteContours,'icons','screenIndividualRegions2.png'));
            
            % Set the button icon
            set(hObj,'CData',icon);
            
        case 'off'
            filePathToDeleteContours = which('deleteContours');
            [filePathToDeleteContours,~] = fileparts(filePathToDeleteContours);
            [icon] = imread(fullfile(filePathToDeleteContours,'icons','screenIndividualRegions.png'));
            
            % Set the button icon
            set(hObj,'CData',icon);
            
            try
                fig2 = getappdata(figHand,'singleCellWindowHand');
                close(fig2);
                
            catch ME
                
            end
            return
    end
end


jFrame = getappdata(figHand,'jFrame');
storedFrame = getappdata(figHand,'storedFrame');
contourHandles = getappdata(figHand,'contourHandles');
readInImage = getappdata(figHand,'readInImage');
imageSize = size(readInImage);
dispColor = getappdata(figHand,'dispColor');

% determine if there are pillMeshes to display
isPillMesh = isfield(storedFrame.object(1),'pill_mesh');
isSpineRibs = isfield(storedFrame.object(1),'spine');


nObjects = size(storedFrame(jFrame).object,2);
if nObjects == 0
    return
end

try
    fig2 = getappdata(figHand,'singleCellWindowHand');
    figure(fig2);
    
    kObj = getappdata(fig2,'kObj');
    
catch ME
    fig2 = figure();
    setappdata(figHand,'singleCellWindowHand',fig2);
    kObj = 1;
    setappdata(fig2,'kObj',kObj);
    setappdata(fig2,'mainFigHandle',figHand);
end

% highlight in main figure
% if size(contourHandles,2)==4
    columnsToSet = [1,3,4];
% else
%     columnsToSet = 1;
% end
set(contourHandles(kObj,columnsToSet),'Color',dispColor.highlight);


% clear figure of previous plotting
clf(fig2);
set(fig2,'WindowKeyPressFcn',@keyHookFunction2);
set(fig2,'CloseRequestFcn',@closeIndividualView);
setappdata(fig2,'nObjects',nObjects);

if not(isempty(storedFrame(jFrame).object(kObj).Xcont))
    % pull out the bounding box
    XcontTemp = storedFrame(jFrame).object(kObj).Xcont;
    YcontTemp = storedFrame(jFrame).object(kObj).Ycont;
    
    % determine bounding box plus a little
    xmin = min(XcontTemp);
    xmax = max(XcontTemp);
    ymin = min(YcontTemp);
    ymax = max(YcontTemp);
    xrange = xmax-xmin;
    yrange = ymax-ymin;
    
    xmin = xmin - 0.1*(xrange);
    xmin = round(xmin);
    xmin = max(1,xmin);
    
    ymin = ymin - 0.1*(yrange);
    ymin = round(ymin);
    ymin = max(1,ymin);
    
    xmax = xmax + 0.1*(xrange);
    xmax = round(xmax);
    xmax = min(imageSize(2),xmax);
    
    ymax = ymax + 0.1*(yrange);
    ymax = round(ymax);
    ymax = min(imageSize(1),ymax);
    
    % subimage
    partialImage = readInImage(ymin:ymax,:);
    partialImage = partialImage(:,xmin:xmax);
    imshow(partialImage,[],'InitialMagnification','fit');
    hold on;
    
    % contour
    % close contours
    XcontTemp = [XcontTemp;XcontTemp(1)];
    YcontTemp = [YcontTemp;YcontTemp(1)];
    
    p1 = plot(XcontTemp-xmin+1,YcontTemp-ymin+1,'linewidth',2);
    p1(3) = plot(XcontTemp(1)-xmin+1,YcontTemp(1)-ymin+1,'x','linewidth',2);
    
    if isSpineRibs
        if not(isnan(storedFrame(jFrame).object(kObj).spine))
            % centerline from spine and ribs
            p1(2)  = plot(storedFrame(jFrame).object(kObj).spine(:,1)-xmin+1,...
                storedFrame(jFrame).object(kObj).spine(:,2)-ymin+1,...
                'linestyle',':','linewidth',2);
        else
            % no centerline
            p1(2) = plot(nan,nan);
        end
    elseif isPillMesh
        if not(isempty(storedFrame(jFrame).object(kObj).centerline))
            % centerline from pillMesh
            p1(2) = plot(storedFrame(jFrame).object(kObj).centerline(:,1)-xmin+1,...
                storedFrame(jFrame).object(kObj).centerline(:,2)-ymin+1,...
                'linestyle',':','linewidth',2);
        else
            % no centerline
            p1(2) = plot(nan,nan);
        end
    else
        % no centerline
        p1(2) = plot(nan,nan);
    end
    
    
    
    
    
    
    switch contourHandles(kObj,2);
        case 0
            set(p1,'Color',dispColor.outline);
            
        case 1
            set(p1,'Color',dispColor.selected);
    end
end

title(['Object: ',num2str(kObj),' out of ',num2str(nObjects),'.']);
setappdata(fig2,'p1',p1);
updateIndividualRegions(fig2);

function keyHookFunction2(src,evnt,varargin)
figHandle = getappdata(src,'mainFigHandle');
contourHandles = getappdata(figHandle,'contourHandles');
kObj = getappdata(src,'kObj');
dispColor = getappdata(figHandle,'dispColor');

% highlight in main figure
% if size(contourHandles,2)==3
    columnsToSet = [1,3,4];
% else
%     columnsToSet = 1;
% end

try
    if contourHandles(kObj,2)==0
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.outline);
    elseif contourHandles(kObj,2)==1
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.select);
    end
catch ME
    % sometimes there's an issue of re-viewing contours that have already been removed but haven't been saved.
    
end


switch evnt.Key
    case {'rightarrow'};
        nextBlob(src);
    case {'leftarrow'};
        prevBlob(src);
    case {'uparrow'};
        acceptBlob(src);
    case {'downarrow'};
        vetoBlob(src);
    case {'h'};
        if or(strcmp(evnt.Modifier,'control'),...
                strcmp(evnt.Modifier,'command'));
            toggleContours(figHandle);
        end
    otherwise
end

function nextBlob(src)
kObj = getappdata(src,'kObj');
nObjects = getappdata(src,'nObjects');
if kObj == nObjects
    return
else
    setappdata(src,'kObj',kObj+1);
end
screenIndividualRegions(src,[]);

function prevBlob(src)
kObj = getappdata(src,'kObj');
nObjects = getappdata(src,'nObjects');
if kObj == 1
    return
else
    setappdata(src,'kObj',kObj-1);
end
screenIndividualRegions(src,[]);

function vetoBlob(src)
kObj = getappdata(src,'kObj');
nObjects = getappdata(src,'nObjects');
fig2 = src;
figHand = getappdata(fig2,'mainFigHandle');
contourHandles = getappdata(figHand,'contourHandles');
dispColor = getappdata(figHand,'dispColor');

% if size(contourHandles,2)==3
    columnsToSet = [1,3,4];
% else
%     columnsToSet = 1;
% end

contourHandles(kObj,2) = 1;
set(contourHandles(kObj,columnsToSet),'Color',dispColor.selected);
setappdata(figHand,'contourHandles',contourHandles);

if kObj == nObjects
    return
else
    setappdata(src,'kObj',kObj+1);
end
screenIndividualRegions(src,[]);

function acceptBlob(src)
kObj = getappdata(src,'kObj');
nObjects = getappdata(src,'nObjects');
fig2 = src;

figHand = getappdata(fig2,'mainFigHandle');
contourHandles = getappdata(figHand,'contourHandles');
dispColor = getappdata(figHand,'dispColor');

% if size(contourHandles,2)==3
    columnsToSet = [1,3,4];
% else
%     columnsToSet = 1;
% end

contourHandles(kObj,2) = 0;
set(contourHandles(kObj,columnsToSet),'Color',dispColor.outline);
setappdata(figHand,'contourHandles',contourHandles);


if kObj == nObjects
    return
else
    setappdata(src,'kObj',kObj+1);
end
screenIndividualRegions(src,[]);

function closeIndividualView(src,eventdata,varargin)
try
    figHandle = getappdata(src,'mainFigHandle');
    contourHandles = getappdata(figHandle,'contourHandles');
    kObj = getappdata(src,'kObj');
    dispColor = getappdata(figHandle,'dispColor');
    
    % highlight in main figure
%     if size(contourHandles,2)==3
        columnsToSet = [1,3,4];
%     else
%         columnsToSet = 1;
%     end
    
    if contourHandles(kObj,2)==0
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.outline);
    elseif contourHandles(kObj,2)==1
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.select);
    end
catch ME
    warning('morphometrics:deleteContours:closeError','Error closing individual view. Closing harder.');
end

% update icon in main figure
singleViewToggleTool = findall(figHandle,'tag','Toolbar.IndividualRegions');
set(singleViewToggleTool,'state','off');

filePathToExtractIntensities = which('extractIntensities');
[filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
[icon] = imread(fullfile(filePathToExtractIntensities,'icons','screenIndividualRegions.png'));

% Set the button icon
set(singleViewToggleTool,'CData',icon);
delete(src);



function      updateZoomByImrect(figHandle);
rectMark = getappdata(figHandle,'rectMark');
positionOfRect = getPosition(rectMark);
mainAxes = findobj(figHandle,'Tag','Axes.Main');
xlimits = [positionOfRect(1),positionOfRect(1)+positionOfRect(3)];
xlimits = sort(xlimits);
ylimits = [positionOfRect(2),positionOfRect(2)+positionOfRect(4)];
ylimits = sort(ylimits);
set(mainAxes,'Xlim',xlimits,'Ylim',ylimits);

