% find unique stems for ND2 files

% list all the contours files for this folder
folderToRearrange = uigetdir();
fileList = dir([folderToRearrange,filesep,'*.nd2*CONTOURS*.mat']);

% loop over the contours files and find the ND2 stem
for iiFile = 1:length(fileList)
   filenameTemp = fileList(iiFile).name;
   splitfilename = strsplit(filenameTemp,'.nd2');
   filenameStem = splitfilename{1};
   
   numericCount = 0;
   % trim off the numeric characters at the end of the file name before the .nd2
   while not(isnan(str2double(filenameStem(end))))
      filenameStem(end) = [];   
      numericCount = numericCount+1;
   end
   
   switch numericCount
       case 0
%            warning('rearrangeContoursTifs:noNumericCount',...
%                ['No numbers at the end of filename. Assuming ',...
%                filenameStem,' is the series name.']);
       case {3}
           
       otherwise
           warning('rearrangeContoursTifs:unexpectedNumericCount',...
               ['Unexpected number of digits at the end of filename. Assuming ',...
               filenameStem,' is the series name.']);
   end
  
   filenameStemList{iiFile} = filenameStem;
   
   % 
end

%% 
% find the unique series names, this will end up being the name of the
% folders
[uniqueFilenameStemList,~,ic] = unique(filenameStemList);

% make these new storage folders
for iiFolder = 1:length(uniqueFilenameStemList)
   mkdir([ folderToRearrange,filesep,uniqueFilenameStemList{iiFolder}]);
end

% move the images and associated files into the appropriate folder
for iiFile = 1:length(fileList)
    filenameTemp = fileList(iiFile).name;
    splitfilename = strsplit(filenameTemp,'.nd2');
    filenameStem = splitfilename{1};
    
    % search for everything that matches this stem
    associatedFileList = dir([ folderToRearrange,filesep,filenameStem,'.nd2*']);
    
    % move all these to the appropriate subdirectory
    for jjFile = 1:length(associatedFileList)
        movefile([folderToRearrange,filesep,associatedFileList(jjFile).name],...
            [folderToRearrange,filesep,uniqueFilenameStemList{ic(iiFile)},filesep,associatedFileList(jjFile).name]);
    end
end
%%

