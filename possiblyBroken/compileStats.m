function statsList = compileStats(frame);
% this function will process a set of data in morphometrics "frame" format
% into a list of statistics

nCellsTot = 0;
% first count up the number of cells total
for iFrame = 1:numel(frame);
    nCellsTot = nCellsTot+frame(iFrame).num_cells;
end
statsList = nan(nCellsTot,12);

% loop over all the cells and pull out the desired data
iCell = 1; jFrame = 1; isAnotherCell = true; lCounter =  1;

fieldList = fieldnames(frame(1).object(1).channel(1));
while isAnotherCell
    % pull out the data of interest
    cellData = frame(jFrame).object(iCell);
    
    % area, length, width
    % reject cell and move to next if it hasn't been processed
    if isempty(cellData.area)
        nCellsTot = nCellsTot-1;
        iCell = iCell+1;
        
        
        % move to next frame
        if iCell>size(frame(jFrame).object)
            iCell = 1;
            jFrame = jFrame+1;
            if jFrame > numel(frame)
                isAnotherCell = false;
            end
        end
        
        continue
    elseif or(cellData.area == 0,isnan(cellData.area));
        nCellsTot = nCellsTot-1;
        iCell = iCell+1;
        
        % move to next frame
        if iCell>size(frame(jFrame).object)
            iCell = 1;
            jFrame = jFrame+1;
            if jFrame > numel(frame)
                isAnotherCell = false;
            end
        end
        continue
    end
    statsList(lCounter,1) = cellData.area;
    
    if isempty(cellData.length)        
        nCellsTot = nCellsTot-1;
        iCell = iCell+1;
        
        % move to next frame
        if iCell>size(frame(jFrame).object)
            iCell = 1;
            jFrame = jFrame+1;
            if jFrame > numel(frame)
                isAnotherCell = false;
            end
        end
        continue
    end
    statsList(lCounter,2) = cellData.length;
    statsList(lCounter,3) = cellData.width;
    
    channelCounter = 1;
    for mChannel = 1:size(cellData.channel,2)
        if isempty(cellData.channel(mChannel).integInt)
            % phase image, ignore
            
            continue
        end
        
        
        % store the data, assume everything should be summed together if
        % more than one element
        for iiField = 1:numel(fieldList);
            try
            statsList(lCounter,3+(channelCounter-1)*numel(fieldList)+iiField) = ...
                sum(...
                cellData.channel(mChannel).(fieldList{iiField})(:));%.*...
%                 cellData.channel(mChannel).max;
            catch ME
                statsList(lCounter,3+(channelCounter-1)*numel(fieldList)+iiField) = nan;
            end
        end
        
        channelCounter = channelCounter+1;
    end
    
    
    % increment to next cell
    iCell = iCell+1;
    lCounter = lCounter+1;
    
    % move to next frame
    if iCell>size(frame(jFrame).object)
        iCell = 1;
        jFrame = jFrame+1;
        if jFrame > numel(frame)
            isAnotherCell = false;
        end
    end
end

% display number of cells
% disp(['Total number of cells: ', num2str(nCellsTot)]);
