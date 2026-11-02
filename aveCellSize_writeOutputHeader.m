function [fidA,measurementString] = aveCellSize_writeOutputHeader(folderList)

% BPB 20231102 add surface area to volume

%% labels for txt output
% label the property being measured
measurementString{1} = 'cellArea';
measurementString{2} = 'longAxisLength';
measurementString{3} = 'centerLineLength';
measurementString{4} = 'meanWidth_includingPoles';
measurementString{5} = 'meanWidth_noPoles';
measurementString{6} = 'stdWidth_includingPoles';
measurementString{7} = 'stdWidth_noPoles';
measurementString{8} = 'ratioOfPoleSizes';
measurementString{9} = 'rmsCenterlineCurvature_includingPoles';
measurementString{10} = 'rmsCenterlineCurvature_noPoles';
measurementString{11} = 'rmsContourCurvature_onlyPoles';
measurementString{12} = 'rmsContourCurvature_noPoles';
measurementString{13} = 'meanSignedContourCurvature_noPoles';
measurementString{14} = 'coefficientOfVariationIntracellularDiameterDeviation';
measurementString{15} = 'coefficientOfVariationPopulationDiameterDeviation';
measurementString{16} = 'microbeTrackerCenterlineCurvature';
measurementString{17} = 'meanUnsignedCenterlineCurvature_includingPoles';
measurementString{18} = 'meanUnsignedCenterlineCurvature_noPoles';
measurementString{19} = 'meanSurfaceArea_cylindricalSegmentApproximation';
measurementString{20} = 'meanVolume_cylindricalSegmentApproximation';
measurementString{21} = 'perimeterLength';
measurementString{22} = 'surfaceAreaToVolumeRatio_cylindricalSegmentApproximation';
measurementString{23} = 'aspectRatio_longAxisOverMeanWidth';

% label the type of measurement
measurementType{1} = 'mean';
measurementType{2} = 'standardDeviation';
measurementType{3} = 'CI_mean';
measurementType{4} = 'CI_standardDeviation';

%% check for batch mode
if not(isappdata(0,'isBatchAveCellSize'));
    isBatchAveCellSize = false;
else
    isBatchAveCellSize = getappdata(0,'isBatchAveCellSize');
end

if isBatchAveCellSize
    outputFolder = uigetdir([],'Output folder');
else
    outputFolder = folderList{1};
end

% if neccessary, open an output file for a single folder run
outputFileName = fullfile(outputFolder,['aveCellSizeOutput',datestr(now,30),'.csv']);

% open the file
fidA = fopen(outputFileName,'w+');

%% write the header


%% version and timestamp
dateAndTime = datestr(now);
% aveCellSizeVersion = '0.5.0'; 
% aveCellSizeVersion = '0.6.0'; % 20170810 bpb adds perimeter
% aveCellSizeVersion = '0.7.0'; % 20170826 bpb adds spineNribs
aveCellSizeVersion = '0.8.0'; % 20231102 bpb adds surfaceAreaToVolume


allOfMorphometrics = fileread(which('morphometrics'));
verPosition = strfind(allOfMorphometrics,'ver_num');
if length(verPosition)~=3
    warning('aveCellSize:morphometricsVersion:troubleFindingVersion','Morphometrics version number may be wrong in output file. Unexpected format in morphometrics.m');
end

verPosition = verPosition(1);
verString = allOfMorphometrics(verPosition:verPosition+35);
verStringEndIdx = strfind(verString,';');
morphometricsVerString = verString(1:verStringEndIdx);
clear allOfMorphometrics;

dateAndTime = datestr(now);
fprintf(fidA,['Date and time: ',dateAndTime,'\n']);
fprintf(fidA,['Currently installed Morphometrics: ',morphometricsVerString,'\n']);
fprintf(fidA,['aveCellSize version: ',aveCellSizeVersion,'\n']);


modeString = evalin('caller','modeString');
fprintf(fidA,['type of mesh/spine files: ',modeString,'\n']);

%% borrow from ver.m

% Find platform OS.
platform = system_dependent('getos');
if ispc
    platform = [platform, ' ', system_dependent('getwinsys')];
elseif ismac
    [status, result] = unix('sw_vers');
    if status == 0
        platform = strrep(result, 'ProductName:', '');
        platform = strrep(platform, sprintf('\t'), '');
        platform = strrep(platform, sprintf('\n'), ' ');
        platform = strrep(platform, 'ProductVersion:', ' Version: ');
        platform = strrep(platform, 'BuildVersion:', 'Build: ');
    end
end

% Construct header and display it.
header = {sprintf('MATLAB %s: %s', getString(message('MATLAB:ver:Version')), version);
    sprintf('MATLAB %s: %s', getString(message('MATLAB:ver:LicenseNumber')), license);
    sprintf('%s: %s', getString(message('MATLAB:ver:OperatingSystem')), platform);
    sprintf('Java %s: %s', getString(message('MATLAB:ver:Version')), version('-java'))};

%%
for ii = 1:length(header);
    fprintf(fidA, [header{ii},'\n']);
end
fprintf(fidA,'\n\n');

%% write out a list of files with their IDs
if isBatchAveCellSize
    fprintf(fidA,'Batch mode of aveCellSize\n');
    fprintf(fidA,'sampleID,fullFolderPath\n');
    for jj = 1:length(folderList)
        fprintf(fidA,[num2str(jj),',',strrep(folderList{jj},'\','\\'),'\n']);
%         fprintf(fidA,'\n\n');
    end
    fprintf(fidA,'\n\n');

else
    fprintf(fidA,'Single folder mode of aveCellSize\n');
    fprintf(fidA,'sampleID,fullFolderPath\n');
    fprintf(fidA,['1,',strrep(folderList{1},'\','\\'),'\n']);
    fprintf(fidA,'\n\n');
end

%%
%% write the column labels
% single valued measurements
fprintf(fidA,'sampleID,');
fprintf(fidA,'sampleLongPath,');
fprintf(fidA,'sampleParentName,');
fprintf(fidA,'sampleFolderName,');
fprintf(fidA,'sampleShortPath,');
fprintf(fidA,'nCellsKept,');
fprintf(fidA,'nCellsReject,');

% averages and standard deviations
for jj = 1:length(measurementString)
    for kk = [1,3,2,4]
        switch kk
            case {1,2}
                fprintf(fidA,[measurementString{jj},':',measurementType{kk},',']);
            case {3,4}
                fprintf(fidA,[measurementString{jj},':',measurementType{kk},'-lower,']);
                fprintf(fidA,[measurementString{jj},':',measurementType{kk},'-upper,']);
        end
    end
end
fprintf(fidA,'\n');

% return the file handle
