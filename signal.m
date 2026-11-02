function signal(repeat);

if nargin < 1
    %% select files with contours
    [matName,matPath] = uigetfile('.mat','Please select .mat file(s) with contours','MultiSelect','on');
    % allow first cancel to actually cancel
    if matPath==0
        return
    end
    
    channel(1).type = questdlg('What type of image was used for the contours?','','phase','fluor','phase');
    
    
    %     load(fullfile(matPath,matName));
    if not(iscell(matName))
        matName = {matName};
    end
    %
    % select folder with images
    channel(1).path = matPath;
    iChannel=1;
    isAnotherChannel = true;
    while isAnotherChannel
        iChannel = iChannel + 1;
        [~,channel(iChannel).path] = uigetfile(['*.*'],['Select a file from folder ',num2str(iChannel),' for ',channel(1).path]);
        % check to see if cancel was selected
        if channel(iChannel).path==0
            break
        end
        channel(iChannel).label = inputdlg(['What label to give to channel ',num2str(iChannel),'?'],...
            'Channel label',1,{['Channel',num2str(iChannel)]});
        channel(iChannel).type = questdlg('What type of image?',['Channel: ',num2str(iChannel)],'phase','fluor','fluor');
    end
    
    % subtract final from cancelled
    channel(iChannel) = [];
    % subtract 1 for contours image
    nOtherChannels = size(channel,2)-1;
    
    setappdata(0,'signalChannels',channel);
    setappdata(0,'signalOtherChannels',nOtherChannels);
    setappdata(0,'signalMatName',matName);
    setappdata(0,'signalMatPath',matPath);
    
else
    channel = getappdata(0,'signalChannels');
    nOtherChannels = getappdata(0,'signalOtherChannels');
    matName = getappdata(0,'signalMatName');
    matPath = getappdata(0,'signalMatPath');
end

%% run segment companion images on each of the mat files
progressbar(0);
progressbar('mat files','frames', 'cells')     % Initialize/reset two bars with two labels

params.progbar.type = 'multipleFiles';
params.progbar.fileIncrement = 1/size(matName,2);
for iiMat = 1:size(matName,2);
    params.progbar.currentFile = -10*eps+(iiMat-1)*params.progbar.fileIncrement;
%     progressbar((iiMat-1)/size(matName,2)+10*eps,[],[]);
    for iChannel=1:nOtherChannels+1
        channel(iChannel).name = strrep(matName{iiMat},'CONTOURS.mat','.tif');
        whereIsC0 = strfind(channel(iChannel).name,'C=');
        whereIsDotTif = strfind(channel(iChannel).name,'.tif');
        channel(iChannel).name = [channel(iChannel).name(1:whereIsC0+1),...
            num2str(iChannel-1),channel(iChannel).name(whereIsDotTif:end)];
    
    end
    
    segmentCompanionImages(channel,matName{iiMat},params);
end

progressbar(1);


%%