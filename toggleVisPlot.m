
function hObject = toggleVisPlot(hObject,eventdata,plotHandles)
xlimits = get(get(plotHandles,'parent'),'xlim');
ylimits = get(get(plotHandles,'parent'),'ylim');


if get(hObject,'Value')
    set(plotHandles,'Visible','off');
else
    set(plotHandles,'Visible','on');
end

set(get(plotHandles,'parent'),'xlim',xlimits);
set(get(plotHandles,'parent'),'ylim',ylimits);

