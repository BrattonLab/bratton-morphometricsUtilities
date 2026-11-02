function [listOfStats,statNames] =statsList(cellList,varargin)
% Modified from cellstat
% 20130108 BPB instead of returning the mean and standard deviation, return an
% array of values
%
% function cellstat(cellList,varargin)
% cellstat(cellList)
% cellstat(cellList,range)
%
% This function displays basic statistics on an experiment, such as the 
% number of frames, the number of detected cells and spots, cell length,
% width (area divided by length), area, volume, values of fluorescence
% signals.
%
% <cellList> - an array that contains the meshes. You can drag and drop
% the file with the data into MATLAB workspace or open it using MATLAB
% Import Tool. The default name of the variable is cellList, but it can be
% renamed.
% <range> - an optional parameter, indicating the frames on which
% statistics will be calculated, e.g. 1 for the first frame, 2:5 for all
% frames from frame 2 to frame 5.

if ~isempty(varargin),
    range = varargin{1};
else
    range = 1:length(cellList);
end
ncells = 0;
frames = zeros(1,length(cellList));
nspots = 0;
ncellswithspots = 0;
totlength = [];
totarea = [];
totvolume = [];
nsignal1 = 0;
nsignal2 = 0;
isignal1 = [];
isignal2 = [];
asignal1 = [];
asignal2 = [];
for frame=range
    for cell=1:length(cellList{frame})
        if ~isempty(cellList{frame}{cell}) && length(cellList{frame}{cell}.mesh)>4
            ncells = ncells + 1;
            frames(frame) = 1;
            if isfield(cellList{frame}{cell},'spots') && ~isempty(cellList{frame}{cell}.spots.magnitude)
                nspots = nspots + length(cellList{frame}{cell}.spots.magnitude);
                ncellswithspots = ncellswithspots + 1;
            end
            area = cellList{frame}{cell}.area;
            totlength = [totlength cellList{frame}{cell}.length];
            totarea = [totarea area];
            totvolume = [totvolume cellList{frame}{cell}.volume];
            if isfield(cellList{frame}{cell},'signal1') && area>0
                nsignal1=nsignal1+1;
                isignal1=[isignal1 sum(cellList{frame}{cell}.signal1)]; 
                asignal1=[asignal1 area];
            end
            if isfield(cellList{frame}{cell},'signal2') && area>0
                nsignal2=nsignal2+1;
                isignal2=[isignal2 sum(cellList{frame}{cell}.signal2)];
                asignal2=[asignal2 area];
            end
        end
    end
end

statNames = [{'totlength'},{'totwidth(area/length)'},{'totarea'},{'totvolume'}];
listOfStats = [totlength(:),totarea(:)./totlength(:),totarea(:),totvolume(:)];

if nsignal1>0 
    statNames = [statNames,...
    {'totalIntensity1'},{'mormalizedIntensity1'}];
while numel(isignal1)<size(listOfStats,1)
    isignal1 = [isignal1,nan];
    asignal1 = [asignal1,nan];
end
    listOfStats = [listOfStats,isignal1(:),isignal1(:)./asignal1(:)];
end
if nsignal2>0
   statNames = [statNames,...
      {'totalIntensity2'},{'mormalizedIntensity2'}]; 
end

if ncellswithspots==0 && nspots==0, ncellswithspots=1; end
disp(' ')
disp(['Total number of cells: ' num2str(ncells) ', located on ' num2str(sum(frames)) ' frames'])
disp(['Total number of spots: ' num2str(nspots) ', located in ' num2str(ncellswithspots) ' cells (' num2str(nspots/ncellswithspots) ' spots/cell)'])
disp(['Cell length is ' num2str(mean(totlength)) ' +/- ' num2str(std(totlength)) ' pixels (mean +/- st. dev.)'])
disp(['Cell width is ' num2str(nanmean(totarea./totlength)) ' +/- ' num2str(nanstd(totarea./totlength)) ' pixels'])
disp(['Cell area is ' num2str(nanmean(totarea)) ' +/- ' num2str(nanstd(totarea)) ' pixels^2'])
disp(['Cell volume is ' num2str(nanmean(totvolume)) ' +/- ' num2str(nanstd(totvolume)) ' pixels^3'])
if nsignal1>0, disp(['Signal1 intensity (total) is ' num2str(nansum(isignal1)/nsignal1) ' +/- ' num2str(nanstd(isignal1)) ' (in ' num2str(nsignal1) ' cells)']); end
if nsignal1>0, disp(['Signal1 intensity (normalized by area) is ' num2str(nansum(isignal1)/nansum(asignal1)) ' +/- ' num2str(nanstd(isignal1./asignal1))]); end
if nsignal2>0, disp(['Signal2 intensity (total) is ' num2str(nansum(isignal2)/nsignal2) ' +/- ' num2str(nanstd(isignal2)) ' (in ' num2str(nsignal2) ' cells)']); end
if nsignal2>0, disp(['Signal2 intensity (normalized by area) is ' num2str(nansum(isignal2)/nansum(asignal2)) ' +/- ' num2str(nanstd(isignal2./asignal2))]); end
disp(' ');