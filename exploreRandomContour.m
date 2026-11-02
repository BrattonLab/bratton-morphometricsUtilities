%%
display('First run aveCell size to generate a merged dataset with the name ''allContours''');
%%
figure(gcf);
clf;
randomCellIndex = randi(length(allContours),1);
for jjCell = 1:4
    figure(jjCell);
    clf;
    randomCellIndex = jjCell;
    for iiCell=randomCellIndex;
        subplot(4,4,[1,2,3,5,6,7,9,10,11,13,14,15]);
        
        h1 = color_line(allContours(iiCell).Xcont,...
            allContours(iiCell).Ycont,...
            allContours(iiCell).kappa_smooth*allContours(iiCell).pixSize,...
            'Marker','.','MarkerSize',15,'LineWidth',3);
        handles.toggleButton1 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.1,0.15,0.08],...
            'Callback',{@toggleVisPlot,h1},...
            'String','uutline');
        axis image;
        hold on;
        title(['Cell number: ',num2str(iiCell)]);
        h2 = color_line(allContours(iiCell).centerline(:,1),...
            allContours(iiCell).centerline(:,2),...
            allContours(iiCell).cent_kappa* allContours(iiCell).pixSize,...
            'Marker','.','MarkerSize',15,'LineWidth',2);
        handles.toggleButton2 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.2,0.15,0.08],...
            'Callback',{@toggleVisPlot,h2},...
            'String','centerline');
        
        curvatureMean = mean(abs(allContours(iiCell).kappa_smooth(:)));
        curvatureStd = std(abs(allContours(iiCell).kappa_smooth(:)));
        curvatureMin = min([allContours(iiCell).kappa_smooth(:)',allContours(iiCell).cent_kappa(:)']);
        curvatureMax = max([allContours(iiCell).kappa_smooth(:)',allContours(iiCell).cent_kappa(:)']);
        set(gca,'clim',[-curvatureMean-1.5*curvatureStd;curvatureMean+1.5*curvatureStd]);
        set(gca,'clim',[-1,1]);
        set(gca,'clim',[0,.5]);
        
        colorbar(gca);
        
        
        % contour length of the cell centerline, in pixels
        tCL = allContours(iiCell).centerline;
        % distance between centerline points
        tSegment = diff(tCL);
        tSegment = sqrt(sum(tSegment.^2,2));
        % add up the distance between center line points
        tCumSegLength = cumsum(tSegment);
        % start at 0
        tCumSegLength = [0;tCumSegLength];
        % the final is another measure of the length of the cell
        tclLength = tCumSegLength(end);
        
        % use this length to define poles
        poleFrac = (1-INCLUDE_FRAC)/2;
        % left end of cell body starts at
        leftStart = find(tCumSegLength>poleFrac*tclLength,1,'first');
        % make sure there are at least POLE_MIN_SIZE pixels in the
        % left pole
        leftStart = max(leftStart,POLE_MIN_SIZE+1);
        
        % right end of cell body ends at
        rightEnd = find(tCumSegLength<(1-poleFrac)*tclLength,1,'last');
        % make sure that there are at least POLE_MIN_SIZE pixels in
        % the right pole
        rightEnd = min(length(tCL)-POLE_MIN_SIZE,rightEnd);
        
        h3 = color_line(allContours(iiCell).centerline(leftStart:rightEnd,1),...
            allContours(iiCell).centerline(leftStart:rightEnd,2),...
            allContours(iiCell).cent_kappa(leftStart:rightEnd)*allContours(iiCell).pixSize,...
            'Marker','.','MarkerSize',35,'LineWidth',1);
        handles.toggleButton3 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.3,0.15,0.08],...
            'Callback',{@toggleVisPlot,h3},...
            'String','non-poles centerline');
        [~,clIdx] = pdist2(...
            allContours(iiCell).centerline,...
            [allContours(iiCell).Xcont,allContours(iiCell).Ycont],...
            'euclidean','smallest',1);
        % find the surface idx associated with both poles
        leftPoleSurfIdx = find(clIdx<leftStart);
        rightPoleSurfIdx = find(clIdx>rightEnd);
        bodySurfIdx = find(and(le(clIdx,rightEnd),ge(clIdx,leftStart)));
        
        h4 = color_line(allContours(iiCell).Xcont(bodySurfIdx),allContours(iiCell).Ycont(bodySurfIdx),allContours(iiCell).kappa_smooth(bodySurfIdx),'Marker','.','MarkerSize',35,'LineStyle','none');
        handles.toggleButton4 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.4,0.15,0.08],...
            'Callback',{@toggleVisPlot,h4},...
            'String','non-poles contour');
        [tMTCurvature,tMTX0,tMTY0] = bestFitCircle(allContours(iiCell).centerline(:,1),...
            allContours(iiCell).centerline(:,2));
        disp(tMTCurvature);
        % what orientation do we know about from center to pole
        dx1 = -tMTX0+allContours(iiCell).centerline(1,1);
        dx2 = -tMTX0+allContours(iiCell).centerline(end,1);
        dy1 = -tMTY0+allContours(iiCell).centerline(1,2);
        dy2 = -tMTY0+allContours(iiCell).centerline(end,2);
        
        thetaCirc = linspace(atan2(dy1,dx1),atan2(dy2,dx2),25);
        circX = tMTCurvature*cos(thetaCirc)+tMTX0;
        circY = tMTCurvature*sin(thetaCirc)+tMTY0;
        
        h5 = color_line(circX,circY,repmat(1./tMTCurvature,size(circY)),'linestyle',':','linewidth',3);
        handles.toggleButton5 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.5,0.15,0.08],...
            'Callback',{@toggleVisPlot,h5},...
            'String','circle fit');
        %                 h5 = scatter(tMTX0,tMTY0,'ks');
    end
    
end


%%
%%
figure(gcf);
clf;
randomCellIndex = randi(length(allContours),1);
for jjCell = 1:4
    figure(jjCell);
    clf;
    randomCellIndex = jjCell;
    for iiCell=randomCellIndex;
        subplot(4,4,[1,2,3,5,6,7,9,10,11,13,14,15]);
        
        h1 = color_line(allContours(iiCell).Xcont,allContours(iiCell).Ycont,abs(allContours(iiCell).kappa_smooth),'Marker','.','MarkerSize',15,'LineWidth',3);
        handles.toggleButton1 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.1,0.15,0.08],...
            'Callback',{@toggleVisPlot,h1},...
            'String','uutline');
        axis image;
        hold on;
        title(['Cell number: ',num2str(iiCell)]);
        h2 = color_line(allContours(iiCell).centerline(:,1),allContours(iiCell).centerline(:,2),abs(allContours(iiCell).cent_kappa),'Marker','.','MarkerSize',15,'LineWidth',2);
        handles.toggleButton2 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.2,0.15,0.08],...
            'Callback',{@toggleVisPlot,h2},...
            'String','centerline');
        
        curvatureMean = mean(abs(allContours(iiCell).kappa_smooth(:)));
        curvatureStd = std(abs(allContours(iiCell).kappa_smooth(:)));
        curvatureMin = min([allContours(iiCell).kappa_smooth(:)',allContours(iiCell).cent_kappa(:)']);
        curvatureMax = max([allContours(iiCell).kappa_smooth(:)',allContours(iiCell).cent_kappa(:)']);
        
        
        
        % contour length of the cell centerline, in pixels
        tCL = allContours(iiCell).centerline;
        % distance between centerline points
        tSegment = diff(tCL);
        tSegment = sqrt(sum(tSegment.^2,2));
        % add up the distance between center line points
        tCumSegLength = cumsum(tSegment);
        % start at 0
        tCumSegLength = [0;tCumSegLength];
        % the final is another measure of the length of the cell
        tclLength = tCumSegLength(end);
        
        % use this length to define poles
        poleFrac = (1-INCLUDE_FRAC)/2;
        % left end of cell body starts at
        leftStart = find(tCumSegLength>poleFrac*tclLength,1,'first');
        % make sure there are at least POLE_MIN_SIZE pixels in the
        % left pole
        leftStart = max(leftStart,POLE_MIN_SIZE+1);
        
        % right end of cell body ends at
        rightEnd = find(tCumSegLength<(1-poleFrac)*tclLength,1,'last');
        % make sure that there are at least POLE_MIN_SIZE pixels in
        % the right pole
        rightEnd = min(length(tCL)-POLE_MIN_SIZE,rightEnd);
        
        h3 = color_line(allContours(iiCell).centerline(leftStart:rightEnd,1),...
            allContours(iiCell).centerline(leftStart:rightEnd,2),...
            abs(allContours(iiCell).cent_kappa(leftStart:rightEnd))* allContours(iiCell).pixSize,...
            'Marker','.','MarkerSize',35,'LineWidth',1);
        handles.toggleButton3 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.3,0.15,0.08],...
            'Callback',{@toggleVisPlot,h3},...
            'String','non-poles centerline');
        [~,clIdx] = pdist2(...
            allContours(iiCell).centerline,...
            [allContours(iiCell).Xcont,allContours(iiCell).Ycont],...
            'euclidean','smallest',1);
        % find the surface idx associated with both poles
        leftPoleSurfIdx = find(clIdx<leftStart);
        rightPoleSurfIdx = find(clIdx>rightEnd);
        bodySurfIdx = find(and(le(clIdx,rightEnd),ge(clIdx,leftStart)));
        
        h4 = color_line(allContours(iiCell).Xcont(bodySurfIdx),allContours(iiCell).Ycont(bodySurfIdx),abs(allContours(iiCell).kappa_smooth(bodySurfIdx)),'Marker','.','MarkerSize',35,'LineStyle','none');
        handles.toggleButton4 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.4,0.15,0.08],...
            'Callback',{@toggleVisPlot,h4},...
            'String','non-poles contour');
        [tMTCurvature,tMTX0,tMTY0] = bestFitCircle(allContours(iiCell).centerline(:,1),...
            allContours(iiCell).centerline(:,2));
        disp(tMTCurvature);
        % what orientation do we know about from center to pole
        dx1 = -tMTX0+allContours(iiCell).centerline(1,1);
        dx2 = -tMTX0+allContours(iiCell).centerline(end,1);
        dy1 = -tMTY0+allContours(iiCell).centerline(1,2);
        dy2 = -tMTY0+allContours(iiCell).centerline(end,2);
        
        thetaCirc = linspace(atan2(dy1,dx1),atan2(dy2,dx2),25);
        circX = tMTCurvature*cos(thetaCirc)+tMTX0;
        circY = tMTCurvature*sin(thetaCirc)+tMTY0;
        
        h5 = color_line(circX,circY,...
            abs(repmat(1./tMTCurvature,size(circY))),...
            'linestyle',':','linewidth',3);
        handles.toggleButton5 = uicontrol('style','togglebutton',...
            'units','normalized',...
            'Position',[0.8,0.5,0.15,0.08],...
            'Callback',{@toggleVisPlot,h5},...
            'String','circle fit');
        
        set(gca,'clim',[-curvatureMean-1.5*curvatureStd;curvatureMean+1.5*curvatureStd]);
        set(gca,'clim',[0,0.3]);
        colorbar(gca);
        %                 h5 = scatter(tMTX0,tMTY0,'ks');
    end
    
end