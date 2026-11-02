%% this will make a list of the folders
matFolderList = uipickfiles();

fig1 = figure(); 
hold on; 


for iFolder = 1:length(matFolderList)
    [~,dataLabel] = fileparts(matFolderList{iFolder}); %~ ignores the first thing which would be the pathname, then we get the folder name
    try
    tempLoad = load(fullfile(matFolderList{iFolder},'SpotCountsOutput.mat'));
scatter(tempLoad.cellIntensity./tempLoad.cellArea,tempLoad.spotFractionalIntensity.*tempLoad.cellIntensity,...
    'DisplayName',dataLabel);
    catch ME
    end
    
end
xlabel('Normalized Cell Intensity (AU/pix)');
ylabel('Spot Intensity (AU)');
legend('show');
