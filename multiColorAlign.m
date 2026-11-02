function multiColorAlign
% this function is an accessory to morphometrics and allows users to
% calculate the background subtracted intensity in accessory channels
% Release notes:
% 20190619 Initial release (forked and refactored from extractIntensities
% 0.1.15)
% % 20190128 Initial release (forked and refactored from deleteContours 0.3.7
% 20190213 Include support for new axes toolbars (R2018a and later) instead
% of figure toolbars

% define cell as a variable. It will be overwritten when the mat file is
% loaded. Otherwise the compiler treats the later call to "cell" as a
% reference to the function named cell

%%

if verLessThan('MATLAB','9.4')
    currentVersionString = ver('MATLAB');
    warning('multiColorAlign:LegacyMode',...
        ['Current version of MATLAB (',currentVersionString.Version,...
        ') is less than expected (9.4). ',...
        'Some functionality may not be supported. ',...
        'Enabling legacy mode and silencing this warning.']);
    warning('off','multiColorAlign:LegacyMode');
    
end
%%

cell = [];
fileNames = {};
pathNames = {};


fileNames = uipickfiles('Prompt','Please select all image files of interest');

iiFile = 1;
jFrame = 1;


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
figHandle = figure('Tag','multiColorAlignMainFigure');
setappdata(figHandle,'versionTag','0.1.2');
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


% buttons to select channels
indicatorHandles.channel1Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',1,'tag','channel1Button',...
    'ButtonDownFcn',{@channelButton_Callback,1},...
    'Callback',{@channelButton_Callback,1},'String','1','FontSize',14,...
    'FontWeight','Bold');



indicatorHandles.channel2Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXOffsetSpacing,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel2Button',...
    'ButtonDownFcn',{@channelButton_Callback,2},...
    'Callback',{@channelButton_Callback,2},'String','2','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel3Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+2*channelButtonXOffsetSpacing,channelButtonYStart+2*channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel3Button',...
    'ButtonDownFcn',{@channelButton_Callback,3},...
    'Callback',{@channelButton_Callback,3},'String','3','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel4Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel4Button',...
    'ButtonDownFcn',{@channelButton_Callback,4},...
    'Callback',{@channelButton_Callback,4},'String','4','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel5Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXOffsetSpacing,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel5Button',...
    'ButtonDownFcn',{@channelButton_Callback,5},...
    'Callback',{@channelButton_Callback,5},'String','5','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channel6Button = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+2*channelButtonXOffsetSpacing,channelButtonYStart+channelButtonYOffsetSpacing,channelButtonXSize,channelButtonYSize],...
    'min',0,'max',1,'value',0,'tag','channel6Button',...
    'ButtonDownFcn',{@channelButton_Callback,6},...
    'Callback',{@channelButton_Callback,6},'String','6','FontSize',14,...
    'FontWeight','Bold');

totalIndicatorWidth = 2*channelButtonXOffsetSpacing + channelButtonXSize;
indicatorHandles.channelNButton = uicontrol(figHandle,'Style','ToggleButton',...
    'units','normalized',...
    'position',[indicatorXStart+channelButtonXSize,channelButtonYStart,...
    totalIndicatorWidth - 2*channelButtonXSize,channelButtonYSize],... % x size should go to end of the buttons of the same style
    'min',0,'max',1,'value',0,'tag','channelNButton',...
    'ButtonDownFcn',{@channelButton_Callback,-1},...
    'Callback',{@channelButton_Callback,-1},'String','n = ','FontSize',14,...
    'FontWeight','Bold');

indicatorHandles.channelLabelText = uicontrol(figHandle,'Style','Text',...
    'units','normalized',...
    'position',[indicatorXStart,channelButtonYStart+3*channelButtonYOffsetSpacing,...
    2*channelButtonXOffsetSpacing + channelButtonXSize,channelButtonYSize],...
    'string','channel','FontSize',12,'tag','radiusOffsetText');


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

p = uitoggletool(toolbarHandle,'TooltipString','Adjust contrast',...
    'ClickedCallback',{@adjustContrast},'tag','Toolbar.AdjustContrast');

% Read an image
% deal with a path setting where the icon is unavailable
filePathToMultiColorAlign = which('multiColorAlign');
[filePathToMultiColorAlign,~] = fileparts(filePathToMultiColorAlign);
[icon] = imread(fullfile(filePathToMultiColorAlign,'icons','grayContrast.png'));

% Set the button icon
set(p,'CData',icon);
% % 
% % p2 = uitoggletool(toolbarHandle,'TooltipString','Screen individual regions?',...
% %     'ClickedCallback',    {@screenIndividualRegions},'tag','Toolbar.IndividualRegions');
% % 
% % % deal with a path setting where the icon is unavailable
% % filePathToMultiColorAlign = which('multiColorAlign');
% % [filePathToMultiColorAlign,~] = fileparts(filePathToMultiColorAlign);
% % [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','screenIndividualRegions.png'));
% % 
% % % Set the button icon
% % set(p2,'CData',icon);
% % 
% % p3 = uitoggletool(toolbarHandle,'TooltipString','Display contour break point',...
% %     'ClickedCallback',{@toggleDisplayContourBreak},'tag','Toolbar.ContourBreak');
% % 
% % setappdata(figHandle,'displayContourBreak',false);
% % 
% % % deal with a path setting where the icon is unavailable
% % filePathToMultiColorAlign = which('multiColorAlign');
% % [filePathToMultiColorAlign,~] = fileparts(filePathToMultiColorAlign);
% % [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','displayContourBreakOff.png'));
% % 
% % % Set the button icon
% % set(p3,'CData',icon);

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

save2 = uipushtool(toolbarHandle,'TooltipString','Save aligned image',...
    'ClickedCallback',{@saveAlignedImage},...
    'Tag','SaveAlignedImage',...
    'CData',get(saveHand,'CData'));

% store some initialized variables
setappdata(figHandle,'xOffsetsPerColor',zeros(1,7));
setappdata(figHandle,'yOffsetsPerColor',zeros(1,7));
setappdata(figHandle,'iiFile',1);
setappdata(figHandle,'jFrame',1);
setappdata(figHandle,'pathNames',pathNames);
setappdata(figHandle,'fileNames',fileNames);
% setappdata(figHandle,'storedFrame',frame);
setappdata(figHandle,'filePathToMultiColorAlign',filePathToMultiColorAlign);
% storedCell = cell;
% setappdata(figHandle,'storedCell',storedCell);

% default colors
dispColor.outline = 'green';
dispColor.selected = 'red';
dispColor.highlight = 'blue';
dispColor.overview = [255,165,0]/255;
dispColor.buttonText = get(indicatorHandles.channel1Button,'ForegroundColor');

% default line styles
dispStyle.contour = '-';
dispStyle.background = ':';


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
showImageFirstTime(figHandle);

% --------------------------------------------------------------------
function saveAlignedImage(figureHand,varargin);
if isa(figureHand,'matlab.ui.container.toolbar.PushTool')
    figureHand = get(get(figureHand,'parent'),'parent');
end
indicatorHandles = getappdata(figureHand,'indicatorHandles');
xyLambdaStack = getappdata(figureHand,'baseHyperStack');
xyLambdaStack = squeeze(xyLambdaStack(:,:,1,:));

displayRanges = getappdata(figureHand,'displayRanges');
% anonymous function to simplify repetitive code
normalizeChannel = @(tImage,iChannel) (tImage - displayRanges{iChannel}(1))./...
    (diff(displayRanges{iChannel}));

% get spatial offsets
xOffsets = getappdata(figureHand,'xOffsetsPerColor');
yOffsets = getappdata(figureHand,'yOffsetsPerColor');

% loop over all color channels and build up a colorized image using the
% current color mapping and display range
totalAlignedImage = [];
for iiChannel = 1:size(xyLambdaStack,3)
    tempImage = squeeze(xyLambdaStack(:,:,iiChannel));
    tempImage = normalizeChannel(tempImage,iiChannel);
    fixedPoints = randn(5,2);
    movingPoints = bsxfun(@minus, fixedPoints, [xOffsets(iiChannel),yOffsets(iiChannel)]);
    tform = fitgeotrans(movingPoints,fixedPoints,'affine');
    tempImage = imwarp(tempImage,tform,'OutputView',imref2d(size(tempImage)));
    switch iiChannel
        case {1}
            if get(indicatorHandles.channel1Button,'value');
               totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        case {2}
            if get(indicatorHandles.channel2Button,'value');
               totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        case {3}
            if get(indicatorHandles.channel3Button,'value');
               totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        case {4}
            if get(indicatorHandles.channel4Button,'value');
              totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        case {5}
            if get(indicatorHandles.channel5Button,'value');
              totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        case {6}
            if get(indicatorHandles.channel6Button,'value');
          totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
        otherwise
            if get(indicatorHandles.channelNButton,'value');
         totalAlignedImage = cat(3,totalAlignedImage,tempImage);
            end
    end
    
end

% parse file name for output
fileNames = getappdata(figureHand,'fileNames');
iiFile = getappdata(figureHand,'iiFile');

newTifName = strrep(fileNames{iiFile},'.nd2','_realigned.tif');

if strcmp(fileNames{iiFile},newTifName)
newTifName = strrep(fileNames{iiFile},'.tif','_realigned.tif');
end

if strcmp(fileNames{iiFile},newTifName)
   error('morphometrics:multiColorAlign:notNewFile',['Saving file would overwrite original file (',...
       fileNames{iiFile},'). Please contact the developer.' ]);
end
versionTag = getappdata(figureHand,'versionTag');
tiffwrite(newTifName,totalAlignedImage,['multiColorAlign_',versionTag,...
    '; xOffsets ',num2str(xOffsets),'; yOffsets ',num2str(yOffsets)]);
% 
% for ii = 1:size(totalAlignedImage,3);
%    imwrite(uint8(255*(totalAlignedImage(:,:,ii))),strrep(newTifName,'.tif',[num2str(ii),'.tif']),'compression','none')
% end
% --------------------------------------------------------------------
function adjustContrast(figureHand,varargin)

if isa(figureHand,'matlab.ui.container.toolbar.ToggleTool')
    figureHand = get(get(figureHand,'parent'),'parent');
end

% display the base image, calculate the display image;
baseImg = getappdata(figureHand,'baseHyperStack');
activeChannel = getappdata(figureHand,'activeChannel');
displayRanges = getappdata(figureHand,'displayRanges');
try
baseImg = squeeze(baseImg(:,:,1,activeChannel));
catch ME
    warning('morphometrics:multiColorAlign:no_channel',...
        ['No data in selected channel (',num2str(activeChannel),').']);
    return
end
tempFigHand = figure();
imshowHand = imshow(baseImg,displayRanges{activeChannel});
contrastWindow = imcontrast(get(imshowHand,'Parent'));
waitfor(contrastWindow);
newContrast = getDisplayRange(getimagemodel(imshowHand));

displayRanges(activeChannel) = {newContrast};
setappdata(figureHand,'displayRanges',displayRanges);
close(tempFigHand);
colorizeImage(figureHand);

function autoContrast(figureHand)
% display the base image, calculate the display image;
baseImg = getappdata(figureHand,'baseHyperStack');
activeChannel = getappdata(figureHand,'activeChannel');
displayRanges = getappdata(figureHand,'displayRanges');
try
baseImg = squeeze(baseImg(:,:,1,activeChannel));
catch ME
    warning('morphometrics:multiColorAlign:no_channel',...
        ['No data in selected channel (',num2str(activeChannel),').']);
    return
end

displayRanges(activeChannel) = {[min(baseImg(:)),max(baseImg(:))]};
setappdata(figureHand,'displayRanges',displayRanges);

colorizeImage(figureHand);



function channelButton_Callback(h,evd,channelID)
switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
    otherwise
        mainFigHandle = h;
end

switch get(mainFigHandle,'SelectionType')
    case 'alt' % toggle selected channel
        activateChannel(mainFigHandle,channelID);

    otherwise % toggle channel display
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        colorizeImage(mainFigHandle);
end
        




function xOffsetSlider_Callback(h,evd);
switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
        % update the value
        xOffsetVal = get(h,'Value');
        xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
        xOffsetsPerColor(getappdata(mainFigHandle,'activeChannel'))=...
            xOffsetVal;
        setappdata(mainFigHandle,'xOffsetsPerColor',xOffsetsPerColor);
        % store the value at the indicator
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        set(indicatorHandles.xOffsetText,'String', ['x offset: ',num2str(xOffsetVal,'%4.2g')]);
        colorizeImage(mainFigHandle);

    otherwise
        mainFigHandle = h;
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        xOffsetsPerColor = getappdata(mainFigHandle,'xOffsetsPerColor');
        xOffsetVal = xOffsetsPerColor(getappdata(mainFigHandle,'activeChannel'));
        set(indicatorHandles.xOffsetText,'String', ['x offset: ',num2str(xOffsetVal,'%4.2g')]);
        set(indicatorHandles.xOffsetSlider,'value', xOffsetVal);
        colorizeImage(mainFigHandle);

end



function yOffsetSlider_Callback(h,evd);

switch class(h)
    case 'matlab.ui.control.UIControl'
        % grab the main figure
        mainFigHandle = get(h,'Parent');
        % update the value
        yOffsetVal = get(h,'Value');
        yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');
        yOffsetsPerColor(getappdata(mainFigHandle,'activeChannel'))=...
            yOffsetVal;
        setappdata(mainFigHandle,'yOffsetsPerColor',yOffsetsPerColor);
        % store the value at the indicator
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        set(indicatorHandles.yOffsetText,'String', ['y offset: ',num2str(yOffsetVal,'%4.2g')]);
        colorizeImage(mainFigHandle);
        
    otherwise
        mainFigHandle = h;
        indicatorHandles = getappdata(mainFigHandle,'indicatorHandles');
        
        yOffsetsPerColor = getappdata(mainFigHandle,'yOffsetsPerColor');
        yOffsetVal = yOffsetsPerColor(getappdata(mainFigHandle,'activeChannel'));
        set(indicatorHandles.yOffsetText,'String', ['y offset: ',num2str(yOffsetVal,'%4.2g')]);
        set(indicatorHandles.yOffsetSlider,'value', yOffsetVal);
        colorizeImage(mainFigHandle);
        
        
end


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
        warning('morphometrics:multiColorAlign:unknownCursorMode','Unknown cursor mode.');
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
        end
end


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
        displayHelpScreen();
    case {'L','l'}
        adjustContrast(src);
    case {'K','k'}
        autoContrast(src);
    case {'1'};
        activateChannel(src,1);
    case {'2'};
         activateChannel(src,2);
    case {'3'};
         activateChannel(src,3);
    case {'4'};
         activateChannel(src,4);
    case {'5'};
         activateChannel(src,5);
    case {'6'};
         activateChannel(src,6);
    case {'7'};
         activateChannel(src,7);
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
        globalXYOffsets(src,'x',-bigStep)
    case {'D','d'}
        globalXYOffsets(src,'x',bigStep)
    case {'S','s'}
        globalXYOffsets(src,'y',bigStep)
    case {'W','w'}
        globalXYOffsets(src,'y',-bigStep)
    otherwise
end

function   globalXYOffsets(src,dimension,stepSize)
% poll the indicators for their min/max
indicatorHandles = getappdata(src,'indicatorHandles');
activeChannel = getappdata(src,'activeChannel');

switch dimension
    case 'x'
        minVal = get(indicatorHandles.xOffsetSlider,'Min');
        maxVal = get(indicatorHandles.xOffsetSlider,'Max');
        currentVal = get(indicatorHandles.xOffsetSlider,'Value');
        updatedVal = min(currentVal+stepSize,maxVal);
        updatedVal = max(updatedVal,minVal);
        xOffsets = getappdata(src,'xOffsetsPerColor');
        xOffsets(activeChannel) = updatedVal;
        setappdata(src,'xOffsetsPerColor',xOffsets);
        xOffsetSlider_Callback(src,[]);
    case 'y'
        minVal = get(indicatorHandles.yOffsetSlider,'Min');
        maxVal = get(indicatorHandles.yOffsetSlider,'Max');
        currentVal = get(indicatorHandles.yOffsetSlider,'Value');
        updatedVal = min(currentVal+stepSize,maxVal);
        updatedVal = max(updatedVal,minVal);
        yOffsets = getappdata(src,'yOffsetsPerColor');
        yOffsets(activeChannel) = updatedVal;
        setappdata(src,'yOffsetsPerColor',yOffsets);
        yOffsetSlider_Callback(src,[]);
    otherwise
end


function  displayHelpScreen()
% write out a text document
helpPath = fullfile(tempdir,'multiColorAlignHelp.txt');
fidA = fopen(helpPath,'w+');
fprintf(fidA,'Welcome to ''multiColorAlign Help!''\r\n');
fprintf(fidA,'\r\n');
fprintf(fidA,'Key press combinations:\r\n');
fprintf(fidA,'F1 OR f1: open this help screen\r\n');
fprintf(fidA,'right arrow: move to next file\r\n');
fprintf(fidA,'left arrow: move to prev file\r\n');
fprintf(fidA,'ctrl-s: save results (may not work on PC)\r\n');
fprintf(fidA,'ctrl-a OR cmd-a: select/deselect all\r\n');
fprintf(fidA,'c: enable pan mode\r\n');
fprintf(fidA,'alt-c: disable pan mode, only works when ''c'' enabled pan\r\n');
fprintf(fidA,'z: enable zoom in mode\r\n');
fprintf(fidA,'shift-z: enable zoom out mode\r\n');
fprintf(fidA,'alt-z: disable zoom mode, only works when ''z'' enabled zoom\r\n');

fprintf(fidA,'\r\nKnown issues:\r\n');
fprintf(fidA,['+ Sometimes warning of ''Cannot access method ''ActionData'' in class ''matlab.ui.eventdata.ActionData''',...
    ' occurs when loading a file.\r\n']);
% find the main gui
mainFigHandle = findall(groot,'tag','multiColorAlignMainFigure');

versionTag = getappdata(mainFigHandle(1),'versionTag');
fprintf(fidA,['\r\nmultiColorAlign Version: ',versionTag,'\r\n']);

% display the contents of the text document
f = popupmessage(helpPath,'Help for multiColorAlign');
textboxHand = findall(f,'tag','textbox');
set(textboxHand,'fontsize',14);
% delete the text document
delete(helpPath);


function displayCurrentImage(figureHand)



% % % %
% % %
% % % cla(axesHand);
% % % imshowHand = imshow(colorizedImage,[],'Parent',axesHand,'initialMagnification','Fit');
% % % setappdata(figureHand,'imshowHand',imshowHand);
% % %
% % % setappdata(figureHand,'activeChannel',1);
% % %
% % % adjustContrast(figureHand);
% % % colorizeImage(figureHand,initialHyperStack);
% % %

function activateChannel(figureHand,activeChannel);
% grab data from the parent figure
indicatorHandles = getappdata(figureHand,'indicatorHandles');
dispColor = getappdata(figureHand,'dispColor');
colorCoeffs = getappdata(figureHand,'colorCoeffs');

% turn all buttons back to their default
set(indicatorHandles.channel1Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channel2Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channel3Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channel4Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channel5Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channel6Button,'ForegroundColor',dispColor.buttonText);
set(indicatorHandles.channelNButton,'ForegroundColor',dispColor.buttonText);

setappdata(figureHand,'activeChannel',activeChannel);
switch activeChannel
    case 1
        set(indicatorHandles.channel1Button,'ForegroundColor',colorCoeffs(activeChannel,:));
    case 2
        set(indicatorHandles.channel2Button,'ForegroundColor',colorCoeffs(activeChannel,:));

    case 3
        set(indicatorHandles.channel3Button,'ForegroundColor',colorCoeffs(activeChannel,:));

    case 4
        set(indicatorHandles.channel4Button,'ForegroundColor',colorCoeffs(activeChannel,:));

    case 5
        set(indicatorHandles.channel5Button,'ForegroundColor',colorCoeffs(activeChannel,:));

    case 6
        set(indicatorHandles.channel6Button,'ForegroundColor',colorCoeffs(activeChannel,:));

    case 7
        set(indicatorHandles.channelNButton,'ForegroundColor',colorCoeffs(activeChannel,:));

end
% update sliders to display the current offset
xOffsets = getappdata(figureHand,'xOffsetsPerColor');
set(indicatorHandles.xOffsetSlider,'Value',xOffsets(activeChannel));
set(indicatorHandles.xOffsetText,'String',['x offset: ',num2str(xOffsets(activeChannel),'%4.2g')]);
set(indicatorHandles.xOffsetText,'ForegroundColor',colorCoeffs(activeChannel,:));

xOffsets = getappdata(figureHand,'yOffsetsPerColor');
set(indicatorHandles.yOffsetSlider,'Value',xOffsets(activeChannel));
set(indicatorHandles.yOffsetText,'String',['y offset: ',num2str(xOffsets(activeChannel),'%4.2g')]);
set(indicatorHandles.yOffsetText,'ForegroundColor',colorCoeffs(activeChannel,:));




    function loadNewND2File(figureHand)
        % get stored data values
        nd2FileNames = getappdata(figureHand,'fileNames');
        
        iiFile = getappdata(figureHand,'iiFile');
        
        [fileParent,fileName,ext] = fileparts(nd2FileNames{iiFile});
        switch ext
            case 'nd2'
                % need to load the image
                tempBFread = bfopen(nd2FileNames{iiFile});
                hyperStackTotal = [];
                % read all the series
                for jjSeriesIndex = 1:size(tempBFread,1)
                    if jjSeriesIndex < 0
                        % sometimes the ND2 file is saved in a 'flat' format instead of as a rectangular hyperstack
                    else
                        [iSeries,nSeries,iPlane,nPlanes,iColor,nColors,iTime,nTimes,stackString,iZ,nZs] =...
                            parseND2label(tempBFread{jjSeriesIndex,1}{1,2});
                        
                        % dimension 1-2 xy
                        % dimension 3 z
                        % dimension 4 color/lambda
                        % dimension 5 time
                        % dimension 6 is multi-point xy
                        
                        nRows = size(tempBFread{jjSeriesIndex,1}{1,1},1);
                        nCols = size(tempBFread{jjSeriesIndex,1}{1,1},2);
                        hyperStack1 = nan(nRows,nCols,nZs,nColors,nTimes);
                        
                        for jjPlane = 1:size(tempBFread{1,1},1)
                            % partition out the planes into the appropriate hyperstack
                            [iSeries,nSeries,iPlane,nPlanes,iColor,nColors,iTime,nTimes,stackString,iZ,nZs] =...
                                parseND2label(tempBFread{jjSeriesIndex,1}{jjPlane,2});
                            try
                                hyperStack1(:,:,iZ,iColor,iTime) = double(tempBFread{jjSeriesIndex,1}{jjPlane,1});
                            catch ME
                                error('multiColorAlign:nd2Format:non_rectangular_hyperstack',...
                                    'Error loading file. ND2 file may contain a non-rectangular hyperstack. Please contact the developer for assistance.')
                            end
                        end
                    end
                    
                    % at the end of this loop, we need store the hyperstack of images
                    hyperStackTotal = cat(6,hyperStackTotal,hyperStack1);
                end
                %
                %
                % cell=[];
                % load(fullfile(pathNames{iiFile},nd2FileNames{iiFile}));
                % iiFile = getappdata(figureHand,'iiFile');
                %
                % storedFrame = frame;
                % storedCell = cell;
                % setappdata(figureHand,'storedFrame',storedFrame);
                % setappdata(figureHand,'storedCell',storedCell);
                %
                % tifFileNameList = findCompanionTifFile(pathNames{iiFile},nd2FileNames{iiFile});
                % setappdata(figureHand,'tifFileNameList',tifFileNameList);
                
                % throw warnings if this is a complicated nd2 file
                % dimension 1-2 xy
                % dimension 3 z
                % dimension 4 color/lambda
                % dimension 5 time
                % dimension 6 is multi-point xy
                
                
                % how many zPlanes are there?
                if size(hyperStackTotal,3)>1
                    warning('multiColorAlign:multipleZPlanes:maxProject','Multiple z-planes detected. Using max project along z.');
                    hyperStackTotal = max(hyperStackTotal,[],3);
                end
                
                % how many times t are there?
                if size(hyperStackTotal,5)>1
                    warning('multiColorAlign:multipleTimes:maxProject','Multiple times detected. Using max project along t.');
                    hyperStackTotal = max(hyperStackTotal,[],5);
                end
                
                % how many color channels?
                nChannels = size(hyperStackTotal,4);
                
                % how many fields of view are there?
                nFields = size(hyperStackTotal,6);
                if nFields>1
                    warning('multiColorAlign:multipleFields:viewFirstOnly','Multiple fields of view detected. Only displaying the first.');
                    hyperStackTotal = hyperStackTotal(:,:,:,:,:,1);
                end
                
                
            case '.tif'
                tifFileInfo = imfinfo(nd2FileNames{iiFile});
                for kkPlane = 1:size(tifFileInfo)
                    hyperStackTotal(:,:,1,kkPlane) = double(imread(nd2FileNames{iiFile},'index',kkPlane,'info',tifFileInfo));
                end
                nChannels = size(hyperStackTotal,4);
                warning('morphometrics:multiColorAlign:tifFileHyperstack','Tif file hyperstacks are not yet supported, assuming lambda only.');
        end
        
        
        setappdata(figureHand,'baseHyperStack',hyperStackTotal);
% turn off buttons that don't apply
                indicatorHandles = getappdata(figureHand,'indicatorHandles');
                
                set(indicatorHandles.channel1Button,'value',1);
                
                
                if nChannels < 2
                    set(indicatorHandles.channel2Button,'visible','off');
                    set(indicatorHandles.channel2Button,'value',0);
                else
                    set(indicatorHandles.channel2Button,'value',1);
                    
                end
                
                if nChannels < 3
                    set(indicatorHandles.channel3Button,'visible','off');
                    set(indicatorHandles.channel3Button,'value',0);
                else
                    set(indicatorHandles.channel3Button,'value',1);
                end
                
                if nChannels < 4
                    set(indicatorHandles.channel4Button,'visible','off');
                    set(indicatorHandles.channel4Button,'value',0);
                else
                    set(indicatorHandles.channel4Button,'value',1);
                end
                
                if nChannels < 5
                    set(indicatorHandles.channel5Button,'visible','off');
                    set(indicatorHandles.channel5Button,'value',0);
                else
                    set(indicatorHandles.channel5Button,'value',1);
                end
                
                if nChannels < 6
                    set(indicatorHandles.channel6Button,'visible','off');
                    set(indicatorHandles.channel6Button,'value',0);
                else
                    set(indicatorHandles.channel6Button,'value',1);
                end
                
                if nChannels < 7
                    set(indicatorHandles.channelNButton,'visible','off');
                    set(indicatorHandles.channelNButton,'value',0);
                else
                    set(indicatorHandles.channeN2Button,'value',1);
                end




function updateImageNotFirstTime(figureHand)
axesHand = getappdata(figureHand,'axesHand');
activeChannel = getappdata(figureHand,'activeChannel');
currentImage = getappdata(figureHand,'currentImage');
imshowHand = getappdata(figureHand,'imshowHand');
set(imshowHand,'cdata',currentImage);

function calculateColorCoeffs(figureHand);
%%
baseHyperStack = getappdata(figureHand,'baseHyperStack');
nColors = size(baseHyperStack,4);
%%
HUE_OFFSET = 0;
% build up colors that go around the color wheel
hList = mod(linspace(0,1,nColors+1)+HUE_OFFSET,1);
hList(end) = [];
sList = 0.8.*ones(1,nColors);
vList = 0.8.*ones(1,nColors);
colorCoeffs = hsv2rgb(cat(2,hList',sList',vList'));
setappdata(figureHand,'colorCoeffs',colorCoeffs);

function colorizeImage(figureHand,xyLambdaStack);
if nargin<2
    xyLambdaStack = getappdata(figureHand,'baseHyperStack');
    xyLambdaStack = squeeze(xyLambdaStack(:,:,1,:));
end
colorizedImage = zeros(size(xyLambdaStack,1),size(xyLambdaStack,2),3);
displayRanges = getappdata(figureHand,'displayRanges');
colorCoeffs = getappdata(figureHand,'colorCoeffs');
indicatorHandles = getappdata(figureHand,'indicatorHandles');
imshowHand = getappdata(figureHand,'imshowHand');
imshowHand2 = getappdata(figureHand,'imshowHand2');

% anonymous function to simplify repetitive code
normalizeChannel = @(tImage,iChannel) (tImage - displayRanges{iChannel}(1))./...
    (diff(displayRanges{iChannel}));

% preallocate to be ready
tempColorizedImage = colorizedImage;
% get spatial offsets
xOffsets = getappdata(figureHand,'xOffsetsPerColor');
yOffsets = getappdata(figureHand,'yOffsetsPerColor');

% loop over all color channels and build up a colorized image using the
% current color mapping and display range
for iiChannel = 1:size(xyLambdaStack,3)
    % put on a 0 to 1 basis
    tempImage = squeeze(xyLambdaStack(:,:,iiChannel));
    tempImage = normalizeChannel(tempImage,iiChannel);
    tempImage(tempImage<0) = 0;
    tempImage(tempImage>1) = 1;
    fixedPoints = randn(5,2);
    movingPoints = bsxfun(@minus, fixedPoints, [xOffsets(iiChannel),yOffsets(iiChannel)]);
    tform = fitgeotrans(movingPoints,fixedPoints,'affine');
    tempImage = imwarp(tempImage,tform,'OutputView',imref2d(size(tempImage)));
%     tempImage = imtranlate(tempImage,[xOffsets(iiChannel),yOffsets(iiChannel)],...
%         'cubic','FillValues',median(tempImage(:)));

    switch iiChannel
        case {1}
            if get(indicatorHandles.channel1Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        case {2}
            if get(indicatorHandles.channel2Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        case {3}
            if get(indicatorHandles.channel3Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        case {4}
            if get(indicatorHandles.channel4Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        case {5}
            if get(indicatorHandles.channel5Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        case {6}
            if get(indicatorHandles.channel6Button,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
        otherwise
            if get(indicatorHandles.channelNButton,'value');
                for iiRGB = 1:3
                    tempColorizedImage(:,:,iiRGB) = tempImage.*colorCoeffs(iiChannel,iiRGB);
                end
                colorizedImage = colorizedImage+tempColorizedImage;
            end
    end
    
end

% update to new rendering
set(imshowHand,'cdata',colorizedImage);
set(imshowHand2,'cdata',colorizedImage);


function showImageFirstTime(figureHand)
% grab data from the main figure
axesHand = getappdata(figureHand,'axesHand');
indicatorHandles = getappdata(figureHand,'indicatorHandles');
dispColor = getappdata(figureHand,'dispColor');

% parse file name
iiFile = getappdata(figureHand,'iiFile');
fileNames = getappdata(figureHand,'fileNames');

currentFileName = fileNames{iiFile};

[folderName, fileName] = fileparts(currentFileName);
[gparentname,folderName] = fileparts(folderName);
set(indicatorHandles.fileText,'String',[folderName,filesep,fileName]);
set(indicatorHandles.folderText,'String',[gparentname]);

loadNewND2File(figureHand);
baseHyperStack = getappdata(figureHand,'baseHyperStack');

%
initialHyperStack = squeeze(baseHyperStack(:,:,1,:));

for iiChannel = 1:size(initialHyperStack,3);
    displayRanges{iiChannel} = [min(min(initialHyperStack(:,:,iiChannel))),max(max(initialHyperStack(:,:,iiChannel)))];
end
setappdata(figureHand,'displayRanges',displayRanges);

calculateColorCoeffs(figureHand);

cla(axesHand);

imshowHand = imshow(rand(size(initialHyperStack,1),size(initialHyperStack,2),3),...
    [],'Parent',axesHand,'initialMagnification','Fit');
setappdata(figureHand,'imshowHand',imshowHand);


xlim(axesHand,[1, size(initialHyperStack,2)]);
ylim(axesHand,[1, size(initialHyperStack,1)]);

set(axesHand,'Tag','Axes.Main');
overviewAxes = findall(figureHand,'tag','Axes.Overview');
if isempty(overviewAxes)
    overviewAxes = getappdata(figureHand,'overviewAxes');
end

imshowHand2 = imshow(rand(size(initialHyperStack,1),size(initialHyperStack,2),3),...
    [],'Parent',overviewAxes,'initialMagnification','Fit');
setappdata(figureHand,'imshowHand2',imshowHand2);

set(overviewAxes,'Tag','Axes.Overview');

% adjustContrast(figureHand);
colorizeImage(figureHand,initialHyperStack);


hold(overviewAxes,'on');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Left');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Right');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Top');
plot(overviewAxes,[1,1],[1,10],':','LineWidth',2,'Tag','RegionMark.Bottom');
hold(overviewAxes,'off');

rectMark = imrect(overviewAxes,[1,1,size(initialHyperStack,2)-1,size(initialHyperStack,1)-1]);
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

activateChannel(figureHand,1);

function nextFrame(figHandle)
% get stored data values
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');

% check to see if there is an available frame
if iiFile==size(fileNames,2)
        disp(['That was the last frame silly willy. Finished at ',datestr(now),'.']);
        beep();
        pause(0.2);
        beep();
        pause(0.2);
        beep();
        
        
        % no later frames available
        return
end

axesHand = getappdata(figHandle,'axesHand');
set(get(axesHand,'children'),'visible','off');
indicatorHandles = getappdata(figHandle,'indicatorHandles');

% move to next frame
setappdata(figHandle,'iiFile',iiFile+1);

% display the image
showImageFirstTime(figHandle)


function prevFrame(figHandle)
% get stored data values
fileNames = getappdata(figHandle,'fileNames');
iiFile = getappdata(figHandle,'iiFile');

% check to see if there is an available frame
if iiFile==1
        
        % no earlier frames available
        return
end

axesHand = getappdata(figHandle,'axesHand');
set(get(axesHand,'children'),'visible','off');
indicatorHandles = getappdata(figHandle,'indicatorHandles');

% move to next frame
setappdata(figHandle,'iiFile',iiFile-1);

% display the image
showImageFirstTime(figHandle)






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
filePathToMultiColorAlign = getappdata(figHand,'filePathToMultiColorAlign');

if selectPartialRegion
    % switch to select all
    setappdata(figHand,'selectPartialRegion',false);
    
    % Read an image
    [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','selectWholeRegion.png'));
    set(src,'Cdata',icon);
else
    % switch to select region
    setappdata(figHand,'selectPartialRegion',true);
    % Read an image
    [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','selectPartialRegion.png'));
    set(src,'Cdata',icon);
end

function toggleDisplayContourBreak(src,evt)

figHand = get(get(src,'parent'),'parent');
displayContourBreak = getappdata(figHand,'displayContourBreak');
filePathToMultiColorAlign = getappdata(figHand,'filePathToMultiColorAlign');

% update single cell window
updateIndividualRegions(figHand);

contourHandles = getappdata(figHand,'contourHandles');
if displayContourBreak
    % switch to select all
    setappdata(figHand,'displayContourBreak',false);
    
    % Read an image
    [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','displayContourBreakOff.png'));
    set(src,'Cdata',icon);
else
    % switch to select region
    setappdata(figHand,'displayContourBreak',true);
    % Read an image
    [icon] = imread(fullfile(filePathToMultiColorAlign,'icons','displayContourBreak.png'));
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

function updateZoomByImrect(figHandle);
rectMark = getappdata(figHandle,'rectMark');
positionOfRect = getPosition(rectMark);
mainAxes = findobj(figHandle,'Tag','Axes.Main');
xlimits = [positionOfRect(1),positionOfRect(1)+positionOfRect(3)];
xlimits = sort(xlimits);
ylimits = [positionOfRect(2),positionOfRect(2)+positionOfRect(4)];
ylimits = sort(ylimits);
set(mainAxes,'Xlim',xlimits,'Ylim',ylimits);

