folderList = uipickfiles('Prompt','Please select folders');
[storedOutputFolder] = uigetdir();
DEFAULT_RECURSE = 10;
N_BOOT_SAMPLES = 500;
BOOT_ALPHA = 0.05;
%%
if numel(folderList) == 0;
    disp('Finished');
    return;
end


if numel(folderList) == 1; % check to see if this is a folder of folders, or just a folder of files
    subdirList = dir([folderList{1},filesep]);
    % remove . and .. and ~
    for kkSubdir = length(subdirList):-1:1
        if strncmpi(subdirList(kkSubdir).name,'.',1);
            subdirList(kkSubdir) = [];
            continue
        elseif strncmpi(subdirList(kkSubdir).name,'~',1);
            subdirList(kkSubdir) = [];
            continue
        end
    end
    
    nFolders = nnz([subdirList.isdir]);
    nFiles = nnz(not([subdirList.isdir]));
    
    if and(nFiles,nFolders);
        if nFiles>nFolders
            warning('spotCounts:batchMode:indeterminateFolderSelection:assumeFiles',...
                ['Ambiguous selection. More files than subdirectories in ',folderList{1},...
                '. Running as single folder mode and ignoring subdirectories.']);
            isUseAllChildFolders = false;
            recurseLevel = 0;
        elseif nFolders>nFiles
            recurseLevel = DEFAULT_RECURSE;
            
            warning('spotCounts:batchMode:indeterminateFolderSelection:assumeFolders',...
                ['Ambiguous selection. More subdirectories than files in ',folderList{1},...
                '. Running as batch on subdirectories and ignoring files. ',...
                'Using ''DEFAULT_RECURSE'' = ',num2str(DEFAULT_RECURSE),'.']);
            isUseAllChildFolders = true;
        else
            warning('spotCounts:batchMode:indeterminateFolderSelection:equalFilesAndFolders',...
                ['Ambiguous selection. ',folderList{1},...
                ' contains files and subdirectories. Aborting.']);
            return
        end
    elseif and(~nFiles,~nFolders)
        warning('spotCounts:batchMode:indeterminateFolderSelection:noFilesOrFolders',...
            ['Ambiguous selection. ',folderList{1},...
            ' contains neither files nor subdirectories. Aborting.']);
        return
    elseif nFiles
        isUseAllChildFolders = false;
        recurseLevel = 0;
    else
        isUseAllChildFolders = true;
        recurseLevel = DEFAULT_RECURSE;
    end
else
    isUseAllChildFolders = false;
end
%
if isUseAllChildFolders
    while recurseLevel>1
        newFolderList = [];
        for kkFolder = 1:length(folderList)
            tFolderList = dir(folderList{kkFolder});
            
            % remove . and .. and ~ and files
            for llSubdir = length(tFolderList):-1:1
                if strncmpi(tFolderList(llSubdir).name,'.',1);
                    tFolderList(llSubdir) = [];
                    continue
                elseif strncmpi(tFolderList(llSubdir).name,'~',1);
                    tFolderList(llSubdir) = [];
                    continue
                elseif not(tFolderList(llSubdir).isdir)
                    tFolderList(llSubdir) = [];
                    continue
                end
            end
            
            if nnz([tFolderList.isdir])==0;
                newFolderList = cat(1,newFolderList,{folderList{kkFolder}});
            else
                for  llSubdir = 1:length(tFolderList)
                    newFolderList = cat(1,newFolderList,{[folderList{kkFolder},filesep,tFolderList(llSubdir).name]});
                end
            end
        end
        recurseLevel = recurseLevel-1;
        folderList = newFolderList;
    end
end
%% Loop over folder list
progressbar('folders');
storedOutputFID = fopen([storedOutputFolder,filesep,'batchSpotCountsOutput.csv'],'w+');
fprintf(storedOutputFID,'%s',strjoin({'folderName','numberOfObjects',...
    'intensity_arbUnits','intensity_arbUnits_CI-low','intensity_arbUnits_CI-low'...
    'area_pixels','area_pixels_CI-low','area_pixels_CI-low',...
    'brightness_arbUnitsPerPixels','brightness_arbUnitsPerPixels_CI-low','brightness_arbUnitsPerPixels_CI-high', 'brightnessSTD'},','));

%%

for iiFolder = 1:numel(folderList)
    progressbar((iiFolder-1)/numel(folderList));
    tempFiles = dir([folderList{iiFolder},filesep,'*CONTOURS.mat']);
    % clear the fileList variable between folders in case each one has a
    % different number of files
    clear fileList;
    for iiFile = 1:length(tempFiles)
        fileList(iiFile) = {[folderList{iiFolder},filesep,tempFiles(iiFile).name]};
        fileListForBetterSpotFinder(iiFile) = {[tempFiles(iiFile).name]};
    end
    
    % use default values for most of the input parameters
    MIN_SBR = 10;
    THRESHOLD_CELLS = 3;
    offsetY = 0;
    offsetX = 0;
    isDisplayImages2 = 0;
    isSingleFileSummary = 0;
    
    % ASSUMPTION: two color channels with names c=1 and c=2
    
    for gfpChannel = {'1'}
        %For each directory, run BetterSpotFinder on a number of fluorescent
        %channels saving a set of SPOT files for each channel
%         BetterSpotFinder(folderList{iiFolder}, ... name of the folder
%             fileListForBetterSpotFinder,... cell array of a file list
%             THRESHOLD_CELLS,... threshold for segmenting spots, relative to mean intensity
%             gfpChannel,... string for name of color channel of interest
%             isDisplayImages2,... boolean for displaying segmented images
%             isSingleFileSummary,... boolean for displaying summary per file
%             offsetX,... % pixels to offset between segmented and color channel of interest
%             offsetY,... % pixels to offset between segmented and color channel of interest
%             MIN_SBR); % minimum signal to background ratio
        
        % rename to include the color channel being used
        spotFiles = dir([folderList{iiFolder},filesep,'*SPOTS.mat']);
        clear aggregatedCells cellArea cellIntensity   recal
        aggregatedCells = [];
        for iiFile = 1 :numel(spotFiles)
            if strcmp(spotFiles(iiFile).name(1:2),'._')
                continue
            end

%             movefile([folderList{iiFolder},filesep,spotFiles(iiFile).name],...
%                 [folderList{iiFolder},filesep,[strrep(spotFiles(iiFile).name,'SPOTS.mat',...
%                 ['SPOTS_c=',gfpChannel{1},'.mat'])]]);
%             
            % Run SpotCounts on each set of SPOT files per sample, per channel
            
            
            
%             tempLoad = load([folderList{iiFolder},filesep,[strrep(spotFiles(iiFile).name,'SPOTS.mat',...
%                 ['SPOTS_c=',gfpChannel{1},'.mat'])]],'totalCells','THRESHOLD_CELLS');
        tempLoad = load([folderList{iiFolder},filesep,spotFiles(iiFile).name],'totalCells','THRESHOLD_CELLS');
% check to make sure that the same threshold was used for all the files
            if not (exist('tempThresh', 'var'))
                tempThresh = tempLoad.THRESHOLD_CELLS;
            else
                if tempThresh ~= tempLoad.THRESHOLD_CELLS
                    error('morphometrics:spotcounts:batchMode:spotthresholdsdiffer',...
                        ['spot threshold is different between ', ...
                        matFileList{iiFile-1}, ' and ', matFileList{iiFile},'.']);
                else
                    tempThresh = tempLoad.THRESHOLD_CELLS;
                    
                end
            end
            
            % aggregate all cells for a single condition together
            aggregatedCells = cat(1,aggregatedCells,tempLoad.totalCells');
        end
        
        %%
        % on a per cell basis, pull out relevant pieces of information
        for iCell = 1:length(aggregatedCells)
            cellIntensity(iCell) = aggregatedCells(iCell).totalCellIntensity;
            cellArea(iCell) = aggregatedCells(iCell).cellArea;
        end
        
        
        
        %Calculate Statistics of pixel intensities in cells and output to CSV
        disp(folderList{iiFolder})
        meanCellIntensity = mean(cellIntensity);
        meanCellIntensityCI = bootci(N_BOOT_SAMPLES,{@nanmean,cellIntensity},'alpha',BOOT_ALPHA);
        
        meanCellArea = mean(cellArea);
        meanCellAreaCI = bootci(N_BOOT_SAMPLES,{@nanmean,cellArea},'alpha',BOOT_ALPHA);
        
        meanCellBrightness = mean(cellIntensity./cellArea);
        meanCellBrightnessCI = bootci(N_BOOT_SAMPLES,{@nanmean,cellIntensity./cellArea},'alpha',BOOT_ALPHA);
        CellBrightnessSTD = std(cellIntensity./cellArea);
        
        fprintf(storedOutputFID,'\r\n');
        fprintf(storedOutputFID,'%s',[folderList{iiFolder},',']);
        fprintf(storedOutputFID,'%s',num2str(numel(cellIntensity)),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellIntensity)),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellIntensityCI(1))),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellIntensityCI(2))),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellArea)),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellAreaCI(1))),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellAreaCI(2))),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellBrightness)),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellBrightnessCI(1))),',');
        fprintf(storedOutputFID,'%s',num2str((meanCellBrightnessCI(2))),',');
        fprintf(storedOutputFID,'%s',num2str((CellBrightnessSTD)));

       
    end
end
fclose(storedOutputFID);
progressbar(1);

