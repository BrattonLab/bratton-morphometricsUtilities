clear all; 
%% this will make a list of the files
matFileList = uipickfiles('FilterSpec','*SPOTS.mat');

%% 
aggregatedCells = [];

% loop over each mat file and include its information in the aggregated set
for iFile = 1:length(matFileList)
    
    tempLoad = load(matFileList{iFile},'totalCells','THRESHOLD_CELLS');
    % check to make sure that the same threshold was used for all the files
    if iFile ==1;
        tempThresh = tempLoad.THRESHOLD_CELLS;
    else
        if tempThresh ~= tempLoad.THRESHOLD_CELLS
            error('morphometrics:spotcounts:spotthresholdsdiffer',...
                ['spot threshold is different between ', ...
                matFileList{iFile-1}, ' and ', matFileList{iFile},'.']);
        else
            tempThresh = tempLoad.THRESHOLD_CELLS;
            
        end
    end
    
    aggregatedCells = cat(1,aggregatedCells,tempLoad.totalCells');
   
    
    
end
%% 
% on a per cell basis, pull out relevant pieces of information
for iCell = 1:length(aggregatedCells)   
    numberSpots(iCell) = length(aggregatedCells(iCell).listOfSpots);
    cellIntensity(iCell) = aggregatedCells(iCell).totalCellIntensity;
    cellArea(iCell) = aggregatedCells(iCell).cellArea;
    spotFractionalIntensity(iCell) = aggregatedCells(iCell).fractionalIntensity;
    spotFractionalArea(iCell) = sum(aggregatedCells(iCell).spotAreaInCell_pix)./...
        aggregatedCells(iCell).cellArea;
end


% display some beautiful histograms
figCell = figure();
subplot(3,2,1);
[counts,x] = hist(numberSpots,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('number of spots');

subplot(3,2,2);
[counts,x] = hist(cellIntensity,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('total cell intensity (AU)');


subplot(3,2,3);
[counts,x] = hist(cellArea,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('cell area (pix)');


subplot(3,2,4);
[counts,x] = hist(spotFractionalIntensity,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('fraction of intensity in spots');


subplot(3,2,5);
[counts,x] = hist(spotFractionalArea,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('fraction of area in spots');

subplot(3,2,6);
[counts,x] = hist(cellIntensity./cellArea,20);
bar(x,counts./sum(counts)); % display in percentage of cells
ylabel('Frequency (% of cells)');
xlabel('cell brightness (AU/pix)');

%% look on a per spot basis
spotArea_pix = []';
spotIntensities = []';
spotLongAxis_pix = []';
spotAspectRatio = []';
spotShortAxis_pix = []';
for iCell = 1:length(aggregatedCells);
  % find out how many spots are in this cell
  if ~isempty(aggregatedCells(iCell).listOfSpots)
      % the total size of the spots is "hidden" as the area in the cell and
      % the fraction of the total spot area in the cell
      tempSpotPixArea = aggregatedCells(iCell).spotAreaInCell_pix;
      tempSpotFractionalArea = aggregatedCells(iCell).spotAreaInCell_frac;
      
      % the total intensity of the spots is "hidden" as the intensity in
      % the cell and the fraction of the total spot intensity in the cell
      tempSpotIntInCell = aggregatedCells(iCell).spotIntensityInCell;
      tempSpotFractionalInt = aggregatedCells(iCell).spotIntensityInCell_frac;
      
      % spot sizes
      tempSpotLongAxis_pix = aggregatedCells(iCell).MajorAxis_pix;
      tempSpotShortAxis_pix = aggregatedCells(iCell).MinorAxis_pix;
      tempSpotAspectRatio = aggregatedCells(iCell).aspectRatio;
      
      % concatenate with previous spots
      spotArea_pix = cat(1,spotArea_pix,tempSpotPixArea(:)./tempSpotFractionalArea(:));
      spotIntensities = cat(1,spotIntensities,tempSpotIntInCell(:)./tempSpotFractionalInt(:));
      spotLongAxis_pix = cat(1,spotLongAxis_pix,tempSpotLongAxis_pix);
      spotAspectRatio = cat(1,spotAspectRatio,tempSpotAspectRatio);
      spotShortAxis_pix = cat(1,spotShortAxis_pix,tempSpotShortAxis_pix);
  end
    
end


% display some histograms

figSpot = figure();
subplot(3,2,1);
[counts,x] = hist(spotArea_pix,20);
bar(x,counts./sum(counts),'r'); % display in percentage of cells
ylabel('Frequency (% of spots)');
xlabel('area (pix)');

subplot(3,2,2);
[counts,x] = hist(spotAspectRatio,20);
bar(x,counts./sum(counts),'r'); % display in percentage of cells
ylabel('Frequency (% of spots)');
xlabel('spot aspect ratio');

subplot(3,2,3);
[counts,x] = hist(spotIntensities,20);
bar(x,counts./sum(counts),'r'); % display in percentage of cells
ylabel('Frequency (% of spots)');
xlabel('spot intensity (AU)');

subplot(3,2,4);
[counts,x] = hist(spotLongAxis_pix,20);
bar(x,counts./sum(counts),'r'); % display in percentage of cells
ylabel('Frequency (% of spots)');
xlabel('spot long axis length (pix)');

subplot(3,2,5);
[counts,x] = hist(spotIntensities./spotArea_pix,20);
bar(x,counts./sum(counts),'r'); % display in percentage of cells
ylabel('Frequency (% of spots)');
xlabel('spot brightness (AU/pix)');
%% scatterplot 
figCorrelations = figure();
subplot(3,2,1);
scatter(cellIntensity,spotFractionalIntensity.*cellIntensity);
xlabel('Cell Intensity (AU)');
ylabel('Spot Intensity (AU)');

subplot(3,2,2);
scatter(cellIntensity./cellArea,spotFractionalIntensity.*cellIntensity);
xlabel('Normalized Cell Intensity (AU/pix)');
ylabel('Spot Intensity (AU)');


%% give some statistics

% char(177) is a ±
disp('Here is a list of the files included in this summary:')
disp(matFileList');
disp(['Threshold level: ',num2str(tempThresh,'%4.3g')]);
% display text with statistics about spots
disp([' ']);
disp(['Number of cells: ',num2str(numel(numberSpots),'%4.3g')]);
disp(['Average number of spots per cell: ', ...
    num2str(nanmean(numberSpots),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(numberSpots),'%4.3g')]);
disp(['Fraction of cells that have at least one spot: ',...
    num2str(nnz(numberSpots)./numel(numberSpots),'%4.3g')]);
disp(['Average cell brightness (AU/pix): ', ...
    num2str(nanmean(cellIntensity./cellArea),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(cellIntensity./cellArea),'%4.3g')]);
disp(['Average cell intensity (AU): ', ...
    num2str(nanmean(cellIntensity),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(cellIntensity),'%4.3g')]);
disp(['Average cell area (pix): ', ...
    num2str(nanmean(cellArea),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(cellArea),'%4.3g')]);
% display text with statistics about spots
disp(' ');
disp(['Number of spots: ',num2str(numel(spotIntensities),'%4.3g')]);
disp(['Average spot area (pix): ', ...
    num2str(nanmean(spotArea_pix),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotArea_pix),'%4.3g')]);
disp(['Average spot intensity (AU): ', ...
    num2str(nanmean(spotIntensities),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotIntensities),'%4.3g')]);
disp(['Average spot brightness (AU/pix): ', ...
    num2str(nanmean(spotIntensities./spotArea_pix),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotIntensities./spotArea_pix),'%4.3g')]);
disp(['Average spot long axis (pix): ', ...
    num2str(nanmean(spotLongAxis_pix),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotLongAxis_pix),'%4.3g')]);
disp(['Average spot aspect ratio: ', ...
    num2str(nanmean(spotAspectRatio),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotAspectRatio),'%4.3g')]);
disp(['Fraction of total cell intensity in spots: ', ...
    num2str(nanmean(spotFractionalIntensity),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotFractionalIntensity),'%4.3g')]);
disp(['Average spot short axis (pix): ', ...
    num2str(nanmean(spotShortAxis_pix),'%4.3g'),...
   ' ', char(177), ' ',num2str(nanstd(spotShortAxis_pix),'%4.3g')]);


% make something that is easy to copy to excel, for example
% threshold nCells spotsPerCell %cellsWithASpot cellBrightness nSpots
% spotSizePix spotBrightness spotLongAxis spotAspectRatio
fprintf(1,['\n',...
    num2str(numel(numberSpots)),'\t',...
    num2str(nanmean(numberSpots),'%4.3g'),' ',char(177),' ',...
    num2str(nanstd(numberSpots),'%4.3g'),'\t',...
    ...
    num2str(nnz(numberSpots)./numel(numberSpots),'%4.3g'),'\t'...
    ...
    num2str(nanmean(cellIntensity./cellArea),'%4.3g'),' ',char(177),' ',...
    num2str(nanstd(cellIntensity./cellArea),'%4.3g'),'\t'...
    ...
    num2str(numel(spotIntensities),'%4.3g'),'\t'...
    ...
    num2str(nanmean(spotArea_pix),'%4.3g'),' ',char(177),' ',...
    num2str(nanstd(spotArea_pix),'%4.3g'),'\t'...
    ...
    num2str(nanmean(spotIntensities./spotArea_pix),'%4.3g'),' ',char(177),' ',...
    num2str(nanstd(spotIntensities./spotArea_pix),'%4.3g'),'\t'...
...
    num2str(nanmean(spotFractionalIntensity),'%4.3g'),' ',char(177),' ',...
    num2str(nanstd(spotFractionalIntensity),'%4.3g'),'\t'...
    ...
    num2str(nanmean(spotLongAxis_pix),'%4.3g'),' \t ',...
    num2str(nanstd(spotLongAxis_pix),'%4.3g'),'\t'... 
    ...
    num2str(nanmean(spotAspectRatio),'%4.3g'),' \t ',...
    num2str(nanstd(spotAspectRatio),'%4.3g'),'\t'...
        ...
    num2str(nanmean(spotShortAxis_pix),'%4.3g'),' \t ',...
    num2str(nanstd(spotShortAxis_pix),'%4.3g'),'\n'...
]);


%% save histogram figures

lastFile = matFileList{end};
parentFolder = fileparts(lastFile);
[~,parentName] = fileparts(parentFolder);
cellHistName = fullfile(parentFolder,[parentName,'Cells.png']);
spotHistName = fullfile(parentFolder,[parentName,'Spots.png']);
correlationFigName = fullfile(parentFolder, [parentName, 'Correlation.png']);
matFileName = fullfile(parentFolder,[parentName,'SpotCountsOutput.mat']);
save(matFileName);
saveas(figCell, cellHistName);
saveas(figSpot, spotHistName);
saveas(figCorrelations,correlationFigName); 
disp(cellHistName); 









