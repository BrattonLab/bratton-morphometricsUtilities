%% 
% 20170826 BPB updates for non-pill meshes 
% 20231102 BPB add surface area to volume and aspect ratio

%% Prompt the user for a folder
if not(isappdata(0,'isBatchAveCellSize'));
    isBatchAveCellSize = false;
else
    isBatchAveCellSize = getappdata(0,'isBatchAveCellSize');
end

% BPB 20190523 given the vagaries and pixel dependent nature of calculating
% curvature, allow the user to select the version of curvature estimation
% present when the centerlines are generated or recalculate on the fly
if not(isBatchAveCellSize)
    folderName = uigetdir();
    isRecalcCurvature = questdlg('Recalculate curvatures of centerlines and/or spines?','','Yes','No (legacy mode)','Yes');
    switch isRecalcCurvature
        case 'Yes'
            isRecalcCurvature = 1;
        otherwise
            isRecalcCurvature = 0;
    end
    
        isRemoveStatisticalOutliers = questdlg('Remove extreme statistical outliers?','','Yes','No (legacy mode)','Yes');
    switch isRemoveStatisticalOutliers
        case 'Yes'
            isRemoveStatisticalOutliers = 1;
        otherwise
            isRemoveStatisticalOutliers = 0;
    end
else
    
    % the 'foldername' variable will be prepopulated from some other
    % function/script
    
    
    % the 'isRecalcCurvature' variable will be prepopulated from some other
    % function/script
end

%%  parameters
N_BOOT_SAMPLES = 500;
BOOT_ALPHA = 0.05;
if N_BOOT_SAMPLES*BOOT_ALPHA<5
    warning('aveCellSize:bootstats:sampleSizeTooSmall',...
    ['Bootstrap sampling underdefined. Please increase N_BOOT_SAMPLES or BOOT_ALPHA']);
end

INCLUDE_FRAC = 0.65; % fraction of the cell length to retain as non-poles
POLE_MIN_SIZE = 3; % minimum number of pixels in each pole

% if there is a measurement which is more than this many standard deviations outside the mean, remove it
Z_SCORE_OUTLIER = 5; 

%% feature request: not have to enter pixel size every time
% started 20170130a bpb: use appdata in 0 to maintain the users choice
if false
if not(isappdata(0,'isAveCellPixelPrompt'));
    questdlg('If the corresponding image for the contours files is missing or has malformed metadata, what would you like to happen?','Prompter for pixel size if unknown?',...
        [{'prompt once per MATLAB session'},...
        {'prompt once per batchAveCellSize'},...
           {'prompt once per aveCellSize'},...
            {'prompt once per image'},...
            {'don''t prompt and use a value of 1'},...
            {'don''t prompt and throw an error'},...
            {'cancel this dialog'}],'cancel this dialog')
    isBatchAveCellSize = false;
else
    isAveCellPixelPrompt = getappdata(0,'isAveCellPixelPrompt');
end
end
%% find a list of non-hidden files of the right type

% search for pill_MESH
% search for spineNribs
% search for simple contours


fileList_pill = dir([folderName,filesep,'*pill_MESH.mat']);
fileList_spine = dir([folderName,filesep,'*SpineAndRibs.mat']);

if length(fileList_spine)>=length(fileList_pill)
    fileList = fileList_spine;
    modeString = 'Spine';
else
    modeString = 'Pill';
    fileList = fileList_pill;
end

% remove hidden/temporary files
badFileList=[];
for iFile=1:length(fileList)
    if strcmp(fileList(iFile).name(1:2),'._')
        badFileList=cat(1,badFileList,iFile);
    end 
    
    if strcmp(fileList(iFile).name(1),'~')
        badFileList=cat(1,badFileList,iFile);
    end 
    
end
fileList(badFileList)=[];
%% set up holders for the appropriate variables
% % if  and(not(isBatchAveCellSize),exist('cellArea','var'));
% %     warning('morphometrics:aveCellSize:previousRun',...
% %         ['Previous data found in workspace. Consider clearing the workspace',...
% %         ' before running aveCellSize.']);
% % end
population_COV = @(x) nanstd(x(:))/nanmean(x(:));
cellArea = []; % in pixels
longAxis = []; % length of long axis of the region in pixels
clLength = []; % contour length of the centerline
clPixLength = []; % number of pixels in the centerline

% after parameterizing: radius along centerline
meanWidth = []; % average of the diameter, in pix
truncWidth = []; % average of the diameter, ignoring end caps, in pix
endSizeRat = []; % ratio of endcap diameters
widthStd = []; % standard deviation of the width, in pix
truncWidthStd = []; % standard deviation of the width, in pix, ignoring poles
surfAreaApprox = []; % approximate each segment along centerline as a circular segment
volumeApprox = []; % approximate each segment along centerline as a circular segment
perimeterLength = []; % approximate length of the perimeter
pixSizePerObject = []; % pixelSize in um/pix

% curvatures
clCurv = []; % root mean squared curvature of the centerline
truncClCurv = []; % root mean squared curvature of the centerline, ignoring poles
poleCurv = []; % curvature of the outline at the poles, root mean squared
bodyCurv = []; % curvature of the outline in the non-poles, root mean squared
bodyMean = []; % curvature of the outline in the non-poles, mean signed curvature
MTCurvature = []; % microbeTracker style curvature of the centerline
        
clCurvUnsign = []; % mean unsigned curvature of the centerline,
truncClCurvUnsign = []; % mean unsigned curvature of the centerline, ignoring poles

fileIndex = []; % which file in the folder did this come from
frameIndex = []; % which frame in the file did this come from
objectIndex = []; % what was the object index in this file
            
% count the number of cells that fail some portion
nReject = 0;
nKept = 0;

allContours = struct();




% loop over all of the files in the folder
for iFile = 1:numel(fileList)
    % get set up for this file
    clear frame N
    
    % preallocate a nan
    pixSize =  nan;
    % 
    
    % BPB 20170828 this is tricky business, determining the name of the
    % image file from the file name of the mat file
       
    % find the name of the image file, needed to find the size of pixels
    imageFileName = fileList(iFile).name;
    contourStringIndx = strfind(imageFileName,'_CONTOURS');
    imageFileName = [imageFileName(1:(contourStringIndx-1)),'.tif'];
    
    if exist([folderName,filesep,imageFileName],'file');
    elseif exist([folderName,filesep,imageFileName(1:end-16),'.tif'],'file');
        % morphometrics 1.1 appends a date stamp to contours file names
        imageFileName = [imageFileName(1:end-16),'.tif'];
    else
        warning('morphometrics:aveCellSize:imageFileMissing',...
            ['Image file for ',fileList(iFile).name,' can not be found.']);
        pixSizeStr = inputdlg('Pixel size in um','Pixel size');
        pixSize = str2double(pixSizeStr{1});
    end
    
    % try to load the pixel size if it doesn't already exist 
    if isnan(pixSize)
        imageFileInfo = imfinfo(fullfile(folderName,imageFileName));
        pixSize = 1/imageFileInfo.XResolution;
        % check to see if the resolution unit is cm or not
        pixUnits = imageFileInfo.ResolutionUnit;
        switch pixUnits
            case 'Centimeter' % to micron is 1e-4
                pixSize = pixSize/1e-4;
            case 'None' % to micron is 1e0;
                try 
                    ImageDescrip1 = imageFileInfo.ImageDescription;
                    pixSize = pixSize*1;

                catch ME
                    warning('aveCellSize:pixelUnits',['Pixel units of ''', pixUnits,''' is unknown, assuming microns']);
                    pixSize = pixSize*1;
                end
            otherwise
                warning('aveCellSize:pixelUnits',['Pixel units of ''', pixUnits,''' is unknown, assuming microns']);
        end
   
    end
    
    % load in the mat file with the pill mesh
    load(fullfile(folderName,fileList(iFile).name),'frame');
    % each image in the original tif is a "frame"
    for jFrame = 1:numel(frame)
        % each object/cell in a frame is held in object
        for kObj = 1:numel(frame(jFrame).object)
            % for each cell, first try to pull out all the pieces of
            % information, then if there are no errors, store that
            % information
            
            try
                % all temp variables should be name that it will be stored
                % as with a little t prefix
                
                % ignore cell if it is on the edge of the frame
                if isfield(frame(jFrame).object(kObj),'on_edge');
                    % this is a leftover from v0.97
                    assert(not(frame(jFrame).object(kObj).on_edge));
                else
                    % this field is not included in v1.1
                end
                
                % add a field for pixelSize
                frame(jFrame).object(kObj).pixSize = pixSize;
                fieldList = fieldnames( allContours);
                if isempty(fieldList)
                    allContours =  frame(jFrame).object(kObj);
                else
                   allContours =  cat(1,allContours,frame(jFrame).object(kObj));
                end
                
                
                
                switch modeString
                    case 'Pill'
                        % check to make sure things exist
                        if isempty(frame(jFrame).object(kObj).length);
                            error('morphometrics:aveCellSize',['Data for cell ',num2str(jFrame),':',num2str(kObj),' are missing.']);
                        end
                        
                        % length of cell in pixels
                        tlongAxis = frame(jFrame).object(kObj).length;
                                        
                        % contour length of the cell centerline, in pixels
                        tCL = frame(jFrame).object(kObj).centerline;
                        
                        % distance between centerline points
                        tSegment = diff(tCL);
                        tSegment = sqrt(sum(tSegment.^2,2));
                        % add up the distance between center line points
                        tCumSegLength = cumsum(tSegment);
                        % start at 0
                        tCumSegLength = [0;tCumSegLength];
                        % the final is another measure of the length of the cell
                        tclLength = tCumSegLength(end);
                
                        % pull out the width field
                        tempWidth = frame(jFrame).object(kObj).width;

                    case 'Spine'
                        tSpine = frame(jFrame).object(kObj).spine;
                        % integrate along the contour length
                        tSegment = sqrt(sum(diff(tSpine).^2,2));

                        tCumSegLength = cumsum(sqrt(sum(diff(tSpine).^2,2)));
                        tCumSegLength = [0;tCumSegLength];
                        tclLength = tCumSegLength(end);
                        tlongAxis = sqrt(sum((tSpine(1,:)-tSpine(end,:)).^2));
                        % establish the width of the object
                        tRibEnds = frame(jFrame).object(kObj).xyRibEnds;
                        clear tempWidth;
                        for kkRib = 1:size(tRibEnds,1)
                            tempWidth(kkRib) = sqrt(sum((tRibEnds(kkRib,1:2)-tSpine(kkRib,:)).^2));
                            tempWidth(kkRib) = tempWidth(kkRib)+sqrt(sum((tRibEnds(kkRib,3:4)-tSpine(kkRib,:)).^2));
                        end
                        
                        tCL = tSpine;
                        
                end
 
                % use this length to define poles
                poleFrac = (1-INCLUDE_FRAC)/2;
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
                
                % width of cell in pixels
                tmeanWidth = mean(tempWidth);
                ttruncWidth = mean(tempWidth(leftStart:rightEnd));
                
                % area of the cell in square pixels
                tarea = frame(jFrame).object(kObj).area;
                if not(isfinite(tarea))
                   error('aveCellSize:notFiniteArea','The area for this cell is not finite. Skipping.'); 
                end
                
                % surface areas
                tWidth = tempWidth;
                tWidth_Radius = (tWidth(1:end-1)+tWidth(2:end))/4; % use the trapezoid approximation
                tWidth_Radius = tWidth_Radius(:);
                tVolume = sum(pi.*tWidth_Radius.*tWidth_Radius.*tSegment);
                tSurfaceArea = sum(2.*pi.*tWidth_Radius.*tSegment);

                
                
                % width standard deviation
                twidthStd = std(tWidth);
                ttruncWidthStd = std(tWidth(leftStart:rightEnd));
                
                % centerline curvature
                switch modeString
                    case 'Pill'
                        if isRecalcCurvature
                            centerlineCoords = frame(jFrame).object(kObj).centerline;
                            % for the matrix multiplication to work, append
                            % a third dimension
                            centerlineCoords(:,3) = 1;
                            tempCenterlineCurvatureField = signedCurvature(centerlineCoords,3);
                        else
                            tempCenterlineCurvatureField = frame(jFrame).object(kObj).cent_kappa(:);
                        end
                    case 'Spine'
                        if isRecalcCurvature
                            centerlineCoords = double(frame.object(kObj).spine);
                            % for the matrix multiplication to work, append
                            % a third dimension
                            centerlineCoords(:,3) = 1;
                            tempCenterlineCurvatureField = signedCurvature(centerlineCoords,3);
                        else
                            tempCenterlineCurvatureField = frame(jFrame).object(kObj).spineCurvature(:);
                        end
                end

                tclCurv = tempCenterlineCurvatureField;
                tclCurv = tclCurv.^2;
                tclCurv = sqrt(mean(tclCurv));
                ttruncClCurv = tempCenterlineCurvatureField(leftStart:rightEnd);
                ttruncClCurv = ttruncClCurv.^2;
                ttruncClCurv = sqrt(mean(ttruncClCurv));
                
                % unsigned curvature of the centerline
                ttruncClCurvUnsign = tempCenterlineCurvatureField(leftStart:rightEnd);
                ttruncClCurvUnsign = mean(abs(ttruncClCurvUnsign));
                
                tclCurvUnsign = tempCenterlineCurvatureField;
                tclCurvUnsign = mean(abs(tclCurvUnsign));
                
                
                % pole size ratio
                tLeftPoleSize = mean(tWidth(1:leftStart-1));
                tRightPoleSize = mean(tWidth(rightEnd+1:end));
                tendSizeRat = max(tLeftPoleSize/tRightPoleSize,tRightPoleSize/tLeftPoleSize);
                    
                % sometimes the longAxis does not exist?
                if isempty(tlongAxis)
                    error('aveCellSize:emptyLongAxis','tLongAxis is empty. Skipping cell.')
                end
                
                
                % find which centerline point is closest to each of surface points
                % clIdx(ii) gives the index of the centerline for surface contour point ii
                [~,clIdx] = pdist2(...
                    double(tCL),...
                    [frame.object(kObj).Xcont,frame.object(kObj).Ycont],...
                    'euclidean','smallest',1);
                
                % find the surface idx associated with both poles
                leftPoleSurfIdx = find(clIdx<leftStart);
                rightPoleSurfIdx = find(clIdx>rightEnd);
                bodySurfIdx = find(and(le(clIdx,rightEnd),ge(clIdx,leftStart)));
                
                % outline of cell curvatures  
                if isRecalcCurvature
                    contourCoords = [frame.object(kObj).Xcont,frame.object(kObj).Ycont];
                    contourCoords(:,3) = 1;
                    % closed contour, wrap back around on itself
                    contourCoordsNew = repmat(contourCoords,3,1);
                    tempOutlineCurvatureField = signedCurvature(contourCoordsNew,3);
                    % remove the first wrap around
                    tempOutlineCurvatureField(1:size(contourCoords,1),:) = [];
                    % keep only the second wrap around
                    tempOutlineCurvatureField(size(contourCoords,1)+1:end,:) = [];
                else
                    tempOutlineCurvatureField = frame(jFrame).object(kObj).kappa_smooth(:);
                end

                
                % pull out the curvatures in the poles
                tpoleCurve = cat(1,tempOutlineCurvatureField(leftPoleSurfIdx),...
                    tempOutlineCurvatureField(rightPoleSurfIdx));
                % root mean squared
                tpoleCurve = tpoleCurve.^2;
                tpoleCurve = mean(tpoleCurve);
                tpoleCurve = sqrt(tpoleCurve);
               
                % pull out the curvatures in the body
                tbodyCurve = tempOutlineCurvatureField(bodySurfIdx);
                % root mean squared
                tbodyCurve = tbodyCurve.^2;
                tbodyCurve = mean(tbodyCurve);
                tbodyCurve = sqrt(tbodyCurve);
                
                % mean curvature in the body
                tbodyCurveMean = tempOutlineCurvatureField(bodySurfIdx);
                tbodyCurveMean = mean(tbodyCurveMean);
             
                % curvature of centerline ala MicrobeTracker  
                switch modeString
                    case 'Pill'
                        tempCenterline = frame.object(kObj).centerline;
                    case 'Spine'
                        tempCenterline = double(frame.object(kObj).spine);
                end
                
                tMTCurvature = bestFitCircle(tempCenterline(:,1),...
                    tempCenterline(:,2));
                               
                % total perimeter length  
                tPerimeter = sum(frame.object(kObj).arc_length(:));

%%
            catch ME
                nReject = nReject+1;
                rejectReason{nReject} = ME;
                continue
            end % assemble information
            
            % if all the information was able to be obtained, increase the
            % counter and store it
            nKept = nKept+1;
            
            % store the statistics for this cell
            cellArea(nKept) = tarea*pixSize*pixSize;
            longAxis(nKept) = tlongAxis*pixSize;
            clLength(nKept) = tclLength*pixSize;
            meanWidth(nKept) = tmeanWidth*pixSize;
            truncWidth(nKept) = ttruncWidth*pixSize;
            widthStd(nKept) = twidthStd*pixSize;
            truncWidthStd(nKept) = ttruncWidthStd*pixSize;
            endSizeRat(nKept) = tendSizeRat;
            clCurv(nKept) = tclCurv/pixSize;
            truncClCurv(nKept) = ttruncClCurv/pixSize;
            poleCurv(nKept) = tpoleCurve/pixSize;
            bodyCurv(nKept) = tbodyCurve/pixSize;
            bodyMean(nKept) = tbodyCurveMean/pixSize;
            MTCurvature(nKept) = 1/(tMTCurvature*pixSize);
            
            clCurvUnsign(nKept) = tclCurvUnsign/pixSize; 
            truncClCurvUnsign(nKept) = ttruncClCurvUnsign/pixSize;
            
            surfAreaApprox(nKept) = tSurfaceArea*pixSize*pixSize;
            volumeApprox(nKept) = tVolume*pixSize*pixSize*pixSize;

            perimeterLength(nKept) = tPerimeter*pixSize;
            pixSizePerObject(nKept) = pixSize;
            
            fileIndex(nKept) = iFile;
            frameIndex(nKept) = jFrame;
            objectIndex(nKept) = kObj;
            
        end % objects in this frame
    end % frames in this image file
end % image files in this folder


% size ratios can sometimes be infinite? ignore these
endSizeRat(not(isfinite(endSizeRat))) = nan;
%%
fprintf(1,'\n');
disp([folderName]);
fprintf(1,'\n');

%% new names 20140923
if isRemoveStatisticalOutliers
    for iiIter = 1:3
        % check to see if there are incredibly extreme values
        totalZscores = cat(2, ...
            abs(zscore(cellArea(:))),...
            abs(zscore(longAxis(:))),...
            abs(zscore(clLength(:))),...
            abs(zscore(meanWidth(:))),...
            abs(zscore(truncWidth(:))),...
            abs(zscore(widthStd(:))),...
            abs(zscore(truncWidthStd(:))),...
            abs(zscore(endSizeRat(:))),...
            abs(zscore(clCurv(:))),...
            abs(zscore(truncClCurv(:))),...
            abs(zscore(poleCurv(:))),...
            abs(zscore(bodyMean(:))),...
            abs(zscore(widthStd(:)./meanWidth(:))),...
            abs(zscore(MTCurvature(:))),...
            abs(zscore(clCurvUnsign(:))),...
            abs(zscore(truncClCurvUnsign(:))),...
            abs(zscore(surfAreaApprox(:))),...
            abs(zscore(volumeApprox(:))),...
            abs(zscore(perimeterLength(:)))...
            );
        
        maxZ = max(totalZscores,[],2);
        
        isRemoveVal = maxZ>Z_SCORE_OUTLIER;
        
        if nnz(isRemoveVal)>0
            warning('morphometrics:aveCellSize:extremeOutliers',['Removing ',num2str(nnz(isRemoveVal)),' objects that have extreme properties.']);
            cellArea(isRemoveVal) = nan;
            longAxis(isRemoveVal) = nan;
            clLength(isRemoveVal) = nan;
            meanWidth(isRemoveVal) = nan;
            truncWidth(isRemoveVal) = nan;
            widthStd(isRemoveVal) = nan;
            truncWidthStd(isRemoveVal) = nan;
            endSizeRat(isRemoveVal) = nan;
            clCurv(isRemoveVal) = nan;
            truncClCurv(isRemoveVal) = nan;
            poleCurv(isRemoveVal) = nan;
            bodyCurv(isRemoveVal) = nan;
            bodyMean(isRemoveVal) = nan;
            MTCurvature(isRemoveVal) = nan;
            clCurvUnsign(isRemoveVal) = nan;
            truncClCurvUnsign(isRemoveVal) = nan;
            surfAreaApprox(isRemoveVal) = nan;
            volumeApprox(isRemoveVal) = nan;
            perimeterLength(isRemoveVal) = nan;
            
        end
        
    end
end

% average values
aa = nanmean(cellArea);
ab = nanmean(longAxis);
ac = nanmean(clLength);
ad = nanmean(meanWidth);
ae = nanmean(truncWidth);
af = nanmean(widthStd);
ag = nanmean(truncWidthStd);
ah = nanmean(endSizeRat);
ai = nanmean(clCurv);
aj = nanmean(truncClCurv);
ak = nanmean(poleCurv);
al = nanmean(bodyCurv);
am = nanmean(bodyMean);
an = nanmean(widthStd./meanWidth); % individual cell width variation accounting for cell size (coefficient of variation)
ao = population_COV(meanWidth); % coefficient of variation, sigma/mu for average diameter between cells
ap = nanmean(MTCurvature);
aq = nanmean(clCurvUnsign);
ar = nanmean(truncClCurvUnsign);
as = nanmean(surfAreaApprox);
at = nanmean(volumeApprox);
au = nanmean(perimeterLength);
av = nanmean(surfAreaApprox./volumeApprox);
aw = nanmean(longAxis./meanWidth);

% standard deviations
ba = nanstd(cellArea);
bb = nanstd(longAxis);
bc = nanstd(clLength);
bd = nanstd(meanWidth);
be = nanstd(truncWidth);
bf = nanstd(widthStd);
bg = nanstd(truncWidthStd);
bh = nanstd(endSizeRat);
bi = nanstd(clCurv);
bj = nanstd(truncClCurv);
bk = nanstd(poleCurv);
bl = nanstd(bodyCurv);
bm = nanstd(bodyMean);
bn = nanstd(widthStd./meanWidth);
bo = nan;
bp = nanstd(MTCurvature);
bq = nanstd(clCurvUnsign);
br = nanstd(truncClCurvUnsign);
bs = nanstd(surfAreaApprox);
bt = nanstd(volumeApprox);
bu = nanstd(perimeterLength);
bv = nanstd(surfAreaApprox./volumeApprox);
bw = nanstd(longAxis./meanWidth);

% confidence intervals for the mean
ca = bootci(N_BOOT_SAMPLES,{@nanmean,cellArea},'alpha',BOOT_ALPHA);
cb = bootci(N_BOOT_SAMPLES,{@nanmean,longAxis},'alpha',BOOT_ALPHA);
cc = bootci(N_BOOT_SAMPLES,{@nanmean,clLength},'alpha',BOOT_ALPHA);
cd = bootci(N_BOOT_SAMPLES,{@nanmean,meanWidth},'alpha',BOOT_ALPHA);
ce = bootci(N_BOOT_SAMPLES,{@nanmean,truncWidth},'alpha',BOOT_ALPHA);
cf = bootci(N_BOOT_SAMPLES,{@nanmean,widthStd},'alpha',BOOT_ALPHA);
cg = bootci(N_BOOT_SAMPLES,{@nanmean,truncWidthStd},'alpha',BOOT_ALPHA);
ch = bootci(N_BOOT_SAMPLES,{@nanmean,endSizeRat},'alpha',BOOT_ALPHA);
ci = bootci(N_BOOT_SAMPLES,{@nanmean,clCurv},'alpha',BOOT_ALPHA);
cj = bootci(N_BOOT_SAMPLES,{@nanmean,truncClCurv},'alpha',BOOT_ALPHA);
ck = bootci(N_BOOT_SAMPLES,{@nanmean,poleCurv},'alpha',BOOT_ALPHA);
cl = bootci(N_BOOT_SAMPLES,{@nanmean,bodyCurv},'alpha',BOOT_ALPHA);
cm = bootci(N_BOOT_SAMPLES,{@nanmean,bodyMean},'alpha',BOOT_ALPHA);
cn = bootci(N_BOOT_SAMPLES,{@nanmean,(widthStd./meanWidth)},'alpha',BOOT_ALPHA);
co = bootci(N_BOOT_SAMPLES, {population_COV, meanWidth},'alpha',BOOT_ALPHA);
cp = bootci(N_BOOT_SAMPLES,{@nanmean,MTCurvature},'alpha',BOOT_ALPHA);
cq = bootci(N_BOOT_SAMPLES,{@nanmean,clCurvUnsign},'alpha',BOOT_ALPHA);
cr = bootci(N_BOOT_SAMPLES,{@nanmean,truncClCurvUnsign},'alpha',BOOT_ALPHA);
cs = bootci(N_BOOT_SAMPLES,{@nanmean,surfAreaApprox},'alpha',BOOT_ALPHA);
ct = bootci(N_BOOT_SAMPLES,{@nanmean,volumeApprox},'alpha',BOOT_ALPHA);
cu = bootci(N_BOOT_SAMPLES,{@nanmean,perimeterLength},'alpha',BOOT_ALPHA);
cv = bootci(N_BOOT_SAMPLES,{@nanmean,surfAreaApprox./volumeApprox},'alpha',BOOT_ALPHA);
cw = bootci(N_BOOT_SAMPLES,{@nanmean,longAxis./meanWidth},'alpha',BOOT_ALPHA);




% confidence interval on standard deviation of width
da =  bootci(N_BOOT_SAMPLES,{@nanstd,cellArea},'alpha',BOOT_ALPHA);
db =  bootci(N_BOOT_SAMPLES,{@nanstd,longAxis},'alpha',BOOT_ALPHA);
dc =  bootci(N_BOOT_SAMPLES,{@nanstd,clLength},'alpha',BOOT_ALPHA);
dd =  bootci(N_BOOT_SAMPLES,{@nanstd,meanWidth},'alpha',BOOT_ALPHA);
de =  bootci(N_BOOT_SAMPLES,{@nanstd,truncWidth},'alpha',BOOT_ALPHA);
df =  bootci(N_BOOT_SAMPLES,{@nanstd,widthStd},'alpha',BOOT_ALPHA);
dg =  bootci(N_BOOT_SAMPLES,{@nanstd,truncWidthStd},'alpha',BOOT_ALPHA);
dh =  bootci(N_BOOT_SAMPLES,{@nanstd,endSizeRat},'alpha',BOOT_ALPHA);
di =  bootci(N_BOOT_SAMPLES,{@nanstd,clCurv},'alpha',BOOT_ALPHA);
dj =  bootci(N_BOOT_SAMPLES,{@nanstd,truncClCurv},'alpha',BOOT_ALPHA);
dk =  bootci(N_BOOT_SAMPLES,{@nanstd,poleCurv},'alpha',BOOT_ALPHA);
dl =  bootci(N_BOOT_SAMPLES,{@nanstd,bodyCurv},'alpha',BOOT_ALPHA);
dm =  bootci(N_BOOT_SAMPLES,{@nanstd,bodyMean},'alpha',BOOT_ALPHA);
dn =  bootci(N_BOOT_SAMPLES,{@nanstd,(widthStd./meanWidth)},'alpha',BOOT_ALPHA);
% do =  bootci(nBootSamples,@nanstd,,'alpha',BOOT_ALPHA);
do = [nan;nan];
dp =  bootci(N_BOOT_SAMPLES,{@nanstd,MTCurvature},'alpha',BOOT_ALPHA);
dq =  bootci(N_BOOT_SAMPLES,{@nanstd,clCurvUnsign},'alpha',BOOT_ALPHA);
dr =  bootci(N_BOOT_SAMPLES,{@nanstd,truncClCurvUnsign},'alpha',BOOT_ALPHA);
ds =  bootci(N_BOOT_SAMPLES,{@nanstd,surfAreaApprox},'alpha',BOOT_ALPHA);
dt =  bootci(N_BOOT_SAMPLES,{@nanstd,volumeApprox},'alpha',BOOT_ALPHA);
du = bootci(N_BOOT_SAMPLES,{@nanstd,perimeterLength},'alpha',BOOT_ALPHA);
dv = bootci(N_BOOT_SAMPLES,{@nanstd,surfAreaApprox./volumeApprox},'alpha',BOOT_ALPHA);
dw = bootci(N_BOOT_SAMPLES,{@nanstd,longAxis./meanWidth},'alpha',BOOT_ALPHA);

%% save the results as a mat file

%save([transcodeDate(now),'.mat']);
%% print out the results to the display
disp([num2str(nKept),' cells kept.']);
disp([num2str(nReject),' cells rejected.']);

disp(['Average area: ',num2str(aa,'%4.5g'),' um^2 ',...
    char(177),' ',num2str(ba,'%4.5g'),' um^2.'])

disp(['Average long axis: ',num2str(ab,'%4.5g'),' um ',...
    char(177),' ',num2str(bb,'%4.5g'),' um.'])

disp(['Average centerline length: ',num2str(ac,'%4.5g'),' um ',...
    char(177),' ',num2str(bc,'%4.5g'),' um.'])

disp(['Average width: ',num2str(ad,'%4.5g'),' um ',...
    char(177),' ',num2str(bd,'%4.5g'),' um.'])

disp(['Average width (no poles): ',num2str(ae,'%4.5g'), ' um ',...
    char(177),' ',num2str(be,'%4.5g'),' um.'])

disp(['Diameter std: ',num2str(af,'%4.5g'),' um ',...
    char(177),' ',num2str(bf,'%4.5g'),' um.'])

disp(['Diameter std (no poles): ',num2str(ag,'%4.5g'),' um ',...
    char(177),' ',num2str(bg,'%4.5g'),' um.'])

disp(['Pole size ratio: ',num2str(ah,'%4.5g'),' ',...
    char(177),' ',num2str(bh,'%4.5g'),'.'])

%disp(['RMS centerline curvature: ',num2str(ai,'%4.5g'),' um^-1 ',...
    %char(177),' ',num2str(bi,'%4.5g'),' um^-1.'])

disp(['RMS centerline curvature (no poles): ',num2str(aj,'%4.5g'),' um^-1 ',...
    char(177),' ',num2str(bj,'%4.5g'),' um^-1.'])

disp(['RMS surface pole curvature: ',num2str(ak,'%4.5g'),' um^-1 ',...
    char(177),' ',num2str(bk,'%4.5g'),' um^-1.'])

disp(['RMS surface non-pole curvature: ',num2str(al,'%4.5g'),' um^-1 ',...
    char(177),' ',num2str(bl,'%4.5g'),' um^-1.'])

disp(['Mean surface curvature non-pole: ',num2str(am,'%4.5g'),' um^-1 ',...
       char(177), ' ',num2str(bm,'%4.5g'),' um^-1.'])

disp(['Coefficient of variation of width: ',num2str(an, '%4.5g'),...
    char(177), ' ',num2str(bn, '%4.5g')]);

disp(['C-O-V_{betweenCells}: ',num2str(ao, '%4.5g')]);

disp(['MicrobeTracker curvature: ',num2str(ap, '%4.5g'),...
    char(177), ' ',num2str(bp, '%4.5g'),' um^-1.']);

disp(['Mean unsigned centerline curvature: ',num2str(aq,'%4.5g'),' um^-1 ',...
    char(177),' ',num2str(bq,'%4.5g'),' um^-1.'])

disp(['Mean unsigned centerline curvature (no poles): ',num2str(ar,'%4.5g'),' um^-1 ',...
    char(177),' ',num2str(br,'%4.5g'),' um^-1.'])

disp(['Mean surface area (cylindrical segment approximation): ',num2str(as,'%4.5g'),' um^2 ',...
    char(177),' ',num2str(bs,'%4.5g'),' um^2.'])

disp(['Mean volume (cylindrical segment approximation): ',num2str(at,'%4.5g'),' um^3 ',...
    char(177),' ',num2str(bt,'%4.5g'),' um^3.'])

disp(['Mean perimeter length: ',num2str(au,'%4.5g'),' um ',...
    char(177),' ',num2str(bu,'%4.5g'),' um.'])


%% print out for copying into excel
% averages
fprintf(1,['\n',...
    num2str(nKept),'\t',...
    num2str(aa,'%4.3g'),' ',char(177),' ',...
    num2str(ba,'%4.3g'),'\t',...
    num2str(ab,'%4.3g'),' ',char(177),' ',...
    num2str(bb,'%4.3g'),'\t'...
    num2str(ac,'%4.3g'),' ',char(177),' ',...
    num2str(bc,'%4.3g'),'\t'...
    num2str(ad,'%4.3g'),' ',char(177),' ',...
    num2str(bd,'%4.3g'),'\t'...
    num2str(ae,'%4.3g'),' ',char(177),' ',...
    num2str(be,'%4.3g'),'\t'...
    num2str(af,'%4.3g'),' ',char(177),' ',...
    num2str(bf,'%4.3g'),'\t'...
    num2str(ag,'%4.3g'),' ',char(177),' ',...
    num2str(bg,'%4.3g'),'\t'...
    ...%num2str(ah,'%4.3g'),' ',char(177),' ',...
    ...%num2str(bh,'%4.3g'),'\t'...
    ...%num2str(ai,'%4.3g'),' ',char(177),' ',...
    ...%num2str(bi,'%4.3g'),'\t'...
    num2str(aj,'%4.3g'),' ',char(177),' ',...
    num2str(bj,'%4.3g'),'\t'...
    ...%num2str(ak,'%4.3g'),' ',char(177),' ',...
    ...%num2str(bk,'%4.3g'),'\t'...
    num2str(al,'%4.3g'),' ',char(177),' ',...
    num2str(bl,'%4.3g'),'\t'...
    num2str(an,'%4.3g'),' ',char(177),' ',...
    num2str(bn,'%4.3g'),'\t'...
    num2str(ao,'%4.3g'),'\t'...
    num2str(ar,'%4.3g'),' ',char(177),' ',...
    num2str(br,'%4.3g'),'\t'...
    num2str(av,'%4.3g'),' ',char(177),' ',...
    num2str(bv,'%4.3g'),'\t'...
    num2str(aw,'%4.3g'),' ',char(177),' ',...
    num2str(bw,'%4.3g'),'\t'...
    '\n'])

% confidence intervals
fprintf(1,[...
    ' ','\t',...
    num2str(ca','%4.3g  '),'\t',...
    num2str(cb','%4.3g  '),'\t',...
    num2str(cc','%4.3g  '),'\t',...
    num2str(cd','%4.3g  '),'\t',...
    num2str(ce','%4.3g  '),'\t',...
    num2str(cf','%4.3g  '),'\t',...
    num2str(cg','%4.3g  '),'\t',...
    ...%num2str(ch','%4.3g  '),'\t',...
    ...%num2str(ci','%4.3g  '),'\t',...
    num2str(cj','%4.3g  '),'\t',...
    ...%num2str(ck','%4.3g  '),'\t',...
    num2str(cl','%4.3g  '),'\t',...
    num2str(cn','%4.3g  '),'\t',...
    num2str(co','%4.3g  '),'\t',...
    num2str(cr','%4.3g  '),'\t',...    
    num2str(cv','%4.3g  '),'\t',... 
    num2str(cw','%4.3g  '),'\t',... 
    ]);


fprintf(1,'\n');

fprintf(1,[...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    num2str(dd','%4.3g  '),'\t',...
    num2str(de','%4.3g  '),'\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ' ','\t',...
    ]);

% new line
fprintf(1,'\n');


%%

%% measurementString comes from header writing
if not(isBatchAveCellSize)
[fidA,measurementString] = aveCellSize_writeOutputHeader({folderName});
end

fieldNameList = {'fieldnames'};
for jj = 1:length(measurementString)
%     for kk = 1:length(measurementType)
        fieldNameList = cat(2,fieldNameList,char(['a',96+jj]));
        fieldNameList = cat(2,fieldNameList,char(['c',96+jj]));
        fieldNameList = cat(2,fieldNameList,char(['b',96+jj]));
        fieldNameList = cat(2,fieldNameList,char(['d',96+jj]));
end
  
aggregatedMeasurements = v2struct(fieldNameList);

    
%% write out the measurements
fullFolderPath = folderName;
[parent,endingString] = fileparts(folderName);
[grandParent,parentString] = fileparts(parent);
fullFolderPath = strrep(fullFolderPath,'\','\\');
endingString = strrep(endingString,'\','\\');
parentString = strrep(parentString,'\','\\');
grandParent = strrep(grandParent,'\','\\');
%% output style 3, one row per sample
% if isBatchAveCellSize
%     fidA = getappdata(0,'batchAveCellSizeOutputFID');
% else
%    fidA = getappdata(0,'batchAveCellSizeOutputFID');
% end
% 


% 
% 
% for jj = 2:numel(fieldNameList);
%     switch fieldNameList{jj}(1)
%         case {'a','b'}
%             fprintf(fidA,[fieldNameList{jj},',']);
%         case {'c','d'}
%             fprintf(fidA,[fieldNameList{jj},'-lower,']);
%             fprintf(fidA,[fieldNameList{jj},'-upper,']);
%     end
% end
% fprintf(fidA,'\n');

% single valued measurements
% handle the batch processing, pull the sample number from the calling
% function
if not(isBatchAveCellSize)
    fprintf(fidA,'1,'); 
else
    fprintf(fidA,[num2str(mmFolder),',']); 
end
fprintf(fidA,[fullFolderPath,',']);
fprintf(fidA,[parentString,',']);
fprintf(fidA,[endingString,',']);
fprintf(fidA,[parentString,':',endingString,',']);
fprintf(fidA,[num2str(nKept),',']);
fprintf(fidA,[num2str(nReject),',']);

% averages and standard deviations
for jj = 2:numel(fieldNameList);
    switch fieldNameList{jj}(1)
        case {'a','b'}
            fprintf(fidA,[num2str(aggregatedMeasurements.(fieldNameList{jj})),',']);
        case {'c','d'}
            fprintf(fidA,[num2str(aggregatedMeasurements.(fieldNameList{jj})(1)),',']);
            fprintf(fidA,[num2str(aggregatedMeasurements.(fieldNameList{jj})(2)),',']);
    end
end
fprintf(fidA,'\n');

if not(isBatchAveCellSize)
fclose(fidA);
end
