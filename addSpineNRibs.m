function addSpineNRibs(fileList);
% This function will loop over the objects in a morphometrics CONTOUR file
% and add spines and ribs to it. This is an analogous process to MT_mesh_cl
% which generates PILL_mesh files
%
% USAGE: 
% addSpineNRibs(fileList); % where fileList is a cell array of valid
%                          % fileNames or folderNames, operate on each
%                          % file, and ALL contour files in those folders
% addSpineNRibs(); % prompt the user for a list of files/folders to process
%

% what string should be used to match contours files
CONTOURS_STRING_MATCH = '_CONTOURS.mat';
PILLMESH_STRING_MATCH = '_pill_MESH.mat';
FULLMESH_STRING_MATCH = '_full_MESH.mat';

% process input arguments
if nargin==0
   fileList = uipickfiles();
   % politely return if no files are selected
   if isempty(fileList)
       return
   end
end

% correct the input if it isn't a cell array
if not(iscell(fileList))
    fileList = {fileList};
end

% look at the list and see if there are any that should be expanded as
% folders
for kkFile = length(fileList):-1:1
    if isdir(fileList{kkFile})
        folderContents = dir([fileList{kkFile},filesep,'*',CONTOURS_STRING_MATCH]);
        for jjFile = 1:length(folderContents)
            fileList = cat(1,fileList,{[fileList{kkFile},filesep,folderContents(jjFile).name]});
        end
        
        % remove the original folder from the list
        fileList(kkFile) = [];
    end
end

% look at the list and see if there are any that don't match the
% appropriate string
for kkFile = length(fileList):-1:1
    % assume the file doesn't match a naming convention
    isRemoveFile = true;
    tempFileName = fileList{kkFile};
    tempFileName = strrep(tempFileName,'\','/');
    % contours file
    if strcmp(tempFileName((end-length(CONTOURS_STRING_MATCH)+1):end),CONTOURS_STRING_MATCH)
       isRemoveFile = false;
    end
    
    % pill_MESH file
    if strcmp(tempFileName((end-length(PILLMESH_STRING_MATCH)+1):end),PILLMESH_STRING_MATCH)
       isRemoveFile = false;
    end
    
    % full_MESH file
    if strcmp(tempFileName((end-length(FULLMESH_STRING_MATCH)+1):end),FULLMESH_STRING_MATCH)
       isRemoveFile = false;
    end
    
    if isRemoveFile 
        % tell the user that the file is being removed from the list
        disp(['Removing: ''',fileList{kkFile},'''. Doesn''t match correct file naming structure.']);
        % remove the original folder from the list
        fileList(kkFile) = [];
    end
end

%% loop over each object and add in the spine/ribs
for kkFile = 1:length(fileList)
    progressbar((kkFile-1)/length(fileList));
   tempLoad = load(fileList{kkFile});
   
   for jjFrame = 1:length(tempLoad.frame);
      for iiObject = 1:length(tempLoad.frame(jjFrame).object)
          try
          [tempLoad.frame(jjFrame).object(iiObject).spine,...
           tempLoad.frame(jjFrame).object(iiObject).xyRibEnds,...
           tempLoad.frame(jjFrame).object(iiObject).spineCurvature] =  ...
                        spineNribs( tempLoad.frame(jjFrame).object(iiObject).Xcont,...
                                    tempLoad.frame(jjFrame).object(iiObject).Ycont);
          
          catch ME
              tempFileName = fileList{kkFile};
              tempFileName = strrep(tempFileName,'\','/');
              warning('morphometrics:addSpineNRibs:generalErrorAddingSpineRibs',...
                  ['Problem with ',tempFileName,...
                  ' - frame ', num2str(jjFrame),...
                  ' - object ',num2str(iiObject),'.']);
              tempLoad.frame(jjFrame).object(iiObject).spine = nan;
              tempLoad.frame(jjFrame).object(iiObject).xyRibEnds = nan;
              tempLoad.frame(jjFrame).object(iiObject).spineCurvature = nan;
          end
          end
   end

   % determine what to call the file
   savedFileName = strrep(fileList{kkFile},'.mat','_SpineAndRibs.mat');
   if strcmp(savedFileName, fileList{kkFile})
       % don't save because this will overwrite
       warning('morphometrics:addSpineNRibs:saveFileNameError',...
           ['Data not saved. Problem with ', fileList{kkFile}]);
   else
       save(savedFileName,'-struct','tempLoad');
       disp(['Saving: ',savedFileName]);
   end
   
end
    progressbar(1);


