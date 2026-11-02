function nCells = howManyCells();
%%
[fileNames,filePath] = uigetfile('*.mat','MultiSelect','on');

if not(iscell(fileNames))
    fileNames = {fileNames};
end

nCells = 0;

for iFile = 1:size(fileNames,2);
    load(fullfile(filePath,fileNames{iFile}));
    for jFrame = 1:size(frame,2)
        nCells = nCells + frame(jFrame).num_cells;
    end
end

