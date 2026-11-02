function plotOnly1(passInStruct)

resultsTable = passInStruct.resultsTable;
dataLabel = passInStruct.dataLabel;
intId = passInStruct.intId;
areaId = passInStruct.areaId;
resultsCell1 = passInStruct.resultsCell1;
fieldIdxNames = passInStruct.fieldIdxNames;
color = passInStruct.color;


%% calculate intensity in ends/periphery

fig3 = figure();
clear mean std;
clear plotVal plotErr;

% group by total intensity/area
groupingIdx1 = nan(size(resultsTable,1),1);
% grouping values
intens1 = (resultsTable(:,intId))./resultsTable(:,areaId);
groupingIdx1(intens1<quantile(intens1,0.25)) = 1;
groupingIdx1(intens1>quantile(intens1,0.75)) = 3;
groupingIdx1(isnan(groupingIdx1)) = 2;

progressbar('cell bins');
for jCategory = 1:5
    progressbar((jCategory-1)/5+100*eps);
    switch jCategory
        case 1
            categoryName = 'poles';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'leftIntNorm'));
            idx2sum(2) = find(strcmp(fieldIdxNames,'rightIntNorm'));
            normalizeItConstant = 0.4;
        case 2
            categoryName = 'midLR';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'lcIntNorm'));
            idx2sum(2) = find(strcmp(fieldIdxNames,'rcIntNorm'));
            normalizeItConstant = 0.4;
        case 3
            categoryName = 'midplane';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'centerIntNorm'));
            normalizeItConstant = 0.2;
        case 4
            categoryName = 'periphery';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'bottomIntNorm'));
            idx2sum(2) = find(strcmp(fieldIdxNames,'topIntNorm'));
            normalizeItConstant = 0.6;
        case 5
            categoryName = 'central slice';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'middleIntNorm'));
            normalizeItConstant = 0.4;
        case 6
            categoryName = 'all horizontal';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'centerIntNorm'));
            idx2sum(2) = find(strcmp(fieldIdxNames,'lcIntNorm'));
            idx2sum(3) = find(strcmp(fieldIdxNames,'rcIntNorm'));
            idx2sum(4) = find(strcmp(fieldIdxNames,'leftIntNorm'));
            idx2sum(5) = find(strcmp(fieldIdxNames,'rightIntNorm'));
            normalizeItConstant = 1;
        case 7
            categoryName = 'all vertical';
            clear idx2sum;
            idx2sum(1) = find(strcmp(fieldIdxNames,'bottomIntNorm'));
            idx2sum(2) = find(strcmp(fieldIdxNames,'topIntNorm'));
            idx2sum(3) = find(strcmp(fieldIdxNames,'middleIntNorm'));
            normalizeItConstant = 1;
    end
    progressbar(1);
    
    categoryString{jCategory} = categoryName;
    for iiGroup = 1:3
        % section 1
        tempValues = (resultsTable(groupingIdx1==iiGroup,idx2sum));
        tempValues = sum(tempValues,2);
        tempValues = tempValues./((resultsTable(groupingIdx1==iiGroup,intId)));
        tempValues = tempValues./normalizeItConstant;
        % store values
        plotVal(jCategory,iiGroup) = nanmean(tempValues);
        plotErr(jCategory,iiGroup) = nanstd(tempValues)./sqrt(nnz(groupingIdx1==iiGroup));
    end
end


barHandles = barwitherr(plotErr,plotVal);
for ii = 1:3
    % red
    
    switch color
        case 'red'
            set(barHandles(ii),'DisplayName',[dataLabel,' - Int',num2str(ii)],...
                'FaceColor',hsv2rgb(0,0.33*ii,1));
        case 'blue'
            set(barHandles(ii),'DisplayName',[dataLabel,' - Int',num2str(ii)],...
                'FaceColor',hsv2rgb(229/360,0.33*ii,1));
        otherwise
            disp(['don''t understand color: ', color]);
    end
    
end
disp(1);
%
for ii = 4:6
    set(get(get(barHandles(ii),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
%         save('Compare2data.mat');
%         bar(plotVal);
hold on;
set(gca,'XTickLabel',categoryString)
legend('show')
ylabel('intensity (au)');

% load in the intensity profiles
% unused variable
maxLength = max(max(resultsTable(:,2)));
% how large is the padded region?
paddingSize = 6;
% how many divisions in the final image
finalSize = 30;

% preallocate
intProfile1 = nan(size(resultsTable,1),finalSize);
% loop over cells and populate the table

progressbar('cell profile averaging');
for iCell = 1:size(resultsTable,1);
    progressbar((iCell-1)/size(resultsTable,1)+100*eps);
    
    tempProfile = resultsCell1{iCell}.longAxisInt;
    cellLength = length(tempProfile)-2*paddingSize+2;
    % just 1 nan, no information here
    if cellLength <=1
        continue
    end
    newIdx = linspace(1,round(cellLength),finalSize);
    
    intProfile1(iCell,:) = interp1(1:cellLength,tempProfile(paddingSize:end-paddingSize+1),newIdx);
    intProfile1(iCell,:) = intProfile1(iCell,:)./sum(intProfile1(iCell,:));
    if resultsTable(iCell,10)>resultsTable(iCell,18)
        intProfile1(iCell,:) = fliplr(intProfile1(iCell,:));
    end
    xlabel('relative cell position');
    ylabel('average intensity');
end
progressbar(1);

disp(2)


figure();
for ii=1:3
    subplot(3,2,2*ii-1);
    tempValues = nanmean(intProfile1(groupingIdx1==ii,:));
    switch color
        case 'red'
            plot((tempValues+fliplr(tempValues))/2,'rx-');
        case 'blue'
            plot((tempValues+fliplr(tempValues))/2,'bx-');
    end
    
    switch ii
        case 1
            title('dim - sym');
        case 2
            title('medium - sym');
        case 3
            title('bright - sym');
    end
    subplot(3,2,2*ii)
    switch color
        case 'red'
            plot(tempValues,'rx-');
            
        case 'blue'
            plot(tempValues,'bx-');
            
    end
    
    
    hold on;
    switch ii
        case 1
            title('dim - asym');
        case 2
            title('medium - asym');
        case 3
            title('bright - asym');
    end
    xlabel('relative cell position');
    ylabel('relative intensity');
end


% bumpiness parameter
intFiltId = find(strcmp(fieldIdxNames,'integIntFilt'));
disp(['Bumpiness (',dataLabel,'): ',num2str(nanmean(resultsTable(:,intFiltId)./resultsTable(:,intId))),...
    ' +/- ',num2str(nanstd(resultsTable(:,intFiltId)./resultsTable(:,intId)))]);

% figure();
% switch color
%     case 'red'
%         scatter(resultsTable(:,intId)./resultsTable(:,areaId),resultsTable(:,intFiltId)./resultsTable(:,intId),'rx');
%     case 'blue'
%         scatter(resultsTable(:,intId)./resultsTable(:,areaId),resultsTable(:,intFiltId)./resultsTable(:,intId),'bx');
%         
% end
% hold on;
% xlabel('int/area');
% ylabel('fractional intensity in bumps');



% % section 1
% figure();
% clear idx2sum
% idx2sum(1) = find(strcmp(fieldIdxNames,'leftIntNorm'));
% idx2sum(2) = find(strcmp(fieldIdxNames,'rightIntNorm'));
% normalizeItConstant = 0.4;
% tempValues = (resultsTable(:,idx2sum));
% tempValues = sum(tempValues,2);
% tempValues = tempValues./((resultsTable(:,intId)));
% tempValues = tempValues./normalizeItConstant;
% switch color
%     case 'red'
%         scatter(resultsTable(:,intId)./resultsTable(:,areaId),tempValues,'rx');
%     case 'blue'
%         scatter(resultsTable(:,intId)./resultsTable(:,areaId),tempValues,'bx');
%         
% end
% 
% hold on;
% 
% xlabel('int/area');
% ylabel('relative intensity endcaps');



%
%         figure();
%         subplot(1,2,1);
%         plot(intProfileFrac1,'rx');
%         subplot(1,2,2);
%         plot(sum(intProfile2,2),'bo');

% %         isNormalized = true;
% %         [endInt,periphInt,centInt,midInt] = sliceNDice(resultsTable,isNormalized);
% %
% %         disp(['Intensity in ends, ',dataLabel1,': ',num2str(100*mean(endInt)),'%',...
% %             ' ',char(177),' ',num2str(100*std(endInt)),'%']);
% %          disp(['Intensity in periphery, ',dataLabel1,': ',num2str(100*mean(periphInt)),'%',...
% %             ' ',char(177),' ',num2str(100*std(periphInt)),'%']);
% %           disp(['Intensity in middle (LR), ',dataLabel1,': ',num2str(100*mean(midInt)),'%',...
% %             ' ',char(177),' ',num2str(100*std(midInt)),'%']);
% %         disp(['Intensity in center (TB), ',dataLabel1,': ',num2str(100*mean(centInt)),'%',...
% %             ' ',char(177),' ',num2str(100*std(centInt)),'%']);
% %
% %
% %         [endInt2,periphInt2,centInt2,midInt2] = sliceNDice(resultsTable,isNormalized);
% %                disp(['Intensity in ends, ',dataLabel2,': ',num2str(100*mean(endInt2)),'%',...
% %             ' ',char(177),' ',num2str(100*std(endInt2)),'%']);
% %          disp(['Intensity in periphery, ',dataLabel2,': ',num2str(100*mean(periphInt2)),'%',...
% %             ' ',char(177),' ',num2str(100*std(periphInt2)),'%']);
% %           disp(['Intensity in middle (LR), ',dataLabel2,': ',num2str(100*mean(midInt2)),'%',...
% %             ' ',char(177),' ',num2str(100*std(midInt2)),'%']);
% %         disp(['Intensity in center (TB), ',dataLabel2,': ',num2str(100*mean(centInt2)),'%',...
% %             ' ',char(177),' ',num2str(100*std(centInt2)),'%']);
% %

% load and calculate profiles

