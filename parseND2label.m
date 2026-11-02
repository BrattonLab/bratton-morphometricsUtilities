function [iSeries,nSeries,iPlane,nPlanes,iColor,nColors,iTime,nTimes,stackString,iZ,nZs] = parseND2label(nd2label);
%%
% 201903 BPB notes, the earlier version of this parser assumes that ALL tags
% are used. In the case of some files, there are not multiple t or lambda
% or z planes, so the ordering listed was not always correct. This was
% updated to be agnostic to how many of which type of label is present

nd2label = textscan(nd2label,'%s','delimiter',';');
nd2label = nd2label{1};

%% filename string : index 1
fileLabel = nd2label{1};

%% setup default values
iSeries = 1;
nSeries = 1;

iPlane = 1;
nPlanes = 1;

iColor = 1;
nColors = 1;

iTime = 1;
nTimes = 1;

iZ = 1;
nZs = 1;

for kkMetaDataFields = 2:size(nd2label);
    % pull out the next tag
    tagString = nd2label{kkMetaDataFields};
    tagString = textscan(tagString,'%s','Delimiter',{' ','='});

    switch tagString{1}{1}
        case 'plane'
            % split before and after the slash
            tagString = textscan(tagString{1}{2},'%f','delimiter','/');
            iPlane = tagString{1}(1);
            nPlanes = tagString{1}(2);
        case {'c','C'}
            % split before and after the slash
            tagString = textscan(tagString{1}{2},'%f','delimiter','/');
            iColor = tagString{1}(1);
            nColors = tagString{1}(2);
        case {'t','T','T?','t?'}
            % split before and after the slash
            tagString = textscan(tagString{1}{2},'%f','delimiter','/');
            iTime = tagString{1}(1);
            nTimes = tagString{1}(2);
        case {'z','Z'}
            % split before and after the slash
            tagString = textscan(tagString{1}{2},'%f','delimiter','/');
            iZ = tagString{1}(1);
            nZs = tagString{1}(2);
        otherwise
            % when there is a multi-point ND2 file, the second field looks
            % like the name of the file with a 'series' tag in it
            seriesLabelIndex = regexp(nd2label{kkMetaDataFields},'\(series \d+\)');
            
            if not(isempty(seriesLabelIndex))
                seriesLabel = nd2label{kkMetaDataFields}(seriesLabelIndex+8:end-1);
                iSeries = str2double(seriesLabel);
                if iSeries>nSeries
                    nSeries = iSeries;
                end
            else
                error('parseND2label:unexpectedFormat',...
                    ['Unexpected format: ''',nd2label{kkMetaDataFields},'''. Please contact the developer.']);
            end
            
    end
    
end

%% composite string describing this plane
% This is without spaces and without the 'out of' indication, so 
% 'plane 3/139' becomes '_plane003'

% strip off the parent path
[~,filename] = fileparts(fileLabel);

% add on tags if they exist
stackString = filename;

% planes are like the index into a stacked tiff, this is the index of the
% image out of the total number of planes
if nPlanes>1
    numberLength = 1+floor(log10(nPlanes));
    formatString = ['%0',num2str(numberLength),'i'];
    stackString = [stackString,'_plane',num2str(iPlane,formatString)];
end

% series label is for multipoint stacks, which of the multipoint positions
% was used
if nSeries>1
    numberLength = 1+floor(log10(nSeries));
    formatString = ['%0',num2str(numberLength),'i'];
    stackString = [stackString,'_series',num2str(iSeries,formatString)];
end

% time points
if nTimes>1
    numberLength = 1+floor(log10(nTimes));
    formatString = ['%0',num2str(numberLength),'i'];
    stackString = [stackString,'_time',num2str(iTime,formatString)];
end

% z positions
if nZs>1
    numberLength = 1+floor(log10(nZs));
    formatString = ['%0',num2str(numberLength),'i'];
    stackString = [stackString,'_Z',num2str(iZ,formatString)];
end

% lambda or color settings
if nColors>1
    numberLength = 1+floor(log10(nColors));
    formatString = ['%0',num2str(numberLength),'i'];
    stackString = [stackString,'_color',num2str(iColor,formatString)];
end
