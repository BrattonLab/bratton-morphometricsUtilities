function extractIntensities
% this function is an accessory to morphometrics and allows users to
% calculate the background subtracted intensity in accessory channels
% Release notes:
% 20190619 Initial release (forked and refactored from extractIntensities 0
% 
% 20190128 Initial release (forked and refactored from deleteContours 0.3.7
% 20190213 Include support for new axes toolbars (R2018a and later) instead
% of figure toolbars

% define cell as a variable. It will be overwritten when the mat file is
% loaded. Otherwise the compiler treats the later call to "cell" as a
% reference to the function named cell

%%

if verLessThan('MATLAB','9.4')
    currentVersionString = ver('MATLAB');
    warning('extractIntensities:LegacyMode',...
        ['Current version of MATLAB (',currentVersionString.Version,...
        ') is less than expected (9.4). ',...
        'Some functionality may not be supported. ',...
        'Enabling legacy mode and silencing this warning.']);
    warning('off','extractIntensities:LegacyMode');
    
end
%%

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
kkColorChannel = 1;

% first, assume that the mat file is in the same folder as the image
load(fullfile(pathNames{iiFile},fileNames{iiFile}));

iiFile = 1;

% set up handles for various display objects

% indicators parameters
if ispc
    channelButtonYSize = 0.06;
    sliderHeight = 0.04;
    titleHeight = 0.04;
else
    channelButtonYSize = 0.06;
    sliderHeight = 0.15;
    titleHeight = 0.06;
    
end
channelButtonYStart = 0.50;
channelButtonYOffsetSpacing = 0.065;


indicatorXStart = 0.03;
channelButtonXOffsetSpacing = 0.045;
channelButtonXSize = 0.03;

% main figure and axes
figHandle = figure('Tag','extractIntensitiesMainFigure');
setappdata(figHandle,'versionTag','0.1.14');
axesHand = axes('Units','normalized','Parent',figHandle,...
    'Position',[0.2,0.02,0.78,0.86],'tag','Axes.Main');
axes2 = axes('Units','normalized','Parent',figHandle,...
    'Position',[indicatorXStart,0.02,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,0.15],'tag','Axes.Overview');

if not(verLessThan('MATLAB','9.4'))
    % version 9.4 / R2018a compatibility
    axes2.Toolbar.Visible = 'off';
    axesHand.Toolbar.Visible = 'off';
end


% % indicators

% x Offset
indicatorHandles.xOffsetSlider = uicontrol(figHandle,'Style','Slider',...
    'units','normalized','position',[indicatorXStart,0.425-sliderHeight,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,sliderHeight],...
    'min',-10,'max',10,'value',0,'tag','xOffsetSlider',...
    'Callback',{@xOffsetSlider_Callback});
indicatorHandles.xOffsetText = uicontrol(figHandle,'Style','Text',...
    'units','normalized','position',[indicatorXStart,0.435,2*channelButtonXOffsetSpacing + channelButtonXSize,0.04],...
    'string',['x offset: ',num2str(0)],'FontSize',12,'tag','xOffsetText');

% y Offset
indicatorHandles.yOffsetSlider = uicontrol(figHandle,'Style','Slider',...
    'units','normalized','position',[indicatorXStart,0.325-sliderHeight,2*channelButtonXOffsetSpacing + channelButtonXSize,sliderHeight],...
    'min',-10,'max',10,'value',0,'tag','yOffsetSlider',...
    'Callback',{@yOffsetSlider_Callback});
indicatorHandles.yOffsetText = uicontrol(figHandle,'Style','Text',...
    'units','normalized','position',[indicatorXStart,0.335,2*channelButtonXOffsetSpacing + channelButtonXSize,0.04],...
    'string',['y offset: ',num2str(0)],'FontSize',12,'tag','yOffsetText');

% background radius
indicatorHandles.radiusOffsetSlider = uicontrol(figHandle,'Style','Slider',...
    'units','normalized','position',[indicatorXStart,0.225-sliderHeight,2*channelButtonXOffsetSpacing + channelButtonXSize,sliderHeight],...
    'min',1,'max',35,'value',1,'tag','radiusOffsetSlider',...
    'Callback',{@offsetRadiusSlider_Callback});
indicatorHandles.radiusOffsetText = uicontrol(figHandle,'Style','Text',...
    'units','normalized','position',[indicatorXStart,0.235,2*channelButtonXOffsetSpacing + channelButtonXSize,0.04],...
    'string',['radius: ',num2str(1)],'FontSize',12,'tag','radiusOffsetText');


% buttons to select channels
indicatorHandles.channel1Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',1,'tag','channel1Button',...
    'Callback',{@channelButton_Callback,1},'String','1','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel2Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXOffsetSpacing,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel2Button',...
    'Callback',{@channelButton_Callback,2},'String','2','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel3Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+2*channelButtonXOffsetSpacing,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel3Button',...
    'Callback',{@channelButton_Callback,3},'String','3','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel4Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel4Button',...
    'Callback',{@channelButton_Callback,4},'String','4','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel5Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXOffsetSpacing,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel5Button',...
    'Callback',{@channelButton_Callback,5},'String','5','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel6Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+2*channelButtonXOffsetSpacing,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel6Button',...
    'Callback',{@channelButton_Callback,6},'String','6','FontSize',14,...
    'FontWeight','Bold');

totalIndicatorWidth = 2*channelButtonXOffsetSpacing + channelButtonXSize;
indicatorHandles.channelNButton = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXSize,channelButtonYStart,...
    totalIndicatorWidth - 2*channelButtonXSize,channelButtonYSize],... % x size should go to end of the buttons of the same style
    'min',0,'max',1,'value',0,'tag','channelNButton',...
    'Callback',{@channelButton_Callback,-1},'String','n = ','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channelLabelText = uicontrol(figHandle,'Style','Text',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+3*channelButtonYOffsetSpacing,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,channelButtonYSize],...
    'string','channel','FontSize',12,'tag','radiusOffsetText');

% information
indicatorHandles.infoLabelText = uicontrol(figHandle,'Style','Text',...
    'units','normalized',...
    'position',[indicatorXStart,0.92,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,channelButtonYSize],...
    'string','info','FontSize',12,'tag','infoLabelText');

indicatorHandles.infoTable = uitable(figHandle,...
    'units','normalized',...
    'position',[indicatorXStart,0.77,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,0.17],...
    'enable','on',...
    'Data',{},'RowName',[],'FontSize',10,'tag','infoTable');

set(indicatorHandles.infoTable,'Data',{'Please wait, loading...'},'ColumnName',[]);
updateColumnWidthToLargestData(indicatorHandles.infoTable);


% titles
indicatorHandles.folderText = uicontrol(figHandle,'Style','Edit',...
    'units','normalized',...
    'position',[0.2,0.98-titleHeight,0.78,titleHeight],...
    'string','folder name','FontSize',12,'FontWeight','Bold',...
    'tag','folderText');

indicatorHandles.fileText = uicontrol(figHandle,'Style','Edit',...
    'units','normalized',...
    'position',[0.2,0.94-titleHeight,0.78,titleHeight],...
    'string','file name','FontSize',12,'FontWeight','Bold',...
    'tag','fileText');

% store handles for indicators
setappdata(figHandle,'indicatorHandles',indicatorHandles);

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
    'ClickedCallback',{@toggleSelectPartialRegion},'tag','Toolbar.PartialRegionSelect');

% Read an image
setappdata(figHandle,'selectPartialRegion',true);

% deal with a path setting where the icon is unavailable
filePathToExtractIntensities = which('extractIntensities');
[filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
[icon] = imread(fullfile(filePathToExtractIntensities,'icons','selectPartialRegion.png'));

% Set the button icon
set(p,'CData',icon);

p2 = uitoggletool(toolbarHandle,'TooltipString','Screen individual regions?',...
    'ClickedCallback',    {@screenIndividualRegions},'tag','Toolbar.IndividualRegions');

% deal with a path setting where the icon is unavailable
filePathToExtractIntensities = which('extractIntensities');
[filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
[icon] = imread(fullfile(filePathToExtractIntensities,'icons','screenIndividualRegions.png'));

% Set the button icon
set(p2,'CData',icon);

p3 = uitoggletool(toolbarHandle,'TooltipString','Display contour break point',...
    'ClickedCallback',{@toggleDisplayContourBreak},'tag','Toolbar.ContourBreak');

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
    imagePanHand = imagePanHand-nanmin(imagePanHand(:));
    imagePanHand = imagePanHand./nanmax(imagePanHand(:));
    imagePanHand = repmat(imagePanHand,1,1,3);
else
    imagePanHand = get(panHand,'CData');
end
pan2 = uitoggletool(toolbarHandle,'TooltipString','Pan',...
    'ClickedCallback',{@togglePanMode,figHandle},...
    'Tag','Exploration.Pan',...
    'CData',imagePanHand);

if isempty(zoomInHand)
    
    zoomInCData = setptr('glassplus');
    imageZoomIn = zoomInCData{4};
    imageZoomIn = imageZoomIn-nanmin(imageZoomIn(:));
    imageZoomIn = imageZoomIn./nanmax(imageZoomIn(:));
    imageZoomIn = repmat(imageZoomIn,1,1,3);
else
    imageZoomIn = get(zoomInHand,'CData');
end

zoomIn2 = uitoggletool(toolbarHandle,'TooltipString','ZoomIn',...
    'ClickedCallback',{@toggleZoomInMode,figHandle},...
    'Tag','Exploration.ZoomIn',...
    'CData',imageZoomIn);

if isempty(zoomOutHand)
    zoomOutCData = setptr('glassminus');
    imageZoomOut = zoomOutCData{4};
    imageZoomOut = imageZoomOut-nanmin(imageZoomOut(:));
    imageZoomOut = imageZoomOut./nanmax(imageZoomOut(:));
    imageZoomOut = repmat(imageZoomOut,1,1,3);
else
    imageZoomOut = get(zoomOutHand,'CData');
end

zoomOut2 = uitoggletool(toolbarHandle,'TooltipString','ZoomOut',...
    'ClickedCallback',{@toggleZoomOutMode,figHandle},...
    'Tag','Exploration.ZoomOut',...
    'CData',imageZoomOut);

save2 = uipushtool(toolbarHandle,'TooltipString','ExportMeasurements',...
    'ClickedCallback',{@exportMeasurements},...
    'Tag','ExportMeasurements',...
    'CData',get(saveHand,'CData'));

% store some initialized variables
setappdata(figHandle,'xOffsetsPerColor',[0]);
setappdata(figHandle,'yOffsetsPerColor',[0]);
setappdata(figHandle,'iiFile',1);
setappdata(figHandle,'jFrame',1);
setappdata(figHandle,'kkColorChannel',kkColorChannel);
setappdata(figHandle,'pathNames',pathNames);
setappdata(figHandle,'fileNames',fileNames);
setappdata(figHandle,'storedFrame',frame);
setappdata(figHandle,'filePathToExtractIntensities',filePathToExtractIntensities);
storedCell = cell;
setappdata(figHandle,'storedCell',storedCell);

% default colors
dispColor.outline = 'green';
dispColor.selected = 'red';
dispColor.highlight = 'blue';
dispColor.overview = [255,165,0]/255;

% default line styles
dispStyle.contour = '-';
dispStyle.background = ':';

% region border for calculating background
backgroundOffsetRadius = 3;

% store styles
setappdata(figHandle,'dispColor',dispColor);
setappdata(figHandle,'dispStyle',dispStyle);
backgroundOffsetRadius = 3;
setappdata(figHandle,'backgroundOffsetRadius',backgroundOffsetRadius);

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
    set(contourHandles(:,[4,6]),'visible','off');
end

function updateColumnWidthToLargestData(uiTableHand);

currentData = get(uiTableHand,'Data');
% how big is this string??
% using https://www.mathworks.com/matlabcentral/answers/56317-determine-size-of-text-objects
% we could render every single data element and count. However, this would
% likely be pretty slow. Instead, we'll calculate the width of a single
% capital M (typically one of the widest letters in non-monospaced fonts)
% and store this information.
%
% Then we'll make the column wide enough to hold the largest number of
% characters at the width of M

if not(isappdata(uiTableHand,'widthCapitalM'))
    tempText = uicontrol('Parent',get(uiTableHand,'Parent'),...
        'FontName',get(uiTableHand,'FontName'),...
        'FontSize',get(uiTableHand,'FontSize'),...
        'FontUnits',get(uiTableHand,'FontUnits'),...
        'FontWeight',get(uiTableHand,'FontWeight'),...
        'FontAngle',get(uiTableHand,'FontAngle'),...
        'String', 'MMMMM',...
        'Units','pixels','position',[10,10,10,10]);
    tempTextSize = get(tempText,'extent');
    set(tempText,'String','MMMMMM');
    tempTextSize2 = get(tempText,'extent');
    
    widthCapitalM = tempTextSize2(3)-tempTextSize(3);
    setappdata(uiTableHand,'widthCapitalM',widthCapitalM);
else
    widthCapitalM = getappdata(uiTableHand,'widthCapitalM');
end

set(uiTableHand,'units','pixel');

% Calculate the with of the data in cell C.

% uitables support mixed data types in each of the cells, however the
% length of the numeric types must be one, even when this would be rendered
% as many more than a single character.
formatStyle = get(uiTableHand,'ColumnFormat');

for iiCol = 1:size(currentData,2)
    for iiRow = 1:size(currentData,1)
        if isnumeric(currentData{iiRow,iiCol})
            if numel(formatStyle)<iiCol
                currentData{iiRow,iiCol} = num2str(currentData{iiRow,iiCol});
            elseif isempty(formatStyle{iiCol})
                currentData{iiRow,iiCol} = num2str(currentData{iiRow,iiCol});
            else
                currentData{iiRow,iiCol} = num2str(currentData{iiRow,iiCol},formatStyle{iiCol});
            end
        end
    end
end

maxLen = max(cellfun(@length,currentData),[],1);

cellMaxLen = num2cell(maxLen*widthCapitalM);
set(uiTableHand, 'ColumnWidth', cellMaxLen);
set(uiTableHand,'units','normalized');


function tifFileNameList = findCompanionTifFile(pathName,contourFileName);
% load and show image
testString = '_CONTOURS_pill_MESH.mat';
tifFileName = strrep(fullfile(pathName,contourFileName),testString,'.tif');

% check to see if it is a contours or contours_pill_mesh or something else
if strcmp(tifFileName,fullfile(pathName,contourFileName));
    % if these are identical, it didn't replace the extension correctly
    testString = '_CONTOURS.mat';
    tifFileName = strrep(fullfile(pathName,contourFileName),testString,'.tif');
    % if these are identical, it didn't replace the extension correctly
    if strcmp(tifFileName,fullfile(pathName,contourFileName));
        testString = '_CONTOURS_SpineAndRibs.mat';
        tifFileName = strrep(fullfile(pathName,contourFileName),testString,'.tif');
        % if these are identical, it didn't replace the extension correctly
        if strcmp(tifFileName,fullfile(pathName,contourFileName));
            testString = '_CONTOURS_pill_MESH_SpineAndRibs.mat';
            tifFileName = strrep(fullfile(pathName,contourFileName),testString,'.tif');
            % if these are identical, it didn't replace the extension correctly
            if strcmp(tifFileName,fullfile(pathName,contourFileName));
                warning('morphometrics:extractIntensities:contoursFileNameIssue','Countours file stem of unknown style. Original image file not found.');
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
    warning('morphometrics:extractIntensities:imageFileMissing',...
        ['Image file for ',pathName,' can not be found.']);
    return
end

% check and see if there are any other color channels

testC1 = strrep(tifFileName,'c=0','c=1');
if strcmp(testC1,tifFileName)
    % c=0 was not the channel used for segmentation
    warning('morphometrics:extractIntensities:channel0notSegmented','Channel 0 not used as segmentation channel. Please contact the developer.');
else
    tifFileNameList = {tifFileName};
    index = 1;
    testC1 = strrep(tifFileName,'c=0',['c=',num2str(index)]);
    
    while exist(testC1,'file');
        tifFileNameList{end+1} = testC1;
        index = index+1;
        testC1 = strrep(tifFileName,'c=0',['c=',num2str(index)]);
        
        
    end
end



function channelButton_Callback(h,evd,channelID)
switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
    otherwise
        mainFigHandle = h;
end

indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');

% turn them all off
set(indicatorHandles.channel1Button,'value',0);
set(indicatorHandles.channel2Button,'value',0);
set(indicatorHandles.channel3Button,'value',0);
set(indicatorHandles.channel4Button,'value',0);
set(indicatorHandles.channel5Button,'value',0);
set(indicatorHandles.channel6Button,'value',0);
set(indicatorHandles.channelNButton,'value',0);

switch channelID
    case {1}
        set(indicatorHandles.channel1Button,'value',1);
    case {2}
        set(indicatorHandles.channel2Button,'value',1);
    case {3}
        set(indicatorHandles.channel3Button,'value',1);
    case {4}
        set(indicatorHandles.channel4Button,'value',1);
    case {5}
        set(indicatorHandles.channel5Button,'value',1);
    case {6}
        set(indicatorHandles.channel6Button,'value',1);
    otherwise
        set(indicatorHandles.channelNButton,'value',1);
end


setappdata(mainFigHandle,'kkColorChannel',channelID);
updateImageNotFirstTime(mainFigHandle);
try
    screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
catch ME4
end

updateDisplayedInfo(mainFigHandle)


function xOffsetSlider_Callback(h,evd);

switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
        % update the value
        xOffsetVal = get(h,'Value');
        xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
        xOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))=...
            xOffsetVal;
        setappdata(mainFigHandle,'xOffsetsPerColor',xOffsetsPerColor);
        % store the value at the indicator
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        set(indicatorHandles.xOffsetText,'String', ['x offset: ',num2str(xOffsetVal,'%4.2g')]);
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
    otherwise
        mainFigHandle = h;
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
        xOffsetVal = xOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'));
        set(indicatorHandles.xOffsetText,'String', ['x offset: ',num2str(xOffsetVal,'%4.2g')]);
        set(indicatorHandles.xOffsetSlider,'value', xOffsetVal);
        
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
end
updateDisplayedInfo(mainFigHandle);



function yOffsetSlider_Callback(h,evd);

switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
        % update the value
        yOffsetVal = get(h,'Value');
        yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');
        yOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))=...
            yOffsetVal;
        setappdata(mainFigHandle,'yOffsetsPerColor',yOffsetsPerColor);
        % store the value at the indicator
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        set(indicatorHandles.yOffsetText,'String', ['y offset: ',num2str(yOffsetVal,'%4.2g')]);
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
    otherwise
        mainFigHandle = h;
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');
        yOffsetVal = yOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'));
        set(indicatorHandles.yOffsetText,'String', ['y offset: ',num2str(yOffsetVal,'%4.2g')]);
        set(indicatorHandles.yOffsetSlider,'value', yOffsetVal);
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
        
end
updateDisplayedInfo(mainFigHandle);


function offsetRadiusSlider_Callback(h,evd);

switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
        % update the value
        offsetRadiusVal = get(h,'Value');
        setappdata(mainFigHandle,'backgroundOffsetRadius',offsetRadiusVal);
        % store the value at the indicator
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        set(indicatorHandles.radiusOffsetText,'String', ['radius: ',num2str(offsetRadiusVal,'%4.2g')]);
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
    otherwise
        mainFigHandle = h;
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        offsetRadiusVal = getappdata(mainFigHandle,'backgroundOffsetRadius');
        set(indicatorHandles.radiusOffsetText,'String', ['radius: ',num2str(offsetRadiusVal,'%4.2g')]);
        set(indicatorHandles.radiusOffsetSlider,'value', offsetRadiusVal);
        
        try
            screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
        catch ME4
            
        end
        updateContourDisplay(mainFigHandle);
        
        
end
updateDisplayedInfo(mainFigHandle);




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
numericPointerVersion = round(10000*nanmean(nanmean(currentPointer{2})));
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
        warning('morphometrics:extractIntensities:unknownCursorMode','Unknown cursor mode.');
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
                    
                    set(contourHandles(:,[1,3,4,5,6]),'Color',dispColor.outline);
                    contourHandles(:,2) = 0;
                    set(contourHandles(contourIndex ,[1,3,4,5,6]),'Color',dispColor.selected);
                    contourHandles(contourIndex,2) = 1;
                case 'extend'
                    set(contourHandles(contourIndex ,[1,3,4,5,6]),'Color',dispColor.selected);
                    contourHandles(contourIndex,2) = 1;
                case 'extendToggle' % shift click, either left or right, single cell
                    if contourHandles(contourIndex,2) == 1; % already selected, remove
                        set(contourHandles(contourIndex,[1,3,4,5,6]),'Color',dispColor.outline);
                        contourHandles(contourIndex,2) = 0;
                    else
                        set(contourHandles(contourIndex ,[1,3,4,5,6]),'Color',dispColor.selected);
                        contourHandles(contourIndex,2) = 1;
                    end
                case 'alt' % right click
                    % remove region
                    set(contourHandles(contourIndex,[1,3,4,5,6]),'Color',dispColor.outline);
                    contourHandles(contourIndex,2)=0;
            end
            
            setappdata(figHandle,'contourHandles',contourHandles);
            updateDisplayedInfo(figHandle);
        end
end

function addDataTableRow(uiTableHandle,dataToAdd);
currentData = get(uiTableHandle,'Data');

if size(currentData,2)<4
    currentData = {};
end

if not(isempty(dataToAdd))
    newTableData = cat(1,currentData,...
        {dataToAdd.Measurement,dataToAdd.Description,dataToAdd.Value,dataToAdd.Type});
    
else
    newTableData = cat(1,currentData,{[],[],[],[]});
end

set(uiTableHandle,'Data',newTableData);


function updateDisplayedInfo(figHandle)
% this will display various pieces of information about the selected cells

contourHandles = getappdata(figHandle,'contourHandles');
indicatorHandles = getappdata(figHandle,'indicatorHandles');
storedFrame = getappdata(figHandle,'storedFrame');

if any(contourHandles(:,2))
    
    set(indicatorHandles.infoTable,'Data',{});
    % get the table ready to receive data
    set(indicatorHandles.infoTable,'ColumnName',{'Measurement','Description','Value','Type'});
    
    nObjects = nnz(contourHandles(:,2));
    
    % display the list of objects selected
    if nObjects > 4 % truncate list
        indicesSelected = find(contourHandles(:,2)==1);
        indexString = num2str(indicesSelected(1:4),'%3g, ');
        indexString = indexString';
        indexString = indexString(:)';
        
        dataToAdd.Measurement = '# selected';
        dataToAdd.Description = '';
        dataToAdd.Value = num2str(nObjects);
        dataToAdd.Type = 'count';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
        dataToAdd.Measurement = 'object';
        dataToAdd.Description = '';
        dataToAdd.Value = ['[',indexString(1:end),'...]'];
        dataToAdd.Type = 'indices';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
    elseif nObjects > 1 % display all
        indicesSelected = find(contourHandles(:,2)==1);
        indexString = num2str(indicesSelected,'%3g, ');
        indexString = indexString';
        indexString = indexString(:)';
        
        dataToAdd.Measurement = '# selected';
        dataToAdd.Description = '';
        dataToAdd.Value = num2str(nObjects);
        dataToAdd.Type = 'count';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
        dataToAdd.Measurement = 'object';
        dataToAdd.Description = '';
        dataToAdd.Value = ['[',indexString(1:end-1),']'];
        dataToAdd.Type = 'indices';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
    else % use the term object for singular
        indicesSelected = find(contourHandles(:,2)==1);
        indexString = num2str(indicesSelected,'%3g, ');
        indexString = indexString';
        indexString = indexString(:)';
        
        dataToAdd.Measurement = '# selected';
        dataToAdd.Description = '';
        dataToAdd.Value = num2str(nObjects);
        dataToAdd.Type = 'count';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
        dataToAdd.Measurement = 'object';
        dataToAdd.Description = '';
        dataToAdd.Value = ['[',indexString(1:end-1),']'];
        dataToAdd.Type = 'index';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        
        %         set(indicatorHandles.infoTable,'Data',[num2str(nObjects), ' object selected: [',...
        %             indexString(1:end-1),']']);
    end
    
    
    % --- add another property to the info string (blank line)
    addDataTableRow(indicatorHandles.infoTable,[]);
    % ------ end appending new information to info string
    
    % --- add another property to the info string (area)
    % loop over all the objects and pull out the desired property
    tempProp = [];
    for iiObj = indicesSelected(:)';
        tempProp = [tempProp,storedFrame.object(iiObj).area];
    end
    
    dataToAdd.Measurement = 'area';
    dataToAdd.Description = 'pix^2';
    dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
    dataToAdd.Type = 'average';
    addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    % ------ end appending new information to info string
    
    % --- add another property to the info string (centerline length)
    % loop over all the objects and pull out the desired property
    tempProp = [];
    for iiObj = indicesSelected(:)';
        if isfield(storedFrame.object(iiObj),'length')
            tempProp = [tempProp,storedFrame.object(iiObj).length];
        else
        end
        
    end
    
    if not(isnan(nanmean(tempProp))) % only update if not NaN
        dataToAdd.Measurement = 'length';
        dataToAdd.Description = 'pill_mesh, pix';
        dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
        dataToAdd.Type = 'average';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    end
    % ------ end appending new information to info string
    
    % --- add another property to the info string (centerline length)
    % loop over all the objects and pull out the desired property
    tempProp = [];
    for iiObj = indicesSelected(:)';
        if isfield(storedFrame.object(iiObj),'spine')
            spineTemp = storedFrame.object(iiObj).spine;
            if not(isnan(spineTemp))
                tempProp = [tempProp,sum(sqrt(sum(diff(spineTemp).^2,2)))];
            end
        else
        end
        
    end
    
    if not(isnan(nanmean(tempProp))) % only update if not NaN
        dataToAdd.Measurement = 'length';
        dataToAdd.Description = 'spine, pix';
        dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
        dataToAdd.Type = 'average';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    end
    % ------ end appending new information to info string
    
    
    % --- add another property to the info string (cell width)
    % loop over all the objects and pull out the desired property
    tempProp = [];
    for iiObj = indicesSelected(:)'; % turn indices into a row vector
        if isfield(storedFrame.object(iiObj),'width')
            
            tempProp = [tempProp,nanmean(storedFrame.object(iiObj).width(:))];
        end
    end
    
    if not(isnan(nanmean(tempProp))) % only update if not NaN
        dataToAdd.Measurement = 'width';
        dataToAdd.Description = 'pill_mesh, pix';
        dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
        dataToAdd.Type = 'average';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    end
    % ------ end appending new information to info string
    
    % --- add another property to the info string (cell width)
    % loop over all the objects and pull out the desired property
    tempProp = [];
    for iiObj = indicesSelected(:)'; % turn indices into a row vector
        if isfield(storedFrame.object(iiObj),'xyRibEnds')
            tempSpine = storedFrame.object(iiObj).spine;
            
            if not(isnan(tempSpine))
                tempRibs = storedFrame.object(iiObj).xyRibEnds;
                tempDistRib1 = [tempRibs(:,1)-tempSpine(:,1),tempRibs(:,2)-tempSpine(:,2)];
                tempDistRib2 = [tempRibs(:,3)-tempSpine(:,1),tempRibs(:,4)-tempSpine(:,2)];
                
                tempDistRib1 = sqrt(sum(tempDistRib1.^2,2));
                tempDistRib2 = sqrt(sum(tempDistRib2.^2,2));
                % ignore first and last points, those rib lengths are 0  because they are
                % at the pole
                tempProp = [tempProp,nanmean([tempDistRib1(2:end-1),tempDistRib1(2:end-1)])];
            end
        end
    end
    
    if not(isnan(nanmean(tempProp))) % only update if not NaN
        dataToAdd.Measurement = 'width';
        dataToAdd.Description = 'spine, pix';
        dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
        dataToAdd.Type = 'average';
        addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    end
    % ------ end appending new information to info string
    
    % --- add another property to the info string (centerline curvature Pill Mesh)
    % loop over all the objects and pull out the desired property
    if isfield(storedFrame.object(iiObj),'cent_kappa');
        tempProp = [];
        
        INCLUDE_FRAC = 0.65; % fraction of the cell length to retain as non-poles
        POLE_MIN_SIZE = 3; % minimum number of pixels in each pole
        
        % use this length to define poles
        poleFrac = (1-INCLUDE_FRAC)/2;
        
        for iiObj = indicesSelected(:)';
            
            % contour length of the cell centerline, in pixels
            tCL = storedFrame.object(iiObj).centerline;
            
            % distance between centerline points
            tSegment = diff(tCL);
            tSegment = sqrt(sum(tSegment.^2,2));
            % add up the distance between center line points
            tCumSegLength = cumsum(tSegment);
            % start at 0
            tCumSegLength = [0;tCumSegLength];
            % the final is another measure of the length of the cell
            tclLength = tCumSegLength(end);
            
            % left end of cell body starts at
            leftStart = find(tCumSegLength>poleFrac*tclLength,1,'first');
            % make sure there are at least POLE_MIN_SIZE pixels in the
            % left pole
            leftStart = max(leftStart,POLE_MIN_SIZE+1);
            
            % right end of cell body ends at
            rightEnd = find(tCumSegLength<(1-poleFrac)*tclLength,1,'last');
            % make sure that there are at least POLE_MIN_SIZE pixels in
            % the right pole
            rightEnd = min(length(tCL)-POLE_MIN_SIZE,rightEnd);
            
            tempCurvatureField = storedFrame.object(iiObj).cent_kappa(:);
            ttruncClCurv = tempCurvatureField(leftStart:rightEnd);
            ttruncClCurv = ttruncClCurv.^2;
            ttruncClCurv = sqrt(mean(ttruncClCurv));
            %             tempVals = storedFrame.object(iiObj).spineCurvature;
            tempProp = [tempProp,ttruncClCurv];
        end
        
        
        if not(isnan(nanmean(tempProp))) % only update if not NaN
            dataToAdd.Measurement = 'centerline curvature';
            dataToAdd.Description = 'pill_mesh, rms, no poles, pix^-1';
            dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
            dataToAdd.Type = 'average';
            addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        end
    end
    
    % ------ end appending new information to info string
    
    
    % --- add another property to the info string (centerline curvature SpineNRibs)
    % loop over all the objects and pull out the desired property
    if isfield(storedFrame.object(iiObj),'spineCurvature');
        tempProp = [];
        for iiObj = indicesSelected(:)';
            tempVals = storedFrame.object(iiObj).spineCurvature;
            tempProp = [tempProp,sqrt(nanmean(tempVals.^2))];
        end
        
        
        if not(isnan(nanmean(tempProp))) % only update if not NaN
            dataToAdd.Measurement = 'centerline curvature';
            dataToAdd.Description = 'spine, rms, poles included, pix^-1';
            dataToAdd.Value = num2str(nanmean(tempProp),'%4.3g');
            dataToAdd.Type = 'average';
            addDataTableRow(indicatorHandles.infoTable,dataToAdd);
        end
    end
    % ------ end appending new information to info string
    
    % --- add another property to the info string (blank line)
    addDataTableRow(indicatorHandles.infoTable,[]);
    % ------ end appending new information to info string
    
    % extract intensities of the regions
    clear bkgdIntensity totalSignal avgSignal
    counter = 1;
    for iiObj = indicesSelected(:)';
        [bkgdIntensity(counter),totalSignal(counter), avgSignal(counter)] = measureIntensity(figHandle,iiObj);
        counter = counter+1;
    end
    
    % --- add another property to the info string (background intensity)
    dataToAdd.Measurement = 'background';
    dataToAdd.Description = 'counts';
    dataToAdd.Value = num2str(nanmean(bkgdIntensity),'%4.3g');
    dataToAdd.Type = 'average';
    addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    
    % ------ end appending new information to info string
    
    % --- add another property to the info string (total signal)
    dataToAdd.Measurement = 'total signal';
    dataToAdd.Description = 'counts';
    dataToAdd.Value = num2str(nanmean(totalSignal),'%4.3g');
    dataToAdd.Type = 'average';
    addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    % ------ end appending new information to info string
    
    % --- add another property to the info string (signal per area)
    
    dataToAdd.Measurement = 'average brightness';
    dataToAdd.Description = 'counts/(pix^2)';
    dataToAdd.Value = num2str(nanmean(avgSignal),'%4.3g');
    dataToAdd.Type = 'average';
    addDataTableRow(indicatorHandles.infoTable,dataToAdd);
    % ------ end appending new information to info string
    
else
    set(indicatorHandles.infoTable,'ColumnName',[]);
    set(indicatorHandles.infoTable,'Data',{'No objects selected.'});
end

% update column widths
updateColumnWidthToLargestData(indicatorHandles.infoTable);



% ---------------------------
function selectAll(figHandle)
% this function should select all the contours
contourHandles = getappdata(figHandle,'contourHandles');
dispColor = getappdata(figHandle,'dispColor');

% check to see if everything is selected
if all(contourHandles(:,2))
    % deselect all
    set(contourHandles(:,[1,3,4,5,6]),'Color',dispColor.outline);
    contourHandles(:,2) = 0;
else
    % select all
    set(contourHandles(:,[1,3,4,5,6]),'Color',dispColor.selected);
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
    case {'uparrow'};
        if contains(evnt.Modifier,'shift')
            increaseBackgroundOffset(src,10);
        else
            increaseBackgroundOffset(src,1);
        end
    case {'downarrow'};
        if contains(evnt.Modifier,'shift')
            decreaseBackgroundOffset(src,10);
        else
            decreaseBackgroundOffset(src,1);
        end
    case {'rightarrow'};
        nextFrame(src);
    case {'leftarrow'};
        prevFrame(src);
    case {'s'};
        if strcmp(evnt.Modifier,'control');
            exportMeasurements(src);
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

if not(contains(evnt.Modifier,'Shift'))
    bigStep = 1;
    littleStep = 0.2;
else
    bigStep = 0.2;
    littleStep = 1;
end

switch evnt.Character
    case {'A','a'}
        globalXYContourOffsets(src,'x',-bigStep)
    case {'D','d'}
        globalXYContourOffsets(src,'x',bigStep)
    case {'S','s'}
        globalXYContourOffsets(src,'y',bigStep)
    case {'W','w'}
        globalXYContourOffsets(src,'y',-bigStep)
    otherwise
end

function globalXYContourOffsets(src,dimension,direction)
if isappdata(src,'mainFigHandle')
    mainFigHandle = getappdata(src,'mainFigHandle');
else
    mainFigHandle = src;
end

switch dimension
    case {'x','X'};
        xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
        xOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))=...
            xOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))+direction;
        setappdata(mainFigHandle,'xOffsetsPerColor',xOffsetsPerColor);
        xOffsetSlider_Callback(mainFigHandle,[]);
    case {'y','Y'};
        yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');
        yOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))=...
            yOffsetsPerColor(getappdata(mainFigHandle,'kkColorChannel'))+direction;
        setappdata(mainFigHandle,'yOffsetsPerColor',yOffsetsPerColor);
        yOffsetSlider_Callback(mainFigHandle,[]);
        
        
end

try
    screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
catch ME4
end
updateContourDisplay(mainFigHandle);

function  displayHelpScreen()
% write out a text document
helpPath = fullfile(tempdir,'extractIntensitiesHelp.txt');
fidA = fopen(helpPath,'w+');
fprintf(fidA,'Welcome to ''extractIntensities Help!''\r\n');
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
fprintf(fidA,['+ Does not support segmentation channels being something other than ''c=0''.\r\n']);
fprintf(fidA,['+ Does not support color channels that skip, such as ''c=0, c=2, c=3, c=4''.\r\n']);

% find the main gui
mainFigHandle = findall(groot,'tag','extractIntensitiesMainFigure');
% extractIntensitiesVersion = getappdata(

versionTag = getappdata(mainFigHandle(1),'versionTag');
fprintf(fidA,['\r\nextractIntensities Version: ',versionTag,'\r\n']);

% display the contents of the text document
f = popupmessage(helpPath,'Help for extractIntensities');
textboxHand = findall(f,'tag','textbox');
set(textboxHand,'fontsize',14);
% delete the text document
delete(helpPath);


function displayCurrentImage(figureHand)
% get stored data values
pathNames = getappdata(figureHand,'pathNames');
contourFileNames = getappdata(figureHand,'fileNames');
iiFile = getappdata(figureHand,'iiFile');

cell=[];
load(fullfile(pathNames{iiFile},contourFileNames{iiFile}));
iiFile = getappdata(figureHand,'iiFile');

storedFrame = frame;
storedCell = cell;
setappdata(figureHand,'storedFrame',storedFrame);
setappdata(figureHand,'storedCell',storedCell);

tifFileNameList = findCompanionTifFile(pathNames{iiFile},contourFileNames{iiFile});
setappdata(figureHand,'tifFileNameList',tifFileNameList);

% how many files are there?
nChannels = numel(tifFileNameList);

% turn off buttons that don't apply
indicatorHandles = getappdata(figureHand,'indicatorHandles');

if nChannels < 2
    set(indicatorHandles.channel2Button,'visible','off');
end

if nChannels < 3
    set(indicatorHandles.channel3Button,'visible','off');
end

if nChannels < 4
    set(indicatorHandles.channel4Button,'visible','off');
end

if nChannels < 5
    set(indicatorHandles.channel5Button,'visible','off');
end

if nChannels < 6
    set(indicatorHandles.channel6Button,'visible','off');
end

if nChannels < 7
    set(indicatorHandles.channelNButton,'visible','off');
end


axesHand = getappdata(figureHand,'axesHand');
showImageFirstTime(figureHand,tifFileNameList{1})
kkColorChannel = getappdata(figureHand,'kkColorChannel');
channelButton_Callback(figureHand,[],kkColorChannel)
set(get(axesHand,'children'),'visible','on');
set(indicatorHandles.infoTable,'String','Loading complete.');



function updateImageNotFirstTime(figureHand)
axesHand = getappdata(figureHand,'axesHand');
tifFileNameList = getappdata(figureHand,'tifFileNameList');
kkColorChannel = getappdata(figureHand,'kkColorChannel');
tifFileName = tifFileNameList{kkColorChannel};
imshowHand = getappdata(figureHand,'imshowHand');
jFrame = getappdata(figureHand,'jFrame');

readInImage = imread(tifFileName,'index',jFrame);
readInImage = double(readInImage);
readInImage = readInImage-min(readInImage(:));
readInImage = readInImage./max(readInImage(:));
set(imshowHand,'cdata',readInImage);
setappdata(figureHand,'readInImage',readInImage);
updateContourDisplay(figureHand);

function showImageFirstTime(figureHand,tifFileName)
axesHand = getappdata(figureHand,'axesHand');
contourFileNames = getappdata(figureHand,'fileNames');
iiFile = getappdata(figureHand,'iiFile');
jFrame = getappdata(figureHand,'jFrame');
storedFrame = getappdata(figureHand,'storedFrame');
dispColor = getappdata(figureHand,'dispColor');

readInImage = imread(tifFileName,'index',jFrame);
readInImage = double(readInImage);
readInImage = readInImage-min(readInImage(:));
readInImage = readInImage./max(readInImage(:));

cla(axesHand);
imshowHand = imshow(readInImage,[],'Parent',axesHand,'initialMagnification','Fit');
setappdata(figureHand,'imshowHand',imshowHand);

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
    if contains(get(hrectchild(iiChild),'tag'),'marker')
        set(hrectchild(iiChild),'Marker','.')
        set(hrectchild(iiChild),'MarkerFaceColor',dispColor.overview);
        set(hrectchild(iiChild),'MarkerEdgeColor',dispColor.overview);
        
        continue
    end
    if contains(get(hrectchild(iiChild),'tag'),'wing')
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

% update title
indicatorHandles = getappdata(figureHand,'indicatorHandles');

% parse file name into parts
[parentFolder,childFile,childExt] = fileparts(tifFileName);

set(indicatorHandles.folderText,'string',[parentFolder]);
set(indicatorHandles.fileText,'string',[childFile,childExt,': Frame ',num2str(jFrame)]);

hold on;

% get mask ready for faster processing of selections
storedMask = zeros(size(readInImage));
nRowsImage = size(readInImage,1);
nColsImage = size(readInImage,2);
setappdata(figureHand,'nRowsImage',nRowsImage);
setappdata(figureHand,'nColsImage',nColsImage);

% check to make sure there are some objects
if isempty( storedFrame.object)
    warning('morphometrics:extractIntensities:noObjects',['No contours in: ',contourFileNames{iiFile}]);
    
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
        
        % close contours and offset for background region
        XcontTemp = storedFrame(jFrame).object(kObj).Xcont;
        YcontTemp = storedFrame(jFrame).object(kObj).Ycont;
        
        [XcontOffset,YcontOffset] = offsetContour(XcontTemp,YcontTemp,getappdata(figureHand,'backgroundOffsetRadius'));
        
        
        XcontTemp = [XcontTemp;XcontTemp(1)];
        YcontTemp = [YcontTemp;YcontTemp(1)];
        
        XcontOffset = [XcontOffset;XcontOffset(1)];
        YcontOffset = [YcontOffset;YcontOffset(1)];
        
        contourHandles(kObj,1) = plot(XcontTemp,...
            YcontTemp,'parent',axesHand);
        contourHandles(kObj,4) = plot(XcontTemp(1),...
            YcontTemp(1),'x','parent',axesHand);
        contourHandles(kObj,5) = plot(XcontOffset,...
            YcontOffset,'linestyle',':','parent',axesHand);
        contourHandles(kObj,6) = plot(XcontOffset(1),...
            YcontOffset(1),'x','parent',axesHand);
        
        % mask region for mouse selection
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
        contourHandles(kObj,5) = plot(nan,nan,'parent',axesHand);
        contourHandles(kObj,6) = plot(nan,nan,'parent',axesHand);
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
set(contourHandles(:,[1,3,4,5,6]),'Color',dispColor.outline);

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

axesHand = getappdata(figHandle,'axesHand');
set(get(axesHand,'children'),'visible','off');
indicatorHandles = getappdata(figHandle,'indicatorHandles');
set(indicatorHandles.infoTable,'String','Please wait, loading...');

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
    set(contourHandles(:,[4,6]),'visible','off');
end


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

axesHand = getappdata(figHandle,'axesHand');
set(get(axesHand,'children'),'visible','off');
indicatorHandles = getappdata(figHandle,'indicatorHandles');
set(indicatorHandles.infoTable,'String','Please wait, loading...');

%
% % check for unsaved changes
% [statusOut] = checkForUnsavedChanges(figHandle);
%
% if statusOut==1;
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
    set(contourHandles(:,[4,6]),'visible','off');
end

% else
%     % error in checking for changes or user cancelled
% end

function [bkgdIntensity,totalSignal, avgSignal] = measureIntensity(figHandle,regionID,readInImage)
contourHandles = getappdata(figHandle,'contourHandles');
% can't use stored readInImage because it has already been normalized
tifFileNameList = getappdata(figHandle,'tifFileNameList');
kkColorChannel = getappdata(figHandle,'kkColorChannel');
if nargin<3
    readInImage = double(imread(tifFileNameList{kkColorChannel}));
end
objectMask = false(size(readInImage));

nRowsImage = size(readInImage,1);
nColsImage = size(readInImage,2);

% mask region for mouse selection
objectOutlineX = get(contourHandles(regionID,1),'XData');
objectOutlineY = get(contourHandles(regionID,1),'YData');

% interpolate 2-fold to make sure object is enclosed
objectOutlineX = round(interp(objectOutlineX,4));
objectOutlineY = round(interp(objectOutlineY,4));


outlineIdx = sub2ind([nRowsImage,nColsImage],objectOutlineY,objectOutlineX);

% outline regions
objectMask(outlineIdx) = 1;

% fill in the mask
objectMask = imfill(objectMask,'holes');
bkgRadius = getappdata(figHandle,'backgroundOffsetRadius');
bkgdMask = imdilate(objectMask,strel('disk',round(bkgRadius),8));

% calculate intensities
bkgdIntensity = nansum((bkgdMask(:)-objectMask(:)).*readInImage(:))./ nansum(bkgdMask(:)-objectMask(:));
totalSignal =  nansum(objectMask(:).*(readInImage(:)-bkgdIntensity));
avgSignal = totalSignal./nansum(objectMask(:));


function exportMeasurements(src,varargin)
mainFigHandle = get(get(src,'Parent'),'Parent');
indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
set(indicatorHandles.infoTable,'String','Please wait, writing out results...');
% get stored data values
pathNames = getappdata(mainFigHandle,'pathNames');
contourFileNames = getappdata(mainFigHandle,'fileNames');
iiFile = getappdata(mainFigHandle,'iiFile');

cell=[];
load(fullfile(pathNames{iiFile},contourFileNames{iiFile}));
iiFile = getappdata(mainFigHandle,'iiFile');

storedFrame = frame;
storedCell = cell;

jFrame = getappdata(mainFigHandle,'jFrame');
if jFrame ~= 1
    error('morphometrics:extractIntensities:jjFrameNotOne',['Please contact developer, jjFrame = ',num2str(jFrame)]);
end
kkColorChannel = getappdata(mainFigHandle,'kkColorChannel');


tifFileNameList = getappdata(mainFigHandle,'tifFileNameList');
kkColorChannel = getappdata(mainFigHandle,'kkColorChannel');
readInImage = double(imread(tifFileNameList{kkColorChannel}));


% get ready to save some output csv
outputFileName = fullfile(pathNames{iiFile},contourFileNames{iiFile});
extraNameInfo = ['_ExportedIntensitiesFor_channel_c=', num2str(kkColorChannel-1),'_',datestr(now,30),'.csv'];
outputFileName = strrep(outputFileName,'.mat',[extraNameInfo]);

fidA = fopen(outputFileName,'w+');

% write some header information
versionTag = getappdata(mainFigHandle,'versionTag');
fprintf(fidA,['MATLAB version,',version(),'\r\n']);
fprintf(fidA,['extractIntensities version,',versionTag,'\r\n']);
fprintf(fidA,['contours file,',strrep(fullfile(pathNames{iiFile},contourFileNames{iiFile}),'\','\\'),'\r\n']);
fprintf(fidA,['color channel,',num2str(kkColorChannel),'\r\n']);
tifFileNameList = getappdata(mainFigHandle,'tifFileNameList');
fprintf(fidA,['tif file,',strrep(tifFileNameList{kkColorChannel},'\','\\'),'\r\n']);

% write out some settings
fprintf(fidA,['\r\n Adjustable settings\r\n']);
xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');

fprintf(fidA,['xContourOffset,',num2str(xOffsetsPerColor(kkColorChannel)),'\r\n']);
fprintf(fidA,['yContourOffset,',num2str(yOffsetsPerColor(kkColorChannel)),'\r\n']);
fprintf(fidA,['backgroundRadius,',num2str(getappdata(mainFigHandle,'backgroundOffsetRadius')),'\r\n']);

fprintf(fidA,['\r\n Object index, background intensity (counts), total intensity (counts), average intensity (counts/pix)\r\n']);

nObjects = size(storedFrame(jFrame).object,2);

progressbar('Writing out results');

for kObj = 1:nObjects
    progressbar(kObj/nObjects);
    % in lineaged samples, sometimes an object exists even when it is
    % empty. That is, if a cell of ID jj exists in frames ii and ii+2,
    % there may be an empty contour in frame ii+1
    if not(isempty(storedFrame(jFrame).object(kObj).Xcont))
        fprintf(fidA,[num2str(kObj),',']);
        
        % intensity values
        [bkgdIntensity,totalSignal, avgSignal] = measureIntensity(mainFigHandle,kObj,readInImage);
        
        fprintf(fidA,[num2str(bkgdIntensity),',']);
        fprintf(fidA,[num2str(totalSignal),',']);
        fprintf(fidA,[num2str(avgSignal),'\r\n']);
    end
end
progressbar(1);

fclose(fidA);
%
updateDisplayedInfo(mainFigHandle);





function toggleContours(figHandle)
contourHandles = getappdata(figHandle,'contourHandles');

% are they currently visible?
switch get(contourHandles(1),'Visible')
    case 'on'
        set(contourHandles(:,[1,3,4,5,6]),'Visible','off');
    case 'off'
        if getappdata(figHandle,'displayContourBreak')
            set(contourHandles(:,[4,6]),'Visible','on')
        else
            set(contourHandles(:,[4,6]),'Visible','off')
        end
        set(contourHandles(:,[1,3,5]),'Visible','on');
end

updateIndividualRegions(figHandle)

function closeFigure(figHandle,varargin)

% check to see if small window is open
if isappdata(figHandle,'singleCellWindowHand')
    singleCellWindowHand = getappdata(figHandle,'singleCellWindowHand');
    try
        close(singleCellWindowHand);
    catch ME5
    end
end
% % check for unsaved changes
% [statusOut] = checkForUnsavedChanges(figHandle);
% if statusOut==1;
delete(figHandle);
% else
%     % error in checking for changes or user cancelled
% end

function toggleSelectPartialRegion(src,evt)

figHand = get(get(src,'parent'),'parent');
selectPartialRegion = getappdata(figHand,'selectPartialRegion');
filePathToExtractIntensities = getappdata(figHand,'filePathToExtractIntensities');

if selectPartialRegion
    % switch to select all
    setappdata(figHand,'selectPartialRegion',false);
    
    % Read an image
    [icon] = imread(fullfile(filePathToExtractIntensities,'icons','selectWholeRegion.png'));
    set(src,'Cdata',icon);
else
    % switch to select region
    setappdata(figHand,'selectPartialRegion',true);
    % Read an image
    [icon] = imread(fullfile(filePathToExtractIntensities,'icons','selectPartialRegion.png'));
    set(src,'Cdata',icon);
end

function toggleDisplayContourBreak(src,evt)

figHand = get(get(src,'parent'),'parent');
displayContourBreak = getappdata(figHand,'displayContourBreak');
filePathToExtractIntensities = getappdata(figHand,'filePathToExtractIntensities');

% update single cell window
updateIndividualRegions(figHand);

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
    set(contourHandles(:,[4,6]),'Visible','on')
else
    set(contourHandles(:,[4,6]),'Visible','off')
end


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
            
            % as of 20190131: for minor window, there are five display objects,
            % main contour, centerline, main contour break, offset contour,
            % offset contour break.
            set(p1([3,5]),'visible',get(contourBreakHand,'State'))
            
            
            
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
    % %     figHand = findobj(groot,'type','figure','tag','extractIntensitiesMainFigure');
    figHand =  getappdata(hObj,'mainFigHandle');
    
    
else
    
    figHand = get(get(hObj,'Parent'),'Parent');
    switch get(hObj,'State')
        case 'on'
            filePathToExtractIntensities = which('extractIntensities');
            [filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
            [icon] = imread(fullfile(filePathToExtractIntensities,'icons','screenIndividualRegions2.png'));
            
            % Set the button icon
            set(hObj,'CData',icon);
            
        case 'off'
            filePathToExtractIntensities = which('extractIntensities');
            [filePathToExtractIntensities,~] = fileparts(filePathToExtractIntensities);
            [icon] = imread(fullfile(filePathToExtractIntensities,'icons','screenIndividualRegions.png'));
            
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
if size(contourHandles,2)==3
    columnsToSet = [1,3,4,5,6];
else
    columnsToSet = 1;
end
set(contourHandles(kObj,columnsToSet),'Color',dispColor.highlight);


% clear figure of previous plotting
clf(fig2);
set(fig2,'WindowKeyPressFcn',@keyHookFunction2);
set(fig2,'CloseRequestFcn',@closeIndividualView);
setappdata(fig2,'nObjects',nObjects);

% global offset
kkColorChannel = getappdata(figHand,'kkColorChannel');
xOffsetsPerColor = getappdata(figHand,'xOffsetsPerColor');
yOffsetsPerColor = getappdata(figHand,'yOffsetsPerColor');

if not(isempty(storedFrame(jFrame).object(kObj).Xcont))
    % pull out the bounding box
    XcontTemp = storedFrame(jFrame).object(kObj).Xcont;
    YcontTemp = storedFrame(jFrame).object(kObj).Ycont;
    
    
    
    % global offset
    if numel(xOffsetsPerColor)<kkColorChannel
        
        xOffsetsPerColor(kkColorChannel) = 0;
        yOffsetsPerColor(kkColorChannel) = 0 ;
        setappdata(figHand,'yOffsetsPerColor',yOffsetsPerColor);
        setappdata(figHand,'xOffsetsPerColor',xOffsetsPerColor);
    end
    
    XcontTemp = XcontTemp+xOffsetsPerColor(kkColorChannel);
    YcontTemp = YcontTemp+yOffsetsPerColor(kkColorChannel);
    
    
    offsetSize = getappdata(figHand,'backgroundOffsetRadius');
    
    % pull out the offset box
    [XcontOffset,YcontOffset] = offsetContour(XcontTemp,YcontTemp,offsetSize);
    
    
    % determine bounding box plus a little
    xmin = min(XcontOffset);
    xmax = max(XcontOffset);
    ymin = min(YcontOffset);
    ymax = max(YcontOffset);
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
    imshow(partialImage,[],'initialMagnification','fit');
    hold on;
    
    % contour
    % close contours
    XcontTemp = [XcontTemp;XcontTemp(1)];
    YcontTemp = [YcontTemp;YcontTemp(1)];
    
    XcontOffset = [XcontOffset;XcontOffset(1)];
    YcontOffset = [YcontOffset;YcontOffset(1)];
    
    p1 = plot(XcontTemp-xmin+1,YcontTemp-ymin+1,'linewidth',2);
    p1(3) = plot(XcontTemp(1)-xmin+1,YcontTemp(1)-ymin+1,'x','linewidth',2);
    p1(4) = plot(XcontOffset-xmin+1,YcontOffset-ymin+1,'linewidth',2,'linestyle',':');
    p1(5) = plot(XcontOffset(1)-xmin+1,YcontOffset(1)-ymin+1,'o','linewidth',2);
    
    if isSpineRibs
        if not(isnan(storedFrame(jFrame).object(kObj).spine))
            % centerline from spine and ribs
            p1(2)  = plot(storedFrame(jFrame).object(kObj).spine(:,1)-xmin+1+xOffsetsPerColor(kkColorChannel),...
                storedFrame(jFrame).object(kObj).spine(:,2)-ymin+1+yOffsetsPerColor(kkColorChannel),...
                'linestyle',':','linewidth',2);
        else
            % no centerline
            p1(2) = plot(nan,nan);
        end
    elseif isPillMesh
        if not(isempty(storedFrame(jFrame).object(kObj).centerline))
            % centerline from pillMesh
            p1(2) = plot(storedFrame(jFrame).object(kObj).centerline(:,1)-xmin+1+xOffsetsPerColor(kkColorChannel),...
                storedFrame(jFrame).object(kObj).centerline(:,2)-ymin+1+yOffsetsPerColor(kkColorChannel),...
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
if size(contourHandles,2)==3
    columnsToSet = [1,3,4,5,6];
else
    columnsToSet = 1;
end

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
        if contains(evnt.Modifier,'shift')
            increaseBackgroundOffset(src,10);
        else
            increaseBackgroundOffset(src,1);
        end
    case {'downarrow'};
        if contains(evnt.Modifier,'shift')
            decreaseBackgroundOffset(src,10);
        else
            decreaseBackgroundOffset(src,1);
        end
    case {'h'};
        if or(strcmp(evnt.Modifier,'control'),...
                strcmp(evnt.Modifier,'command'));
            toggleContours(figHandle);
        end
    otherwise
end

if not(contains(evnt.Modifier,'Shift'))
    bigStep = 1;
    littleStep = 0.2;
else
    bigStep = 0.2;
    littleStep = 1;
end

switch evnt.Character
    case {'A','a'}
        globalXYContourOffsets(src,'x',-bigStep)
    case {'D','d'}
        globalXYContourOffsets(src,'x',bigStep)
    case {'S','s'}
        globalXYContourOffsets(src,'y',bigStep)
    case {'W','w'}
        globalXYContourOffsets(src,'y',-bigStep)
    otherwise
end

function     increaseBackgroundOffset(src,increaseModifier);
if isappdata(src,'mainFigHandle')
    mainFigHandle = getappdata(src,'mainFigHandle');
else
    mainFigHandle = src;
    
end
backgroundOffsetRadius = getappdata(mainFigHandle,'backgroundOffsetRadius');
backgroundOffsetRadius = backgroundOffsetRadius + increaseModifier*0.5;
setappdata(mainFigHandle,'backgroundOffsetRadius',backgroundOffsetRadius);

try
    screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
catch ME4
end
offsetRadiusSlider_Callback(mainFigHandle,[]);



function     decreaseBackgroundOffset(src,decreaseModifier);
if isappdata(src,'mainFigHandle')
    mainFigHandle = getappdata(src,'mainFigHandle');
else
    mainFigHandle = src;
end
backgroundOffsetRadius = getappdata(mainFigHandle,'backgroundOffsetRadius');
backgroundOffsetRadius = backgroundOffsetRadius - decreaseModifier*0.5;
if backgroundOffsetRadius<1
    backgroundOffsetRadius = 1;
end
setappdata(mainFigHandle,'backgroundOffsetRadius',backgroundOffsetRadius);

try
    screenIndividualRegions(getappdata(mainFigHandle,'singleCellWindowHand'),[]);
catch ME4
end
offsetRadiusSlider_Callback(mainFigHandle,[]);


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


function closeIndividualView(src,eventdata,varargin)
try
    figHandle = getappdata(src,'mainFigHandle');
    contourHandles = getappdata(figHandle,'contourHandles');
    kObj = getappdata(src,'kObj');
    dispColor = getappdata(figHandle,'dispColor');
    
    % highlight in main figure
    if size(contourHandles,2)==3
        columnsToSet = [1,3,4,5,6];
    else
        columnsToSet = 1;
    end
    
    
    if contourHandles(kObj,2)==0
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.outline);
    elseif contourHandles(kObj,2)==1
        set(contourHandles(kObj,columnsToSet),'Color',dispColor.select);
    end
catch ME
    warning('morphometrics:extractIntensities:closeError','Error closing individual view. Closing harder.');
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




function updateZoomByImrect(figHandle);
rectMark = getappdata(figHandle,'rectMark');
positionOfRect = getPosition(rectMark);
mainAxes = findobj(figHandle,'Tag','Axes.Main');
xlimits = [positionOfRect(1),positionOfRect(1)+positionOfRect(3)];
xlimits = sort(xlimits);
ylimits = [positionOfRect(2),positionOfRect(2)+positionOfRect(4)];
ylimits = sort(ylimits);
set(mainAxes,'Xlim',xlimits,'Ylim',ylimits);

function [xContNew,yContNew] = offsetContour(xCont,yCont,offsetSize);
% take the coordinates of the contour and offset 'normal' by a fixed amount
%% add beginning and end to make it wrap around correctly
xContWrap = cat(1,xCont(end),xCont,xCont(1));
yContWrap = cat(1,yCont(end),yCont,yCont(1));

% distance between two subsequent points
yContDiff = (yContWrap(3:end)-yContWrap(1:end-2));
xContDiff = (xContWrap(3:end)-xContWrap(1:end-2));

% calculate angle and add 90 degrees
normalDirection = atan2(yContDiff,xContDiff)-pi/2;

xContNew = xCont+cos(normalDirection).*offsetSize;
yContNew = yCont+sin(normalDirection).*offsetSize;

function updateContourDisplay(mainFigHandle)

% retrieve stored data
storedFrame = getappdata(mainFigHandle,'storedFrame');
storedMask = getappdata(mainFigHandle,'storedMask');
contourHandles = getappdata(mainFigHandle,'contourHandles');
jFrame = getappdata(mainFigHandle,'jFrame');
nRowsImage = getappdata(mainFigHandle,'nRowsImage');
nColsImage = getappdata(mainFigHandle,'nColsImage');
backgroundOffsetRadius = getappdata(mainFigHandle,'backgroundOffsetRadius');

% global offset
kkColorChannel = getappdata(mainFigHandle,'kkColorChannel');
xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');

if numel(xOffsetsPerColor)<kkColorChannel
    xOffsetsPerColor(kkColorChannel)=0;
    yOffsetsPerColor(kkColorChannel)=0;
    setappdata(mainFigHandle,'xOffsetsPerColor',xOffsetsPerColor);
    setappdata(mainFigHandle,'yOffsetsPerColor',yOffsetsPerColor);
    
end
% determine if there are pillMeshes to display
isPillMesh = isfield(storedFrame.object(1),'pill_mesh');
isSpineRibs = isfield(storedFrame.object(1),'spine');

% draw contours
nObjects = size(storedFrame(jFrame).object,2);
for kObj = 1:nObjects
    % in lineaged samples, sometimes an object exists even when it is
    % empty. That is, if a cell of ID jj exists in frames ii and ii+2,
    % there may be an empty contour in frame ii+1
    if not(isempty(storedFrame(jFrame).object(kObj).Xcont))
        
        % close contours
        XcontTemp = storedFrame(jFrame).object(kObj).Xcont;
        YcontTemp = storedFrame(jFrame).object(kObj).Ycont;
        
        XcontTemp = [XcontTemp;XcontTemp(1)]+xOffsetsPerColor(kkColorChannel);
        YcontTemp = [YcontTemp;YcontTemp(1)]+yOffsetsPerColor(kkColorChannel);
        
        % make sure it fits in image
        XcontTemp = max(XcontTemp,1);
        XcontTemp = min(XcontTemp,nColsImage);
        
        YcontTemp = max(YcontTemp,1);
        YcontTemp = min(YcontTemp,nRowsImage);
        
        
        
        % update the xy positions, don't make a new object
        set(contourHandles(kObj,1),'xdata',XcontTemp,'ydata',YcontTemp);
        set(contourHandles(kObj,4) ,'xdata',XcontTemp(1),'ydata',YcontTemp(1));
        
        
        % update the mask??
        outlineX = XcontTemp;
        outlineY = YcontTemp;
        outlineX = round(interp(outlineX,2));
        outlineY = round(interp(outlineY,2));
        outlineIdx = sub2ind([nRowsImage,nColsImage],outlineY,outlineX);
        storedMask(outlineIdx) = kObj;
        
    else
    end
    
    if isSpineRibs
        if not(isnan(storedFrame(jFrame).object(kObj).spine))
            set(contourHandles(kObj,3),'xdata',storedFrame(jFrame).object(kObj).spine(:,1)+xOffsetsPerColor(kkColorChannel),...
                'ydata',storedFrame(jFrame).object(kObj).spine(:,2)+yOffsetsPerColor(kkColorChannel));
        else
        end
    elseif isPillMesh
        if not(isempty(storedFrame(jFrame).object(kObj).centerline))
            set(contourHandles(kObj,3),'xdata',storedFrame(jFrame).object(kObj).centerline(:,1)+xOffsetsPerColor(kkColorChannel),...
                'ydata',storedFrame(jFrame).object(kObj).centerline(:,2)+yOffsetsPerColor(kkColorChannel));
        else
        end
    else
    end
    
    % background regions should also move offsets
    XcontTemp = storedFrame(jFrame).object(kObj).Xcont+xOffsetsPerColor(kkColorChannel);
    YcontTemp = storedFrame(jFrame).object(kObj).Ycont+yOffsetsPerColor(kkColorChannel);
    
    
    
    try
        [XcontOffset,YcontOffset] = offsetContour(XcontTemp,YcontTemp,backgroundOffsetRadius);
        
        % make sure it fits in image
        XcontOffset = max(XcontOffset,1);
        XcontOffset = min(XcontOffset,nColsImage);
        
        YcontOffset = max(YcontOffset,1);
        YcontOffset = min(YcontOffset,nRowsImage);
        
        XcontOffset = [XcontOffset;XcontOffset(1)];
        YcontOffset = [YcontOffset;YcontOffset(1)];
    catch ME2
        XcontOffset = nan;
        YcontOffset = nan;
        
    end
    
    
    set(contourHandles(kObj,5),'xdata',XcontOffset,'ydata',YcontOffset);
    set(contourHandles(kObj,6),'xdata',XcontOffset(1),'ydata',YcontOffset(1));
    
    
end

setappdata(mainFigHandle,'storedMask',storedMask);


