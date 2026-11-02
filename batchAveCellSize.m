function batchAveCellSize(varargin);
% NM190603 added to support passing folders as a cell array into batchAveCellSize
if nargin == 0
    folderList = uipickfiles('Prompt','Please select folders');
    called = 0;
    
    saveAggregatedData = questdlg('Save aggregated datasets?','','yes','no','yes');
    if strcmp(saveAggregatedData,'yes')
        saveAggregatedDataIdentifier = questdlg('File identifier?','','s=','entire','s=');
    end
    
    % BPB 20190523 given the vagaries and pixel dependent nature of calculating
    % curvature, allow the user to select the version of curvature estimation
    % present when the centerlines are generated or recalculate on the fly
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
    
elseif nargin == 1
    %NM190603 added to support passing folders as a cell array into batchAveCellSize
    %if there is an argument passed in set the flag called to indicate this
    called = 1;
    %folder will be where the outputs are eventually saved
    folder = varargin{1};
    %open up that folder and make a list of all the folders in the top
    %level of that folder to analyze
    subfolder = dir(folder{1}) ;
    for subdir = 3:size(subfolder,1)
        if subfolder(subdir).isdir
            folderList(subdir-2) = {fullfile(subfolder(subdir).folder,subfolder(subdir).name)};
        end
    end
    % set default values for dialogue options
    saveAggregatedData = 'yes';
    saveAggregatedDataIdentifier = 'entire';
    isRecalcCurvature = 1;
    isRemoveStatisticalOutliers = 0;
end
DEFAULT_RECURSE = 10;
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
            warning('aveCellSize:batchMode:indeterminateFolderSelection:assumeFiles',...
                ['Ambiguous selection. More files than subdirectories in ',strrep(folderList{1},'\','\\'),...
                '. Running as single folder mode and ignoring subdirectories.']);
            isUseAllChildFolders = false;
            recurseLevel = 0;
        elseif nFolders>nFiles
            recurseLevel = DEFAULT_RECURSE;
            
            warning('aveCellSize:batchMode:indeterminateFolderSelection:assumeFolders',...
                ['Ambiguous selection. More subdirectories than files in ',strrep(folderList{1},'\','\\'),...
                '. Running as batch on subdirectories and ignoring files. ',...
                'Using ''DEFAULT_RECURSE'' = ',num2str(DEFAULT_RECURSE),'.']);
            isUseAllChildFolders = true;
        else
            warning('aveCellSize:batchMode:indeterminateFolderSelection:equalFilesAndFolders',...
                ['Ambiguous selection. ',strrep(folderList{1},'\','\\'),...
                ' contains files and subdirectories. Aborting.']);
            return
        end
    elseif and(~nFiles,~nFolders)
        warning('aveCellSize:batchMode:indeterminateFolderSelection:noFilesOrFolders',...
            ['Ambiguous selection. ',strrep(folderList{1},'\','\\'),...
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

%% loop over all the folders
try
    setappdata(0,'isBatchAveCellSize',true);
    modeString = 'batchMode-unknownMeshType';
    % NM190603 added to support passing folders as a cell array into batchAveCellSize
    if called
        %if you passed in a folder to start, pass on the folder to save the
        %mat files into (folder) and the folders to save the individual
        %population data into (folderList)
        [fidA,measurementString] = aveCellSize_writeOutputHeader(folder,folderList);
    else
        [fidA,measurementString] = aveCellSize_writeOutputHeader(folderList);
    end
    aveCellSizeOutputFName = fopen(fidA);
    
    aveCellSizeTag = strrep(aveCellSizeOutputFName,'.csv','');
    for mmFolder = 1:length(folderList)
        %         if ~called
        %             progressbar((mmFolder-1)/length(folderList),[]);
        %         elseif ~(mmFolder-1)/length(folderList)==0
        %             progressbar((mmFolder-1)/length(folderList),[]);
        %         end
        folderName = folderList{mmFolder};
        aveCellSize;
        switch            saveAggregatedData
            case 'yes'
                %NRM 190601
                %I want cells in the aggregated dataset to have the
                %filename they came from, not just the index in the batch
                
                %                 for each sample use fileIndex to index into fileList and
                %                 build a cell array of mesh files corresponding to each
                %                 contour
                fileName=[];
                for i = 1:size(fileIndex,2)
                    fileName{i}=fileList(fileIndex(i)).name;
                end
                % store the data as a .mat file
                cellIDD = widthStd./meanWidth;
                save([aveCellSizeTag,'-sample',num2str(mmFolder),'.mat'],...
                    'cellArea','truncClCurv','perimeterLength',...
                    'widthStd','clLength','meanWidth','cellIDD','folderName',...
                    'surfAreaApprox','volumeApprox','longAxis',...
                    'fileIndex', 'frameIndex', 'objectIndex','fileName');
                
                % store the data as a CSV
                fidC = fopen([folderName,filesep,'cellSizeCompilation-',num2str(mmFolder),'.csv'],'w+');
                fprintf(fidC,'%s',['sampleID,objectID,sampleName,filePath,',...
                    'cellLength,avgCellWidth,',...
                    'stdCellWidth,approxSurfArea,',...
                    'approxVolume,centerlineCurv_noPolesRMS,',...
                    'truncWidth,',...
                    'SAVRatio,',...
                    'aspectRatio',...
                    'subsampleFileID,subsampleFrameID,subsampleObjectID']);
                [~,sampleName] = fileparts(folderName);
                for kkObjectInSample = 1:numel(cellArea);
                    fprintf(fidC,'\r\n');
                    fprintf(fidC,'%g,',[mmFolder,kkObjectInSample]);
                    fprintf(fidC,'%s,',sampleName);
                    fprintf(fidC,'%s,',folderName);
                    
                    fprintf(fidC,'%g,',...
                        [longAxis(kkObjectInSample),meanWidth(kkObjectInSample),...
                        widthStd(kkObjectInSample),surfAreaApprox(kkObjectInSample),...
                        volumeApprox(kkObjectInSample),truncClCurv(kkObjectInSample),...
                        truncWidth(kkObjectInSample),...
                        surfAreaApprox(kkObjectInSample)./volumeApprox(kkObjectInSample)...
                        longAxis(kkObjectInSample)./meanWidth(kkObjectInSample)...
                        fileIndex(kkObjectInSample),frameIndex(kkObjectInSample),objectIndex(kkObjectInSample)]);
                end
                fclose(fidC)
                %           switch saveAggregatedDataIdentifier
                %                 case 's='
                %                 case 'entire'
                %                 case 'otherwise'
                %             end
        end
        if mmFolder ~= length(folderList)
            progressbar(mmFolder/length(folderList),[]);
        end
    end
catch ME
    % set the default back to 0 so that it can run single folder
    % aveCellSize
    setappdata(0,'isBatchAveCellSize',false);
    rethrow(ME)
end

% when finished, close output file and end progressbar
fclose (fidA);
progressbar(1);
%% ---- old ------
% aggregateStats = [];
% labels = [];
% clear labelNames;
% %%
% for iiFolder = 1:length(folderList);
%     folderName = folderList{iiFolder};
%     aveCellSize;
%     labels = cat(1,labels,repmat(iiFolder,length(widthStd),1));
%     aggregateStats = cat(1,aggregateStats,widthStd');
%     [label1,label2] = fileparts(folderList{iiFolder});
%     [~,label3] = fileparts(label1);
%     labelNames{iiFolder} = [label3,filesep,label2];
%
% end
% %%
% clf;
% %plot(3,1,1);
% % box and whisker plots
% boxplot(aggregateStats,labels,'notch','on','labels',labelNames);
% ylabel('Diameter deviation (pixel)');
% ylimits = ylim();
% ylim([0,1.1* ylimits(2)]);
% % subplot(3,1,2);
% % violin plots
% % violinScale = 8;
% % hold on;
% % for ii = 1:length(labelNames)
% % [counts,x] = ksdensity(aggregateStats(labels==ii));
% % plot(ii+violinScale*counts/sum(counts),x,'k');
% % plot(ii-violinScale*counts/sum(counts),x,'k');
% % end
% % set(gca,'xtick',1:length(labelNames),'xticklabels',labelNames);
% % ylabel('Diameter deviation (pixel)');
% % ylimits = ylim();
% % ylim([0,1.1*ylimits(2)]);
% % subplot(3,1,3);
% % % violin plots
% % violinScale = 2;
% % hold on;
% % for ii = 1:length(labelNames)
% % [counts,x] = hist(aggregateStats(labels==ii),25);
% % plot(ii+violinScale*counts/sum(counts),x,'k');
% % plot(ii-violinScale*counts/sum(counts),x,'k');
% % end
% % set(gca,'xtick',1:length(labelNames),'xticklabels',labelNames);
% % ylabel('Diameter deviation (pixel)');
% % ylimits = ylim();
% % ylim([0,1.1*ylimits(2)]);
