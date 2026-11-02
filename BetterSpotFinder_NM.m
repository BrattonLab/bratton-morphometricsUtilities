function cellstruct = BetterSpotFinder(varargin)
% BETTERSPOTFINDER takes contours from morphometrics and locates bright
% spots in the companion images
%
% USAGE
% BetterSpotFinder(varargin)
%   folderName is a name of a folder
%   fileList is a list of files, preferably in a cell array, without their
%       parent folder. Remember to strip the parent folder from the name or it
%       will be additionally prepended
%   THRESHOLD_CELLS is the threshold for peak detection. It is a
%       multiplier/factor above the mean intensity in the image after
%       background subtraction
%   gfpChannel is a string '1', '2', etc indicating which fluorescence
%       image to analyze for spots. For example, c=0.tif may be the phase image
%       and c=1.tif may be the GFP channel.
%   isDisplayImages2 (0, 1) 1 will display the fluorescence images with
%       colored pixels for what is segmented as a spot with cell outlines.
%   isSingleFileSummary (0, 1) 1 will display a brief summary for each file
%   offsetX is the amount to offset the contours from the phase to the
%       fluorescence channel along the x axis
%   offsetY is the amount to offset the contours from the phase to the
%       fluorescence channel along the y axis
%
%   MIN_SBR is the ratio of signal above the background of the image. The
%       the value of the bottom 10% is subtracted off the image as a form
%       of background subtraction. Then the relative background value is
%       10% of the pixels that are not in cells and are above 0. This then
%       gets multiplied by the MIN_SBR
if nargin<9
    MIN_SBR = [];
else
    MIN_SBR = varargin{9};
end

if nargin<8
    offsetY = [];
else
    offsetY = varargin{8};
end

if nargin<7
    offsetX = [];
else
    offsetX = varargin{7};
end

if nargin<6
    isSingleFileSummary = [];
else
    isSingleFileSummary = varargin{6};
end

if nargin<5
    isDisplayImages2 = [];
else
    isDisplayImages2 = varargin{5};
end

if nargin<4
    gfpChannel = [];
else
    gfpChannel = varargin{4};
end

if nargin<3
    THRESHOLD_CELLS = [];
else
    THRESHOLD_CELLS = varargin{3};
end

if nargin<2
    fileList = [];
else
    fileList = varargin{2};
end

if nargin<1
    folderName = [];
else
    try 
    a = exist(varargin{1});
    catch ME2
        a = exist(varargin{1}{1});
        varargin = varargin{1};
    end
    switch a
        case 7
            folderName = varargin{1};
        case 2
            fileList = varargin;
            folderName = [];
        case 0
            return
        otherwise
            fileList = {varargin{1}};
            folderName = [];                
    end
end

%% process inputs
% passed in the name of a folder but not any files
if and(isempty(fileList),not(isempty(folderName)))
    fileList = dir([folderName,filesep,'*CONTOURS.mat']);
end

% didn't pass in the name of a folder
if isempty(folderName) && isempty(fileList);
    [fileList, folderName] = uigetfile('*CONTOURS.mat','MultiSelect', 'on');
    % if the user presses cancel, stop executing
    if folderName == 0
        return
    end
    if ~iscell(fileList)
        fileList = {fileList}; %makes fileList a cell array of length = 1
    end
end

% some of the values are not defined, instead of having default values that
% are just automatically used, let the user see all of them
if any([isempty(THRESHOLD_CELLS),...
        isempty(offsetY),...
        isempty(offsetX),...
        isempty(isDisplayImages2),...
        isempty(isSingleFileSummary),...
        isempty(gfpChannel),...
        isempty(MIN_SBR)])
    
    
    if isempty(MIN_SBR)
        MIN_SBR = 10;
    end
    
    if isempty(THRESHOLD_CELLS)
        THRESHOLD_CELLS = 3;
    end
    
    if isempty(offsetY)
        offsetY = 0;
    end
    
    if isempty(offsetX)
        offsetX = 0;
    end
    
    if isempty(isDisplayImages2)
        isDisplayImages2 = 1;
    end
    
    if isempty(isSingleFileSummary)
        isSingleFileSummary = 1;
    end
    
    if isempty(gfpChannel)
        gfpChannel = '1';
    end
    
    
    answer = inputdlg({'Would you like to see a figure for each file (1 for yes, 0 for no)',...
        'xOffset for contours','yOffset for contours',...
        'fluorescent spot channel number (1,2,3,...)',...
        'threshold','summary of spots for each file (1 for yes, 0 for no)',...
        'signal to background ratio (recommended >5)'},...
        'BetterSpotFinder options',...
        1,...
        {num2str(isDisplayImages2),...
        num2str(offsetX),...
        num2str(offsetY),...
        gfpChannel,...
        num2str(THRESHOLD_CELLS),...
        num2str(isSingleFileSummary),...
        num2str(MIN_SBR)},'on');
    
    isDisplayImages2 = str2double(answer{1});
    offsetX = str2double(answer{2});
    offsetY = str2double(answer{3});
    gfpChannel = answer{4};
    THRESHOLD_CELLS = str2double(answer{5});
    isSingleFileSummary = str2double(answer{6});
    MIN_SBR = str2double(answer{7});
end

%% default values
isDisplayImages = false; % this display setting displays even more images
% THRESHOLD_CELLS = 2;
% GFP_CHANNEL = '1';
%
%
%
% %% process input arguments
% isDisplayImages2 = false;
% isSingleFileSummary = false;
%
%
% switch nargin
%     case 0
%         [fileList, folderName] = uigetfile('*.mat','MultiSelect', 'on');
%         if ~iscell(fileList)
%             fileList = {fileList}; %makes fileList a cell array of length = 1
%         end
%
%
%
%         THRESHOLD_CELLS = THRESHOLD_CELLS;
%         GFP_CHANNEL = GFP_CHANNEL;
%         button = questdlg('Would you like to see a million figures?','isDisplayImages2','yes','no','yes');
%         switch button
%             case 'yes'
%                 isDisplayImages2 = true;
%             case 'no'
%                 isDisplayImages2 = false;
%         end
%
%                 button = questdlg('Would you like to offset contours?','offsetCountours','yes','no','no');
%         switch button
%             case 'yes'
%                 offsetX = 0.5;
%                 offsetY = 1;
%             case 'no'
%                 offsetX = 0;
%                 offsetY = 0;
%
%         end
%
%         isSingleFileSummary = true;
%     case 1
%         % only the folder was passed in, used all files in this folder and
%         % defaults for the rest of the inputs
%         fileList = dir([folderName,filesep,'*CONTOURS.mat']);
%         THRESHOLD_CELLS = THRESHOLD_CELLS;
%         GFP_CHANNEL = GFP_CHANNEL;
%     case 2
%         % files and folder were passed in
%         fileList = fileList;
%         THRESHOLD_CELLS = THRESHOLD_CELLS;
%         GFP_CHANNEL = GFP_CHANNEL;
%     case 3
%         % only channel name is default
%         fileList = fileList;
%         THRESHOLD_CELLS = threshold;
%         GFP_CHANNEL = GFP_CHANNEL;
%     case 4
%         % don't use any defaults
%         fileList = fileList;
%         THRESHOLD_CELLS = threshold;
%         GFP_CHANNEL = gfpChannel;
%     otherwise
%         % this doesn't make sense, throw an error
%         error('morphometrics:betterSpotFinder',...
%             ['Expected 4 input arguments or fewer. Was passed ',num2str(nargin),' instead.']);
% end
%
%
% isDisplayImages = false;
%


%% 1 Find contour files (group of files)

for jfile = 1:length(fileList) %goes through all the selected files
    progressbar((jfile-1)/length(fileList))

    contourName = fileList{jfile};
    
    
    %% 2 Open and display images.
    
    phaseName = strrep(contourName,'_CONTOURS.mat','.tif');
    
    
    if exist(fullfile(folderName,phaseName),'file');
    elseif exist(fullfile(folderName,[phaseName(1:end-16),'.tif']),'file');
        % morphometrics 1.1 appends a date stamp to contours file names
        phaseName = [phaseName(1:end-16),'.tif'];
    else
        warning('morphometrics:BBetterSpotFinder:imageFileMissing',...
            ['Phase image file for ',contourName,' can not be found.']);
        continue
        
    end
    %readInImage = imread(fullfile(folderName,phaseName),'index',jFrame);
    
    fluorName = strrep(phaseName,'c=0',['c=',gfpChannel]);
    if strcmp(phaseName,fluorName)
        fluorName = strrep(phaseName,'c1',['c',gfpChannel]);
        
        if strcmp(phaseName,fluorName)
            warning('BetterSpotFinder:nofluorescentfile','File Naming Format Not Correct (Fluor vs Phase)')
        end
        
    end
    
    
    fluorImage = imread(fullfile(folderName,fluorName));
    % phase image is c=0 where fluor is c=1
    phaseImage = imread(fullfile(folderName,phaseName));
    if isDisplayImages
        imshow(fluorImage,[],'initialmagnification','fit');
    end
    
    %% 3 Change to double.
    
    fluorImage = double(fluorImage);
    if isDisplayImages
        imshow(fluorImage,[],'initialmagnification','fit');
    end
    
    %% Mask of cell outlines
    loadedContours = load(fullfile(folderName,contourName));
    %nContours = loadedContours.frame(1).num_cells;
    if isfield(loadedContours.frame(1),'num_cells')
        % v0.97
        nContours = loadedContours.frame(1).num_cells;
    elseif isfield(loadedContours.frame(1),'num_objs')
        % v1.1
        nContours = loadedContours.frame(1).num_objs;
    else
        error('morphometrics:BetterSpotFinder:numObjFieldName','Unclear what field name contains the number of objects in this frame');
    end
    xContours = [];
    yContours = [];
    
    for iObject = 1:nContours %building a list of the x and y contours
        xContours = cat(1,xContours,(loadedContours.frame(1).object(iObject).Xcont(:)));
        yContours = cat(1,yContours, (loadedContours.frame(1).object(iObject).Ycont(:)));
        
        
    end
    xContours = round(xContours); %rounds to nearest pixel
    yContours = round(yContours);
    xContours = max(xContours,1); %makes sure you stay on the image
    yContours = max(yContours,1);
    
    
    numberRows = size(fluorImage,1);
    numberColumns = size(fluorImage,2);
    
    xContours = min(numberColumns,xContours);
    yContours = min(numberRows,yContours);
    
    contourMask = zeros(numberRows,numberColumns);
    contourIDX = sub2ind([numberRows,numberColumns],yContours,xContours);
    contourMask(contourIDX)=1;
    contourMask = bwmorph(contourMask,'dilate');
    contourMask = imfill(contourMask,'holes');
    contourMask = bwmorph(contourMask,'erode');
    contourMask = bwmorph(contourMask,'dilate'); %NM190423
    % contourMask = imdilate(contourMask, strel('disk',3));
    
    %cellRegions = contourMask.*localEnrichment;
    
    
    % subplot(1,2,1);
    % imshow(cellRegions,[],'initialMagnification','fit');
    % subplot(1,2,2);
    % imshow(log(localEnrichment),[],'initialMagnification','fit');
    %% new 4.1 use a spot finding threshold
    
    % display colorized fluorescence
    fluorImage = fluorImage-quantile(fluorImage(:),0.1);
    fluorImage = max(fluorImage,0);
    % find background pixels (not inside a contour, not zero valued)
    fluorBackground = fluorImage(:).*(not(contourMask(:)));
    fluorBackground = fluorBackground(fluorBackground(:)>0);
    fluorBackgroundValue = quantile(fluorBackground(:),0.1);
    
    filteredImage = bpass(fluorImage, .5, 5);  %band pass filter; first thing
    %can be any number, second must
    %be odd integer; can do empty
    %vector with either
    filteredCells = filteredImage.*contourMask;
    threshold = sum(filteredCells(:))/sum(contourMask(:));
    threshold = THRESHOLD_CELLS*threshold;
    spotImage = and(filteredImage>threshold,fluorImage>(MIN_SBR*fluorBackgroundValue)); %how much brighter are spots than bckgrd
    
    spotImage =  bwmorph(spotImage,'clean');
    %spotImage = bwmorph(spotImage, 'dilate',3);
    spotImage = imfill(spotImage,'holes');
    
    % %% 4.1 use a built in edge detector
    % fluorImage = fluorImage-min(fluorImage(:));
    % [spotEdges] = edge(fluorImage,'sobel',THRESHOLD);
    % spotEdges = bwmorph(spotEdges,'clean');
    % spotEdges = bwmorph(spotEdges, 'dilate');
    % spotEdges = imfill(spotEdges,'holes');
    
    % % compare each pixel to the local average, average ignores self
    % localEnrichmentFilterMask = ...
    %     [[1,1,1,1,1];...
    %     [1,1,0,1,1];...
    %     [1,0,0,0,1];...
    %     [1,1,0,0,1];...
    %     [1,1,1,1,1]];
    % localEnrichmentFilterMask = localEnrichmentFilterMask./sum(localEnrichmentFilterMask(:));
    % %localAverage = imfilter(filteredImage,localEnrichmentFilterMask,'same');
    % localAverage = medfilt2(filteredImage,[11,11]);
    % localAverage(localAverage(:)==0) = min(localAverage(localAverage(:)>0));
    % localEnrichment = filteredImage./localAverage;
    %
    regions = bwlabel(spotImage,4);
    regionsInfo = regionprops(regions,fluorImage,'all');
    regionArea = [regionsInfo.Area];
    regionsToDelete = find(regionArea<=3); %deletes regions below a certain number of pixels
    for iregion = regionsToDelete
        regions(regions(:)==iregion)=0;
    end
    regionsInfo = regionprops(regions,fluorImage,'all');
    
    coloredRegion = label2rgb(regions,'prism');
    
    
    
    % build three planes R, G , B that are all the same
    rgbImage = 255*cat(3,fluorImage, fluorImage, fluorImage);
    
    % set the red plane to be the mask
    rgbImage(:,:,1) = 255*double(spotImage);
    rgbImage = uint8(rgbImage);
    if isDisplayImages
        imshow(coloredRegion,[],'InitialMagnification','fit');
    end
    
    %% 5 load in the contours
    loadedContours = load(fullfile(folderName,contourName));
    
    
    % switch to a 'normalized' image for display purposes
    % what should be used is the maximum value of the fluorImageForDisplay
    % should only depend on the values within cells
    maxVal = quantile(fluorImage(:).*contourMask(:),0.999);
    fluorImageForDisplay = fluorImage./maxVal;
    fluorImageForDisplay = max(fluorImageForDisplay,0);
    fluorImageForDisplay = min(fluorImageForDisplay,1);
    
    if isDisplayImages2
        figure
        
        imshow(uint8(bsxfun(@times,double(coloredRegion),fluorImageForDisplay)),...
            [],'InitialMagnification','fit');
        % imshow(fluorImage,[],'InitialMagnification','fit');
        
        % display cell outlines on current figure
        hold on % keeps the current figure
    end
    
    %nContours = loadedContours.frame(1).num_cells;
    if isfield(loadedContours.frame(1),'num_cells')
        % v0.97
        nContours = loadedContours.frame(1).num_cells;
    elseif isfield(loadedContours.frame(1),'num_objs')
        % v1.1
        nContours = loadedContours.frame(1).num_objs;
    else
        error('morphometrics:BetterSpotFinder:numObjFieldName','Unclear what field name contains the number of objects in this frame');
    end
    if isDisplayImages2
        
        for iObject = 1:nContours
            plot(loadedContours.frame(1).object(iObject).Xcont+offsetX,...
                loadedContours.frame(1).object(iObject).Ycont+offsetY,'r')
            
        end
        title(contourName,'interpreter','none');
        drawnow;
    end
    % %% Mask of cell outlines
    % nContours = loadedContours.frame(1).num_cells;
    % xContours = [];
    % yContours = [];
    %
    % for iObject = 1:nContours %building a list of the x and y contours
    %     xContours = cat(1,xContours,(loadedContours.frame(1).object(iObject).Xcont(:)));
    %     yContours = cat(1,yContours, (loadedContours.frame(1).object(iObject).Ycont(:)));
    %
    %
    % end
    %     xContours = round(xContours); %rounds to nearest pixel
    %     yContours = round(yContours);
    %     xContours = max(xContours,1); %makes sure you stay on the image
    %     yContours = max(yContours,1);
    %
    %
    %     numberRows = size(fluorImage,1);
    % numberColumns = size(fluorImage,2);
    %
    % xContours = min(numberColumns,xContours);
    % yContours = min(numberRows,yContours);
    %
    % contourMask = zeros(numberRows,numberColumns);
    % contourIDX = sub2ind([numberRows,numberColumns],yContours,xContours);
    % contourMask(contourIDX)=1;
    % contourMask=bwmorph(contourMask,'dilate');
    % contourMask = imfill(contourMask,'holes');
    % contourMask = imdilate(contourMask, strel('disk',3));
    %
    % cellRegions = contourMask.*localEnrichment;
    %
    
    % subplot(1,2,1);
    % imshow(cellRegions,[],'initialMagnification','fit');
    % subplot(1,2,2);
    % imshow(log(localEnrichment),[],'initialMagnification','fit');
    %% 6 Mask individual cells.
    
    totalCells = struct([]);
    totalSpots = struct([]);
    
    
    % empty holder for list of cells that have a portion of the current spot
    try
        totalSpots(max(regions(:))).listOfCells = [];
    catch ME
        totalSpots(1).listOfCells = []; %sometimes there are no spots
    end
    FRAME_IDX = 1;
    
    for iObject = 1:nContours
        % for iObject = 7;
        
        % if a cell is on the edge, don't include
        if   isfield(loadedContours.frame(FRAME_IDX).object(iObject),'on_edge');
            totalCells(iObject).on_edge = loadedContours.frame(FRAME_IDX).object(iObject).on_edge;
        else
            totalCells(iObject).on_edge = false;
        end
        
        
        tempX = loadedContours.frame(FRAME_IDX).object(iObject).Xcont+offsetX;
        tempY = loadedContours.frame(FRAME_IDX).object(iObject).Ycont+offsetY;
        
        cellMask = zeros(numberRows,numberColumns);
        
        for ii = 1:length(tempX)
            cellMask(round(tempY(ii)),round(tempX(ii))) = 1; % set this pixel to true, it is "in" the cell
        end
        cellMask = imfill(cellMask,'holes'); %filling the contours of each cell
        cellSpots = cellMask.*regions; %this is telling us which spots are overlapping with cells
        
        % preallocate some space for variables of arbitrary sizes
        totalCells(iObject).listOfSpots = [];
        totalCells(iObject).spotAreaInCell_pix = [];
        totalCells(iObject).spotAreaInCell_frac = [];
        totalCells(iObject).spotIntensityInCell = [];
        totalCells(iObject).spotIntensityInCell_frac = [];
        totalCells(iObject).aspectRatio = [];
        totalCells(iObject).MinorAxis_pix = [];
        totalCells(iObject).MajorAxis_pix = [];
        
        % total cell intensity
        totalCells(iObject).totalCellIntensity = sum(fluorImage(cellMask(:) == 1));
        totalCells(iObject).totalSpotIntensity = 0;
        totalCells(iObject).cellArea = sum(cellMask(:) == 1);
        
        % count of spots in cell, always region 0, so subtract 1
        totalCells(iObject).numberOfSpotsInCell = numel(unique(cellSpots(:)))-1;
        
        % for each of the spots that exists, store its information in total
        % cells
        for jSpot = unique(cellSpots(:))';
            
            if jSpot == 0
                % ignore spot 0, it is the background
            else
                % this spot's area in this cell
                areaInCell = nnz(cellSpots(:) == jSpot);
                % this spot's intensity in this cell
                intensityInCell = sum(fluorImage(:) .* ((cellSpots(:)==jSpot)));
                
                % this spot's total intensity
                totalIntensity = sum(fluorImage(:) .* (regions(:)==jSpot)); % may have some outside of cell
                
                % add this spot label to the current list of spots in this cell/object
                totalCells(iObject).listOfSpots = cat(1,totalCells(iObject).listOfSpots,jSpot);
                
                % what fraction of this spot's area is in this cell
                totalCells(iObject).spotAreaInCell_pix = cat(1,totalCells(iObject).spotAreaInCell_pix,areaInCell);
                totalCells(iObject).spotAreaInCell_frac = cat(1,totalCells(iObject).spotAreaInCell_frac,...
                    areaInCell./regionsInfo(jSpot).Area);
                
                % what fraction of this spot's itensity is in this cell
                totalCells(iObject).spotIntensityInCell = cat(1,totalCells(iObject).spotIntensityInCell,intensityInCell);
                totalCells(iObject).spotIntensityInCell_frac = cat(1,totalCells(iObject).spotIntensityInCell_frac,...
                    intensityInCell./totalIntensity);
                
                % size of object
                totalCells(iObject).aspectRatio = cat(1,totalCells(iObject).aspectRatio,...
                    regionsInfo(jSpot).MajorAxisLength./regionsInfo(jSpot).MinorAxisLength);
                totalCells(iObject).MajorAxis_pix = cat(1,totalCells(iObject).MajorAxis_pix,...
                    regionsInfo(jSpot).MajorAxisLength);
                totalCells(iObject).MinorAxis_pix = cat(1,totalCells(iObject).MinorAxis_pix,...
                    regionsInfo(jSpot).MinorAxisLength);
                
                % add up the total intensity of the spot, even if it is
                % somewhat outside the contour of the cell
                totalCells(iObject).totalSpotIntensity = totalCells(iObject).totalSpotIntensity+...
                    totalIntensity;
                
                
                
                % how many cells is this spot represented in
                totalSpots(jSpot).listOfCells = cat(1,totalSpots(jSpot).listOfCells,iObject);
                
                
            end
        end % end of spots in this object/cell
        
        % fraction of total fluorescence intensity in spots
        totalCells(iObject).fractionalIntensity = totalCells(iObject).totalSpotIntensity./...
            totalCells(iObject).totalCellIntensity;
        
    end
    
    % find which cells are on the edge
    isOnEdge = [totalCells.on_edge];
    totalCells(isOnEdge) = []; % setting entire row/colum to [] deletes it
    if isDisplayImages
        imshow(cellSpots,'InitialMagnification','fit');
        
    end
    
    %% display some results
    if isSingleFileSummary
        
        % figure();
        % hist([totalCells.numberOfSpotsInCell],0:8);
        % xlabel('number of spots per cell');
        % ylabel('cell count');
        disp(' ');
        disp(contourName);
        disp(['number of cells ',num2str(length(totalCells))]);
        disp(['average spots per cell ',num2str(mean([totalCells.numberOfSpotsInCell]))]);
        individualSpotAspectRatio = [];
        for ii = 1:length(totalCells)
            individualSpotAspectRatio = cat(1,individualSpotAspectRatio,totalCells(ii).aspectRatio);
        end
        % figure();
        % hist(individualSpotAspectRatio',1:10);
        % xlabel('aspect ratio');
        % ylabel('spot count');
        disp(['spot aspect ratio ', num2str(mean(individualSpotAspectRatio))]);
    end
    cellstruct = totalCells;
    %title(contourName);
    
    %% Save the data
    saveFileName = strrep(contourName,'.mat','_SPOTS.mat');
    save(fullfile(folderName,saveFileName));
end
progressbar(1)
disp(' ');
disp('done!');