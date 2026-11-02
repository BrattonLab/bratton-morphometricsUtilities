% segmentCompanionImages(channel,matName,paramsNew);
%
% CHANNEL should have four fields
%   type - 'fluor' or 'phase', determines what types of processing to perform
%   after segmentation
%   label - a string with a description of the channel
%   path - relative path to the file
%   name - file name of the image
%
% MATNAME - the name of a mat file in the same path as channel(1).path
%   with the contours
%
% PARAMSNEW - any new parameter settings. Old settings with the same name
%   will be overwritten with a warning
function  segmentCompanionImages(channel,matName,paramsNew)

if nargin<1
    %% select files with contours
    [matName,matPath] = uigetfile('.mat','Please select .mat file with contours');
    load(fullfile(matPath,matName));
    
    %% select files with images
    [channel(1).name,channel(1).path] = uigetfile('.tif','Please select tif which contours are based on');
    channel(1).type = questdlg('What type of image?','','phase','fluor','phase');
    isAnotherChannel = true;
    iChannel = 1;
    while isAnotherChannel
        iChannel = iChannel + 1;
        [channel(iChannel).name,channel(iChannel).path] = uigetfile('.tif',['Please select channel ',num2str(iChannel),' file']);
        % check to see if cancel was selected
        if channel(iChannel).name==0
            break
        end
        channel(iChannel).label = inputdlg(['What label to give to channel ',num2str(iChannel),'?'],...
            'Channel label',1,{['Channel',num2str(iChannel)]});
        channel(iChannel).type = questdlg('What type of image?','','phase','fluor','fluor');
    end
    channel(iChannel) = [];
    nOtherChannels = iChannel-2;
else % parameters are passed in from outside
    channelTemp = channel;
    load(fullfile(channel(1).path,matName));
    if not(isequal(channelTemp,channel))
        warning('segmentCompanion:overwriteChannel',['Saved field ''channel''',...
            ' was overwritten']);
        channel = channelTemp;
    end
    clear channelTemp
end
nOtherChannels = numel(channel);

% be careful to not overwrite parameters that are already stored in the mat
% file
if not(exist('params','var'))
    params = struct();
end

% the parameters that are passed in they should overwrite the old ones but warn
% that they do so.
if nargin>2
    paramFields = fieldnames(paramsNew);
    for iParam = 1:numel(paramFields)
        if isfield(params,paramFields(iParam))
            warning('segmentCompanion:paramOverwrite',...
                ['Overwriting parameter ''',paramFields{iParam},'''.']);
            params.(paramFields{iParam}) = paramsNew.(paramFields{iParam});
        else
            params.(paramFields{iParam}) = paramsNew.(paramFields{iParam});
        end
        
    end
end

% include any defaults that are missing
params = processParams(params);


%% read in those images
% filtering the image is one way to improve the numerical stability for
% estimating the background intensity in the image

switch params.bkgFilterType
    case 'boxcar'
        filterBack = ones(params.bkgFilterSettings);
        filterBack = filterBack./sum(filterBack(:));
    otherwise
        filterBack = 1;
end

%% Background subtracted images
nOtherChannels = numel(channel)-1;

for iChannel = 1:nOtherChannels+1;
    channel(iChannel).finfo = imfinfo(fullfile(channel(iChannel).path,channel(iChannel).name));
    channel(iChannel).nPlanes = size(channel(iChannel).finfo,1);
    channel(iChannel).background = nan(1,channel(iChannel).nPlanes);
    
    for iPlane = 1:channel(iChannel).nPlanes;
        tempPlane = double(imread(fullfile(channel(iChannel).path,channel(iChannel).name),'index',iPlane,'info',channel(iChannel).finfo));
        bkgPlane = imfilter(tempPlane,filterBack);
        switch channel(iChannel).type
            case 'phase'% for phase images, the background value should be the median
                channel(iChannel).background(iPlane) = median(bkgPlane(:));
                channel(iChannel).image(:,:,iPlane) = tempPlane - channel(iChannel).background(iPlane);
            case 'fluor' % for fluorescence, the background value should 0. Merely subtract off the
                % background
                channel(iChannel).background(iPlane) = quantile(bkgPlane(:),params.bkgQuantile);
                channel(iChannel).image(:,:,iPlane) = tempPlane - channel(iChannel).background(iPlane);
        end
    end
end

%% loop over contours and open the companion frames

% get ready to show images
if params.display1
    figHandle = figure();
    axesHandle = cla;
    fig1 = figure();
end

% preallocate a blank image
blankImg = zeros(size(channel(1).image,1),size(channel(1).image,2));

% are there frames in this contour file?
if not(exist('frame','var'))
    warning('segmentCompanionImages:noFrame','No cells in given .mat file');
    return
end

% loop over the frames
params.progbar.frameIncrement = 1/size(frame,2);
params.progbar.currentFrame = -10*eps;
for iFrame = 1:size(frame,2);
    if params.display1 % don't display status bar if in interactive mode
    else
%         params.progbar.currentFrame = (iFrame-1)+10*eps;
%         
%         progressbar([],(iFrame-1)/size(frame,2)+10*eps,[]);
    end
    %     for jObject = 1:40
        
    % progress bar
        params.progbar.currentCell = -10*eps;
        params.progbar.cellIncrement = 1/size(frame(iFrame).object,2);

    for jObject = 1:size(frame(iFrame).object,2);
        if params.display1
        else
            params = updateProgressBar(params);
%             progressbar([],[],(jObject-1)/size(frame(iFrame).object,2)+10*eps);
        end
        
        % initialize mask to all zeros
        mask1 = blankImg;
        
        % initialize displayed image
        if params.display1
            displayImg = [];
        end
        
        % add in contours as ones
        for kPoint = 1:numel(frame(iFrame).object(jObject).Ycont);
            mask1(round(frame(iFrame).object(jObject).Ycont(kPoint)),...
                round(frame(iFrame).object(jObject).Xcont(kPoint))) = 1;
        end
        
        % display current mask
        %         imshow(mask1,[]);
        % pause before continuing
        %         pause();
        
        % make somewhat larger to account for endcaps
        mask1 = imdilate(mask1,strel('disk',3));
        mask1 = imfill(mask1,'holes');
        mask1 = bwmorph(mask1,'thin',1);
        
        % display current mask
        %         imshow(mask1,[]);
        % pause before continuing
        %         pause();
        
        % calculate region information
        regions1 = regionprops(mask1,'centroid','orientation','MajorAxisLength');
        
        % maximum size
        maxR = round(sqrt(2)/2*regions1.MajorAxisLength+params.borderSize);
        indexT = max(1,round(regions1.Centroid(2))-maxR);
        indexB = min(size(mask1,1),round(regions1.Centroid(2))+maxR);
        indexL = max(1,round(regions1.Centroid(1))-maxR);
        indexR = min(size(mask1,2),round(regions1.Centroid(1))+maxR);
        
        % crop out region
        mask1 = mask1(indexT:indexB,indexL:indexR);
        
        % rotate cells to horizontal and find their center of mass in the
        % rotated reference frame
        mask2 = imrotate(mask1,-1*regions1.Orientation,'bicubic','loose');
        % feather edges
        mask2 = imfilter(mask2,params.featherMask);
        regions2 = regionprops(mask2>0.5,'centroid','MajorAxisLength','MinorAxisLength');
        
        
        % apply rotation/multiplication to other channels
        for iChannel = 1:nOtherChannels+1
            try
                % single plane of image
                tempSingle = channel(iChannel).image(:,:,iFrame);
                
                % pull out bounding box
                tempSingle = tempSingle(indexT:indexB,indexL:indexR);
                % rotate bounding box
                tempSingle = imrotate(tempSingle,-1*regions1.Orientation,'bicubic','loose');
                % multiply by rotated cell mask
                tempSingle = tempSingle.*mask2;
                
                % pull out just the cell
                top = max(round(regions2.Centroid(2)-regions2.MinorAxisLength/2-params.borderSize),1);
                bottom = min(size(tempSingle,1),round(regions2.Centroid(2)+regions2.MinorAxisLength/2+params.borderSize));
                left = max(1,round(regions2.Centroid(1)-regions2.MajorAxisLength/2-params.borderSize));
                right = min(size(tempSingle,1),round(regions2.Centroid(1)+regions2.MajorAxisLength/2+params.borderSize));
                
                tempCrop = tempSingle(top:bottom,left:right);
            catch ME1
                warning('segmentCompanionImages:invalidRegion',...
                    ['Contour number ',num2str(jObject), ' is too close to a border']);
                
                
                
                tempCrop = NaN;
                
            end
            % normalize peak pixel to 1
            tempMin = min(tempCrop(:)); % already background subtracted
%             tempMin = 0;
            tempCropNorm = tempCrop - tempMin;
            tempMax = max(tempCropNorm(:));
            tempCropNorm = tempCropNorm./tempMax;
            
            % store cell size properties
            frame(iFrame).object(jObject).width = regions2.MinorAxisLength;
            frame(iFrame).object(jObject).length = regions2.MajorAxisLength;
            frame(iFrame).object(jObject).area = sum(single(mask2(:)));
            
            % store image properties
            frame(iFrame).object(jObject).channel(iChannel).bkg = channel(iChannel).background(iPlane);
            frame(iFrame).object(jObject).channel(iChannel).min = tempMin;
            frame(iFrame).object(jObject).channel(iChannel).max = tempMax;
            
            % save the whole image?
            if params.saveImages
                frame(iFrame).object(jObject).channel(iChannel).imgNorm = tempCropNorm;
            end
            
            % extra processing if a fluorescence channel
            switch channel(iChannel).type
                case 'phase' % nothing extra
                    if params.display1
                        displayImg = cat(1,displayImg,tempCropNorm);
                    end
                    
                case 'fluor'
                    % spatial bandpass to accentuate peaks
                    tempPk = bpass(tempCropNorm,params.peaksBpassN,params.peaksBpassL);
                    
                    % peak finding
                    pkPos = pkfnd(tempPk,params.peaksThresh,params.peaksNeighbor);
                    pkPos = centfind(tempPk,pkPos,params.peaksWindow,params.peaksBpassL,params.centOpt);
                    
                    % store information
                    frame(iFrame).object(jObject).channel(iChannel).integInt =...
                        sum(tempCropNorm(:));%.*tempMax;
                    frame(iFrame).object(jObject).channel(iChannel).integIntFilt = ...
                        sum(tempPk(:));%.*tempMax;
                    frame(iFrame).object(jObject).pkPos = pkPos;
                    
                    % store image?
                    if params.saveImages
                        frame(iFrame).object(jObject).imagePkFilt = tempPk;
                    end
                    
                    % [left, middle, right] intensity, creating indexing
                    % arrays
                    endWidth = round(frame(iFrame).object(jObject).length*...
                        params.endWidth);
                    centWidth = round(frame(iFrame).object(jObject).length*...
                        params.centWidth);% half width
                    topWidth = round(frame(iFrame).object(jObject).width*...
                        params.topWidth);
                    
                    leftBin = params.borderSize:(params.borderSize+endWidth);
                    rightEnd = size(tempCropNorm,2)-params.borderSize;
                    rightBin = rightEnd-endWidth:rightEnd;
                    centerPix = round((rightEnd+params.borderSize)/2);
                    centerBin = centerPix-centWidth:centerPix+centWidth-1;
                    if not(isempty(centerBin))
                        lcBin = (leftBin(end)+1):(centerBin(1)-1);
                        rcBin = (centerBin(end)+1):(rightBin(1)-1);
                    else
                        warning('segmentCompanion:skipping','Skipping cell. unable to find centerBin');
                        
                        frame(iFrame).object(jObject).channel(iChannel).leftIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).leftIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).rightIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).rightIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).centerIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).centerIntNorm = nan;
                        
                        frame(iFrame).object(jObject).channel(iChannel).topIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).topIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).middleIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).middleIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntNorm = nan;
                        
                        continue
                    end
                    topBin = params.borderSize:(params.borderSize+topWidth);
                    bottomEnd = size(tempCropNorm,1)-params.borderSize;
                    bottomBin = bottomEnd-topWidth:bottomEnd;
                    
                    middlePix = round((bottomEnd+params.borderSize)/2);
                    % middle bin should go from top to bottom
                    middleBin = topBin(end)+1:bottomBin(1)-1;
                    
                    % integrate lcr bins in filtered and unfiltered
                    try
                        frame(iFrame).object(jObject).channel(iChannel).leftIntFilt = ...
                            sum(sum(tempPk(:,leftBin)));
                        frame(iFrame).object(jObject).channel(iChannel).leftIntNorm = ...
                            sum(sum(tempCropNorm(:,leftBin)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).lcIntFilt = ...
                            sum(sum(tempPk(:,lcBin)));
                        frame(iFrame).object(jObject).channel(iChannel).lcIntNorm = ...
                            sum(sum(tempCropNorm(:,lcBin)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).centerIntFilt = ...
                            sum(sum(tempPk(:,centerBin)));
                        frame(iFrame).object(jObject).channel(iChannel).centerIntNorm = ...
                            sum(sum(tempCropNorm(:,centerBin)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).rcIntFilt = ...
                            sum(sum(tempPk(:,rcBin)));
                        frame(iFrame).object(jObject).channel(iChannel).rcIntNorm = ...
                            sum(sum(tempCropNorm(:,rcBin)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).rightIntFilt = ...
                            sum(sum(tempPk(:,rightBin)));
                        frame(iFrame).object(jObject).channel(iChannel).rightIntNorm = ...
                            sum(sum(tempCropNorm(:,rightBin)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).topIntFilt = ...
                            sum(sum(tempPk(:,topBin)));
                        frame(iFrame).object(jObject).channel(iChannel).topIntNorm = ...
                            sum(sum(tempCropNorm(topBin,:)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).middleIntFilt = ...
                            sum(sum(tempPk(:,middleBin)));
                        frame(iFrame).object(jObject).channel(iChannel).middleIntNorm = ...
                            sum(sum(tempCropNorm(middleBin,:)));
                        
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntFilt = ...
                            sum(sum(tempPk(:,bottomBin)));
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntNorm = ...
                            sum(sum(tempCropNorm(bottomBin,:)));
                        frame(iFrame).object(jObject).channel(iChannel).longAxisInt = ...
                            sum(tempCropNorm);
                        
                        % display images of things
                        if params.display1
                            
                            figure(fig1);
                            subplot(2,5,1);
                            cla;
                            imshow(tempCropNorm(:,leftBin),[0,1]);
                            title('left');
                            
                            subplot(2,5,2);
                            cla;
                            imshow(tempCropNorm(:,lcBin),[0,1]);
                            title('left center');
                            
                            subplot(2,5,3);
                            cla;
                            imshow(tempCropNorm(:,centerBin),[0,1]);
                            title('center');
                            
                            subplot(2,5,4);
                            cla;
                            imshow(tempCropNorm(:,rcBin),[0,1]);
                            title('right center');
                            
                            subplot(2,5,5);
                            cla;
                            imshow(tempCropNorm(:,rightBin),[0,1]);
                            title('right');
                            
                            subplot(2,5,6);
                            cla;
                            imshow(tempCropNorm(topBin,:),[0,1]);
                            title('top');
                            
                            subplot(2,5,8);
                            cla;
                            imshow(tempCropNorm(bottomBin,:),[0,1]);
                            title('bottom');
                            
                            subplot(2,5,7);
                            cla;
                            imshow(tempCropNorm(middleBin,:),[0,1]);
                            title('middle');
                            
                        end
                    catch ME2
                        assignin('base','ME2',ME2);
                        warning('segmentCompanionImages:lcrBins',...
                            ['Contour number ',num2str(jObject), ' is too close to a border to draw LCR bins']);
                        
                        frame(iFrame).object(jObject).channel(iChannel).leftIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).leftIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).rightIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).rightIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).centerIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).centerIntNorm = nan;
                        
                        frame(iFrame).object(jObject).channel(iChannel).topIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).topIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).middleIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).middleIntNorm = nan;
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntFilt = nan;
                        frame(iFrame).object(jObject).channel(iChannel).bottomIntNorm = nan;
                        
                    end
                    
                    if params.display1
                        displayImg = cat(1,displayImg,tempCropNorm,tempPk);
                    end
            end % extra processing depending on channel type
            
        end % loop over channels
        
        if params.display1
            figure(figHandle);
            imshow(displayImg,'Parent',axesHandle,'InitialMagnification','fit');
            title(num2str(jObject));
            pause();
            if exist('fig1','var')
                %             delete(fig1);
                %             clear fig1;
            end
        end
    end % loop over objects
end % loop over frames
% progressbar([],1-10*eps,[]);

if strcmp(params.progbar.type,'singleFile');
    progressbar(1);
end
%% Save results
save(fullfile(channel(1).path,matName),'frame','params','-append')

%%
function params = processParams(params);
%% filtering the image is one way to improve the numerical stability for
% estimating the background intensity in the image
if not(isfield(params,'bkgFilterType'))
    params.bkgFilterType = 'boxcar';
end

if not(isfield(params,'bkgFilterSettings'))
    params.bkgFilterSettings = 5;
end

if not(isfield(params,'bkgQuantile'))
    % quantile used to estimate the background intensity in the image
    params.bkgQuantile = 0.04;
end

%% display options
if not(isfield(params,'display1'))
    % display every cell and then pause
    params.display1 = false;
end

if not(isfield(params,'display2'))
    params.display2 = false; % display line numbers from time to time
end

%% save images
if not(isfield(params,'saveImages'))
    % save rotated and cropped images in mat file
    params.saveImages = false;
end


%% extract cells from background
if not(isfield(params,'borderSize'))
    params.borderSize = 7; % additional radius to extract on all sides of the contour
end

if not(isfield(params,'featherMask'))
    % params.featherMask = fspecial('gaussian',5,1.5); % feather mask edges
    params.featherMask = fspecial('gaussian',8,3); % feather mask edges
end

%% finding fluorescent peaks
% bpass on fluorescence images for extracting spot information
if not(isfield(params,'peaksBpassL'))
    params.peaksBpassL = 3; % length scale of object
end
if not(isfield(params,'peaksBpassN'))
    params.peaksBpassN = 1; % length scale of noise
end

% first round - bright pixel peak finding parameters
if not(isfield(params,'peaksThresh'));
    params.peaksThresh = 0.13;
end

if not(isfield(params,'peaksNeighbor'));
    params.peaksNeighbor = 7;
end

if not(isfield(params,'peaksWindow'));
    params.peaksWindow = 7;
end

% second round - center of mass peak finding parameters
% centroid determination parameters
if not(isfield(params,'centOpt'));
    params.centOpt.interactive = false;
    params.centOpt.method = 1;
end
if not(isfield(params,''));
    
end

% integrate intensity in bins at left, right and center
% positions
if not(isfield(params,'endWidth'));
    params.endWidth = 0.2; % from tip
end
if not(isfield(params,'centWidth'));
    params.centWidth = 0.1; % one sided, full with is 2X
end
if not(isfield(params,'topWidth'));
    params.topWidth = 0.3; % also the same for bottom
end

if not(isfield(params,'progbar'))
    params.progbar.type = 'singleFile';
    progressbar('frames','cells');
end

function params = updateProgressBar(params)

switch params.progbar.type
    case 'singleFile'
        params.progbar.currentCell = params.progbar.currentCell+params.progbar.cellIncrement;
        params.progbar.currentFrame = params.progbar.currentFrame+params.progbar.cellIncrement*params.progbar.frameIncrement;
        progressbar(params.progbar.currentFrame,params.progbar.currentCell);
    case 'multipleFiles'
        params.progbar.currentCell = params.progbar.currentCell+params.progbar.cellIncrement;
        params.progbar.currentFrame = params.progbar.currentFrame+params.progbar.cellIncrement*params.progbar.frameIncrement;
        params.progbar.currentFile = params.progbar.currentFile+params.progbar.cellIncrement*params.progbar.frameIncrement*params.progbar.fileIncrement;
        progressbar(params.progbar.currentFile,params.progbar.currentFrame,params.progbar.currentCell);
    case 'multipleFolders'
        params.progbar.currentCell = params.progbar.currentCell+params.progbar.cellIncrement;
        params.progbar.currentFrame = params.progbar.currentFrame+params.progbar.cellIncrement*params.progbar.frameIncrement;
        params.progbar.currentFile = params.progbar.currentFile+params.progbar.cellIncrement*params.progbar.frameIncrement*params.progbar.fileIncrement;
        params.progbar.currentFolder = params.progbar.currentFolder+params.progbar.cellIncrement*params.progbar.frameIncrement*params.progbar.fileIncrement.*params.progbar.folderIncrement;
        progressbar(params.progbar.currentFolder,params.progbar.currentFile,params.progbar.currentFrame,params.progbar.currentCell);        
end