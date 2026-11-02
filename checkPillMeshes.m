%%
fileList = uipickfiles();

%%
figure();
for iFile = 1:length(fileList)
    
    tempLoad = load(fileList{iFile});
    objectList = tempLoad.frame.object;
    figure(gcf);
    clf;
    hold all;
    for iObject = 1:length(objectList)
        if not(isempty(objectList(iObject).centerline))
            plot(objectList(iObject).Xcont,objectList(iObject).Ycont,'r')
               plot( objectList(iObject).pill_mesh(:,[1,3])',...
                   objectList(iObject).pill_mesh(:,[2,4])','g')
            
        else
            plot(objectList(iObject).Xcont,objectList(iObject).Ycont,'b')

        end
    end
    axis equal
    uitoolbar;
    pause();

end